# 深入理解ESPullToRefresh

## 前言

ESPullTorefresh是一个很经典的iOS中支持下滑刷新的上拉刷新的开源库。其实现也很简单，源码只有几个文件，非常适合新手学习。

## 项目结构

![image-20191124201902259](https://tva1.sinaimg.cn/large/006y8mN6gy1g99e9d6d6bj308507aq5u.jpg)

## ES

```swift
public protocol ESExtensionsProvider: class {
    associatedtype CompatibleType
    var es: CompatibleType { get }
}

extension ESExtensionsProvider {
    /// A proxy which hosts reactive extensions for `self`.
    public var es: ES<Self> {
        return ES(self)
    }

}

public struct ES<Base> {
    public let base: Base
    
    // Construct a proxy.
    //
    // - parameters:
    //   - base: The object to be proxied.
    fileprivate init(_ base: Base) {
        self.base = base
    }
}

// 
extension UIScrollView: ESExtensionsProvider {}
```

这是在Swift中非常经典的实现命名空间的一种方式。

首先定义了一个`ESExtensionsProvider`协议。协议里面定义了一个`es`的泛型只读变量。在默认实现中采用了通过计算属性创建一个`ES`对象的方式来实现这个协议。`ES`是一个结构体，持有了一个`Base`变量。最后给UIScrollView实现了`ESExtensionsProvider`这个协议。这意味着`UIScrollView`可以通过访问`es`这个计算属性来拿到一个`ES`对象，同时`ES`对象里面持有了一个`base`的UIScrollView对象。这样`UIScrollView`对象只要通过`es`属性就可以轻易的调用我们接下来要为`UIScrollView`进行拓展的方法。

## ESRefreshProtocol

```swift
/**
 *  ESRefreshProtocol
 *  Animation event handling callback protocol
 *  You can customize the refresh or custom animation effects
 *  Mutating is to be able to modify or enum struct variable in the method - http://swifter.tips/protocol-mutation/ by ONEVCAT
 */
public protocol ESRefreshProtocol {
    
    /**
     Refresh operation begins execution method
     You can refresh your animation logic here, it will need to start the animation each time a refresh
    */
    mutating func refreshAnimationBegin(view: ESRefreshComponent)
    
    /**
     Refresh operation stop execution method
     Here you can reset your refresh control UI, such as a Stop UIImageView animations or some opened Timer refresh, etc., it will be executed once each time the need to end the animation
     */
    mutating func refreshAnimationEnd(view: ESRefreshComponent)
    
    /**
     Pulling status callback , progress is the percentage of the current offset with trigger, and avoid doing too many tasks in this process so as not to affect the fluency.
     */
    mutating func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat)
    
    mutating func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState)
}
```

正如注释中所说，这个协议是动画事件的处理回调协议。开发者可以通过实现这个协议来自定义刷新的逻辑或者自定义动画效果。这里面有一个知识点：[将 PROTOCOL 的方法声明为 MUTATING](https://swifter.tips/protocol-mutation/)。参考喵神的文章，我们可以知道：

> Swift 的 `mutating` 关键字修饰方法是为了能在该方法中修改 `struct` 或是 `enum` 的变量，所以如果你没在接口方法里写 mutating 的话，别人如果用 `struct` 或者 `enum` 来实现这个接口的话，就不能在方法里改变自己的变量了。

**ESRefreshAnimatorProtocol**

```swift
public protocol ESRefreshAnimatorProtocol {
    
    // The view that called when component refresh, returns a custom view or self if 'self' is the customized views.
    var view: UIView {get}
    
    // Customized inset.
    var insets: UIEdgeInsets {set get}
    
    // Refresh event is executed threshold required y offset, set a value greater than 0.0, the default is 60.0
    var trigger: CGFloat {set get}
    
    // Offset y refresh event executed by this parameter you can customize the animation to perform when you refresh the view of reservations height
    var executeIncremental: CGFloat {set get}
    
    // Current refresh state, default is .pullToRefresh
    var state: ESRefreshViewState {set get}
    
}
```

这里有两个变量一开始没搞清楚。`trigger`和`executeIncremental`。

+ trigger: 边界值，当scrollView的contentOffset超过这个值时，就会触发refresh的操作
+  executeIncremental: 刷新时，animator跟scrollerView边缘的距离，也可以理解为animator的高度

### ESRefreshAnimator

`ESRefreshAnimator`这个类实现了`ESRefreshProtocol`和`ESRefreshAnimatorProtocol`两个协议，相当于一个基类。

### ESRefreshComponent

`ESRefreshComponent`是一个View，是`ESRefreshHeaderView`和`ESRefreshFooterView`的父类。

里面持有一个刷新时执行的闭包。

```swift
/// @param handler Refresh callback method
open var handler: ESRefreshHandler?
```

以及保存了目前的一些状态：是否正在刷新、是否自动刷新、是否观察scrollView、是否忽略观察scrollView。

## ESRefreshDataManager

ESRefreshDataManager是一个单例的Manager类。主要用来存储上一次的Refresh信息和expiredTimeInterval信息。

还提供了一些日期相关的工具类。



