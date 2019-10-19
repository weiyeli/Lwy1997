# Json in Swift

Json是现在十分通用的一种数据格式，用于前端和后台的通信。在 Swift 里处理 JSON 其实是一件挺棘手的事情，因为 Swift 对于类型的要求非常严格，所以在解析完 JSON 之后想要从结果的 `AnyObject` 中获取某个键值是一件非常麻烦的事情。举个例子，我们使用 `JSONSerialization` 解析完一个 JSON 字符串后，得到的是 `AnyObject?`，比如毕业设计中我要拿医院的信息，通过Postman查看返回的json是这样的：

![image-20190425120734849](https://ws2.sinaimg.cn/large/006tNc79gy1g2er2cec6uj30qa0wu77t.jpg)

```swift
let hospitalDictionaryArray = try JSONSerialization.jsonObject(with: data, options: [])
```

假如我们要拿"patient"里面第一个value："lwy"，我们需要写以下的代码：

```swift
// 先转成一个字典数组
let hospitalDictionaryArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] 
// 再拿到第一个对象
let patients = hospitalDictionaryArray[0] as? [AnyObject]
let patientName = hospitalDictionaryArray[0] as? String
print(patientName)
```

在上面的代码中，最大的问题在于我们为了保证类型的正确性，做了太多的转换和判断。我们并没有利用一个有效的 JSON 容器总应该是字典或者数组这个有用的特性，而导致每次使用下标取得的值都是需要转换的 `AnyObject`。如果我们能够重载下标的话，就可以通过下标的取值配合 `Array` 和 `Dictionay` 的 Optional Binding 来简单地在 JSON 中取值。

使用SwiftyJSON简化上述代码：

```swift
let json = JSON(data: dataFromNetworking)
if let patientName = json[0]["patient"][0].string {
  print(patientName)
}
```

