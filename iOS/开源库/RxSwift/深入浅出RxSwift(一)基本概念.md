# 什么是RxSwift？

[ReactiveX](http://reactivex.io/)（简写: Rx） 是一个可以帮助我们简化异步编程的框架。

[RxSwift](https://github.com/ReactiveX/RxSwift) 是 [Rx](https://github.com/Reactive-Extensions/Rx.NET) 的 **Swift** 版本。RxSwift将响应式编程的思想移植到了 iOS/macOS 平台。

更多的资料可以关注 [ReactiveX.io](http://reactivex.io/)。

# 什么是响应式编程？

响应式编程是使用**高阶函数的特性传递异步事件流的变化的一种编程范式**。这个解释比较抽象，我们看看下面这个例子：

```
a = 1
b = 2
c = a + b // c:3
a = 2
c? 
```

我们初始化了a,和b，可以计算出c = 3。当a是一个根据异步事件变化的序列时，比如a改变为2，那这个时候c的值是不会变的。而响应式编程范式实现的是对这种变化进行传递，在改变a时，c也会随之发生变化，在这个例子中c 会等于4。当然我们可以通过多种方式来实现传递变化，比如我们可以使用Notification,delegate,setter等方式，在改变a和b的值时发送通知，同时监听通知来重新计算出c的值。而响应式编程就是使用高阶函数的方式来简化类似的操作。

```
c = sum(a,b)
```

可以理解为有这么一个动态的函数`sum`，会计算a + b的和，只要a和b的值发生改变，sum的值也会随之改变。响应式编程的概念足够单独出一篇文章，因此不再赘述，可以参考其他的博文。

# 为什么要使用RxSwift

在iOS/macOS平台，开发者可以使用Notification、delegate、block、setter等方式来实现针对异步事件流的编程。试想一下，在一个项目中，如果有的开发者使用Notification，有的开发者使用delegate，还有的开发者使用block，每一个人使用的技术方式都不同，代码的可阅读性就会大大降低，可维护性也会降低，复杂度和定位问题的难度急剧上升。使用RxSwift可以让我们统一异步事件流的编程接口，由于都使用RxSwift，代码的可阅读性会大大提升。

RxSwift是swift的响应式编程框架，它拓展了观察者模式，使你能够自由组合多个异步数据/事件流，而不需要去关心线程，同步，线程安全，并发数据以及I/O阻塞等底层逻辑。

优缺点

- 优点

- - 简洁 - Rx 简化了代码，使用较少的代码即可实现相同的功能

- - 清晰 - 声明都是不可变更的， 而且代码高内聚， 代码易读，易维护

- - 易用 - 它抽象的了异步编程，使我们统一了代码风格

- - 灵活 - 通过组合的方式构建复杂功能

- 缺点

- - 转变思考方式，所有的东西都是数据流(stream/sequence), 入门门槛高

- - 调用栈复杂

# 基本概念

RxSwift的基本概念主要包括以下几个：

- Observable - 产生事件，被观察事件序列

- Observer - 观察者，响应事件

- Disposable - 管理绑定（订阅）的生命周期

- Operator - 用于组合操作事件序列

- Schedulers - 线程队列调配

## Observable

所有的Observable都会实现ObservableType协议，提供一个subscribe方法，通过subscribe方法调用执行Observable的逻辑并将输出通知到Observer。

```swift
public protocol ObservableType : ObservableConvertibleType {
      func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E
}
```

![sequence](https://tva1.sinaimg.cn/large/006y8mN6gy1g8erdpndigj30ex07l0uh.jpg)

在RxSwift中，Observable<Element>代表的是一个可观察序列，从字面意思可以看出这是在观察者模式中的被观察者，它会向观察对象发送事件序列：

- .Next(Element)：新事件

- .Error(error)：带有异常的事件完成序列

- .Complete()：正常事件完结序列

.Next(Element)是Observable发送的正常事件，Element包含了Observer关注的数据，当Observable发送了.Complete()或者因为出错发送了.Error(error)事件时，这个可观察序列的生命周期终止，无法再继续发送事件。

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/GwPtvnL9wiYmzUbpejna8bvYeMIjGOl14b0BVqHGdrq07pEpK9/)

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/VaxjJ6YNJM6RMTUMfzTzX8L0ZtR8EwYFJBYkbq746bdDESPUpW/)

### 创建Observable

RxSwift提供了几种创建Observable的方式第一种方式是create

```swift
Observable.create { (observer) -> Disposable in
    let task = URLSession.shared.dataTask(with: ...) { data, _, error in
        guard error == nil else {
            observer.onError(error!)
            return
        }
        guard let data = data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            else {
            observer.onError(DataError.cantParseJSON)
            return
        }
        observer.onNext(jsonObject)
        observer.onCompleted()
    }
    task.resume()
    return Disposables.create { task.cancel() }
}
```

create方法传进去的闭包并不会马上执行，当调用Observable的subscribe方法时才会执行该闭包，并通知到subscribe方法的observer。

```swift
class AnonymousObservableSink<O: ObserverType> : Sink<O>, ObserverType {
    typealias E = O.E
    typealias Parent = AnonymousObservable<E>
    // state
    private var _isStopped: AtomicInt = 0
    override init(observer: O, cancel: Cancelable) {
        super.init(observer: observer, cancel: cancel)
    }
    func on(_ event: Event<E>) {
        switch event {
        case .next:
            if _isStopped == 1 {
                return
            }
            forwardOn(event)
        case .error, .completed:
            if AtomicCompareAndSwap(0, 1, &_isStopped) {
                forwardOn(event)
                dispose()
            }
        }
    }
    func run(_ parent: Parent) -> Disposable {
        return parent._subscribeHandler(AnyObserver(self))
    }
}
```

subscribe方法最后会调用到AnonymousObservableSink的run方法，参数parent是Observable.create返回的AnonymousObservable 对象，_subscribeHandler就是Observable.create传入的闭包,on方法最后调用forwardOn(Event),将event传递给subcribe方法传入的observer。

总结一下就是Observable.create将闭包持有，当调用subscribe方法时，执行该闭包并且将subcribe方法的参数作为闭包的参数。

rxswift还提供了几种创建Observable的便利方法,具体可以看这个文档[Creating-Observables ](https://github.com/ReactiveX/RxJava/wiki/Creating-Observables)，下面简单介绍几个常用的

- Observable.just(1)

**创**建 Observable 发出唯一的一个元素

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/2v8XTstO59KBlEWcJ9M8KPHT4ORugVPHpkv6KqfdqvKWMzdSjw/)

- Observable.from([10,20,30])

将一个数组转出一个事件序列

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/v1XEq02BTytM6tlt2aJYgsPAGi7W8vg8wZh9J7PhuHHoW8e4rk/)

- Observable.interval(10)

创建一个 Observable 每隔一段时间，发出一个索引数

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/3RT6z5CfF9OnSay7l7eNmnzVBKIELlIxutiUVxWtKwBvcSmj9N/)

- Obervable.timer(30, 10)

在一段延时后，每隔一段时间产生一个元素

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/xtzmZnG5oS6fftbpraY1aODBh8naYk3u4RsXORdWZ5cLbtgpFE/)

### Driver

Driver是一个专门为UI层准备的Observable，它有以下几个特性，便于我们进行和UI的绑定：

- 不会产生error 事件

- 一定在MainScheduler 监听

- 共享状态变化

为什么用Driver？看看下面这个例子：

```
let results = query.rx.text
    .throttle(0.3, scheduler: MainScheduler.instance)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query) 
    }
// 1. results的代码会执行两遍
// 2. 如果请求出错所有绑定被dispose无法继续触发请求
// 3. 可能在后台线程刷新UI
results
    .map { "\($0.count)" }
    .bind(to: resultCount.rx.text)
    .disposed(by: disposeBag)
results
    .bind(to: resultsTableView.rx.items(cellIdentifier: "Cell")) {
      (_, result, cell) in
        cell.textLabel?.text = "\(result)"
    }
    .disposed(by: disposeBag)
```

改成Driver可与确保不会出现上面提到的问题：

```swift
let results = query.rx.text.asDriver()        // 将普通序列转换为 Driver
    .throttle(0.3)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query)
            .asDriver(onErrorJustReturn: [])  // 仅仅提供发生错误时的备选返回值
    }

results
    .map { "\($0.count)" }
    .drive(resultCount.rx.text)               // 这里改用 `drive` 而不是 `bind to`
    .disposed(by: disposeBag)                 // 这样可以确保必备条件都已经满足了

results
    .drive(resultsTableView.rx.items(cellIdentifier: "Cell")) {
      (_, result, cell) in
        cell.textLabel?.text = "\(result)"
    }
    .disposed(by: disposeBag)let results = query.rx.text.asDriver()        // 将普通序列转换为 Driver
    .throttle(0.3)
    .flatMapLatest { query in
        fetchAutoCompleteItems(query)
            .asDriver(onErrorJustReturn: [])  // 仅仅提供发生错误时的备选返回值
    }
```

asDriver(onErrorJustReturn: [])相当于以下代码的组合：

```swift
let safeSequence = xs
  .observeOn(MainScheduler.instance)       // 主线程监听
  .catchErrorJustReturn(onErrorJustReturn) // 无法产生错误
  .share(replay: 1, scope: .whileConnected)// 共享状态变化
```

## Observer

Observer实现了ObserverType协议，支持通过on方法接收Observable的事件通知

```
public protocol ObserverType {
    /// The type of elements in sequence that observer can observe.
    associatedtype E
    /// Notify observer about sequence event.
    /// - parameter event: Event that occurred.
    func on(_ event: Event<E>)
}
```

AnyObserver

但是我们一般很少去创建Observer，而是通过subscribe方法传入一个block，subscribe方法使用这个block创建一个AnyObserver类型的对象，例如下面的代码：

```
URLSession.shared.rx.data(request: URLRequest(url: url))
    .subscribe(onNext: { data in
        print("Data Task Success with count: \(data.count)")
    }, onError: { error in
        print("Data Task Error: \(error)")
    })
    .disposed(by: disposeBag)
```



其内部实现大概是这样的：

```
let observer: AnyObserver<Data> = AnyObserver { (event) in
    switch event {
    case .next(let data):
        print("Data Task Success with count: \(data.count)")
    case .error(let error):
        print("Data Task Error: \(error)")
    default:
        break
    }
}
URLSession.shared.rx.data(request: URLRequest(url: url))
    .subscribe(observer)
    .disposed(by: disposeBag)
```



Binder

另一个常用的Observer类型是Binder，由于在做App开发时，我们经常需要把数据绑定到UI上，所以rxSwift定义了Binder类型，用于UI的Observer，它主要有两个特征：

- 不会处理错误事件；

- 确保绑定都是在给定的Scheduler上执行，默认是MainScheduler;

- 封装复用

由于Observable有个特性，当发生错误时，事件序列结束，不能再继续发射数据，而在和UI绑定时，发生错误时导致的结果就是UI无法再继续响应数据更新（其实是数据不会更新），而Binder在遇到错误时，再调试环境下将执行fatalError，在发布环境下打印错误信息，从一定程度上保证不会误将Error输出到UI空件；另一个特征保证Observer执行的操作实在主线程执行，避免了有时忘了切主线程而在后台线程操作UI控件。

Binder的另一个用处是封装复用，让数据绑定变得更简洁可读：

```
extension Reactive where Base: UIView {
  public var isHidden: Binder<Bool> {
      return Binder(self.base) { view, hidden in
          view.isHidden = hidden
      }
  }
}
```

``

```
usernameValid
    .bind(to: usernameValidOutlet.rx.isHidden)
    .disposed(by: disposeBag)
usernameValid.subscribe( onNext:{ result in
    usernameValidOutlet.isHidden = result
})
```

这样你不必为每个 **UI** 控件单独创建该观察者。这也是rxCocoa对UIView属性的封装方式。用这种方式我们也可以为一些复杂的自定义界面封装界面设置代码，比如一个自定义的进度条View：

```
extension Reactive where Base: SwiftSpinner {
    public var progress: UIBinder<Int> {
        return UIBinder(self.base) { spinner, progress in
            let progress = max(0, min(progress, 100))
            SwiftSpinner.show(progress: Double(progress)/100.0, title: "\(progress)% completed")
        }
    }}
```

``

![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/dCeZkqm5HukSCYH4pQmVtj5LnqEqFqGGtHYQheaf7ubgHMBuK9/)



Disposable

```
**public** **protocol** Disposable {
    /// Dispose resource.
    **func** dispose()
}
```



Disposable是为了更加灵活的管理Observable的生命周期而引入的一个概念，在Observable中，闭包会创建一些资源或者捕获外部的实例对象，前面我们说过，Observable执行结束(接收到complete或者Error事件)时会释放这些资源，当Observable没有结束的时候，这些资源会被一直持有。这是怎么做到的呢？

在调用Observable的subscribe方法时，会创建一个引用循环，保持Observable和Observer都不会被释放直到以下两种情况出现才会打破引用循环：

- 当Observable序列结束时，收到complete或者error事件

- 当显示的调用subscribe返回的Disposable对象的dispose方法





![img](https://internal-api-space-lf.feishu.cn/space/api/file/out/MaJlH8XLrATGyhSwnoIBZIuVDjXZytPotzamDvy4z9wg1gqn5M/)

什么时候需要调用dispose方法呢？比如，进入某个界面后发送一个网络请求，当请求没有返回时，退出了界面，这时有两种可能的需求，一种是由于请求的数据需要在界面展示，退出界面后就不需要继续处理请求了，这个时候我们需要取消请求；另一种情况是我们需要把请求数据存到数据库以备以后使用，这个时候我们希望请求继续执行。

对于第一种情况我们可以：

```
**final** **class** MyViewController: UIViewController {
    **var** subscription: Disposable?
    **override** **func** viewDidLoad() {
        **super**.viewDidLoad()
        subscription = theObservable().subscribe(onNext: {
            *// handle your subscription*
        })
    }
    **deinit** {
        subscription?.dispose()
    }
}
```

而对于第二种情况由于循环引用的存在，可以不需要做任何处理，直到请求成功返回处理数据或者请求失败，自动释放资源。



DisposeBag

对于上面的第一种情况，如果同一个界面有多个Disposable，那么就会有很多处理dispose的代码，同时在ARC环境下，我们更希望自动的去处理资源管理，而不是手动的去管理资源生命周期。于是引入了DisposeBag,将Disposable加入到DisposeBag中，当DisposeBag deinit时，会自动调用所有Disposable的dispose方法，从而达到ARC的效果。

```
**final** **class** MyViewController: UIViewController {
    **let** disposeBag = DisposeBag()
    **override** **func** viewDidLoad() {
        **super**.viewDidLoad()
        theObservable().subscribe(onNext: {
            *// handle your subscription*
        })
            .disposed(by: disposeBag)
    }
}
```