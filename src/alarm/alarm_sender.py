import boto3
from botocore.exceptions import BotoCoreError, ClientError
from config import EMAIL_CONFIG

def lambda_handler(event, context):
    ses = boto3.client('ses')

    try:
        response = ses.send_email(**EMAIL_CONFIG)
    except (BotoCoreError, ClientError) as error:
        print(error)
        return "Email not sent"
    
    print("Email sent! Message ID:")
    print(response['MessageId'])
    return "Email sent!"
