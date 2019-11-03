# loadView, viewDidLoad, viewDidUnLoad,分别是在什么时候被调用的？

## loadView 

## viewDidLoad

![image-20190813154815845](http://ww4.sinaimg.cn/large/006tNc79gy1g5y3lw1g64j30l70bvdk7.jpg)

![image-20190813155306662](http://ww1.sinaimg.cn/large/006tNc79gy1g5y3qw2llyj30f704pwfx.jpg)

### 问题的由来

DriveSingleImagePreviewController中有一个picView。在PDF预览中想把这个picView直接添加到PDF预览VC的view上，但是发现DriveSingleImagePreviewController的delegate都没有被设置，经过排查发现是因为DriveSingleImagePreviewController的viewDidLoad()方法没有被调用。这就牵扯到viewDidLoad()方法什么时候被调用的问题。

### 原理

当ViewController的view被访问，并且view为nil的时候，系统会执行vc的viewDidLoad()方法。在上述例子中，因为我们直接访问了picView，没有访问DriveSingleImagePreviewController.view，所以viewDidLoad()方法没有执行。

## viewDidUnLoad 

