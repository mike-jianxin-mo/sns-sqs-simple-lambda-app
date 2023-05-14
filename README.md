### Step 1. Create a SNS + SQS + Lambda function with Terraform

Example of SNS + SQS + Lambda

Ref:
https://www.youtube.com/watch?v=ciTa2I7-tDE

### Step 2. Add Email function

Upload with command:
aws lambda update-function-code --function-name alarm-email-sender --zip-file fileb://alarm_sender.zip --region ap-southeast-1

### Step 3. Add a Lambda message trigger function to produce messages

#### The function running with SAM, And lambda & SNS permission updates needed.

The following access polcies are not working. Because the default allow account user ONLY policy will block the Lambda's permission. I should remove it.

```
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "AllowPublishFromLambda",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::236353575297:role/event-trigger-app-eventTriggerLambdaFunctionRole-17NIULZE6FJ2G"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:ap-southeast-1:236353575297:simple-sns-sqs-msg-sns-topic"
    }
  ]
}
```

This is the wrong settings with the account ONLY permissions.

```
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "AllowPublishFromLambda",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::236353575297:role/event-trigger-app-eventTriggerLambdaFunctionRole-17NIULZE6FJ2G"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:ap-southeast-1:236353575297:simple-sns-sqs-msg-sns-topic"
    }

    {
      "Sid": "__default_statement_ID",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish"
      ],
      "Resource": "arn:aws:sns:ap-southeast-1:236353575297:simple-sns-sqs-msg-sns-topic",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "236353575297"
        }
      }
    }
  ]
}
```

Also, I need to setup the Lambda function permission as well:
Add the following to the default Lambda permissions

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sns:*",
            "Resource": "arn:aws:sns:ap-southeast-1:236353575297:simple-sns-sqs-msg-sns-topic"
        }
    ]
}
```
