import os
import json
import base64
import gzip
from google.cloud import pubsub_v1
from xialib_gcp import PubsubPublisher
import google.auth
from google.cloud import bigquery
from xialib_gcp import BigQueryAdaptor

def create_ctrl_table():
    conn = bigquery.Client()
    project_id = google.auth.default()[1]
    adaptor = BigQueryAdaptor(connection=conn, project_id=project_id)
    adaptor.create_table(BigQueryAdaptor._ctrl_table_id, '', dict(), BigQueryAdaptor._ctrl_table)

load_config = {
    'publisher_id': 'pubsub',
    'src_topic_id': 'slt-npl-01',
    'src_table_id': 'NPL...MARA',
    'destination': 'x-i-a-test',
    'tar_topic_id': 'agent-001',
    'tar_table_id': '...MARA',
    'fields': ['MANDT', 'MATNR', 'ERNAM', 'MTART', 'NTGEW'],
    'filters': [[]],
    'load_type': 'initial'
}

load_config_bkpf = {
    'publisher_id': 'pubsub',
    'src_topic_id': 'slt-npl-01',
    'src_table_id': 'NPL...BKPF',
    'destination': 'x-i-a-test',
    'tar_topic_id': 'agent-001',
    'tar_table_id': '...BKPF',
    'fields': ['MANDT', 'BUKRS', 'BELNR', 'GJAHR', 'BLART', 'MONAT', 'TCODE', 'WAERS'],
    'filters': [[['GJAHR', '=', 2014]]],
    'load_type': 'initial'
}

pub_client = pubsub_v1.PublisherClient()

publisher = PubsubPublisher(pub_client=pub_client)

publisher.publish('x-i-a-test', 'insight-loader', {'data_spec': 'internal', 'load_config': json.dumps(load_config_bkpf)},
                  base64.b64encode(gzip.compress(b'[]')).decode())
