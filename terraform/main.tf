resource "aws_s3_bucket" "localstack-thumbnails-app-images" {
  bucket = "localstack-thumbnails-app-images"
}

resource "aws_s3_bucket" "localstack-thumbnails-app-resized" {
  bucket = "localstack-thumbnails-app-resized"
}

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