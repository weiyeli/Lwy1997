# Key-value coding in Cocoa
## 什么是KVC
KVC是使用字符串标识符间接访问对象的属性和关系的机制。它支持或与Cocoa编程特有的几种机制和技术相关，其中包括Core Data，scriptability，绑定技术以及声明属性的语言特性。（scriptability和绑定技术特定于OS X系统）。您还可以使用KVC来简化程序代码。

> Key-value coding is a mechanism for indirectly accessing an object’s attributes and relationships using string identifiers. It underpins or is related to several mechanisms and technologies special to Cocoa programming, among them Core Data, application scriptability, the bindings technology, and the language feature of declared properties. (Scriptability and bindings are specific to Cocoa on OS X.) You can also use key-value coding to simplify your program code.

## 对象属性和KVC
KVC的核心在于“属性”（property）这个一般性的概念。属性是对象封装的基本单位，它可以是以下两种常规类型：

1. 对象本身的特征(attribute)，例如：名称、标题、color等等
2. 与其他对象的关系（引用？指针？），可以是一对一，也可以是一对多

KVC通过键定位对象的属性，该键是字符串标识符。 密钥通常对应于由对象定义的访问器方法或实例变量的名称。 密钥必须符合某些约定：它必须是ASCII编码的，以小写字母开头，并且没有空格。 键路径是一串点分隔键，用于指定要遍历的对象属性序列。 序列中第一个键的属性是相对于特定对象（下图中的employee1），并且每个后续键相对于前一个属性的值进行计算。

## 如何使一个类符合KVC
NSKeyValueCoding这个非正式协议使得KVC变成可能。它有两个方法：

+ valueForKey:
+ setValue:forKey:

这两个方法非常的重要。因为他们在通过给定的key值来获取和设置属性的值。NSObject提供了这些方法的默认实现，如果一个类符合KVC，它可以依赖于这个实现。

如何使一个类符合KVC取决于这个属性是一个attribute还是对象一对一关系还是对象一对多的关系。

对于attribute和一对一关系，类必须实现对于属性和一对一关系，类必须按给定的优先顺序实现以下至少一项（键指的是属性的名称）：

1. 该类必须有一个名为key的属性
2. 它实现了名为key的访问器方法，如果属性是可变的，则实现setKey：。（如果属性是布尔属性，则getter访问器方法的格式为isKey）
3. 它声明了form key或_key的实例变量

为对多关系实施KVC合规性是一个更复杂的过程。参考官方文档：[About Key-Value Coding](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html#//apple_ref/doc/uid/10000107i)