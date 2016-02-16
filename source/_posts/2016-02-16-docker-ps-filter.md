---
title: docker ps --filter で前方/後方一致
tags: Docker
---
前方一致は先頭に `/`、後方一致は末尾に `$` を付ける。

{% highlight plaintext %}
$ docker run -d --name=a-1 busybox sleep 1h
e573427357b0bb0649557f0ba8822152cab8defed3c7d73f3d95c87faaa5fb59

$ docker run -d --name=a-10 busybox sleep 1h
668b39819d5fde507df2fe8f4163da02db9d2d5f1ce541743a3ce19d21e74744

$ docker run -d --name=ba-1 busybox sleep 1h
6a691ce9fb92b96ca3f3908d432099180955095259106337a86828f3d4070225

$ docker ps
CONTAINER ID        ...        NAMES
6a691ce9fb92        ...        ba-1
668b39819d5f        ...        a-10
e573427357b0        ...        a-1

$ docker ps --filter name=a-1
CONTAINER ID        ...        NAMES
6a691ce9fb92        ...        ba-1
668b39819d5f        ...        a-10
e573427357b0        ...        a-1

$ docker ps --filter name=a-1$
CONTAINER ID        ...        NAMES
6a691ce9fb92        ...        ba-1
e573427357b0        ...        a-1

$ docker ps --filter name=/a-1
CONTAINER ID        ...        NAMES
668b39819d5f        ...        a-10
e573427357b0        ...        a-1

$ docker ps --filter name=/a-1$
CONTAINER ID        ...        NAMES
e573427357b0        ...        a-1
{% endhighlight %}
