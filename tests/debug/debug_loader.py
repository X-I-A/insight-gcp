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
from pyinsight import Insight, Loader

project_id = google.auth.default()[1]
Insight.set_internal_channel(messager=PubsubPublisher(pub_client=pubsub_v1.PublisherClient()),
                             channel=project_id,
                             topic_cockpit='insight-cockpit',
                             topic_cleaner='insight-cleaner',
                             topic_merger='insight-merger',
                             topic_packager='insight-packager',
                             topic_loader='insight-loader',
                             topic_backlog='insight-backlog'
)

project_id = google.auth.default()[1]
firestore_db = firestore.Client()
gcs_storer = GCSStorer()
pub_client = pubsub_v1.PublisherClient()
loader_url = 'https://insight-loader-zmfr66omva-ew.a.run.app'

load_config_bkpf = {
    'publisher_id': 'pubsub',
    'src_topic_id': 'slt-npl-01',
    'src_table_id': 'NPL...BKPF',
    'destination': 'x-i-a-test',
    'tar_topic_id': 'agent-001',
    'tar_table_id': '...BKPF',
    'fields': ['MANDT', 'BUKRS', 'BELNR', 'GJAHR', 'BLART', 'MONAT', 'TCODE', 'WAERS'],
    'filters': [[]],
    'load_type': 'initial'
}

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

def loader_direct_post(cleaner_url: str, topic_id: str, table_id: str, start_seq: str = '99991231000000000000'):
    headers = get_auth_header(cleaner_url)
    clean_header = {'topic_id': topic_id, 'table_id': table_id, 'data_spec': 'internal', 'start_seq': start_seq}
    json_data = get_envelope(clean_header, [])
    response = requests.post(cleaner_url, headers=headers, json=json_data)
    return response

def loader_callback(s: PubsubSubscriber, message: dict, source, subscription_id):
    global project_id
    global firestore_db
    global gcs_storer

    publishers = {'pubsub': PubsubPublisher(pub_client=pub_client)}
    depositor = FirestoreDepositor(db=firestore_db)
    archiver = GCSListArchiver(storer=gcs_storer)
    storers = [gcs_storer]
    loader = Loader(publishers=publishers, depositor=depositor, archiver=archiver, storers=storers)
    header, data, id = s.unpack_message(message)
    print(header)
    #cleaner.clean_data(header['topic_id'], header['table_id'], header['start_seq'])
    loader.load(load_config=json.loads(header['load_config']))
    s.ack(project_id, subscription_id, id)


if __name__=='__main__':
    loop = asyncio.get_event_loop()
    subscriber = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient())
    task = subscriber.stream('x-i-a-test', 'insight-loader-debug', callback=loader_callback)
    loop.run_until_complete(asyncio.wait([task]))
    loop.close()

