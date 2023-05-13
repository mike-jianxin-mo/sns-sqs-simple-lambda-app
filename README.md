### Step 1. Create a SNS + SQS + Lambda function with Terraform

Example of SNS + SQS + Lambda

Ref:
https://www.youtube.com/watch?v=ciTa2I7-tDE

### Step 2. Add Email function

Upload with command:
aws lambda update-function-code --function-name alarm-email-sender --zip-file fileb://alarm_sender.zip --region ap-southeast-1

### Step 3. Add a Lambda function to produce
