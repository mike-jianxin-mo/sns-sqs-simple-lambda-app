import boto3
from botocore.exceptions import BotoCoreError, ClientError

def alarm_email_handler(event, context):
    ses = boto3.client('ses')

    try:
        response = ses.send_email(
            Source='sender@example.com',
            Destination={
                'ToAddresses': [
                    'recipient@example.com',
                ],
            },
            Message={
                'Subject': {
                    'Data': 'Test Email',
                },
                'Body': {
                    'Text': {
                        'Data': 'Test Email Body',
                    },
                },
            },
        )
    except (BotoCoreError, ClientError) as error:
        print(error)
        return "Email not sent"
    
    print("Email sent! Message ID:"),
    print(response['MessageId'])
    return "Email sent!"
