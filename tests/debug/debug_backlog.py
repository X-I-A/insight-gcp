import os
import gzip
import json
import base64
import asyncio
import google.auth
from google.cloud import pubsub_v1
from xialib_gcp import PubsubSubscriber

project_id = google.auth.default()[1]

def callback(s: PubsubSubscriber, message: dict, source, subscription_id):
    header, data, id = s.unpack_message(message)
    print(header)
    print(json.loads(gzip.decompress(data).decode()))
    # s.ack(project_id, subscription_id, id)

"""
loop = asyncio.get_event_loop()
subscriber = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient())
task = subscriber.stream('x-i-a-test', 'insight-backlog-debug', callback=callback, timeout=2)
loop.run_until_complete(asyncio.wait([task]))
loop.close()
"""

for file_name in os.listdir(os.path.join('.', 'insight', 'messager', 'backlog')):
    with open(os.path.join('.', 'insight', 'messager', 'backlog', file_name)) as fp:
        backlog_data = json.load(fp)
        print(backlog_data)
        print(json.loads(gzip.decompress(base64.b64decode(backlog_data['data'])).decode()))
