# ChildViewController

## 前言

就像如何将UIView添加到另一个UIView以形成层次结构一样，视图控制器可以成为另一个视图控制器的子节点。 这使我们能够从多个构建块组成我们的UI，这可以导致更容易重用的较小视图控制器实现。

作为子控制器添加时，视图控制器会根据应用程序窗口的大小自动调整大小 - 但就像独立UIView的子视图一样，可以使用框架或自动布局约束调整子视图控制器的视图大小并重新定位。

要将视图控制器添加为子视图，我们使用以下三个API调用：

```swift
let parent = UIViewController()
let child = UIViewController()

// First, add the view of the child to the view of the parent
parent.view.addSubview(child.view)

// Then, add the child to the parent
parent.addChild(child)

// Finally, notify the child that it was moved to a parent
child.didMove(toParent: parent)
```

要删除已添加到父级的子级，我们将使用以下三个调用：

```swift
// First, notify the child that it’s about to be removed
child.willMove(toParent: nil)

// Then, remove the child from its parent
child.removeFromParent()

// Finally, remove the child’s view from the parent’s
child.view.removeFromSuperview()
```

正如您在上面所看到的，这两个操作都需要相当多的步骤 - 因此，如果我们在项目中开始广泛使用子视图控制器，事情就会很快发生重复。

该问题的一个解决方案是在UIViewController上添加一个扩展，它将添加或删除子视图控制器所需的所有步骤捆绑成两个易于使用的方法，如下所示：

```swift
extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
```

子视图控制器对于我们希望在项目中重用的UI功能特别有用。 例如，我们可能希望在我们为每个屏幕加载内容时显示加载视图 - 这可以使用子视图控制器轻松实现，然后可以在需要时添加。

要做到这一点 - 首先，让我们创建一个LoadingViewController，在其视图的中心显示一个加载控制器，如下所示：

```swift
class LoadingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)

        // Center our spinner both horizontally & vertically
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
```

接下来，当我们 - 在我们的一个内容视图控制器中 - 开始加载内容时，我们现在可以简单地将新的LoadingViewController作为子项添加以显示加载微调器，然后在完成后将其删除：

```swift
class ContentViewController: UIViewController {
    private let loader = ContentLoader()

    func loadContent() {
        let loadingVC = LoadingViewController()
        add(loadingVC)

        loader.load { [weak self] content in
            loadingVC.remove()
            self?.render(content)
        }
    }
}
```

太酷了！ 👍但问题是 - 为什么要经历一个像加载微调器这样的实现视图控制器的麻烦，而不是仅使用普通的UIView？以下是一些常见原因：

+ 视图控制器可以访问viewDidLoad和viewWillAppear等事件，即使在用作子项时也是如此，这对于多种UI代码非常有用。
+ 视图控制器更加独立 - 并且可以包括驱动其UI所需的逻辑以及UI本身。
+ 作为子项添加时，视图控制器会自动填充屏幕，从而减少了对全屏UI的额外布局代码的需求。
+ 当一个UI被实现为视图控制器时，它可以在许多不同的上下文中使用 - 包括被推送到导航控制器，以及作为孩子嵌入。

当然，这并不一定意味着所有UI都应该使用子视图控制器来实现 - 但是为了以更模块化的方式构建UI，它们是一个很好的工具。