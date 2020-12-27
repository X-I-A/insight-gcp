import os
import json
import base64
import gzip
import requests
from flask import Flask, request, Response, render_template
import google.auth
import google.oauth2.id_token
import google.auth.transport.requests
import google.cloud.logging
from pyinsight import Insight, Caller

INSIGHT_URL = os.environ.get('INSIGHT_LINKER_URL', 'https://insight-linker-aaaaaaaaaa-ew.a.run.app')[8:]

app = Flask(__name__)

credentials, project_id = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])

@app.route('/', methods=['GET', 'POST'])
def main():
    if request.method == 'GET':
        return render_template("index.html"), 200
    envelope = request.get_json()
    if not envelope:
        return "no Pub/Sub message received", 204
    if not isinstance(envelope, dict) or 'message' not in envelope:
        return "invalid Pub/Sub message format", 204
    data_header = envelope['message']['attributes']
    data_body = json.loads(gzip.decompress(base64.b64decode(envelope['message']['data'])).decode())

    caller = Caller(insight_id=INSIGHT_URL)
    insight_url, path, api_data = caller.prepare_call(data_header, data_body)

    auth_req = google.auth.transport.requests.Request()
    credentials.refresh(auth_req)
    target_audience = "https://" + insight_url
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, target_audience)

    api_path = 'https://' + caller.api_url + path
    api_headers = {'insight_url': insight_url, 'insight_auth': ' '.join(['Bearer', id_token])}

    resp = requests.post(api_path, headers=api_headers, json=api_data)

    if resp.status_code == 200:  # pragma: no cover
        return "message received", 200  # pragma: no cover
    else:
        return resp.text, resp.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))  # pragma: no cover