
from http import HTTPStatus as status
import boto3
import json
import os
import secrets
import urllib


def main(event, _context):
    if not event['body']:
        return {
            'statusCode': status.BAD_REQUEST,
            'body': '',
        }

    body = json.loads(event['body'])
    email = body.get('email')
    query = body.get('query')
    if not all([email, query]):
        return {
            'statusCode': status.BAD_REQUEST,
            'body': '',
        }

    generated_secret_token = secrets.token_urlsafe(32)
    url_query_params = [
        ('email', email),
        ('secret', generated_secret_token),
    ]
    encoded_query = urllib.parse.urlencode(url_query_params)
    path = 'confirm-notification-request?'
    confirmation_link = ''.join([
        'https://', os.environ['API_DOMAIN_NAME'], '?', path, encoded_query
    ])

    ses = boto3.client('ses', region_name='eu-west-1')
    ses.send_email(
        Source=os.environ['EMAIL_SEND_ADDRESS'],
        Destination={
            'ToAddresses': [email]
        },
        Message={
            'Subject': {
                'Data': 'Confirm request for notifications: {}'.format(query),
            },
            'Body': {
                'Text': {
                    'Data':
                    'Visit this link to confirm request: {}'.format(
                        confirmation_link
                    )
                }

            }
        }
    )

    return {
        'statusCode': status.OK,
        'body': '',
    }
