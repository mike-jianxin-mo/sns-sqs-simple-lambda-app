# setting lambda file of the email sending function
resource "aws_lambda_function" "email_sender_lambda_func" {
  filename      = "${path.module}/../src/alarm/alarm_sender.zip"
  function_name = "alarm-email-sender"
  role          = aws_iam_role.lambda_role.arn
  handler       = "alarm_sender.alarm_email_handler"
  runtime       = "nodejs18.x"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}