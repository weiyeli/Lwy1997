# CATileLayer大图分块加载原理

## 前言

在iOS加载大图片时很容易出现内存峰值，或者因为图片解码后内存过高导致OOM。为了解决这个问题，苹果提供了CATileLayer，通过每次加载图片的一个tile进行渲染避免一次性将整张图片加载到内存。

## 原始加载方式

加载图片我们一般通过UIImageView设置image进行图片展示。这里以一张分辨率为1903 × 32328，大小为7.9MB的jpg图片为例子，加载到内存后的内存占用情况：![test](http://pwzyjov6e.bkt.clouddn.com/blog/2019-09-20-091123.jpg)

![memory](http://pwzyjov6e.bkt.clouddn.com/blog/2019-09-20-091234.png)

原图加载到内存，内存暴涨大概300MB。如果是在本来内存占用就比较高的应用，突然增加300MB可能导致FOOM，即使没有崩溃，在退后台的时候也很可能被系统kill。

## 分块加载

对于这种大图，为了保证内存的稳定，可以使用CATileLayer来进行分块加载。相同的图片，先展示缩略图，在用户放大后在分块加载原图画质：

![memory2](http://pwzyjov6e.bkt.clouddn.com/blog/2019-09-20-091325.png)

