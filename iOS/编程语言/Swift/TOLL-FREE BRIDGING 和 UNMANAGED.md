# TOLL-FREE BRIDGING 和 UNMANAGED
## Core Foundation的历史
先来说说「Core Foundation」（以下简称CF）的历史吧。当年乔布斯被自己创办的公司驱逐后，成立了「NeXT Computer」,其实做的还是老本行：卖电脑，但依旧不景气。好在NeXTSTEP系统表现还不错，亏损不至于太严重。正好此时苹果的市场份额大跌，急需一个新的操作系统，结果大家都知道了，乔布斯借此收购，重新回到了苹果。
这里就牵扯到了一个问题，如何让旧有的系统（Mac OS 9）和NeXTSTEP合成为一个新系统？这就需要一个更为底层的核心库可以供Mac Toolbox和OPENSTEP双方调用。CF就这么诞生了。
CF是由C语言实现的，而不是Objective-C，所以如果用到了CF，就需要手动管理内存，ARC是无能为力的。当然因为CF和Foundation之间的友好关系，它们之间的管理权也是可以移交的，这个后面再说。
Core Foundation框架 (CoreFoundation.framework) 是一组C语言接口，它们为iOS应用程序提供基本数据管理和服务功能。下面列举该框架支持进行管理的数据以及可提供的服务：

+ 群体数据类型 (数组、集合等)
+ 程序包
+ 字符串管理
+ 日期和时间管理
+ 原始数据块管理
+ 偏好管理
+ URL及数据流操作
+ 线程和RunLoop
+ 端口和soket通讯

Core Foundation框架和Foundation框架紧密相关，它们为相同功能提供接口，但Foundation框架提供Objective-C接口。如果您将Foundation对象和Core Foundation类型掺杂使用，则可利用两个框架之间的 “toll-free bridging”。所谓的Toll-free bridging是说您可以在某个框架的方法或函数同时使用Core Foundatio和Foundation 框架中的某些类型。很多数据类型支持这一特性，其中包括群体和字符串数据类型。每个框架的类和类型描述都会对某个对象是否为 toll-free bridged，应和什么对象桥接进行说明。

## Core Foundation和Foundation的关系
Cocoa 框架中的大部分 NS 开头的类其实在 CF 中都有对应的类型存在，可以说 NS 只是对 CF 在更高层面的一个封装。比如 NSURL 和它在 CF 中的 CFURLRef 内存结构其实是同样的，而 NSString 则对应着 CFStringRef。

## TOLL-FREE BRIDGING
因为在 Objective-C 中 ARC 负责的只是 NSObject 的自动引用计数，因此对于 CF 对象无法进行内存管理。我们在把对象在 NS 和 CF 之间进行转换时，需要向编译器说明是否需要转移内存的管理权(NS向CF转移，ARC转向手动管理)。对于不涉及到内存管理转换的情况，在 Objective-C 中我们就直接在转换的时候加上 __bridge 来进行说明，表示内存管理权不变。例如有一个 API 需要 CFURLRef，而我们有一个 ARC 管理的 NSURL 对象的话，这样来完成类型转换：

```
NSURL *fileURL = [NSURL URLWithString:@"SomeURL"];
SystemSoundID theSoundID;
//OSStatus AudioServicesCreateSystemSoundID(CFURLRef inFileURL,
//                             SystemSoundID *outSystemSoundID);
OSStatus error = AudioServicesCreateSystemSoundID(
        (__bridge CFURLRef)fileURL,
        &theSoundID);
```

## 内存管理对象
Swift中调用Core Foundation函数获得对象时候，对象分为：内存托管对象和内存非托管对象。内存托管对象就是由编译器帮助管理内存，我们不需要调用CFRetain函数获得对象所有权，也不需要调用　CFRelease函数放弃对象所有权。获得这些内存托管对象的方法，是采用了CF_RETURNS_RETAINED或CF_RETURNS_NOT_RETAINED注释声明，示例代码：

```
-(CGPathRef)makeToPath CF_RETURNS_RETAINED { 　　
      UIBezierPath* triangle = [UIBezierPath bezierPath]; 　　 
      [triangle moveToPoint:CGPointZero]; 　　
      [triangle addLineToPoint:CGPointMake(self.view.frame.size.width,0)]; 　　
      [triangle addLineToPoint:CGPointMake(0, self.view.frame.size.height)]; 　　 
      [triangle closePath]; 　　 
      CGPathRef theCGPath = [triangle CGPath]; 　　
      return CGPathCreateCopy(theCGPath); 　　
}
```

内存托管对象使用起来比较简单，不需要我们做额外的事情。

```
func CFStringCreateWithCString(_ alloc: CFAllocator!, 
                　　_ cStr: UnsafePointer<Int8>,
                　　 _ encoding: CFStringEncoding) -> CFString!    //内存托管对象

　　func CFHostCreateCopy(_ alloc: CFAllocator?,
                　　 _ host: CFHost) -> Unmanaged<CFHost>        //内存非托管对象
```

## Unmanaged对象
Unmanaged对象就是内存需要程序员自己管理。这是由于在获得对象的方法中没有使用CF_RETURNS_RETAINED或CF_RETURNS_NOT_RETAINED注释声明，编译器无法帮助管理内存。Unmanaged对象使用起来有些麻烦，要根据获得所有权方法，进行相应的处理。

1. 如果一个函数名中包含Create或Copy，则调用者获得这个对象的同时也获得对象所有权，返回值Unmanaged需要调用takeRetainedValue()方法获得对象。调用者不再使用对象时候，Swift代码中需要调用CFRelease函数放弃对象所有权，这是因为Swift是ARC内存管理的。
2. 如果一个函数名中包含Get，则调用者获得这个对象的同时不会获得对象所有权，返回值Unmanaged需要调用takeUnretainedValue()方法获得对象。 示例代码如下：

```
let host: CFHost = CFHostCreateWithName(kCFAllocatorDefault, 
                "127.0.0.1").takeRetainedValue()

let hostNames: CFArray = CFHostGetNames(host, nil)!.takeUnretainedValue()
```

## 参考资料
https://swifter.tips/toll-free/

https://www.jianshu.com/p/5c98ac2dab58

http://www.ituring.com.cn/article/213768