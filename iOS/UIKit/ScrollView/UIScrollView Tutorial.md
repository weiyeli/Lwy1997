# UIScrollView

## UIScrollView嵌套ImageView

当UIScrollView里面嵌套一个ImageView时，通过代理设置该ImageView为可以缩放的对象。当该ImageView缩放到大于ScrollView时，ImageView的frame就会比ScrollView的frame要大，而scrollView的frame本身却不会改变。

![image-20190808183712816](http://ww2.sinaimg.cn/large/006tNc79gy1g5sge51qtfj30bn01x3yg.jpg)



![image-20190809152331429](http://ww4.sinaimg.cn/large/006tNc79gy1g5tgex4pkoj30n01dsqv5.jpg)

![image-20190809152359617](http://ww1.sinaimg.cn/large/006tNc79gy1g5tgfd3196j30gc039wf6.jpg)

