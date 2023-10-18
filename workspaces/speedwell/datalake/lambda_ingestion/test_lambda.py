from lambda_function import lambda_handler
from pytest import fixture


@fixture
def event():
    return {
        "Records": [
            {
                "s3": {
                    "s3SchemaVersion": "1.0",
                    "bucket": {
                        "name": "speedwell-speedwell-datalake-ingestion-dev",
                        "arn": "arn:aws:s3:::speedwell-speedwell-datalake-ingestion-dev",
                    },
                    "object": {
                        "key": "test4.csv",
                        "size": 63,
                        "eTag": "14b5c8e530d593d14f5e5d64ca5aa011",
                        "sequencer": "0065208A918396337A",
                    },
                },
            }
        ]
    }


@fixture
def context():
    return {}


def test_lambda(event, context):
    lambda_handler(event, context)
