# 什么是RxSwift？

[ReactiveX](http://reactivex.io/)（简写: Rx） 是一个可以帮助我们简化异步编程的框架。

`RxSwift` 是 `ReactiveX` 家族的重要一员, `ReactiveX` 是 `Reactive Extensions` 的缩写，一般简写为 `Rx`。`ReactiveX`官方给`Rx`的定义是：**Rx是一个使用可观察数据流进行异步编程的编程接口。**

`ReactiveX` 不仅仅是一个编程接口，它是一种编程思想的突破，它影响了许多其它的程序库和框架以及编程语言。它拓展了观察者模式，使你能够自由组合多个异步事件，而不需要去关心线程，同步，线程安全，并发数据以及I/O阻塞。

`RxSwift` 是 `Rx` 为 `Swift` 语言开发的一门函数响应式编程语言， 它可以代替iOS系统的 `Target Action` / `代理` / `闭包` / `通知` / `KVO`,同时还提供`网络`、`数据绑定`、`UI事件处理`、`UI的展示和更新`、`多线程`……

鉴于`Swift`日渐增长的影响力，ios开发者不可避免的要学习和使用`Swift`这门语言进行编程开发。而`RxSwift`对使用`Swift`的帮助有如下几点：

`Swift`为值类型，在传值与方法回调上有影响，`RxSwift`一定程度上弥补`Swift`的灵活性

- `RxSwift`使得代码复用性较强，减少代码量
- `RxSwift`因为声明都是不可变更，增加代码可读性
- `RxSwift`使得更易于理解业务代码，抽象异步编程，统一代码风格
- `RxSwift`使得代码更易于编写集成单元测试，增加代码稳定性

#思维脑图

![RxSwift](https://tva1.sinaimg.cn/large/006y8mN6gy1g8et6q0xr6j30zk0k2wlo.jpg)

- 

#基本概念

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

在RxSwift中，Observable<Element>代表的是一个可观察序列，从字面意思可以看出这是在观察者模式中的被观察者，它会向观察对象发送事件序列：

- .Next(Element)：新事件

- .Error(error)：带有异常的事件完成序列

- .Complete()：正常事件完结序列

.Next(Element)是Observable发送的正常事件，Element包含了Observer关注的数据，当Observable发送了.Complete()或者因为出错发送了.Error(error)事件时，这个可观察序列的生命周期终止，无法再继续发送事件。

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

rxswift还提供了几种创建Observable的便利方法,具体可以看这个文档[Creating-Observables ](https://github.com/ReactiveX/RxJava/wiki/Creating-Observables)。

### Driver

Driver是一个专门为UI层准备的Observable，它有以下几个特性，便于我们进行和UI的绑定：

- 不会产生error 事件

- 一定在MainScheduler 监听

- 共享状态变化

为什么用Driver？看看下面这个例子：

```swift
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

```swift
public protocol ObserverType {
    /// The type of elements in sequence that observer can observe.
    associatedtype E
    /// Notify observer about sequence event.
    /// - parameter event: Event that occurred.
    func on(_ event: Event<E>)
}
```

### AnyObserver

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

```swift
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

## Disposable

Disposable是为了更加灵活的管理Observable的生命周期而引入的一个概念，在Observable中，闭包会创建一些资源或者捕获外部的实例对象，前面我们说过，Observable执行结束(接收到complete或者Error事件)时会释放这些资源，当Observable没有结束的时候，这些资源会被一直持有。这是怎么做到的呢？

在调用Observable的subscribe方法时，会创建一个引用循环，保持Observable和Observer都不会被释放直到以下两种情况出现才会打破引用循环：

- 当Observable序列结束时，收到complete或者error事件

- 当显示的调用subscribe返回的Disposable对象的dispose方法

什么时候需要调用dispose方法呢？比如，进入某个界面后发送一个网络请求，当请求没有返回时，退出了界面，这时有两种可能的需求，一种是由于请求的数据需要在界面展示，退出界面后就不需要继续处理请求了，这个时候我们需要取消请求；另一种情况是我们需要把请求数据存到数据库以备以后使用，这个时候我们希望请求继续执行。

对于第一种情况我们可以：

```swift
final class MyViewController: UIViewController {
    var subscription: Disposable?
    override func viewDidLoad() {
        super.viewDidLoad()
        subscription = theObservable().subscribe(onNext: {
            // handle your subscription
        })
    }
    deinit {
        subscription?.dispose()
    }
}
```

而对于第二种情况由于循环引用的存在，可以不需要做任何处理，直到请求成功返回处理数据或者请求失败，自动释放资源。

### DisposeBag

对于上面的第一种情况，如果同一个界面有多个Disposable，那么就会有很多处理dispose的代码，同时在ARC环境下，我们更希望自动的去处理资源管理，而不是手动的去管理资源生命周期。于是引入了DisposeBag,将Disposable加入到DisposeBag中，当DisposeBag deinit时，会自动调用所有Disposable的dispose方法，从而达到ARC的效果。

```swift
final class MyViewController: UIViewController {
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        theObservable().subscribe(onNext: {
            // handle your subscription
        })
            .disposed(by: disposeBag)
    }
}
```