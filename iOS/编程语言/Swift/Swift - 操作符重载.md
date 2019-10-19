## Swift - 操作符重载

与 Objective-C 不同，Swift 支持重载操作符这样的特性，最常见的使用方式可能就是定义一些简便的计算了。比如我们需要一个表示二维向量的数据结构：

```swift
struct Vector2D {
    var x = 0.0
    var y = 0.0
}
```

一个很简单的需求是两个 `Vector2D` 相加：

```swift
let v1 = Vector2D(x: 2.0, y: 3.0)
let v2 = Vector2D(x: 1.0, y: 4.0)
let v3 = Vector2D(x: v1.x + v2.x, y: v1.y + v2.y)
// v3 为 {x 3.0, y 7.0}
```

如果只做一次的话似乎还好，但是一般情况我们会进行很多这种操作。这样的话，我们可能更愿意定义一个 `Vector2D` 相加的操作，来让代码简化清晰。

对于两个向量相加，我们可以重载加号操作符：

```swift
func +(left: Vector2D, right: Vector2D) -> Vector2D {
    return Vector2D(x: left.x + right.x, y: left.y + right.y)
}
```

这样，上面的 `v3` 以及之后的所有表示两个向量相加的操作就全部可以用加号来表达了：

```swift
let v4 = v1 + v2
// v4 为 {x 3.0, y 7.0}
```

上面定义的加号，减号和负号都是已经存在于 Swift 中的运算符了，我们所做的只是变换它的参数进行重载。如果我们想要定义一个全新的运算符的话，要做的事情会多一件。比如[**点积**运算](http://en.wikipedia.org/wiki/Dot_product)就是一个在矢量运算中很常用的运算符，它表示两个向量对应坐标的乘积的和。根据定义，以及参考重载运算符的方法，我们选取 `+*` 来表示这个运算的话，不难写出：

```swift
func +* (left: Vector2D, right: Vector2D) -> Double {
    return left.x * right.x + left.y * right.y
}
```

但是编译器会给我们一个错误：

> Operator implementation without matching operator declaration

这是因为我们没有对这个操作符进行声明。之前可以直接重载像 `+`，`-`，`*` 这样的操作符，是因为 Swift 中已经有定义了，如果我们要新加操作符的话，需要先对其进行声明，告诉编译器这个符号其实是一个操作符。添加如下代码：

```swift
precedencegroup dianji {
    associativity : none
    higherThan: MultiplicationPrecedence
}

infix operator +* : dianji
```

#### `infix`

> 表示要定义的是一个中位操作符，即前后都是输入；其他的修饰子还包括 `prefix` 和 `postfix`，不再赘述；

#### `associativity`

> 定义了结合律，即如果多个同类的操作符顺序出现的计算顺序。比如常见的加法和减法都是 `left`，就是说多个加法同时出现时按照从左往右的顺序计算 (因为加法满足交换律，所以这个顺序无所谓，但是减法的话计算顺序就很重要了)。点乘的结果是一个 `Double`，不再会和其他点乘结合使用，所以这里写成 `none`；

#### `higherthan`

> 指定运算符的优先级高于乘除

这里给出常用类型对应的group

- infix operator ||  : `LogicalDisjunctionPrecedence` 
- infix operator &&  : `LogicalConjunctionPrecedence` 
- infix operator <   : `ComparisonPrecedence` 
- infix operator <=  : `ComparisonPrecedence` 
- infix operator >   : `ComparisonPrecedence` 
- infix operator >=  : `ComparisonPrecedence` 
- infix operator ==  : `ComparisonPrecedence` 
- infix operator !=  : `ComparisonPrecedence` 
- infix operator === : `ComparisonPrecedence` 
- infix operator !== : `ComparisonPrecedence` 
- infix operator ~=  : `ComparisonPrecedence` 
- infix operator ??  : `NilCoalescingPrecedence` 
- infix operator +   : `AdditionPrecedence` 
- infix operator -   : `AdditionPrecedence` 
- infix operator &+  : `AdditionPrecedence` 
- infix operator &-  : `AdditionPrecedence` 
- infix operator |   : `AdditionPrecedence` 
- infix operator ^   : `AdditionPrecedence` 
- infix operator *   : `MultiplicationPrecedence` 
- infix operator /   : `MultiplicationPrecedence` 
- infix operator %   : `MultiplicationPrecedence` 
- infix operator &*  : `MultiplicationPrecedence` 
- infix operator &   : `MultiplicationPrecedence` 
- infix operator <<  : `BitwiseShiftPrecedence` 
- infix operator >>  : `BitwiseShiftPrecedence` 
- infix operator ..< : `RangeFormationPrecedence` 
- infix operator ... : `RangeFormationPrecedence` 
- infix operator *=  : `AssignmentPrecedence` 
- infix operator /=  : `AssignmentPrecedence` 
- infix operator %=  : `AssignmentPrecedence` 
- infix operator +=  : `AssignmentPrecedence` 
- infix operator -=  : `AssignmentPrecedence` 
- infix operator <<= : `AssignmentPrecedence` 
- infix operator >>= : `AssignmentPrecedence` 
- infix operator &=  : `AssignmentPrecedence` 
- infix operator ^=  : `AssignmentPrecedence` 
- infix operator |=  : `AssignmentPrecedence`

