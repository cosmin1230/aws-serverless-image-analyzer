import boto3, os, json, urllib.parse, datetime
rekognition = boto3.client('rekognition')
sns = boto3.client('sns')
dynamodb = boto3.client('dynamodb')
def lambda_handler(event, context):
    record = event['Records'][0]['s3']
    bucket = record['bucket']['name']
    key = urllib.parse.unquote_plus(record['object']['key'])
    try:
        response = rekognition.detect_labels(Image={'S3Object': {'Bucket': bucket, 'Name': key}}, MaxLabels=10, MinConfidence=90)
        labels = response['Labels']
        dynamodb.put_item(
            TableName=os.environ['DYNAMODB_TABLE_NAME'],
            Item={'ImageKey': {'S': key}, 'RekognitionLabels': {'S': json.dumps(labels)}, 'Timestamp': {'S': str(datetime.datetime.now())}}
        )
        sns.publish(TopicArn=os.environ['SNS_TOPIC_ARN'], Message=f"Image '{key}' processed. Labels: {[l['Name'] for l in labels]}", Subject="Image Analysis Complete")
    except Exception as e:
        print(f"Error processing image {key}: {e}")
        raise e