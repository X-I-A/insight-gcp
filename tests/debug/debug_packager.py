import os
import gzip
import json
import base64
import asyncio
import requests
import google.auth
import google.oauth2.id_token
import google.auth.transport.requests
from google.cloud import pubsub_v1
from google.cloud import firestore
from xialib_gcp import PubsubPublisher, PubsubSubscriber, FirestoreDepositor, GCSStorer, GCSListArchiver
from pyinsight import Insight, Packager

project_id = google.auth.default()[1]
firestore_db = firestore.Client()
gcs_storer = GCSStorer()
packager_url = 'https://insight-packager-zmfr66omva-ew.a.run.app'

def get_auth_header(target_url: str) -> dict:
    credentials, project_id = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    target_audience = target_url
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, target_audience)
    return {'Authorization': ' '.join(['Bearer', id_token])}

def get_envelope(header: dict, data: list) -> dict:
    return {'message': {'attributes': header,
                        'data': base64.b64encode(gzip.compress(json.dumps(data, ensure_ascii=False).encode())).decode()
                        }
            }

def packager_direct_post(packager_url: str, topic_id: str, table_id: str):
    headers = get_auth_header(packager_url)
    packager_header = {'topic_id': topic_id, 'table_id': table_id, 'data_spec': 'internal'}
    json_data = get_envelope(packager_header, [])
    response = requests.post(packager_url, headers=headers, json=json_data)
    return response

def packager_callback(s: PubsubSubscriber, message: dict, source, subscription_id):
    global firestore_db
    global gcs_storer
    depositor = FirestoreDepositor(db=firestore_db)
    archiver = GCSListArchiver(storer=gcs_storer)
    packager = Packager(archiver=archiver, depositor=depositor)
    header, data, id = s.unpack_message(message)
    header = dict(header)
    packager.package_data(header['topic_id'], header['table_id'])
    s.ack(project_id, subscription_id, id)


if __name__=='__main__':
    print(packager_direct_post(packager_url, 'slt-npl-01', 'NPL...BKPF'))
    """
    loop = asyncio.get_event_loop()
    subscriber = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient())
    task = subscriber.stream('x-i-a-test', 'insight-cleaner-debug', callback=packager_callback)
    loop.run_until_complete(asyncio.wait([task]))
    loop.close()
    """
