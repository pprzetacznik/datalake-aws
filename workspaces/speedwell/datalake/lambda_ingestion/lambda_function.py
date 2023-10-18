import os
import json
import boto3
import pandas


stream_name = os.getenv("LAMBDA_INGESTION_STREAM_NAME")
stream_arn = os.getenv("LAMBDA_INGESTION_STREAM_ARN")


def handle_record(record):
    s3_properties = record.get("s3")
    bucket_arn = s3_properties.get("bucket").get("arn")
    bucket_name = s3_properties.get("bucket").get("name")
    bucket_path = s3_properties.get("object").get("key")
    print(bucket_arn)
    print(bucket_path)

    kinesis = boto3.client("kinesis")

    s3 = boto3.client("s3")
    data = s3.get_object(Bucket=bucket_name, Key=bucket_path)
    print(data)
    body = data.get("Body")
    df = pandas.read_csv(body)
    json_records = df.to_dict(orient="records")
    print(json_records)
    for json_record in json_records:
        print(json_record)
        response = kinesis.put_record(
            Data=json.dumps(json_record),
            PartitionKey="my_string",
            StreamName=stream_name,
            StreamARN=stream_arn,
        )
        print(response)


def lambda_handler(event, context):
    if not (stream_name and stream_arn):
        return {"statusCode": 400, "body": "Kinesis stream not provided"}

    records = event.get("Records")
    for record in records:
        handle_record(record)
    result = "Hello World"
    print(context)
    return {"statusCode": 200, "body": result}
