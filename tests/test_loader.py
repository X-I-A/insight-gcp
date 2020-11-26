import json
import base64
import gzip
import pytest
from loader.main import app

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

def test_loader(client):
    load_config = {
        'publisher_id': 'pubsub',
        'src_topic_id': 'test-001',
        'src_table_id': 'aged_data',
        'destination': 'x-i-a-test',
        'tar_topic_id': 'test-002',
        'tar_table_id': 'aged_data',
        'load_type': 'initial'
    }
    envoloppe = {'message': {'attributes': {'load_config': json.dumps(load_config)},
        'data': base64.b64encode(gzip.compress(b'[]')).decode()}}
    response = client.post('/', json=envoloppe)
    assert response.status_code == 200

def test_exceptions(client):
    envoloppe = ['Hello', 'World']
    response = client.post('/', json=envoloppe)
    assert response.status_code == 204
    header = {"Hello": "World"}
    response = client.post('/', headers=header)