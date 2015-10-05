---
title: ブログを HTTPS 化した
tags: CloudFront S3
---
最近はブログも HTTPS が当たり前らしいのでこのブログも HTTPS 化することにした。
このブログは S3 上にホストされているので CloudFront と組み合わせることによって実現している。

やったのは以下のこと。

1. 証明書を取得
    * 無料キャンペーンをやってたのでさくらのSSLで
    * 来年の証明書更新時には [Let's Encrypt](https://letsencrypt.org/) に期待
2. CloudFront を準備
    * [「S3 で HTTPS をリダイレクトする」](/2015/10/01/redirect-https-using-s3) で書いた手順とほぼ同じ
    * 加えて
        * Viewer Protocol Policy: Redirect HTTP to HTTPS
        * Default TTL: 31536000
3. [meta referrer を追加](#meta-referrer)
4. [デプロイ時に CloudFront のキャッシュを削除するように変更](#cloudfront-)

CloudFront では HTTP/2 が使えないので個人的にはメリットはあまりないが、
勢いで後戻りできない道に踏み込んでしまった。


## meta referrer

https のページから http のページに遷移した場合、通常リファラは送信されない。
これは今回の HTTPS 化の目的には含まれないので、今までどおり送信されるようにしたい。

以下の1行を追加すれば大体のブラウザはリファラを送信してくれるようになる。

{% highlight html %}
<meta name="referrer" content="unsafe-url">
{% endhighlight %}

## CloudFront のキャッシュ削除

CloudFront から配信するファイルはデフォルトで24時間キャッシュされる。
そのため、ブログ更新を早く反映させたければ何らかの対応が必要。

選択肢は2つ。

1. キャッシュ時間を短くする
2. デプロイ時にキャッシュを削除する

Jekyll での個人ブログという性質上、コンテンツが変化するタイミングが少ないため 2 で行きたい。
そして 2 で行くならば、むしろキャッシュ時間を1年に伸ばしても良いくらいだ。

次は、どうやってキャッシュを削除するか。

1. S3 の PUT, DELETE のタイミングで Lambda を利用しキャッシュを削除する
2. デプロイスクリプトの最後でキャッシュを削除する

最初は 1 で行こうかと考えたが、ファイル単位での削除になってしまう。
削除リクエストは1パス $0.005 かかるため、
100記事あって共通部分を変更しようものならそれだけで $0.5 かかってしまうためつらい。

削除リクエストはパスにワイルドカードも利用できるため、
単にすべてのキャッシュを削除するのであれば $0.005 で済む。
デプロイ時にすべてのキャッシュを削除すれば、
その度に S3 から CloudFront へ全ファイル配信しなおしになってしまうが、
個別に削除リクエストするよりは圧倒的に安そうだ。

単にワイルドカードで全ファイルを削除するならば 2 の方が手軽だと考え、
[デプロイスクリプト](https://github.com/m4i/blog.m4i.jp/blob/master/bin/deploy)に以下のコードを追加した

{% highlight ruby %}
Aws::CloudFront::Client.new.create_invalidation(
  distribution_id: distribution_id,
  invalidation_batch: {
    paths: {
      quantity: 1,
      items: ['/*'],
    },
    caller_reference: (Time.now.to_f * 1000).to_i.to_s,
  }
)
{% endhighlight %}
