import os
import json
import gzip
import base64
import pytest
from receiver.main import app

@pytest.fixture(scope="module")
def client():
    client = app.test_client()
    ctx = app.app_context()
    ctx.push()
    yield client
    ctx.pop()

def test_homepage(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Insight' in response.data

def test_get_receive_page(client):
    response = client.get('/topics/test-001')
    assert response.status_code == 200

def test_receive_age_header(client):
    with open(os.path.join('.', 'input', 'person_complex', 'schema.json'), 'rb') as f:
        data_header = json.loads(f.read().decode())
        field_data = data_header.pop('columns')
        header = {'topic_id': 'test-001', 'table_id': 'aged_data', 'aged': 'True',
                  'data_encode': 'flat', 'data_format': 'record', 'data_spec': 'x-i-a', 'data_store': 'body',
                  'age': '1', 'start_seq': '20201113222500000000', 'meta-data': data_header}
    envoloppe = {'message': {'attributes': header,
        'data': base64.b64encode(gzip.compress(json.dumps(field_data, ensure_ascii=False).encode())).decode()}}
    response = client.post('/topics/test-001', json=envoloppe)
    assert response.status_code == 200

def test_exceptions(client):
    envoloppe = ['Hello', 'World']
    response = client.post('/topics/test-001', json=envoloppe)
    assert response.status_code == 204
    header = {"Hello": "World"}
    response = client.post('/topics/test-001', headers=header)