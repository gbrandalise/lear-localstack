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
  topic_arn = "arn:aws:sns:us-east-1:000000000000:failed-resize-topic"
  protocol  = "email"
  endpoint  = "giovanny.brandalise@gmail.com"
}