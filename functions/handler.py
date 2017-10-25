
from http import HTTPStatus as status
import audiosearch
import json
import os


def search(event, _context):
    params = event['queryStringParameters']
    query = params and params.get('query')
    if not query:
        return {
            'statusCode': status.BAD_REQUEST,
            'body': ''
        }

    normalized_query = '"{}"'.format(
        query.replace('"', '')
    )
    search_response = perform_search(normalized_query)
    body = {
        'results': search_response['results'],
    }

    response = {
        'statusCode': status.OK,
        'body': json.dumps(body)
    }

    return response


def perform_search(query):
    audiosearch_client = audiosearch.Client(
        os.environ['AUDIOSEARCH_ID'],
        os.environ['AUDIOSEARCH_SECRET']
    )

    return audiosearch_client.search(
        {'q': query, 'from': 0, 'size': 20}, 'episodes'
    )
