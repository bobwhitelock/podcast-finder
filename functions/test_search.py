
from datetime import datetime
from unittest.mock import MagicMock
import json
import os
import yaml

import search


def test_gives_correct_results():
    load_environment()

    query = 'jeremy scahill'
    event = {
        'queryStringParameters': {'query': query}
    }

    response = search.main(event, None)

    assert response['statusCode'] == 200

    body = json.loads(response['body'])
    episodes = body['results']
    assert len(episodes) == 20

    # This podcast title should appear at least once.
    expected_show_title = 'intercepted'
    show_titles = [episode['show_title'].lower() for episode in episodes]
    assert any([expected_show_title in title for title in show_titles])

    episodes_with_newest_first = sorted(
        episodes,
        key=lambda e: datetime.strptime(e['date_created'], '%Y-%m-%d'),
        reverse=True
    )
    assert episodes == episodes_with_newest_first


def test_without_query():
    load_environment()

    event = {
        'queryStringParameters': None
    }

    response = search.main(event, None)
    assert response['statusCode'] == 400
    assert response['body'] == ''


def test_with_bad_query():
    load_environment()

    event = {
        'queryStringParameters': {'foo': 'bar'}
    }

    response = search.main(event, None)
    assert response['statusCode'] == 400
    assert response['body'] == ''


def load_environment():
    stage = 'dev'
    with open('secrets.yml') as f:
        secrets = yaml.load(f)[stage].items()

    for var, value in secrets:
        os.environ[var] = value


# Unit-y tests (shouldn't attempt to make AudioSearch API requests).

def test_wraps_query_in_quotes(mocker):
    """So only get exact matches for query"""
    mocker.patch('search.perform_search',
                 MagicMock(return_value={'results': []})
                 )

    query = 'some person'
    event = {
        'queryStringParameters': {'query': query}
    }
    search.main(event, None)

    search.perform_search.assert_called_once_with('"some person"')


def test_strips_other_double_quotes(mocker):
    """These cause AudioSearch API to give 500 error"""
    mocker.patch('search.perform_search',
                 MagicMock(return_value={'results': []})
                 )

    query = 'some person"'
    event = {
        'queryStringParameters': {'query': query}
    }
    search.main(event, None)

    search.perform_search.assert_called_once_with('"some person"')
