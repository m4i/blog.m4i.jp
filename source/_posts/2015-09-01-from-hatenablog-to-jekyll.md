---
title: はてなブログから Jekyll へ
tags: Jekyll S3 GitHubPages CircleCI
modified_at: 2015-09-02
---
自分でのブログの運用に疲れ、重要なのは中身だと、
はてなブログに移る人や Qiita をメインにしている人を最近多く見かけるが、
その流れに逆らってはてなブログから自前のブログに移ることにした。

はてなダイアリーから通算では10年間、はてなブログになってからは4年間お世話になりました。


## はてなブログをやめた理由

1. カスタマイズが大変
    * JavaScript, CSS は [GitHub](https://github.com/m4i/m4i.hatenablog.com) で管理していたが、
      ローカルで build してはてなブログの Web UI にコピペというものすごい大変なことをしていた
    * [今は head 内で include できそう](http://staff.hatenablog.com/entry/2014/02/19/191316)なのでもう少し楽かも
1. カスタマイズのデバッグが大変
    * プレビューできないページのテストは工夫が必要
1. カスタマイズしてもしばらく放置すると崩れている
    * HTML 構造が変わったせいなのか、使っていたテーマが変わったせいなのかはわからない
1. ページの表示が遅い
    * 今計測したところ、記事ページが30Mbpsで4.5秒、1Mbpsで7.5秒かかった
1. 独自ドメインを利用していると、はてなブログPro解約後にはてブの URL が変わってしまう


## 新ブログで実現したかったこと

1. はてなブログ記事のインポートは不要
    * やめた理由 5 に書いたとおりはてブの URL は m4i.hatenablog.com のものになる。
      分散を避けるため、過去記事は引き続きはてなブログ上で見れれば十分
1. リダイレクトを使いたい
    * はてなブログ時代の記事の URL にアクセスされた時には、はてなブログにリダイレクトしたい
        * meta refresh でも実用上問題はなさそう
    * はてなブログでは `/feed` で Atom、`/rss` で RSS 2.0 が提供されているが、
      Atom だけにしたいので、`/rss` は `/feed` にリダクレイトしたい
1. ブラウザだけでも記事を書けるようにしたい
    * じっくり書くときはローカルで書いて `git push` も良いが、気軽に書けるようにもしたい
    * 特に誤字脱字などの修正でエディタと git を使うのは辛い
1. 記事の URL は `/title` にしたい
    * `/title.html`, `/title/` は嫌
1. コメント機能はいらない
    * 将来のはてなブログ脱出に備えて Disqus を使ってたけど4年間で1コメントだし全く無駄だった
    * Twitter で十分では
1. 予算ははてなブログPro(8,434円/年)と同程度


## Jekyll + GitHub Pages を検討

最初のうちは、自分用のブログシステムでも作ろうかと考えていたが、
いつまで経っても作る気力は湧かず、その間にいくつもの記事のアイデアが流れていった。
このままではまずいので、まずは手軽に始めようと思い最初に浮かんだのが Jekyll + GitHub Pages だった。

実現したいこと 1, 5, 6 は問題なくクリア。

### 3. ブラウザだけでも記事を書けるようにしたい

GitHub はブラウザ上でプレビュー付きで Markdown ファイルの作成ができる。
作成すれば自動的に GitHub Pages にデプロイしてくれるらしいのでクリア。

### 4. 記事の URL は `/title` にしたい

タイミング良く [Jekyll 3 から可能になった](http://jekyllrb.com/docs/permalinks/#extensionless-permalinks)ようだ。
しかし、[github-pages](https://rubygems.org/gems/github-pages/versions/39) の
Jekyll はまだ 2.4.0 なので自分でデプロイしないといけなそう。

GitHub Pages は `/title.html` を置くと `/title` にアクセスして表示することができる。
一方で `/feed.atom` を置いて `/feed` でアクセスすることはできない。
`/feed.xml` で `/feed` はできるけど `Content-type: text/xml` になってしまう。

許容範囲内なので一応クリア。

### 2. リダイレクトを使いたい

GitHub Pages ではリダイレクトは使えない。
個別記事は meta refresh で良いけど `/rss` -> `/feed` は諦めるしか無い。


## Jekyll + S3 + CircleCI を採用

実現したいこと 2, 4 を完全に解決するために S3 を使うことにした。
リダイレクトはもちろんできるし、Content-Type の設定も自在。

GitHub Pages に比べて劣る点は

* デプロイは自分でする
* 有料

というところ。

デプロイは CI に任せれば良いので CircleCI を使う。  
[circle.yml](https://github.com/m4i/blog.m4i.jp/blob/ed97d2df4016509b7431277492e8fe7dee69c98b/circle.yml)
[deploy script](https://github.com/m4i/blog.m4i.jp/blob/ed97d2df4016509b7431277492e8fe7dee69c98b/bin/deploy)  
数ある CI サービスの中から CircleCI を選んだのは、
Travis CI は開始まで待たされるイメージがある（過去の話？）、
CircleCI は使い慣れている、というだけ。

また有料といっても500アクセス/月しかないのでほぼ無料みたいなもの。
適当な計算によると10万アクセス/月でも $1 なので予算を超える可能性はなさそう。

そういうわけで、Jekyll + S3 + CircleCI でしばらくやっていこうと思う。
