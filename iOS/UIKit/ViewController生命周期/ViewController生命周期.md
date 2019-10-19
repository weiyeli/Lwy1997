# ViewController生命周期

## 一图胜千言

![ViewController的生命周期](http://ww3.sinaimg.cn/large/006tNc79gy1g3eu86tkcwj313w0u0dlm.jpg)

## ARC环境
### 单个viewController的生命周期

```swift
initWithCoder:(NSCoder *)aDecoder：（如果使用storyboard或者xib）
loadView：加载view
viewDidLoad：view加载完毕
viewWillAppear：控制器的view将要显示
viewWillLayoutSubviews：控制器的view将要布局子控件
viewDidLayoutSubviews：控制器的view布局子控件完成
这期间系统可能会多次调用viewWillLayoutSubviews、viewDidLayoutSubviews俩个方法

viewDidAppear:控制器的view完全显示
viewWillDisappear：控制器的view即将消失的时候
这期间系统也会调用viewWillLayoutSubviews 、viewDidLayoutSubviews 两个方法

viewDidDisappear：控制器的view完全消失的时候
viewWillUnload: 当内存过低时，需要释放一些不需要使用的视图时，即将释放时调用
viewDidUnload: 当内存过低，释放一些不需要的视图时调用
```

### 多个viewControllers跳转

当我们点击push的时候首先会加载下一个界面然后才会调用界面的消失方法

```
initWithCoder:(NSCoder *)aDecoder：ViewController2 (如果用xib创建的情况下）
loadView：ViewController2
viewDidLoad：ViewController2
viewWillDisappear：ViewController1 将要消失
viewWillAppear：ViewController2 将要出现
viewWillLayoutSubviews ViewController2

viewDidLayoutSubviews ViewController2

viewWillLayoutSubviews:ViewController1

viewDidLayoutSubviews:ViewController1

viewDidDisappear:ViewController1 完全消失
viewDidAppear:ViewController2 完全出现
```

## 详细讲解

### Initialization

#### Storyboard

> **OUTPUT:**
>  init(coder:)
>  awakeFromNib()

##### init(coder:)

- 当使用 Storyboard 时，控制器的构造器为 `init(coder:)`。
- 该构造器为必需构造器，如果重写其他构造器，则必须重写该构造器。
- 该构造器为可失败构造器，即有可能构造失败，返回 nil。
- 该方法来源自 NSCoding 协议，而 UIViewController 遵从这一协议。
- 该方法被调用意味着控制器有可能（并非一定）在未来会显示。
- 在控制器生命周期中，该方法只会被调用一次。

##### awakeFromNib()

- 当使用 Storyboard 时，该方法会被调用。
- 当调用该方法时，将保证所有的 outlet 和 action 连接已经完成。
- 该方法内部必须调用父类该方法，虽然默认实现为空，但 UIKit 中许多类的该方法为非空。
- 由于控制器中对象的初始化顺序不能确定，所以构造器中不应该向其他对象发送消息，而应当在 `awakeFromNib()` 中安全地发送。
- 通常使用 `awakeFromNib()` 可以进行在设计时无法完成的必要额外设置。

#### Code

> **OUTPUT:**
>  init(nibName:bundle:) - NibName: nil, Bundle: nil

##### init(nibName:bundle:)

- 当使用纯代码创建控制器，控制器的构造器为 `init(nibName:bundle:)`。
- 虽然使用代码创建时调用了该构造器，但传入的参数均为 nil。

------

> **OUTPUT:**
>  loadView()
>  viewDidLoad()
>  viewWillAppear
>  viewWillLayoutSubviews() - Optional((162.0, 308.0, 50.0, 50.0))
>  viewDidLayoutSubviews() - Optional((67.0, 269.0, 241.0, 129.0))
>  viewDidAppear
>  viewWillDisappear
>  viewDidDisappear
>  deinit

### loadView()

-  `loadView()` 即加载控制器管理的 view。
- 不能直接手动调用该方法；当 view 被请求却为 nil 时，该方法加载并创建 view。
- 若控制器有关联的 Nib 文件，该方法会从 Nib 文件中加载 view；如果没有，则创建空白 UIView 对象。
- 如果使用 Interface Builder 创建 view，则务必不要重写该方法。
- 可以使用该方法手动创建视图，且需要将根视图分配为 view；自定义实现不应该再调用父类的该方法。
- 执行其他初始化操作，建议放在 `viewDidLoad()` 中。

### viewDidLoad()

- view 被加载到内存后调用 `viewDidLoad()`。
- 重写该方法需要首先调用父类该方法。
- 该方法中可以额外初始化控件，例如添加子控件，添加约束。
- 该方法被调用意味着控制器有可能（并非一定）在未来会显示。
- 在控制器生命周期中，该方法只会被调用一次。

### viewWillAppear(_:)

- 该方法在控制器 view 即将添加到视图层次时以及展示 view 时所有动画配置前被调用。
- 重写该方法需要首先调用父类该方法。
- 该方法中可以进行操作即将显示的 view，例如改变状态栏的取向，类型。
- 该方法被调用意味着控制器将一定会显示。
- 在控制器生命周期中，该方法可能会被多次调用。

> 注意：
>  如果控制器 A 被展示在另一个控制器 B 的 popover 中，那么控制器 B 不会调用该方法，直到控制器 A 清除。

### viewWillLayoutSubviews()

- 该方法在通知控制器将要布局 view 的子控件时调用。
- 每当视图的 bounds 改变，view 将调整其子控件位置。
- 该方法可重写以在 view 布局子控件前做出改变。
- 该方法的默认实现为空。
- 该方法调用时，AutoLayout 未起作用。
- 在控制器生命周期中，该方法可能会被多次调用。

### viewDidLayoutSubviews()

- 该方法在通知控制器已经布局 view 的子控件时调用。
- 该方法可重写以在 view 布局子控件后做出改变。
- 该方法的默认实现为空。
- 该方法调用时，AutoLayout 已经完成。
- 在控制器生命周期中，该方法可能会被多次调用。

### viewDidAppear(_:)

- 该方法在控制器 view 已经添加到视图层次时被调用。
- 重写该方法需要首先调用父类该方法。
- 该方法可重写以进行有关正在展示的视图操作。
- 在控制器生命周期中，该方法可能会被多次调用。

### viewWillDisappear(_:)

- 该方法在控制器 view 将要从视图层次移除时被调用。
- 类似 `viewWillAppear(_:)`。
- 该方法可重写以提交变更，取消视图第一响应者状态。

### viewDidDisappear(_:)

- 该方法在控制器 view 已经从视图层次移除时被调用。
- 类似 `viewDidAppear(_:)`。
- 该方法可重写以清除或隐藏控件。

### didReceiveMemoryWarning()

- 当内存预警时，该方法被调用。
- 不能直接手动调用该方法。
- 该方法可重写以释放资源、内存。

### deinit

- 控制器销毁时（离开堆），调用该方法。

### Note

#### Rotation

> **OUTPUT:**
>  willTransition(to:with:)
>  viewWillLayoutSubviews() - Optional((67.5, 269.5, 240.0, 128.0))
>  viewDidLayoutSubviews() - Optional((213.5, 123.5, 240.0, 128.0))
>  viewWillLayoutSubviews() - Optional((213.5, 123.5, 240.0, 128.0))
>  viewDidLayoutSubviews() - Optional((213.5, 123.5, 240.0, 128.0))
>  viewWillLayoutSubviews() - Optional((213.5, 123.5, 240.0, 128.0))
>  viewDidLayoutSubviews() - Optional((213.5, 123.5, 240.0, 128.0))

- 当 view 转变，会调用 `willTransition(to:with:)` 方法。
- 当屏幕旋转，view 的 bounds 改变，其内部的子控件也需要按照约束调整为新的位置，因此也调用了 `viewWillLayoutSubviews()` 和 `viewDidLayoutSubviews()`。

#### Present & Dismiss

> **OUTPUT:**
>  viewWillDisappear
>  viewDidDisappear
>  viewDidDisappear
>  viewWillAppear
>  viewDidAppear

- 当在一个控制器内 Present 新的控制器，原先的控制器并不会销毁，但会消失，因此调用了 `viewWillDisappear` 和 `viewDidDisappear` 方法。
- 如果新的控制器 Dismiss，即清除自己，原先的控制器会再一次出现，因此调用了其中的 `viewWillAppear` 和 `viewDidAppear` 方法。

#### 死循环

```
class LoopViewController: UIViewController {

    override func loadView() {
        print(#function)
    }

    override func viewDidLoad() {
        print(#function)
        let _ = view
    }

}
```

> **OUTPUT:**
>  loadView()
>  viewDidLoad()
>  loadView()
>  viewDidLoad()
>  loadView()
>  viewDidLoad()
>  loadView()
>  viewDidLoad()
>  loadView()

- 若 `loadView()` 没有加载 view，`viewDidLoad()` 会一直调用 `loadView()` 加载 view，因此构成了死循环，程序即卡死。

## 项目中要注意的点

### 1

某些类的生命周期如果要跟随VC的生命周期，在上述方法中配置时一定要成对出现，如果在`viewWillAppear`中初始化，就要在`viewWillDisapper`中销毁。

### 2

viewWillDisappear不仅仅是退出当前VC的时候执行，还有在当前VC上Push或者present一个子VC的时候也会执行，所以viewWillDisappear这个方法里面不能用来做一些配置的销毁操作，要放在deinit中进行销毁。不要搞混了类的生命周期和视图的生命周期。

## 小结

整个控制器声明周期:

1. viewDidLoad
2. viewWillAppear
3. viewWillLayoutSubviews
4. viewDidLayoutSubviews
5. viewDidAppear
6. viewWillDisappear
7. viewDidDisappear


二、非ARC环境下

```
didReceiveMemoryWarning：
```

当app收到内存警告的时候会发消息给视图控制器。
app从来不会直接调用这个方法，而是当系统确定可用内存不足的时候采取调用。

如果你想覆写这个方法来释放一些控制器使用的额外内存，你应该在你的实现方法中调用父类的实现方法。
