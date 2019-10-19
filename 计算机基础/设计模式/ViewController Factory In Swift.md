# ViewController Factory In Swift
> 原文链接：https://medium.com/@sreeks/view-controller-factory-in-swift-1d4ee8f9b54

## 什么是VCFactory
VCFactory是为了解耦VC的创建从而诞生的。创建视图控制器是iOS编程中的一项基本任务。然而，在没有注意到的情况下，很容易陷入不必要的代码耦合中。让我们详细看看这个问题，并学习如何应用设计模式来解决它。

## 示例
本文将采取一个简单的假设用户登录流程，以跨越一个场景。

1. 用户从一个登录页面开始，导航从这里分支到注册或登录。
2. 用户可以从Sign Up导航到Login，以防他们回忆起自己确实有一个帐户。
3. 用户可以从Login页面跳转到忘记密码页面
4. 成功注册/登录后，用户可以返回主界面

一个经典的View Controller将会像这样

```
class LandingPageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func didTapOnSignup() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let signupVC = storyboard.instantiateViewController(withIdentifier: "signup") 
        self.navigationController?.pushViewController(signupVC, animated: true)
    }
    
    func didTapOnLogin() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "login") 
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
}

class LoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func didTapOnForgotPassword() {
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let forgotPasswordVC = storyboard.instantiateViewController(withIdentifier: "forgotPassword")
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    func userLoginDidSuccess() {
        let storyboard = UIStoryboard(name: "PostLogin", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "home") 
        self.navigationController?.pushViewController(homeVC, animated: true)
    }
}
```

上述代码有以下几个问题：

1. 首先，每个视图控制器都知道另一个视图控制器。这并不好。如果Storyboard的名字或者Id改变了就需要修改多处代码。
2. 我们无法测试

## 使用工厂模式解决
我们想要

1. 不需要具体的细节就可以创建一个ViewController
2. 提供一种可预测的测试机制

示例代码如下：

```
struct StoryboardRepresentation {
    let bundle: Bundle?
    let storyboardName: String
    let storyboardId: String
}

enum TypeOfViewController {
    case signup
    case login
    case forgotPassword
    case home
}

extension TypeOfViewController {
    func storyboardRepresentation() -> StoryboardRepresentation {
        switch self {
        case .signup:
            return StoryboardRepresentation(bundle: nil, storyboardName: "UserOnboarding", storyboardId: "signup")
        case .login:
            return StoryboardRepresentation(bundle: nil, storyboardName: "UserOnboarding", storyboardId: "login")
        case .forgotPassword:
            return StoryboardRepresentation(bundle: nil, storyboardName: "UserOnboarding", storyboardId: "forgotPassword")
        case .home:
            return StoryboardRepresentation(bundle: nil, storyboardName: "Home", storyboardId: "home")
        }
    }
}

class ViewControllerFactory: NSObject {
    static func viewController(for typeOfVC: TypeOfViewController) -> UIViewController {
        let metadata = typeOfVC.storyboardRepresentation()
        let sb = UIStoryboard(name: metadata.storyboardName, bundle: metadata.bundle)
        let vc = sb.instantiateViewController(withIdentifier: metadata.storyboardId)
        return vc
    }
}
```

这里我们通过创建枚举类型来支持所有的vc，每一种枚举类型提供一种Storyboard的实现,我们可以通过他来创建一个vc。增加一种vc就通过增加一种枚举来实现。此外，当我们查看enum时，我们得到了应用程序中使用的所有视图控制器的鸟瞰图。

我们可以这样来使用它：

```
class LandingPageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didTapOnSignup() {
        let signupVC = ViewControllerFactory.viewController(for: .signup)
        self.navigationController?.pushViewController(signupVC, animated: true)
    }
    
    func didTapOnLogin() {
        let loginVC = ViewControllerFactory.viewController(for: .login)
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
}

class LoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didTapOnForgotPassword() {
        let forgotPasswordVC = ViewControllerFactory.viewController(for: .forgotPassword)
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    func userLoginDidSuccess() {
        let homeVC = ViewControllerFactory.viewController(for: .home)
        self.navigationController?.pushViewController(homeVC, animated: true)
    }
}
```

## 存在的问题
我们想在推送视图控制器之前配置它?我们如何在不添加不需要的依赖项的情况下干净地做到这一点?请听下回分解