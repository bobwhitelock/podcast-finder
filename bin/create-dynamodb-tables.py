#!/usr/bin/env python3

import boto3


def main():
    dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')

    dynamodb.create_table(
        TableName='unconfirmed_notification_requests',
        KeySchema=[
            {
                'AttributeName': 'email',
                'KeyType': 'HASH',
            },
            {
                'AttributeName': 'secret',
                'KeyType': 'RANGE',
            },
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'email',
                'AttributeType': 'S',
            },
            {
                'AttributeName': 'secret',
                'AttributeType': 'S',
            },
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 1,
            'WriteCapacityUnits': 1,
        }
    )


if __name__ == "__main__":
    main()
