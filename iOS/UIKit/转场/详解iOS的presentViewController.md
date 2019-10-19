# 详解iOS的presentViewController

## 用途和相关概念

iOS中显示ViewController的方式有两种push和modal，modal也叫模态，模态显示VC是iOS的重要特性之一，其主要用于有以下场景

- 收集用户输入信息
- 临时呈现一些内容
- 临时改变工作模式
- 响应设备方向变化（用于针对不同方向分别是想两个ViewController的情况）
- 显示一个新的view层级

这些场景都会暂时中断APP的正常执行流程，主要作用是收集信息以及显示一些重要的提示等。

### presenting view controller & presented view controller

当vcA模态的弹出了vcB，那么vcA就是presenting view controller，vcB就是presented view controller，具体在代码中体现如下:

`vcA.present(vcB, animated: true, completion: nil)`

### container view controller

container view controller 指的是VC的容器类，通过container view controller，我们可以很方便的管理子VC，实现VC之间的跳转等，iOS中container view controller包括NavigationController, UISplitViewController, 以及 UIPageViewController.

## ModalPresentationStyle & Presentation Context

### ModalPresentationStyle

presented VC 的modalPresentationStyle属性决定了此次presentation的行为方式及UIKit寻找presentation context的方法，iOS提供了以下几种常用的presentation style：

#### UIModalPresentationFullScreen

UIKit默认的presentation style。 使用这种模式时，presented VC的宽高与屏幕相同，并且UIKit会直接使用rootViewController做为presentation context，在此次presentation完成之后，UIKit会将presentation context及其子VC都移出UI栈，这时候观察VC的层级关系，会发现UIWindow下只有presented VC.

#### UIModalPresentationPageSheet

在常规型设备（大屏手机，例如plus系列以及iPad系列）的水平方向，presented VC的高为当前屏幕的高度，宽为该设备竖直方向屏幕的宽度，其余部分用透明背景做填充。对于紧凑型设备（小屏手机）的水平方向及所有设备的竖直方向，其显示效果与UIModalPresentationFullScreen相同。

#### UIModalPresentationFormSheet

在常规型设备的水平方向，presented VC的宽高均小于屏幕尺寸，其余部分用透明背景填充。对于紧凑型设备的水平方向及所有设备的竖直方向，其显示效果与UIModalPresentationFullScreen相同

#### UIModalPresentationCurrentContext

使用这种方式present VC时，presented VC的宽高取决于presentation context的宽高，并且UIKit会寻找属性definesPresentationContext为YES的VC作为presentation context，具体的寻找方式会在下文中给出 。当此次presentation完成之后，presentation context及其子VC都将被暂时移出当前的UI栈。

#### UIModalPresentationCustom

自定义模式，需要实现UIViewControllerTransitioningDelegate的相关方法，并将presented VC的transitioningDelegate 设置为实现了UIViewControllerTransitioningDelegate协议的对象。

#### UIModalPresentationOverFullScreen

与UIModalPresentationFullScreen的唯一区别在于，UIWindow下除了presented VC，还有其他正常的VC层级关系。也就是说该模式下，UIKit以rootViewController为presentation context，但presentation完成之后不会将rootViewController移出当前的UI栈。

#### UIModalPresentationOverCurrentContext

寻找presentation context的方式与UIModalPresentationCurrentContext相同，所不同的是presentation完成之后，不会将context及其子VC移出当前UI栈。但是，这种方式只适用于transition style为UIModalTransitionStyleCoverVertical的情况(UIKit默认就是这种transition style)。其他transition style下使用这种方式将会触发异常。

#### UIModalPresentationBlurOverFullScreen

presentation完成之后，如果presented VC的背景有透明部分，会看到presented VC下面的VC会变得模糊，其他与UIModalPresentationOverFullScreen模式没有区别。

present VC是通过UIViewController的**presentViewController: animated:completion:** 
函数实现的，在探讨他们之间的层级关系之前，我们首先要理解一个概念，就是presentation context。 

presentation context是指为本次present提供上下文环境的类，需要指出的是，presenting VC通常并不是presentation context，Apple官方文档对于presentation context的选择是这样介绍的：

> When you present a view controller, UIKit looks for a view controller that provides a suitable context for the presentation. In many cases, UIKit chooses the nearest container view controller but it might also choose the window’s root view controller. In some cases, you can also tell UIKit which view controller defines the presentation context and should handle the presentation.
>

从上面的介绍可以看出，当我们需要present VC的时候，除非我们指定了context，否则UIKit会优先选择presenting VC**所属的容器类**做为presentation context，如果没有容器类，那么会选择rootViewController。但是，UIKit搜索context的方式还与presented VC的modalPresentationStyle属性有关，当modalPresentationStyle为UIModalPresentationFullScreen、UIModalPresentationOverFullScreen等模式时，UIKit会直接选择rootViewController做为context。当modalPresentationStyle为UIModalPresentationOverCurrentContext、UIModalPresentationCurrentContext模式时，UIKit搜索context的方式如下：

UIModalPresentationOverCurrentContext、UIModalPresentationCurrentContext模式下，一个VC能否成为presentation context 是由VC的definesPresentationContext属性决定的，这是一个BOOL值，默认UIViewController的definesPresentationContext属性值是NO，而 container view controller的definesPresentationContext默认值是YES，这也是上文中，UIKit总是将container view controller做为presentation context的原因。如果我们想指定presenting VC做为context，只需要在presenting VC的viewDidLoad方法里添加如下代码即可：

```swift
self.definesPresentationContext = YES
```


UIKit搜索presentation context的顺序为： 

1. presenting VC 
2. presenting VC 的父VC 
3. presenting VC 所属的container VC 
4. rootViewController

还有另外一种特殊情况，当我们在一个presented VC上再present一个VC时，UIKit会直接将这个presented VC做为presentation context。

## presenting VC 与presented VC 之间的层级关系

在iOS 中，presented VC 总是与 presentation context 处于同一层级，而与presenting VC所在的层级无关，且同一个presentation context同时只能有一个presented VC。

下面我们通过代码来验证这个结论。首先新建一个APP，各VC之间的层级关系如下： 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180515111510561?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW53ZWl0YW8=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

在SecondContentVC中present FirstPresentVC,代码如下：

```objective-c
FirstPresentVC *vc = [[FirstPresentVC alloc] init];
vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
[self presentViewController:vc animated:YES completion:nil];
```

为了更好的观察各VC的层级关系，我们将presented VC 的modalPresentationStyle属性设置为UIModalPresentationOverCurrentContext，然后我们再看各VC之间的层级关系： 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180515111145125?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW53ZWl0YW8=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

可以看到FirstPresentVC 与 SecondContentVC的navigationViewController处在同一层级，说明这时的presentation context是navigationViewController。下面我们在FirstContentVC的viewDidLoad方法里添加如下代码：

```swift
self.definesPresentationContext = YES;
```

弹出FirstPresentVC后再看VC之间的层级关系： 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180515111204942?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW53ZWl0YW8=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

可以看到，FirstPresentVC 与 FirstContentVC 处在同一层级，说明此时的presentation context为FirstContentVC.

下面我们将SecondContentVC的definesPresentationContext属性设为YES，然后观察弹出FirstPresentVC之后的层级关系： 

![è¿éåå¾çæè¿°](https://img-blog.csdn.net/20180515111241449?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3RpYW53ZWl0YW8=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

## ModalTransitionStyle

modalTransitionStyle可以设置presentation的转场动画，官方提供了几种不同的转场动画，默认是UIModalTransitionStyleCoverVertical。如果想要使用别的style，只需要设置presented VC的modalTransitionStyle属性即可。其余三种包括:

+ UIModalTransitionStyleFlipHorizontal
+ UIModalTransitionStyleCrossDissolve
+ UIModalTransitionStylePartialCurl

具体每种style的表现形式参考Demo.