import boto3
import os
import json
from botocore.config import Config

s3_client = boto3.client('s3',
                         region_name=os.environ.get('AWS_REGION'),
                         config=Config(signature_version='s3v4'))

def lambda_handler(event, context):
    
    cors_headers = {
        "Access-Control-Allow-Origin": os.environ.get('CLOUDFRONT_URL', '*'),
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
    }
    
    try:
        body = json.loads(event['body'])
        filename = body['filename']
        content_type = body['contentType']
    except Exception as e:
        return {
            'statusCode': 400,
            'headers': cors_headers,
            'body': json.dumps(f'Error: Missing or invalid request body. {str(e)}')
        }

    bucket_name = os.environ['UPLOAD_BUCKET_NAME']
    
    try:
        presigned_post = s3_client.generate_presigned_post(
            Bucket=bucket_name,
            Key=filename,
            Fields={"Content-Type": content_type},
            Conditions=[{"Content-Type": content_type}],
            ExpiresIn=3600
        )
        
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps(presigned_post)
        }
    except Exception as e:
        print(f"Error generating pre-signed post: {e}")
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps('Error generating upload URL.')
        }