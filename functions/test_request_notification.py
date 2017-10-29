
from moto import mock_ses
from unittest.mock import Mock
import boto3
import json
import os
import urllib

import request_notification
import testing_utils


@mock_ses
def test_gives_correct_response_on_success(mocker):
    testing_utils.load_environment()

    ses = boto3.client('ses', region_name='eu-west-1')
    ses.verify_email_identity(EmailAddress='bob.whitelock1@gmail.com')

    request_body_json = {
        'email': 'bob.whitelock1@gmail.com',
        'query': 'things'
    }

    response = request_notification.main({
        'body': json.dumps(request_body_json)
    },
        None
    )
    assert response['statusCode'] == 200
    assert response['body'] == ''


@mock_ses
def test_sends_confirmation_email(mocker):
    testing_utils.load_environment()

    mock_ses_client = Mock()
    mocker.patch('boto3.client', Mock(return_value=mock_ses_client))

    mock_secret_token = 'some-secret-token'
    mocker.patch('secrets.token_urlsafe',
                 Mock(return_value=mock_secret_token)
                 )

    request_body_json = {
        'email': 'bob.whitelock1@gmail.com',
        'query': 'things'
    }

    request_notification.main({
        'body': json.dumps(request_body_json)
    },
        None
    )

    _, email_params = mock_ses_client.send_email.call_args
    assert email_params['Source'] == os.environ['EMAIL_SEND_ADDRESS']
    assert email_params['Destination'] == {
        'ToAddresses': [request_body_json['email']]
    }
    assert email_params['Message']['Subject'] == {
        'Data': 'Confirm request for notifications: {}'.format(
            request_body_json['query']
        ),
    }

    expected_url_query_params = [
        ('email', request_body_json['email']),
        ('secret', mock_secret_token),
    ]
    expected_url_path = 'confirm-notification-request?' + \
        urllib.parse.urlencode(expected_url_query_params)

    expected_confirmation_link = \
        'https://' + os.environ['API_DOMAIN_NAME'] + '?' + expected_url_path
    email_body_text = email_params['Message']['Body']['Text']['Data']
    assert expected_confirmation_link in email_body_text


@mock_ses
def test_with_empty_body(mocker):
    testing_utils.load_environment()

    ses = boto3.client('ses', region_name='eu-west-1')
    ses.verify_email_identity(EmailAddress='bob.whitelock1@gmail.com')

    response = request_notification.main({
        'body': None
    },
        None
    )
    assert response['statusCode'] == 400
    assert response['body'] == ''


@mock_ses
def test_without_required_body_data(mocker):
    testing_utils.load_environment()

    ses = boto3.client('ses', region_name='eu-west-1')
    ses.verify_email_identity(EmailAddress='bob.whitelock1@gmail.com')

    response = request_notification.main({
        'body': '{}'
    },
        None
    )
    assert response['statusCode'] == 400
    assert response['body'] == ''
