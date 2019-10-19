# Auto Layout

## 定义



## Safe Area

[苹果官方文档](https://developer.apple.com/documentation/uikit/uiview/positioning_content_relative_to_the_safe_area)

Safe Area是iPhone X更新后出现的不包括刘海、底部返回位置的一块安全区域，在进行布局的时候要注意不要超出Safe Area。

## 戴铭大佬的解读



## AutoLayout的执行流程

AutoLayout是由Layout Engine在LayoutSubViews的过程中进行的，AutoLayout最终也会输出一个Frame。

下面看一个例子：

```swift
view1.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(50)
        }

        view2.snp.makeConstraints { (make) in
            make.left.equalTo(view1.snp.right).offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
```

设置两个View，分别是View1和View2，View2的左边距离View1的右边距20个px的距离。此时我们拿到View1和View2的Frame如下：

![image-20190609095803651](http://ww2.sinaimg.cn/large/006tNc79gy1g3uo7fqbi3j30ju02aq3c.jpg)

此时，将View1的宽度通过AutoLayout设置为0，并且执行layoutIfNeeded()这个方法强制更新约束：

```swift
print("将view1的宽度设置为0")
view1.snp.updateConstraints { (make) in
    make.width.equalTo(0)
}
view.layoutIfNeeded()
```

此时我们再次拿到View1和View2的Frame如下：

![image-20190609100032987](http://ww4.sinaimg.cn/large/006tNc79gy1g3uoa0x6cbj30jw02igm1.jpg)

会惊奇的发现，View1的frame的宽度变为了0， View2的起点的x轴坐标也发生了改变。

将View1的isHidden设置为true，此时我们再次拿到View1和View2的Frame如下：

![image-20190609100900958](http://ww3.sinaimg.cn/large/006tNc79gy1g3uoiu0felj30jg03w3z4.jpg)

可以发现将View1的isHidden设置为true对View1的frame和View2的frame都没有影响