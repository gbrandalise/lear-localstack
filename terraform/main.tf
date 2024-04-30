# 2. Cria os buckets S3
resource "aws_s3_bucket" "localstack-thumbnails-app-images" {
  bucket = "localstack-thumbnails-app-images"
}

resource "aws_s3_bucket" "localstack-thumbnails-app-resized" {
  bucket = "localstack-thumbnails-app-resized"
}

# 3. Adiciona o nome dos buckets ao Parameter Store para uso futuro
resource "aws_ssm_parameter" "ssm-parameter-localstack-thumbnail-app-buckets-images" {
  name  = "/localstack-thumbnail-app/buckets/images"
  type = "String"
  value = "localstack-thumbnails-app-images"
}

resource "aws_ssm_parameter" "ssm-parameter-localstack-thumbnail-app-buckets-resized" {
  name = "/localstack-thumbnail-app/buckets/resized"
  type = "String"
  value = "localstack-thumbnails-app-resized"
}

# 4. Cria Topico do SNS para as falhas nas chamadas dos Lambdas
resource "aws_sns_topic" "failed-resize-topic" {
  name = "failed-resize-topic"
}

resource "aws_sns_topic_subscription" "failed-resize-topic-subscription" {
  topic_arn = aws_sns_topic.failed-resize-topic.arn
  protocol  = "email"
  endpoint  = "giovanny.brandalise@gmail.com"
}

# 5. Cria o Lambda do presign
data "archive_file" "presign-zip" {
  type        = "zip"
  source_file = "../sample-serverless-image-resizer-s3-lambda/lambdas/presign/handler.py"
  output_path = "presign.zip"
}

resource "aws_lambda_function" "presign" {
  function_name = "presign"
  runtime       = "python3.11"
  timeout       = "10"
  filename      = data.archive_file.presign-zip.output_path
  handler       = "handler.handler"
  role          = "arn:aws:iam::000000000000:role/lambda-role"

  environment {
    variables = {
      STAGE = "local"
    }
  }
}

resource "aws_lambda_function_url" "presign" {
  function_name      = aws_lambda_function.presign.function_name
  authorization_type = "NONE"
}

# 6. Cria o Lambda da lista de imagens
data "archive_file" "list-zip" {
  type        = "zip"
  source_file = "../sample-serverless-image-resizer-s3-lambda/lambdas/list/handler.py"
  output_path = "list.zip"
}

resource "aws_lambda_function" "list" {
  function_name = "list"
  runtime       = "python3.11"
  timeout       = "10"
  filename      = data.archive_file.list-zip.output_path
  handler       = "handler.handler"
  role          = "arn:aws:iam::000000000000:role/lambda-role"

  environment {
    variables = {
      STAGE = "local"
    }
  }
}

resource "aws_lambda_function_url" "list" {
  function_name      = aws_lambda_function.list.function_name
  authorization_type = "NONE"
}

# 7. Cria o Lambda resizer
data "archive_file" "resize-zip" {
  type        = "zip"
  source_dir  = "../sample-serverless-image-resizer-s3-lambda/lambdas/resize/package/"
  output_path = "resize.zip"
}

resource "aws_lambda_function" "resize" {
  function_name = "resize"
  runtime       = "python3.11"
  timeout       = "10"
  filename      = data.archive_file.resize-zip.output_path
  handler       = "handler.handler"
  role          = "arn:aws:iam::000000000000:role/lambda-role"

  dead_letter_config {
    target_arn = aws_sns_topic.failed-resize-topic.arn
  }

  environment {
    variables = {
      STAGE = "local"
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "resize" {
  function_name                = aws_lambda_function.resize.function_name
  maximum_event_age_in_seconds = "3600"
  maximum_retry_attempts       = "0"
}

# 8. Conecta o bucket S3 ao Lambda resizer
resource "aws_s3_bucket_notification" "localstack-thumbnails-app-images" {
  bucket = aws_s3_bucket.localstack-thumbnails-app-images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.resize.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# 9. Cria o website estático no S3
resource "aws_s3_bucket" "webapp" {
  bucket = "webapp"
}

resource "aws_s3_object" "copy-webapp-files" {
  bucket        = aws_s3_bucket.webapp.id
  for_each      = fileset("../sample-serverless-image-resizer-s3-lambda/website", "**/*.*")
  key           = each.value
  source        = "../sample-serverless-image-resizer-s3-lambda/website/${each.value}"
  content_type  = "text/html"
}

resource "aws_s3_bucket_website_configuration" "webapp" {
  bucket = aws_s3_bucket.webapp.id

  index_document {
    suffix = "index.html"
  }
}