# iOS present和Dismiss踩坑记录
## Dismiss的作用
### 官方原话
> The presenting view controller is responsible for dismissing the view controller it presented. If you call this method on the presented view controller itself, UIKit asks the presenting view controller to handle the dismissal.
If you present several view controllers in succession, thus building a stack of presented view controllers, calling this method on a view controller lower in the stack dismisses its immediate child view controller and all view controllers above that child on the stack. When this happens, only the top-most view is dismissed in an animated fashion; any intermediate view controllers are simply removed from the stack. The top-most view is dismissed using its modal transition style, which may differ from the styles used by other view controllers lower in the stack.
If you want to retain a reference to the view controller's presented view controller, get the value in the presentedViewController property before calling this method.

### 简单解释
Dismiss的作用是dismiss掉自己present出来的ViewController，但是通常对自己也适用的原因是因为当前ViewController没有present出另外的ViewController，所以系统会请求自己的presentingViewController来dismiss掉自己。

### 流程

1. 如果自己的presentedViewController不为nil，遍历自己的presentedViewController，逐一dismiss
2. 如果自己的presentedViewController为nil，请求自己的presentingViewController把自己dismiss掉

![](../pic/iOS ViewController Dismiss原理.jpg)


## 参考文章
[iOS present dismiss 小坑](https://www.jianshu.com/p/a1db4af31953)

[iOS 聊聊present和dismiss](https://www.jianshu.com/p/455d5f0b3656)