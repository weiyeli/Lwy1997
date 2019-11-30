# 深入理解UIScrollView

## UIScrollView中几个重要的概念

### ContentOffset

`ContentOffset`这个概念就是scrollView的frame相对于scrollView承载的内容的frame的距离的一个坐标。

![enter image description here](https://i.stack.imgur.com/S8ZxB.jpg)

### ContentOffset和ContentSize

![oCKJr](https://tva1.sinaimg.cn/large/006y8mN6gy1g99e5ierqlj308808t3yx.jpg)

从上图可以看出，contentSize就是scrollView承载的图片的大小。而contentOffset就是scrollView相对于图片的frame的起始点的距离坐标。

 ### ContentInset

![ContentInset.001](https://tva1.sinaimg.cn/large/006y8mN6gy1g99e61wwmcj31hc0u0jsf.jpg)

