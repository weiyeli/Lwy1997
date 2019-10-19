# 什么是objc中的元类

## 在Runtime中创建一个类

以下代码在运行时创建NSError的新子类，并向其添加一个方法：

```objective-c
Class newClass =
    objc_allocateClassPair([NSError class], "RuntimeErrorSubclass", 0);
class_addMethod(newClass, @selector(report), (IMP)ReportFunction, "v@:");
objc_registerClassPair(newClass);
```

添加的方法使用名为ReportFunction的函数作为其实现，其定义如下：

```objective-c
void ReportFunction(id self, SEL _cmd)
{
    NSLog(@"This object is %p.", self);
    NSLog(@"Class is %@, and super is %@.", [self class], [self superclass]);
    
    Class currentClass = [self class];
    for (int i = 1; i < 5; i++)
    {
        NSLog(@"Following the isa pointer %d times gives %p", i, currentClass);
        currentClass = object_getClass(currentClass);
    }

    NSLog(@"NSObject's class is %p", [NSObject class]);
    NSLog(@"NSObject's meta class is %p", object_getClass([NSObject class]));
}
```

从表面上看，这一切都非常简单。 在运行时创建类只需三个简单的步骤：

1. 为“class pair”分配存储空间（使用objc_allocateClassPair方法）。
2. 根据需要向类中添加方法和ivars（我使用class_addMethod添加了一个方法）。
3. 注册该类以便可以使用它（使用objc_registerClassPair）。

然而，当前的问题是：什么是“class pair”？ 函数objc_allocateClassPair只返回一个值：class。 那pair的另一半在哪里？

我敢肯定你已经猜到了这一对的另一半是meta-class但是为了解释这是什么以及你为什么需要它，我将给出一些关于对象的背景知识 和Objective-C中的类。

## 什么是object?

每个对象都有一个类。 这是一个基本的面向对象概念，但在Objective-C中，它也是数据的基本部分。 任何具有指向正确位置的类的指针的数据结构都可以视为对象。

在Objective-C中，对象的类由其isa指针确定。 isa指针指向对象的Class。

实际上，Objective-C中对象的基本定义如下所示：

```objc
typedef struct objc_object {
    Class isa;
} *id;
```

这就是说：任何以指向类结构的指针开头的结构都可以被视为objc_object。

Objective-C中对象最重要的特性是你可以向它们发送消息：

```objc
[@"stringValue"
    writeToFile:@"/file.txt" atomically:YES encoding:NSUTF8StringEncoding error:NULL];
```

这是有效的，因为当您向Objective-C对象（如此处的NSCFString）发送消息时，运行时遵循对象的isa指针来获取对象的Class（在本例中为NSCFString类）。 然后，类包含一个适用于该类的所有对象的方法列表和一个指向超类的指针，以查找继承的方法。 运行时查看类和超类上的方法列表，找到与消息选择器匹配的方法（在上面的例子中，writeToFile：atomically：encoding：NSString上的错误）。 然后运行时调用该方法的函数（IMP）。

重要的是，Class定义了可以发送给对象的消息。

##什么是元类？

现在，正如您可能已经知道的那样，Objective-C中的一个类也是一个对象。 这意味着您可以向类发送消息。

```objective-c
NSStringEncoding defaultStringEncoding = [NSString defaultStringEncoding];
```

在这种情况下，defaultStringEncoding被发送到NSString类。

这是有效的，因为Objective-C中的每个类都是一个对象本身。 这意味着类结构必须以isa指针开头，以便它与上面显示的objc_object结构二进制兼容，并且结构中的下一个字段必须是指向超类的指针（或基类的nil）。

根据运行的运行时版本，可以通过几种不同的方式定义类，但是，它们都以isa字段开头，后跟超类字段。

```objective-c
typedef struct objc_class *Class;
struct objc_class {
    Class isa;
    Class super_class;
    /* followed by runtime specific details... */
};
```

但是，为了让我们在Class上调用一个方法，Class的isa指针本身必须指向一个Class结构，并且该Class结构必须包含我们可以在Class上调用的Methods列表。

这导致了元类的定义：元类是Class对象的类。

简单的说：

向对象发送消息时，将在对象类的方法列表中查找该消息。
当您向类发送消息时，将在类'meta-class的方法列表中查找该消息。
元类是必不可少的，因为它存储了类的类方法。 每个Class必须有一个唯一的元类，因为每个Class都有一个可能唯一的类方法列表。

## 元类的类是什么？

元类与之前的类一样，也是一个对象。 这意味着您也可以在其上调用方法。 当然，这意味着它也必须有一个类。

所有元类都使用基类的元类（其继承层次结构中顶级类的元类）作为它们的类。 这意味着对于所有来自NSObject（大多数类）的类，元类都将NSObject元类作为其类。

遵循所有元类使用基类的元类作为其类的规则，任何基础元类都将是它自己的类（它们的isa指针指向它们自己）。 这意味着NSObject元类上的isa指针指向它自己（它是它自己的一个实例）。

## 类和元类的继承

与Class使用super_class指针指向超类的方式相同，元类使用自己的super_class指针指向Class'super_class的元类。

作为进一步的怪癖，基类的元类将其super_class设置为基类本身。

此继承层次结构的结果是层次结构中的所有实例，类和元类都继承自层次结构的基类。

对于NSObject层次结构中的所有实例，类和元类，这意味着所有NSObject实例方法都是有效的。 对于类和元类，所有NSObject类方法也是有效的。

下图生动形象的解释了这一观点：

![image-20190829183313460](http://pwzyjov6e.bkt.clouddn.com/blog/2019-08-29-115551.jpg)

## 实验证明

为了确认所有这些，让我们看一下我在本文开头给出的ReportFunction的输出。 此函数的目的是遵循isa指针并记录它找到的内容。

要运行ReportFunction，我们需要创建动态创建的类的实例并在其上调用report方法。

```objective-c
id instanceOfNewClass =
    [[newClass alloc] initWithDomain:@"someDomain" code:0 userInfo:nil];
[instanceOfNewClass performSelector:@selector(report)];
[instanceOfNewClass release];
```

由于没有报告方法的声明，我使用performSelector调用它：因此编译器不会发出警告。

ReportFunction现在将遍历isa指针并告诉我们哪些对象被用作元类的类，元类和类。

下面是程序的输出：

```objective-c
This object is 0x10010c810.
Class is RuntimeErrorSubclass, and super is NSError.
Following the isa pointer 1 times gives 0x10010c600
Following the isa pointer 2 times gives 0x10010c630
Following the isa pointer 3 times gives 0x7fff71038480
Following the isa pointer 4 times gives 0x7fff71038480
NSObject's class is 0x7fff710384a8
NSObject's meta class is 0x7fff71038480
```

通过重复查看isa指针的值我们发现：

+ 这个对象的地址是`0x10010c810`.
+ 这个对象的类对象的地址是`0x10010c600`.
+ 类的元类的地址是`0x10010c630`.
+ 元类的类对象（也就是NSObject的元类）的地址是`0x7fff71038480`.
+ NSObject的元类的类对象是它本身

## 总结

元类是类对象的类。 每个类都有自己独特的元类（因为每个类都有自己独特的方法列表）。 这意味着所有Class对象本身并不都是同一个类。

元类将始终确保Class对象具有层次结构中基类的所有实例和类方法，以及中间的所有类方法。 对于来自NSObject的类，这意味着所有NSObject实例和协议方法都是为所有Class（和meta-class）对象定义的。

所有元类本身都使用基类的元类（NSObject元类用于构建NSObject的整个继承关系，本身没有任何意义）作为它们的类，包括基类级元类，它是运行时中唯一的自定义类。

## 参考资料

http://www.cocoawithlove.com/2010/01/what-is-meta-class-in-objective-c.html