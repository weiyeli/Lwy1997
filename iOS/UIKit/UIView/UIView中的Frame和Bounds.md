# UIView中的Frame和Bounds

**Frame代表了一个矩形区域，其位置和大小以父View的坐标系为基准；**

**Bounds也代表了一个矩形区域，其位置和大小以其自己的坐标系为基准；**

关于Frame的解释，详情参考[苹果官方文档](https://developer.apple.com/documentation/uikit/uiview/1622621-frame)

关于Bounds的解释，详情参考[苹果官方文档](https://developer.apple.com/documentation/uikit/uiview/1622580-bounds)

Frame 指子View在父View中的位置以及大小。由两部分构成，第一部分是Origin，规定了子View在父类的位置。第二部分是Size，指View在父类中的可视范围（这里能说是View的大小）。这感觉像是在父View中在Frame.Origin位置打开一个窗户，窗户的大小是Frame.Size，从窗户中可以看到子View的内容。

Bounds指子View自身显示那些内容，Bounds组成和Frame类似。还用窗户来说明，此时把子View看做是很大的油画，在父View中打开了一个窗户后，但是这个窗户是糊上纸的，只能通过把油画投影窗户上。那么，最终窗户上显示什么是由Bounds决定的，Bounds就决定油画中哪部分内容。

最后如下图，右图是真实看见的，而事实上是左图所示的内容。左图的阴影部分就是ChildView没有显示出来的部分。

![img](https://upload-images.jianshu.io/upload_images/277755-217ccf2729acbf5c.png)
