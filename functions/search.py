
from http import HTTPStatus as status
import audiosearch
import json
import os


def main(event, _context):
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

    sort_by = 'date_broadcast desc'
    search_params = {
        'q': query,
        's': sort_by,
        'from': 0,
        'size': 20
    }
    return audiosearch_client.search(search_params, 'episodes')
