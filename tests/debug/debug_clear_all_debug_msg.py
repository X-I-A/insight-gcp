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
    print("{}: {}".format(subscription_id, header))
    s.ack(project_id, subscription_id, id)

loop = asyncio.get_event_loop()
task_backlog = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-backlog-debug', callback=callback)
task_cockpit = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-cockpit-debug', callback=callback)
task_cleaner = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-cleaner-debug', callback=callback)
task_loader = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-loader-debug', callback=callback)
task_merger = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-merger-debug', callback=callback)
task_packager = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'insight-packager-debug', callback=callback)
task_receiver = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'slt-npl-01-debug', callback=callback)
task_agent = PubsubSubscriber(sub_client=pubsub_v1.SubscriberClient()).stream('x-i-a-test', 'agent-001-debug', callback=callback)
loop.run_until_complete(asyncio.wait([task_backlog,
                                      task_cockpit,
                                      task_cleaner,
                                      task_loader,
                                      task_merger,
                                      task_packager,
                                      task_receiver,
                                      task_agent]))
loop.close()