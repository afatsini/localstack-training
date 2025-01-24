import boto3
import os
from flask import Flask, send_file, abort


# Constants
ROLE_ARN = 'arn:aws:iam::000000000000:role/S3AssumableRole'  # Replace with your role ARN
SESSION_NAME = 'S3BucketSession'
BUCKET_NAME = 'bucket'  # Replace with the desired bucket name
FILE_NAME = 'index.html'  # The file to upload


def assume_role(role_arn, session_name):
    """
    Assumes the specified IAM role.
    """
    sts_client = boto3.client('sts', endpoint_url='http://localhost:4566', region_name='us-east-1')
    
    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name
    )

    print("Role assumed successfully with credentials: %s", response['Credentials']['AccessKeyId'])
    
    return response['Credentials']

def create_s3_bucket(credentials, bucket_name):
    """
    Creates an S3 bucket using the provided credentials.
    """
    s3_client = boto3.client(
        's3',
        endpoint_url='http://localhost:4566',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
        region_name='us-east-1'
    )
    
    # Create the bucket
    s3_client.create_bucket(Bucket=bucket_name)

    print(f"Bucket '{bucket_name}' created successfully.")

def upload_file(credentials, bucket_name, file_name):
    """
    Uploads a file to the specified S3 bucket.
    """
    s3_client = boto3.client(
        's3',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
        endpoint_url='http://localhost:4566'
    )
    
    # Upload the file
    s3_client.upload_file(file_name, bucket_name, file_name)
    print(f"File '{file_name}' uploaded to bucket '{bucket_name}' successfully.")

def serve_file_from_s3(credentials, bucket_name, file_name):
    """
    Serves a file from the S3 bucket using Flask.
    """
    s3_client = boto3.client(
        's3',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
        endpoint_url='http://localhost:4566'
    )

    # Create a Flask app
    app = Flask(__name__)

    @app.route('/')
    def serve_index():
        try:
            # Download the file from S3 to a temporary location
            s3_client.download_file(bucket_name, file_name, file_name)
            return send_file(file_name)
        except Exception as e:
            print(f"Error: {e}")
            abort(404)

    # Start the Flask application
    app.run(host='0.0.0.0', port=8888)

if __name__ == "__main__":
    # Assume the role
    print("Assuming role...")
    credentials = assume_role(ROLE_ARN, SESSION_NAME)

    # Create an S3 bucket
    create_s3_bucket(credentials, BUCKET_NAME)

     # Upload the file
    upload_file(credentials, BUCKET_NAME, FILE_NAME)

    # Serve the file
    serve_file_from_s3(credentials, BUCKET_NAME, FILE_NAME)