
import json
import os
import yaml
from unittest.mock import MagicMock

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


# Unit-y tests (shouldn't attempt to make AudioSearch API requests).

def test_search_wraps_query_in_quotes(mocker):
    """So only get exact matches for query"""
    mocker.patch('handler.perform_search',
                 MagicMock(return_value={'results': []})
                 )

    query = 'some person'
    event = {
        'queryStringParameters': {'query': query}
    }
    handler.search(event, None)

    handler.perform_search.assert_called_once_with('"some person"')


def test_search_strips_other_double_quotes(mocker):
    """These cause AudioSearch API to give 500 error"""
    mocker.patch('handler.perform_search',
                 MagicMock(return_value={'results': []})
                 )

    query = 'some person"'
    event = {
        'queryStringParameters': {'query': query}
    }
    handler.search(event, None)

    handler.perform_search.assert_called_once_with('"some person"')
