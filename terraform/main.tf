terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "m4i"
    key    = "tfstates/blog.m4i.jp.tfstate"
  }
}

variable "region" {
}

variable "domain" {
}

variable "log_bucket" {
}

variable "acm_certificate_arn" {
}

variable "user_name" {
  default = "blog"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"],
    resources = ["arn:aws:s3:::${var.domain}/*"]
  }
}

resource "aws_s3_bucket" "blog" {
  bucket = "${var.domain}"
  policy = "${data.aws_iam_policy_document.bucket-policy.json}"

  website {
    index_document = ".index"
    error_document = ".404"
    routing_rules  = "${file("routing-rules.json")}"
  }

  logging {
    target_bucket = "${var.log_bucket}"
    target_prefix = "s3/${var.domain}/"
  }
}

resource "aws_cloudfront_distribution" "blog" {
  enabled             = true
  price_class         = "PriceClass_200"
  aliases             = ["${var.domain}"]

  viewer_certificate {
    acm_certificate_arn      = "${var.acm_certificate_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  logging_config {
    bucket = "${var.log_bucket}.s3.amazonaws.com"
    prefix = "cloudfront/${aws_s3_bucket.blog.id}/"
  }

  origin {
    domain_name = "${aws_s3_bucket.blog.website_endpoint}"
    origin_id   = "${aws_s3_bucket.blog.id}"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "${aws_s3_bucket.blog.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    max_ttl                = 31536000
    default_ttl            = 31536000
    compress               = true
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_iam_policy_document" "user-policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.blog.id}"]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.blog.id}/*"]
  }
  statement {
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user" "blog" {
  name = "${var.user_name}"
}

resource "aws_iam_access_key" "blog" {
  user = "${aws_iam_user.blog.name}"
}

resource "aws_iam_user_policy" "blog" {
  name   = "s3,${aws_s3_bucket.blog.id}"
  user   = "${aws_iam_user.blog.name}"
  policy = "${data.aws_iam_policy_document.user-policy.json}"
}

output "cloudfront_distribution_id" {
  value = "${aws_cloudfront_distribution.blog.id}"
}
