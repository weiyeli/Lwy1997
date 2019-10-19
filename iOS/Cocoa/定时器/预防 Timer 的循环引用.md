# 预防 Timer 的循环引用

在iOS开发过程中，Timer（NSTimer）是我们经常要使用的一个类。通过Timer，可以定时触发某个事件，或者执行一些特定的操作。但是稍微不注意，就会导致内存泄漏（memory leak），而这种内存泄漏，就是循环引用引起的。例如在DrivePreviewViewModel中

```swift
/// 轮询fileInfo的定时器，实时监测文件是否审核不通过
private weak var fileInfoTimer: Timer?
    
// 轮询fileInfo接口获取审核结果
private func pollingFileInfo() {
        // Todo: 是否会循环引用
        fileInfoTimer = Timer.scheduledTimer(timeInterval: 60,
                             target: self,
                             selector: #selector(pollingFileInfoCore),
                             userInfo: nil,
                             repeats: true)
 }
    
 deinit {
     DocsLogger.debug("DrivePreviewViewModel-----deinit")
     fileInfoTimer?.invalidate()
 }
```

那么你调用profile的Leaks工具时会发现MyViDrivePreviewViewModel的deinit方法永远不会执行，就会检测到内存泄漏。如果你看Apple的开发文档足够细心，你将会发现问题所在：

The object to which to send the message specified by aSelector when the timer fires. The timer maintains a strong reference to target until it (the timer) is invalidated.

原来Timer调用scheduledTimer时，会强引用target，这里即是MyViewController对象。解决方法就是按照文档所说在某个地方或时间点，手动将定时器invalidated就可以了。

```swift
self.myTimer.invalidate()
self.myTimer = nil
```

但是你千万不要将上述代码放到deinit里面（惯性思维会让我们把释放清除工作放到deinit里），因为循环引用之后MyViewController对象不会释放，deinit将永远不会被调用。你可以重载viewDidDisappear，放到里面去。或者确定不需要定时器时，及时销毁定时器。

虽然问题得到解决，但很明显，啰嗦且不够优雅。所幸iOS 10.0+之后，一切变得简单起来了……

```swift
weak var weakSelf = self
Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block:{(timer: Timer) -> Void in
  weakSelf?.doSomething()
})
```

项目往往需要向下兼容，有没有办法使得iOS 10.0之前版本能够这样简单的使用 block，优雅的解决循环饮用呢？答案是肯定的。

Timer增加如下扩展

```swift
import Foundation

extension Timer {

    // swiftlint:disable type_name
    public class lu {

        public static func scheduledTimer(timerInterval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
            return Timer.scheduledTimer(timeInterval: timerInterval,
                                        target: self,
                                        selector: #selector(blockInvoke(timer:)),
                                        userInfo: block,
                                        repeats: repeats)
        }

        @objc
        fileprivate static func blockInvoke(timer: Timer) {
            if let block = timer.userInfo as? ((Timer) -> Void) {
                block(timer)
            }
        }

    }
}
```

这样就没有了iOS版本的限制，方便快捷的使用Timer了：

```swift

```

总结：

1. 当调用Apple的API时，需要传递类对象self本身的，我们一定要看清文档，self会不会被保留强引用（MAC时代的被retain）；
2. 当self被强引用时，像Timer一样，增加类似的一个扩展，或者可以很好的解决问题；
3. Block模版类，或许可以很优雅的解决你所遇到的问题。

**拓展**

通过XCode自带的Memory Graph来查看是否有循环引用