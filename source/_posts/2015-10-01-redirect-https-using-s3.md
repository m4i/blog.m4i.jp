---
title: S3 で HTTPS をリダイレクトする
tags: S3 CloudFront
---
ドメインが変わった時など、古いURLから新しいURLに自動でリダイレクトしたい時がある。
そのためにサーバを用意してもよいけど、ただリダイレクトするためにサーバを用意するのは大変だ。

http の場合は [S3 を使うのが簡単](http://docs.aws.amazon.com/AmazonS3/latest/UG/ConfiguringBucketWebsite.html)。

一方で https の場合は S3 単独ではうまくいかない。
S3 website endpoint は [HTTPS に対応していないからだ](http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteEndpoints.html)。
そこで CloudFront と組み合わせて使うとうまくいく。

`old.example.com` から新しい URL にリダイレクトするときの手順は以下のとおり。

1. S3 で http のリダイレクトをしたい時と全く同じ設定をする
2. SSL 証明書を IAM にアップロードする
3. CloudFront で distribution を作成する
    1. "Origin Domain Name" に、
       選択肢としてでてくる S3 bucket `old.example.com` を指定せずに、
       S3 website endpoint `old.example.com.s3-website-{region}.amazonaws.com` を指定する
    2. "Origin Protocol Policy" に "HTTP Only" を指定する
    3. "Alternate Domain Names (CNAMEs)" に `old.example.com` を指定する
    4. "SSL Certificate" に IAM にアップロードした SSL 証明書を指定する
4. DNS の設定で `old.example.com` の CNAME を、割り当てられた CloudFront のホストに設定する
