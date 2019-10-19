# Key-Value Observing In Cocoa
## 什么是KVO
KVO即Key-Value-Observing,键值观察，是观察者模式的一种实现。KVO提供了一种机制能够方便的观察对象的属性。如：指定一个被观察对象，当对象的某个属性发生变化时，对象会获得通知，进而可以做出相应的处理。在实际的开发中对于model与controller之间进行交流是非常有用的。controller通常观察Model的属性，view通过controller观察Model对象的属性。 然而，Model对象可以观察其他Model对象（通常用于确定依赖别人的值何时改变）或甚至自身（再次确定依赖别人的值何时改变）。

一个简单的例子说明了KVO如何在您的应用程序中发挥作用。 假设Person对象与Account对象交互，表示该人在银行的储蓄账户。 Person的实例可能需要知道Account实例的某些方面何时发生变化，例如余额或利率。

![kvo_objects_properties](http://ww2.sinaimg.cn/large/006tNc79gy1g5p3ipzkswj30e802adg4.jpg)

如果这些属性是Account的公共属性，那么Person可以定期轮询帐户以发现更改，但这当然是低效的，并且通常是不切实际的。 更好的方法是使用KVO，类似于当账户的属性值发生更改时Preson接收到一个中断。

## KVO的原理
> Automatic key-value observing is implemented using a technique called isa-swizzling.The isa pointer, as the name suggests, points to the object's class which maintains a dispatch table. This dispatch table essentially contains pointers to the methods the class implements, among other data.
When an observer is registered for an attribute of an object the isa pointer of the observed object is modified, pointing to an intermediate class rather than at the true class. As a result the value of the isa pointer does not necessarily reflect the actual class of the instance.
You should never rely on the isa pointer to determine class membership. Instead, you should use the class method to determine the class of an object instance.


## 如何使用KVO
KVO的实现依赖于OC强大的Runtime，上面文档也说道，KVO是通过使用isa-swizzling技术实现的。

基本的流程是：当某个类的属性对象第一次被观察时，系统会在运行期动态地创建该类的一个子类，在这个子类中重写父类中任何被观察属性的setter方法，子类在被重写的setter方法内实现真正的通知机制。

例如：当 被观察对象为A时，KVO机制动态创建一个新类，名为NSKVONotifying_A。该类继承自对象A的类，并且重写了观察属性的setter方法，setter方法会负责在调用原setter方法之前和之后，通知所有观察者对象属性值的改变情况。

每个类对象都有一个isa指针，该指针指向当前类，当一个类对象的属性第一次被观察，系统会偷偷将isa指针指向动态生成的派生类，从而在给被监听属性赋值时执行的是派生类的setter方法。

**子类setter方法：**

KVO的键值观察通知机制依赖于NSObject的两个方法，willChangeValueForKey:和didChangeValueForKey:，在进行存取数值前后分别调用这2个方法(因为我们所监听的对象属性可以获取新值和旧值，所以属性改变前后都会通知观察者)。被观察属性发生改变之前，willChangeValueForKey：方法被调用，当属性发生改变之后，didChangeValueForKey：方法会被调用，之后observeValueForKey:ofObject:change:context方法也会被调用。这里要注意：重写观察属性的setter方法是在运行时由系统自动执行的。而且苹果还重写了class方法，让我们误认为是使用了当前类，从而达到隐藏生成的派生类。为了帮助理解过程，借用图片一张：

![kvo_yuanli](http://ww4.sinaimg.cn/large/006tNc79gy1g5p3ihdblfj30kz0cbdid.jpg)

## KVO使用流程

1. 调用addObserver:forkeypath:options:context方法添加观察者
2. 重写observeValue方法
3. 记得去除观察者，调用removeObserver:forkeypath:context方法，OC语言在dealloc方法中执行,Swift在deinit方法中,注意：有添加观察者才执行去除观察者，如果没有添加观察者，就调用去除观察者会出现异常，即添加观察者和去除观察者两个操作是一一对应的

## 一般KVO奔溃的原因
1. 被观察的对象被销毁掉了，比如：被观察的对象是一个局部变量
2. 观察者被释放掉了，但是没有移除监听。这个是很常见的错误，在push、pop等相关操作之后很容易崩溃
3. 注册的监听没有被移除掉，又重写进行注册

## Demo

```
let player = AVPlayer(playerItem: playerItem)
// 第一步：监听AVPlayer的timeControlStatus
player.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)

// 第二步：重写observeValue方法
override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            guard let player = player else { return }
            switch player.timeControlStatus {
            case .playing:
                observerDelegate?.playerStatusChangedAction(status: .playing)
            case .paused:
                observerDelegate?.playerStatusChangedAction(status: .paused)
            default:
                return
            }
    }
    
 // 去除监听者
 deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
        DocsLogger.debug("-----deinit-----")
    }
```

## KVO的优缺点
### 优点

### 缺点

## KVO的使用场景