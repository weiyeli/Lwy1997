# Alamofire源码剖析

## [Alamofire](https://link.juejin.im/?target=https%3A%2F%2Fgithub.com%2FAlamofire%2FAlamofire) 是什么？

- 在功能角度，`Alamofire`是一个http请求框架。使用它可以很方便的处理http请求（请求数据，下载，上传）。
- 在代码实现角度，`Alamofire`是对`NSURLSession`的封装。
- 在语言角度可以理解为`Alamofire`是`AFNetworking`的Swift实现（它们出自同一作者）。

## 本博文适用对象

在这篇博文我 **不会阐述Alamofire的使用方法** ， **而是介绍Alamofire的设计思想和组织结构** 。希望这篇博文能够抛砖引玉，助你轻松的理解Alamofire的实现细节。

## NSURLSession概述

`Alamofire`是对`NSURLSession`的封装， 在分析`Alamofire`前，咱先简单看下`NSURLSession`的api。

### Creating a Session

```
//两个初始化方法
init(configuration: URLSessionConfiguration)
init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?)
复制代码
```

### Configuring a Session

```
//配置信息，必须在init方法中指定。在指定后不能修改
var configuration: URLSessionConfiguration { get }
var delegate: URLSessionDelegate? { get }
var delegateQueue: OperationQueue { get }
复制代码
```

### Adding Tasks

1. Adding Data Tasks to a Session

```
//根据url创建Data Task，然后调用URLSessionDataTask对象的resume方法来开始。当接受到response时会调用session’s delegate。
func dataTask(with url: URL) -> URLSessionDataTask
//与上面方法的唯一不同是task结束后调用completionHandler闭包，不再调用session’s delegate。后面还有几个带有completionHandler的方法，就不在说明。
func dataTask(with url: URL, completionHandler: (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
//根据URLRequest对象创建Data Task。URLRequest含有更丰富的配置信息，比如cachePolicy，timeoutInterval等。
func dataTask(with request: URLRequest) -> URLSessionDataTask
func dataTask(with request: URLRequest, completionHandler: (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
复制代码
```

1. Adding Download Tasks to a Session

```
func downloadTask(with url: URL) -> URLSessionDownloadTask
func downloadTask(with url: URL, completionHandler: (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
func downloadTask(with request: URLRequest) -> URLSessionDownloadTask
func downloadTask(with request: URLRequest, completionHandler: (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask
func downloadTask(withResumeData resumeData: Data, completionHandler: (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
复制代码
```

1. Adding Upload Tasks to a Session

```
func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask
func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask
func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask
func uploadTask(withStreamedRequest request: URLRequest) -> URLSessionUploadTask
复制代码
```

1. Adding Stream Tasks to a Session

```
func streamTask(withHostName hostname: String, port: Int) -> URLSessionStreamTask
func streamTask(with service: NetService) -> URLSessionStreamTask
复制代码
```

\##框架核心：Manager Alamofire.swift文件中定义了一组方法以方便我们进行 request, download,upload操作（差不多解决了90%的需求吧）。 这些方法只是为了方便使用，真正做事情的是类`Manager`。`Manager`才是框架的核心。框架结构如下：

![img](http://ww2.sinaimg.cn/large/006tNc79gy1g4oqrb4zy9j30m0080jrw.jpg)

- session: 所有的task都是由这个session创建的，也就是说对session 的配置信息作用于所有的task。
- delegate: session的代理由专门的类`SessionDelegate`负责。`SessionDelegate`实现了 `NSURLSessionDelegate`, `NSURLSessionTaskDelegate`,`NSURLSessionDataDelegate`,`NSURLSessionDownloadDelegate` 协议，并实现了这些协议的所有方法。`SessionDelegate`就是回调事件的枢纽中心，完成回调的统一处理和散发。
- backgroundCompletionHandler：当需要执行后台操作任务时使用。具体内容：[NSURLSession使用说明及后台工作流程分析](https://link.juejin.im/?target=http%3A%2F%2Fwww.cocoachina.com%2Fios%2F20131106%2F7304.html)。
- AddingTasksMethod：这是一组创建Task的方法。上面 **NSURLSession概述** 中提到一组 **Adding Tasks** 方法， 框架对这些方法进行了封装，我们统一称这组方法为AddingTasksMethod。 在后面的 **创建Task** 部分再细说。
- startRequestsImmediately：当创建task后，需要调用这个task的`resume`方法才会开始执行。startRequestsImmediately=true时， 创建好task就会resume。

看下初始化方法：

```
//使用单例模式创建唯一的Manger。
 public static let sharedInstance: Manager = {
     let configuration =NSURLSessionConfiguration.defaultSessionConfiguration()
     
     //defaultHTTPHeaders， 定义http头。内容包括：Accept-Encoding，Accept-Language,User-Agent
     configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
     return Manager(configuration: configuration)
}()

//创建session， delegate，serverTrustPolicyManager。
 public init( configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),delegate: SessionDelegate = SessionDelegate(),serverTrustPolicyManager: ServerTrustPolicyManager? = nil){
        self.delegate = delegate
        self.session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
			//一个session对应一个serverTrustPolicyManager。当使用https需要验证服务器证书时可以通过serverTrustPolicyManager来配置验证策略。例如当服务器使用自定义证书时就可以使用 serverTrustPolicyManager来满足需求。https涉及内容太多，这里就不展开细说了。
        commonInit(serverTrustPolicyManager: serverTrustPolicyManager)
}
复制代码
```

至此我们已经创建好了session和它的delegate。调用流程大致这个样子： 通过`Manager`创建`session`和`SessionDelegate`对象------>使用AddingTasksMethod创建task----->task调用resume()开始执行------>调用`SessionDelegate`中实现的代理方法。

## 使用闭包重载代理方法

为了使用框架的灵活性，`SessionDelegate`为每一个delegate方法声明了一个对应的闭包。这样你就可以很方便的指定如何处理回调。

![img](http://ww1.sinaimg.cn/large/006tNc79gy1g4oqsexsruj30ue0gyadp.jpg)

例如：

```
//当需要认证时会调用这个回调
public func URLSession(session: NSURLSession,didReceiveChallenge challenge: NSURLAuthenticationChallenge,completionHandler: ((NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)){
    guard sessionDidReceiveChallengeWithCompletion == nil else {
         sessionDidReceiveChallengeWithCompletion?(session, challenge, completionHandler)
         return
    }
   //如果没有对闭包赋值，执行框架中的默认操作
}
复制代码
```

## 创建Task

框架中对 **NSURLSession概述** 中的 **Adding Tasks** 方法进行了封装，组成了前面提到的AddingTasksMethod。

![img](http://ww2.sinaimg.cn/large/006tNc79gy1g4oqsaqukfj30rx07174z.jpg)

#### request

通过调用下面的方法，创建`NSURLSessionDataTask`对象。

```
public protocol URLRequestConvertible {
    var URLRequest: NSMutableURLRequest { get }
}
extension NSURLRequest: URLRequestConvertible {
    public var URLRequest: NSMutableURLRequest { 
    		return self.mutableCopy() as! NSMutableURLRequest
    }
}
public func request(URLRequest: URLRequestConvertible) -> Request {
    var dataTask: NSURLSessionDataTask!
    dispatch_sync(queue) {dataTask = self.session.dataTaskWithRequest(URLRequest.URLRequest) }
    //其他代码...
}
复制代码
```

在上面代码中，`URLRequest.URLRequest` 就是一个`NSMutableURLRequest` 对象。我们使用`NSMutableURLRequest`创建了一个`NSURLSessionDataTask`。`queue` 是串行队列，在串行队列 `queue`中执行同步方法能够确保创建task时的线程安全。对线程有疑惑的可以看这里[GCD 深入理解：第一部分](https://link.juejin.im/?target=http%3A%2F%2Fwww.jianshu.com%2Fp%2F5f2c5414e8b3)。

#### download

通过调用下面的方法，创建`URLSessionDownloadTask`对象。 下载包括两种方式：直接下载和断点续传。download方法通过`enum`对不同类型进行区分。`destination` 参数是一个闭包，用于在下载结束后确定将下载的文件保存在什么路径。

```
private enum Downloadable {
     case Request(NSURLRequest)
     case ResumeData(NSData)
}
private func download(downloadable: Downloadable, destination: Request.DownloadFileDestination) -> Request {
     var downloadTask: NSURLSessionDownloadTask!
		switch downloadable {
        case .Request(let request):
            dispatch_sync(queue) {
                downloadTask = self.session.downloadTaskWithRequest(request)
            }
        case .ResumeData(let resumeData):
            dispatch_sync(queue) {
                downloadTask = self.session.downloadTaskWithResumeData(resumeData)
            }
        }
}
复制代码
```

#### upload

通过调用下面的方法，创建`URLSessionUploadTask`对象。 upload分为三种：上传`NSData`，上传`NSURL`指定的文件，还有`NSInputStream`。在upload方法中使用枚举来区分不同的上传内容。 逻辑很简单，不在赘述。

```
private enum Uploadable {
     case Data(NSURLRequest, NSData)
     case File(NSURLRequest, NSURL)
     case Stream(NSURLRequest, NSInputStream)
}
private func upload(uploadable: Uploadable) -> Request {
        var uploadTask: NSURLSessionUploadTask!
        var HTTPBodyStream: NSInputStream?
        switch uploadable {
        case .Data(let request, let data):
            dispatch_sync(queue) {
                uploadTask = self.session.uploadTaskWithRequest(request, fromData: data)
            }
        case .File(let request, let fileURL):
            dispatch_sync(queue) {
                uploadTask = self.session.uploadTaskWithRequest(request, fromFile: fileURL)
            }
        case .Stream(let request, let stream):
            dispatch_sync(queue) {
                uploadTask = self.session.uploadTaskWithStreamedRequest(request)
            }
            HTTPBodyStream = stream
        }
}
复制代码
```

#### stream

通过下面的方法生成`NSURLSessionStreamTask`对象。

```
private enum Streamable {
   case Stream(String, Int)
   case NetService(NSNetService)
}
private func stream(streamable: Streamable) -> Request {
   var streamTask: NSURLSessionStreamTask!
   switch streamable {
        case .Stream(let hostName, let port):
            dispatch_sync(queue) {
                streamTask = self.session.streamTaskWithHostName(hostName, port: port)
            }
        case .NetService(let netService):
            dispatch_sync(queue) {
                streamTask = self.session.streamTaskWithNetService(netService)
            }
        }
}
复制代码
```

## 重构，各司其职

#### 存在的问题

到此总算把各种`Task`创建出来了。调用`Task`的resume方法就可以开始执行任务。从服务器返回数据后就会调用`SessionDelegate`的代理方法。当同时执行多个`Task`时，我的天，发生了什么。。。 下面就拿`NSURLSessionDataTask`举例。当多个task同时执行时，他们会交替频繁的调用`SessionDelegate`代理方法。

![img](http://ww3.sinaimg.cn/large/006tNc79gy1g4oqs2h6akj30yg07x0wq.jpg)

现在我有下面几个需求:

- 显示出每个task的执行进度
- task1得到全部数据后解析成jsonObject, task2得到全部数据后解析成string, task3得到全部数据后解析成propertyList。。。。

#### 创建`TaskDelegate`及子类，为每个task创建专有的delegate对象

要满足上面的需求，我们必须为每一个task创建一个代理对象，这个代理对象只处理这个task的代理回调。`TaskDelegate`及子类就是用于做这件事情的。



![Snip20161215_5.png](https://user-gold-cdn.xitu.io/2017/12/13/1604e8ede68d2a67?imageView2/0/w/1280/h/960/format/webp/ignore-error/1)

执行步骤是这个样子的：



1. 我们创建了一个创建`NSURLSessionDataTask`对象dataTask1;
2. 创建dataTask1对应的`DataTaskDelegate`对象dataTask1Delegate;
3. dataTask1获取到数据后调用`SessionDelegate`的 `public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)`
4. 在`SessionDelegate`的`public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)`方法中调用`DataTaskDelegate`的`public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)`方法。

#### 使用`Request`封装创建TaskDelegate的过程

为了方便创建`TaskDelegate` 对象，框架有一个`Request`类。`Request`所做的事情就是为每个Task生成对应的`TaskDelegate`对象。

```
public class Request {
    public let delegate: TaskDelegate
    public var task: NSURLSessionTask { return delegate.task }
    public let session: NSURLSession
    public var request: NSURLRequest? { return task.originalRequest }
    public var response: NSHTTPURLResponse? { return task.response as? NSHTTPURLResponse }
    public var progress: NSProgress { return delegate.progress }

    init(session: NSURLSession, task: NSURLSessionTask) {
        self.session = session
        switch task {
        case is NSURLSessionUploadTask:
            delegate = UploadTaskDelegate(task: task)
        case is NSURLSessionDataTask:
            delegate = DataTaskDelegate(task: task)
        case is NSURLSessionDownloadTask:
            delegate = DownloadTaskDelegate(task: task)
        default:
            delegate = TaskDelegate(task: task)
        }
        delegate.queue.addOperationWithBlock { self.endTime = CFAbsoluteTimeGetCurrent() }
    }
}
复制代码
```

#### 修改创建Task方法

现在我们需要修改创建Task的方法如下（以*request*为例）：

```
 public func request(URLRequest: URLRequestConvertible) -> Request {
        var dataTask: NSURLSessionDataTask!
        dispatch_sync(queue) { dataTask = self.session.dataTaskWithRequest(URLRequest.URLRequest) }
        // 创建task独有的代理对象
        let request = Request(session: session, task: dataTask)
        //下面这句话就是将生成的代理对象保存在 SessionDelegate的一个字典中。这样在回调时就可以根据task获取这个task对应的代理对象。
        delegate[request.delegate.task] = request.delegate

        if startRequestsImmediately {
            request.resume()
        }

        return request
    }
复制代码
```

设置好了之后， 在回调中根据task取出这个task对应的代理对象， 然后执行对应的方法就ok了。

## 处理响应结果

在`TaskDelegate`类中有串行队列queue:NSOperationQueue，并设置这个队列的queue.suspended = true(添加block不会执行，直到suspended=false) 你可以这个队列中添加要执行的block。在`func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)` 代理方法中如果error=nil,设置queue.suspended = false。 处理相应结果大致就是这个原理。

## 写在最后

- 为了便于理解，在学习框架时画的脑图，相对于文字，脑图结构更加清晰明了。[Alamofire框架脑图](https://www.processon.com/view/link/584fb72ae4b0160bc4dfe8d4#map)
- 虽然写了这么多但还是感觉很多点没有提到。比如说用于对请求参数编码的`ParameterEncoding`，用于对请求响应数据序列化的`ResponseSerialization`,用于https验证服务器证书的`ServerTrustPolicy`, upload操作中对`MultipartFormData`的具体实现。这些代码质量都很高，值得推荐。
- 能力有限，难免出现错误。如发现问题希望不吝指教。
- 写这么多着实占用不少时间，如果对你有帮助，那就给个喜欢吧。