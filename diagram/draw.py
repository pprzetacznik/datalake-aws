from diagrams import Cluster, Diagram
from diagrams.aws.compute import Lambda
from diagrams.aws.storage import S3
from diagrams.aws.analytics import (
    KinesisDataStreams,
    KinesisDataFirehose,
    LakeFormation,
    Athena,
    GlueDataCatalog,
)
from diagrams.aws.management import Cloudwatch


with Diagram("AWS Data Lake", show=False):
    source_bucket = S3("ingestion zone, CSV file")

    with Cluster("ETL pipeline"):
        ingestion_lambda = Lambda("Ingestion lambda")
        kinesis = KinesisDataStreams("Data stream")
        firehose = KinesisDataFirehose("CSV -> Parquet converter")

    with Cluster("Data catalogs"):
        destination_bucket = S3("raw zone, Parquet data")
        glue = GlueDataCatalog("Glue table")
        lake_formation = LakeFormation("Data Catalog permissions")

    logs = Cloudwatch("Logs")
    athena = Athena("Athena analytics")

    (
        source_bucket
        >> ingestion_lambda
        >> kinesis
        >> firehose
        >> destination_bucket
        << glue
    )
    athena >> glue
    ingestion_lambda >> logs
    [firehose, athena] >> lake_formation >> glue
