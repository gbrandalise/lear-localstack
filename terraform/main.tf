resource "aws_s3_bucket" "localstack-thumbnails-app-images" {
  bucket = "localstack-thumbnails-app-images"
}

resource "aws_s3_bucket" "localstack-thumbnails-app-resized" {
  bucket = "localstack-thumbnails-app-resized"
}