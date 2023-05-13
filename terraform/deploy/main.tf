terraform {
  backend "s3" {
    bucket         = "simple-sns-sqs-message-tfstate"
    key            = "simple-sns-sqs-message.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "simple-sns-sqs-message-tfstate" // with LockID as partition key
  }
}

provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Environment = terraform.workspace
      DevStage    = var.devStage
      Project     = var.project
      Owner       = var.contact
      CreatedBy   = "Mike Mo"
    }
  }
}

resource "aws_sns_topic" "sns_topic" {
  name = "${var.project}-sns-topic"
}

resource "aws_sqs_queue" "sqs_queue" {
  name = "${var.project}-sqs-queue"
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.sqs_queue.arn
}

# setting lambda file
data "archive_file" "zip_the_js_code" {
  type        = "zip"
  source_dir  = "${path.module}/../src/messager/"
  output_path = "${path.module}/../src/messager/simple-msg-handler.zip"
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/../src/messager/simple-msg-handler.zip"
  function_name = "simple-msg-handler-v2"
  role          = aws_iam_role.lambda_role.arn
  handler       = "simple-msg-handler.msg_handler"
  runtime       = "nodejs18.x"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}
# end of setting lambda file

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name        = "${var.project}-policy_for_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

# SQS get Message from SNS policy
# https://dashbird.io/blog/5-common-amazon-sqs-issues/#:~:text=SNS%20Topic%20Not%20Publishing%20to,from%20the%20SNS%20service%20principal.&text=This%20problem%20is%20based%20on,are%20deployed%20in%20your%20account.
# SNS Topic Not Publishing to SQS
data "aws_iam_policy_document" "sqs_reciever_iam_policy" {
  policy_id = "${var.project}-SimpleMessageSQSGetMessageFromSNSPolicy"
  statement {
    sid       = "${var.project}-SimpleMessageSQSGetMessageFromSNSPolicy"
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = ["${aws_sqs_queue.sqs_queue.arn}"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = ["${aws_sns_topic.sns_topic.arn}"]
      variable = "aws:SourceArn"
    }
  }
}

# set policy to SQS queue
resource "aws_sqs_queue_policy" "ses_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
  policy    = data.aws_iam_policy_document.sqs_reciever_iam_policy.json
}

# event source mapping for lambda function
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.sqs_queue.arn
  function_name    = aws_lambda_function.terraform_lambda_func.arn
}

# permission for lambda function to access SQS queue
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "${var.project}-lambda_sqs_policy"
  description = "Permissions required by Lambda function to access SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "${aws_sqs_queue.sqs_queue.arn}" # Replace with your SQS queue ARN
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_sqs_permissions" {
  name       = "${var.project}-lambda-sqs-permissions"
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}
