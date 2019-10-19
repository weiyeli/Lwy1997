# Delegation in Swift
> 原文链接：https://www.swiftbysundell.com/posts/delegation-in-swift

## 前言
代理(委托)模式在cocoa框架里面应用十分广泛。代理用于UITableViewDelegate处理表视图事件、NSCacheDelegate修改缓存行为等几乎所有常见的行为。代理模式的核心目的是允许一个代理对象以解耦的方式与它的所有者通信，并且不要求这个代理对象知道其所有者的具体类型，我们可以编写更容易重用和维护的代码。就像观察者模式一样，可以参考前两篇文章。代理模式可以通过多种方式来实现，让我们来看看其中的一些方法，以及它们的优缺点。

## 什么时候使用delegate
将某些决策和行为委托给类型的所有者的主要好处是，支持多个用例变得容易得多，而不必创建大量的类型，而这些类型本身需要考虑所有这些用例(面向接口编程，而不是面向实现编程)。

以UITableView或UICollectionView为例。两者在渲染方式和内容方面都是非常通用的。使用代理，我们可以很容易地处理事件、决定如何创建单元格和调整布局属性——所有这些都不需要任何类了解我们的特定逻辑。

当一个类型需要在许多不同的上下文中可用，并且在所有这些上下文中都有一个明确的所有者时，代理通常是一个很好的选择——就像UITableView通常是由父容器视图或它的视图控制器所拥有一样。与观察者模式相反，使用委托的类型只与单个所有者通信——在它们之间建立1:1的关系。

## Protocols
苹果自己的api中最常见的代理方式是使用protocal。就像UITableView有一个UITableViewDelegate协议一样，我们也可以用类似的方式设置我们自己的类型——就像我们在这里为一个文件导入器类定义一个fileimportterdelegate协议:

```
protocol FileImporterDelegate: AnyObject {
    func fileImporter(_ importer: FileImporter,
                      shouldImportFile file: File) -> Bool

    func fileImporter(_ importer: FileImporter,
                      didAbortWithError error: Error)

    func fileImporterDidFinish(_ importer: FileImporter)
}

class FileImporter {
    weak var delegate: FileImporterDelegate?
}
```

## 注意
在实现我们自己的代理协议时，尝试遵循通过苹果自己使用该模式而建立的命名约定通常是一个好主意。以下是一些需要牢记在心的快速指南:

1. 为了说明方法确实是委托方法，通常使用委托类型的名称开始方法名——就像上面的每个方法都以fileImporter开头一样
2. 理想情况下，代理方法的第一个参数应该是代理对象本身，这使得拥有多个实例的对象在处理事件时很容易区分它们
3. 在使用代理时，重要的是不要向代理对象泄漏任何实现细节。例如，在处理按钮点击时，将按钮本身传递给代理方法似乎很有用——但是如果该按钮是一个私有子视图，那么它并不真正属于公共API。

采用基于协议的路由的优点是，它是大多数Swift开发人员都熟悉的已建立的模式。它还将类型(本例中是FileImporter)可以发出的所有事件分组到一个协议中，如果没有正确实现某些东西，编译器将给我们错误。

但是，这种方法也有一些缺点。上面的FileImporter示例中最明显的一点是，使用代理协议可能是模糊状态的来源。请注意我们如何决定是否将给定文件导入代理 - 但由于分配代理是可选的，因此如果代理为空则代理如何处理会变得有点棘手：

```
class FileImporter {
    weak var delegate: FileImporterDelegate?

    private func processFileIfNeeded(_ file: File) {
        guard let delegate = delegate else {
            // Uhm.... what to do here?
            return
        }

        let shouldImport = delegate.fileImporter(self, shouldImportFile: file)

        guard shouldImport else {
            return
        }

        process(file)
    }
}
```

上述问题可以通过多种方式处理 - 包括在解包委托时在else子句中添加assertionFailure()，或使用默认值。但无论哪种方式，它都表明我们的设置有一些弱点，因为我们正在引入另一个经典的“这应该永远不会发生”的场景，理想情况下应该避免这种情况。

## Closures
我们可以使上述代码更具可预测性的一种方法是重构我们的代理协议的决策部分，通过使用闭包来替代。这样，我们的API用户将需要指定用于决定哪些文件将被预先导入的逻辑，从而消除了文件导入器逻辑中的歧义：

```
class FileImporter {
    weak var delegate: FileImporterDelegate?
    private let predicate: (File) -> Bool

    init(predicate: @escaping (File) -> Bool) {
        self.predicate = predicate
    }

    private func processFileIfNeeded(_ file: File) {
        let shouldImport = predicate(file)

        guard shouldImport else {
            return
        }

        process(file)
    }
}
```

有了上面的更改，我们现在可以继续从代理协议中删除shouldImportFile方法，只留下与状态更改相关的方法:

```
protocol FileImporterDelegate: AnyObject {
    func fileImporter(_ importer: FileImporter,
                      didAbortWithError error: Error)

    func fileImporterDidFinish(_ importer: FileImporter)
}
```

上面的主要优势是,它现在变得更难错误的使用FileImporter类,因为现在及时没有分配一个具体的代理对象给他也是完全有效的(在这种情况下可能是有用的,以防一些文件在后台应该import,我们并不真正感兴趣的操作)的结果。

## Configuration types
假设我们想继续将其余的代理方法转换为闭包。这样做的一种方法是简单地继续添加闭包作为初始化器参数或可变属性。但是，这样做时，我们的API可能开始变得有点混乱 - 并且很难区分配置选项和其他类型的属性。

解决这种困境的一种方法是使用专用配置类型。通过这样做，我们可以实现相同的良好事件分组，就像我们使用原始代理协议一样，同时在实现各种事件时仍然可以实现很多自由。 我们将为配置类型使用结构并为每个事件添加属性，如下所示：

```
struct FileImporterConfiguration {
    var predicate: (File) -> Bool
    var errorHandler: (Error) -> Void
    var completionHandler: () -> Void
}
```

现在，我们可以在初始化文件导入器时更新文件导入器以获取一个参数——它的配置，并通过将配置保存在属性中轻松访问每个闭包:

```
class FileImporter {
    private let configuration: FileImporterConfiguration

    init(configuration: FileImporterConfiguration) {
        self.configuration = configuration
    }

    private func processFileIfNeeded(_ file: File) {
        let shouldImport = configuration.predicate(file)

        guard shouldImport else {
            return
        }

        process(file)
    }

    private func handle(_ error: Error) {
        configuration.errorHandler(error)
    }

    private func importDidFinish() {
        configuration.completionHandler()
    }
}
```

使用上面的方法进行代理还有一个很好的额外好处——为各种常见的文件导入器配置定义方便的api变得超级容易。例如，我们可以在FileImportConfiguration上添加一个方便的初始化器，它只接受一个参数——这使得创建一个“fire and forget”类型导入器变得很简单:

```
extension FileImporterConfiguration {
    init(predicate: @escaping (File) -> Bool) {
        self.predicate = predicate
        errorHandler = { _ in }
        completionHandler = {}
    }
}
```

作为补充说明：通过在扩展中而不是在类型本身中定义struct的convenience初始化器，我们仍然可以保留默认的编译器生成的初始化器。

我们甚至可以为不需要任何参数的常见配置创建静态的convenicence api，例如一个只导入所有文件的变量:

```
extension FileImporterConfiguration {
    static var importAll: FileImporterConfiguration {
        return .init { _ in true }
    }
}
```

然后我们可以使用Swift非常优雅的点语法，制作一个非常容易使用的API，它仍然提供了很多自定义和灵活性：

```
let importer = FileImporter(configuration: .importAll)
```

## Delegation的缺点
代理对象只能是一对一的关系，如果需要一对多的关系应该使用观察者模式

## 使用Delegation要注意的地方
delegation变量要用weak来修饰，避免循环引用