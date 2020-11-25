import os
import json
import base64
import gzip
import hashlib
from flask import Flask, request, Response, render_template
import google.auth
from google.cloud import pubsub_v1
from google.cloud import firestore
from xialib_gcp import PubsubPublisher, FirestoreDepositor, GCSStorer
from pyinsight import Insight, Dispatcher


app = Flask(__name__)

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

firestore_db = firestore.Client()
pub_client = pubsub_v1.PublisherClient()
gcs_storer = GCSStorer()


@app.route('/')
def main():
    return render_template("index.html")


@app.route('/topics/<topic_id>', methods=['GET', 'POST'])
def insight_receiver(topic_id):
    if request.method == 'GET':
        return "OK", 200
    envelope = request.get_json()
    if not envelope:
        return "no Pub/Sub message received", 204
    if not isinstance(envelope, dict) or 'message' not in envelope:
        return "invalid Pub/Sub message format", 204
    data_header = envelope['message']['attributes']
    data_body = json.loads(gzip.decompress(base64.b64decode(envelope['message']['data'])).decode())

    global firestore_db
    global pub_client
    global gcs_storer
    publishers = {'pubsub': PubsubPublisher(pub_client=pub_client)}
    depositor = FirestoreDepositor(db=firestore_db)
    storers = [gcs_storer]
    dipatcher = Dispatcher(publishers=publishers, depositor=depositor, storers=storers)

    if dipatcher.receive_data(data_header, data_body):
        return "message received", 200
    else:
        return "message to be resent", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))  # pragma: no cover