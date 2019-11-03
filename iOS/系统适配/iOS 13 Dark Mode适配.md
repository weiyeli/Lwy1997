# iOS 13 Dark Mode适配

## 前言

iOS 13系统新增了Dark Mode，需要项目进行适配，详细内容可以参考[WWDC](https://developer.apple.com/videos/play/wwdc2019/214/)

## UIView层面

### UIColor

iOS 13 之前 UIColor 只能表示一种颜色，从 iOS 13 开始 UIColor 是一个**动态**的颜色，它可以在 LightMode 和 DarkMode 拥有不同的颜色。

iOS 13 下 UIColor 增加了很多动态颜色，我们来看下用系统提供的颜色能实现怎么样的效果。

```swift
// UIColor 增加的颜色@available(iOS 13.0, *)
open class var systemBackground: UIColor { get }@available(iOS 13.0, *)
open class var label: UIColor { get }@available(iOS 13.0, *)
open class var placeholderText: UIColor { get }
...
view.backgroundColor = UIColor.systemBackground
label.textColor = UIColor.label
placeholderLabel.textColor = UIColor.placeholderText复制代码        
```

![image-20190909211743905](http://pwzyjov6e.bkt.clouddn.com/blog/2019-09-09-131744.png)

对于 UIColor，还使用 UIColor (DynamicColors) 里提供的新 API 去初始化颜色。

这个闭包返回一个 UITraitCollection 类，我们要用这个类的 userInterfaceStyle 属性。 userInterfaceStyle 是一个枚举，声明如下

```swift
@available(iOS 12.0, *)public enum UIUserInterfaceStyle : Int {
    case unspecified
    case light
    case dark
}
```

这个枚举会告诉我们当前是 LightMode or DarkMode，我们可以根据UITraitCollection的值来设置不同的颜色，代码如下：

```swift
view.backgroundColor = UIColor(dynamicProvider: { (collection) -> UIColor in
    if collection.userInterfaceStyle == .dark {
        return UIColor.black
    } else {
        return UIColor.white
    }
 })
```

或者用 Xcode 11 在 Assets 里为每个颜色创建一个 Color Set 然后在 Appearances 里选择带有 Dark 的选项来生成一个动态颜色，代码里通过 [UIColor colorNamed:] 来获取颜色。



```
view.backgroundColor = UIColor(named: "BackgroundColor")
```

### UIImage

对于 UIImage，使用 Xcode 11 在 Assets 里的 Appearances 选择带有 Dark 的选项来创建一个动态的图片。

![img](https://internal-api.feishu.cn/space/api/file/out/29q1KVJOpOwMaMmnaUNoNWMUDXXqDDmvhIzVKTd4YuCqPHwW8f/)

### UIVisualEffect

对于 UIVisualEffect，使用 iOS 10 之后的 UIBlurEffectStyle（例如 UIBlurEffectStyleRegular），系统会自动切换 Light/Dark 样式。

### 其他

其他内容可在 traitCollectionDidChange: 里根据 self.traitCollection.userInterfaceStyle 的值来判断当前的主题。

## UIViewController 层面

通过在 traitCollectionDidChange: 里根据 self.traitCollection.userInterfaceStyle 的值来判断当前的主题。

```swift
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle == .dark {

        } else {
            
        }
    }
```

## 系统适配方案的局限性

对于 UIColor，系统有 API 生成动态颜色，但 CGColor 却没有，所以使用到 CGColor 的地方都需要重写 traitCollectionDidChange: 在里面重新设置一遍，无法保持代码风格的一致性。

对于 UIColor、UIImage 这些对象，如果你将其用于 UIView.backgroundColor、UIView.tintColor 这种系统原生自带的属性，当设备主题发生切换时，UIView 会自动去刷新这些值（因为它知道有这些值需要刷新），但如果你是一个自定义 View 里的自定义属性（例如 demoView.separatorColor），系统并不知道你总共有哪些属性需要更新，所以你依然需要借助 traitCollectionDidChange: 来重新设置一遍，导致 UI 代码需要分散到多个地方，不好维护。

让一个项目兼容 iOS 13 Dark Mode，和让项目在所有 iOS 版本下都能支持 Dark Mode，这两者的工作量相差不大，都是要对已有的 UI 代码做大量修改。如果要兼容 iOS 13 Dark Mode，最好的方案肯定是同时支持所有 iOS 版本，然而系统提供的方案并不考虑 iOS 12 及以下版本的实现。

（网上有很多开源的适配暗黑模式的项目，比如：https://github.com/Tencent/QMUI_iOS/releases/tag/4.0.0-beta）

## 如何改变当前模式

一般修改模式都是直接修改系统的设置，从而让 App 的模式修改，但是对于某些有夜间模式功能的 App 来说，如果用户打开了夜间模式，那么即使现在系统是 light 模式，也要强制用 dark 模式。

我们可以用以下代码将当前 UIViewController 或 UIView 的模式。

```swift
overrideUserInterfaceStyle = .darkprint(traitCollection.userInterfaceStyle)
```

我们可以看到设置了 overrideUserInterfaceStyle 之后，traitCollection.userInterfaceStyle 就是我们设置后的模式了。

需要给每一个 Controller 和 View 都设置一遍吗？

答案是不需要，根据WWDC的讲义：



当我们设置一个 controller 为 dark 之后，这个 controller 下的 view，都会是 dark mode，**但是后续推出的 controller 仍然是跟随系统的样式。**

因为Apple对 overrideUserInterfaceStyle 属性的解释是这样的。

当我们在一个普通的 controlle, view 上重写这个属性，只会影响当前的视图，不会影响前面的controller 和后续推出的controller。

**但是**当我们在 window 上设置 overrideUserInterfaceStyle 的时候，就会影响 window 下所有的 controller, view，包括后续推出的 controller。

回到刚才的问题上，如果 App 打开夜间模式，那么很简单我们只需要设置 window 的 overrideUserInterfaceStyle 属性就好了。

## 如何在模式切换时打印日志

在 Arguments 中的 Arguments Passed On Launch 里面添加下面这行命令。

`-UITraitCollectionChangeLoggingEnabled YES`



## Lark暗黑模式适配方案



在Info.plist中新增User Interface Style，强行设置为Light模式，嗯，很暴力