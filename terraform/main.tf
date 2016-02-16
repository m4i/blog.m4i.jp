provider "aws" {
    region = "${var.aws_region}"
}

resource "template_file" "user-policy" {
    template = "user-policy.json"
    vars {
        bucket_name = "${var.bucket_name}"
    }
}

resource "template_file" "bucket-policy" {
    template = "bucket-policy.json"
    vars {
        bucket_name = "${var.bucket_name}"
    }
}

resource "aws_iam_user" "blog" {
    name = "${var.user_name}"
}

resource "aws_iam_access_key" "blog" {
    user = "${aws_iam_user.blog.name}"
}

resource "aws_iam_user_policy" "blog" {
    name = "s3,${var.bucket_name}"
    user = "${aws_iam_user.blog.name}"
    policy = "${template_file.user-policy.rendered}"
}

resource "aws_iam_server_certificate" "blog_m4i_jp_20161014_cloudfront" {
    name              = "blog.m4i.jp,20161014,cloudfront"
    certificate_body  = "${file("certificates/blog.m4i.jp.20161014.crt")}"
    certificate_chain = "${file("certificates/blog.m4i.jp.20161014.chain.crt")}"
    private_key       = "${file("certificates/blog.m4i.jp.key")}"
    path              = "/cloudfront/"
}

resource "aws_s3_bucket" "blog" {
    bucket = "${var.bucket_name}"
    policy = "${template_file.bucket-policy.rendered}"

    website {
        index_document = ".index"
        error_document = ".404"
    }

    logging {
        target_bucket = "m4i-logs"
        target_prefix = "s3/${var.bucket_name}/"
    }
}
