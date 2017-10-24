
import json
import os
import yaml

import handler


def test_search():
    load_environment()

    query = 'jeremy scahill'
    event = {
        'queryStringParameters': {'query': query}
    }

    response = handler.search(event, None)

    assert response['statusCode'] == 200

    body = json.loads(response['body'])
    show_titles = [
        episode['show_title'].lower()
        for episode in body['results']
    ]

    assert len(show_titles) == 20

    # This podcast title should appear at least once.
    expected_show_title = 'intercepted'
    assert any([expected_show_title in title for title in show_titles])


def test_search_without_query():
    load_environment()

    event = {
        'queryStringParameters': None
    }

    response = handler.search(event, None)
    assert response['statusCode'] == 400
    assert response['body'] == ''


def test_search_with_bad_query():
    load_environment()

    event = {
        'queryStringParameters': {'foo': 'bar'}
    }

    response = handler.search(event, None)
    assert response['statusCode'] == 400
    assert response['body'] == ''


def load_environment():
    stage = 'dev'
    with open('secrets.yml') as f:
        secrets = yaml.load(f)[stage].items()

    for var, value in secrets:
        os.environ[var] = value
