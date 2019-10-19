# 初识URLSeesion
## 概述
URLSession既是一个类，也是一组用于处理基于HTTP/HTTPS的请求的类，关于URLSession的组成可以看下图：

![](../pic/url_session_diagram.png)

URLSession是负责接收和发送HTTP请求的核心类，可以通过URLSessionConfiguration来创建URLSession，URLSessionConfiguration主要有以下三种形式：

1. .default。默认配置对象使用磁盘来持久化global cache、credential、cookie
2. .ephemeral。和默认配置类似，只是所有与session相关的数据都存储在内存里。
3. .background。允许session在后台执行上载或下载任务。即使应用程序本身被系统暂停或终止，传输仍会继续。

URLSessionConfiguration还允许您配置会话属性，例如超时值，缓存策略和其他HTTP头部信息。 有关配置选项的完整列表，请参阅[文档](https://developer.apple.com/documentation/foundation/urlsessionconfiguration)。

URLSessionTask是一个表示任务对象的抽象类。一个session创建一个或多个任务来执行接收数据和下载或上载文件的实际工作。URLSessionTask有三个子类：

1. URLSessionDataTask：将此任务用于HTTP GET请求以将数据从服务器检索到内存
2. URLSessionUploadTask：使用此任务通常通过HTTP POST或PUT方法将文件从磁盘上传到Web服务器
3. URLSessionDownloadTask：使用此任务将文件从远程服务下载到临时文件位置

![](../pic/url_session_diagram_2.png)

您还可以暂停，恢复和取消任务。URLSessionDownloadTask还有暂停功能，以便于将来恢复下载。

通常，URLSession以两种方式返回数据：在任务完成时通过completion handler，不管成功或出错，或者通过调用创建session时设置的委托上的方法。

## Data Task
本文以一个在线搜歌App作为Demo来学习下URLSession的使用，现学现卖。创建一个Data Task来接收iTunes的搜索API，方便用户搜歌。

首先创建一个URLSession对象和一个URLSessionDataTask对象

```
let defaultSession = URLSession(configuration: .default)

var dataTask: URLSessionDataTask?
```

获取API的示例代码

```
func getSearchResults(searchTerm: String, completion: @escaping QueryResult) {
  // 1
  dataTask?.cancel()
  // 2
  if var urlComponents = URLComponents(string: "https://itunes.apple.com/search") {
    urlComponents.query = "media=music&entity=song&term=\(searchTerm)"
    guard let url = urlComponents.url else { return }
    // 3
    dataTask = defaultSession.dataTask(with: url) { data, response, error in
      defer { self.dataTask = nil }
      // 4
      if let error = error {
        self.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
      } else if let data = data,
        let response = response as? HTTPURLResponse,
        response.statusCode == 200 {
        self.updateSearchResults(data)
        // 5
        DispatchQueue.main.async {
          completion(self.tracks, self.errorMessage)
        }
      }
    }
    // 7
    dataTask?.resume()
  }
}
```

按照数字顺序解释：

1. 为了复用dataTask对象，我们使用一个可重用的URLSessionDataTask对象，但是如果dataTask对象如果不为空，我们必须先cancel掉它。
2. 通过urlComponents的query方法来拼接用户的搜索信息，这样可以保证用户输入的字符串被正确的转义。
3. 在创建的session中，使用查询URL初始化URLSessionDataTask，并在数据任务完成时调用完成处理程序。
4. 如果HTTP请求成功，则调用辅助方法updateSearchResults（_ :)，该方法将响应数据解析为tracks数组。
5. 切换回主线程，把tracks数组传给vc，去更新UI
6. 默认情况下，所有任务启动的时候都是suspended状态; 调用resume()启动数据任务。

实现效果如下：

![](../pic/Simulator-Screen-Shot-12-Aug-2015-11.02.34-pm.png)

