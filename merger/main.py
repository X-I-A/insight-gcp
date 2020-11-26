import os
import json
import base64
import gzip
import hashlib
from flask import Flask, request, Response, render_template
import google.auth
from google.cloud import pubsub_v1
from google.cloud import firestore
from xialib_gcp import PubsubPublisher, FirestoreDepositor
from pyinsight import Insight, Merger


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


@app.route('/', methods=['GET', 'POST'])
def insight_receiver():
    if request.method == 'GET':
        return render_template("index.html"), 200
    envelope = request.get_json()
    if not envelope:
        return "no Pub/Sub message received", 204
    if not isinstance(envelope, dict) or 'message' not in envelope:
        return "invalid Pub/Sub message format", 204
    data_header = envelope['message']['attributes']

    global firestore_db
    depositor = FirestoreDepositor(db=firestore_db)
    merger = Merger(depositor=depositor)

    if merger.merge_data(data_header['topic_id'],
                         data_header['table_id'],
                         data_header['merge_key'],
                         int(data_header['merge_level']),
                         int(data_header['target_merge_level'])):
        return "merge message received", 200 # pragma: no cover
    else:  # pragma: no cover
        return "merge message to be resent", 400  # pragma: no cover

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))  # pragma: no cover