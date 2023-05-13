# setting lambda file
data "archive_file" "zip_the_alarm_sender" {
  type        = "zip"
  source_dir  = "${path.module}/../src/alarm/"
  output_path = "${path.module}/../src/alarm/alarm_sender.zip"
}

# setting lambda file of the email sending function
resource "aws_lambda_function" "alarm_sender_lambda_func" {
  filename      = "${path.module}/../src/alarm/alarm_sender.zip"
  function_name = "alarm-email-sender"
  role          = aws_iam_role.lambda_role.arn
  handler       = "alarm_sender.alarm_email_handler"
  runtime       = "python3.10"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# SES policy
resource "aws_iam_policy" "ses_policy_for_alarm_email" {

  name        = "${var.project}-alarm_sender_policy_for_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for alarm email sending lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
    "Effect": "Allow",
    "Action": [
        "ses:*"
    ],
    "Resource": "*"
   }
 ]
}
EOF
}

# attach email policy to lambda role
resource "aws_iam_role_policy_attachment" "attach_ses_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ses_policy_for_alarm_email.arn
}

# event source mapping for lambda function
resource "aws_lambda_event_source_mapping" "alarm_email_event_source_mapping" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  function_name    = aws_lambda_function.alarm_sender_lambda_func.arn
}
