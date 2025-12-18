import sys
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import col
# Read arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
# -----------------------------
# Kafka Configuration
# -----------------------------
kafka_bootstrap_servers = "pkc-921jm.us-east-2.aws.confluent.cloud:9092"
kafka_topic = "customer_details"
consumer_group_id = "Meena2"
kafka_security_protocol = "SASL_SSL"
kafka_sasl_mechanism = "PLAIN"
kafka_sasl_jaas_config = 'org.apache.kafka.common.security.plain.PlainLoginModule required username="JDKYQYSIKUK6LMTM" password="cflt/OjjyI4bhflxKEXDXmZKNDXV0ylMLpZUOuF+z0lH4bRXqqLgIK5m1Me8NiXg";'
# -----------------------------
# S3 Output Configuration
# -----------------------------
output_path = "s3://my-kafka-output-bucket1/consumer-data/"
checkpoint_path = "s3://my-kafka-output-bucket1/checkpoints/"
# -----------------------------
#  Read from Confluent Kafka
# -----------------------------
kafka_df = glueContext.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", kafka_bootstrap_servers) \
    .option("subscribe", kafka_topic) \
    .option("startingOffsets", "earliest") \
    .option("kafka.security.protocol", kafka_security_protocol) \
    .option("kafka.sasl.mechanism", kafka_sasl_mechanism) \
    .option("kafka.sasl.jaas.config", kafka_sasl_jaas_config) \
    .load()
# -----------------------------
#  Extract the Kafka message payload
# -----------------------------
value_df = kafka_df.selectExpr("CAST(value AS STRING) as json_value")
# -----------------------------
#  Write stream to S3
# -----------------------------
value_df.writeStream \
    .format("json") \
    .outputMode("append") \
    .option("path", output_path) \
    .option("checkpointLocation", checkpoint_path) \
    .start() \
    .awaitTermination()
