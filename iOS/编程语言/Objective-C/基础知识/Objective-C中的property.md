## 概括

![img](http://pwzyjov6e.bkt.clouddn.com/blog/2019-08-30-022920.png)

以下：「attribute(s)」，「特性」是指同一事物(都指`@property`后面括号内的单词)。

用Objective-C做过开发的朋友都知道，类里面的属性(可以近似地理解为类的变量)是用`@property`关键字定义的，然后`@property`后面的括号，会写上若干「特性(attribute)」，后面跟数据类型、属性名称。如：

```objective-c
@property (copy, nonatomic) NSString *name;
```

## 为什么要有@property？

要搞清楚「特性」，先搞清楚`@property`，为什么要有`@property`？

在2006年的WWDC大会上，苹果发布了Objective-C 2.0，其中就包括**Properties**这个新的语法，把原来的实例变量定义成**Properties(属性)**。这个变化，和以前相比，有什么变化呢？

### Objective-C2.0之前:

没有Properties之前，定义实例变量，是这样的：

```objective-c
@interface Person : NSObject {
@public
    NSString *name;
@private
    int age;
}
@end
```

然后在.h文件，声明setter和getter方法(setter和getter统称「accessors/存取器/访问器」)，再在.m文件实现setter和getter，这样就可以封装起来，供其他类访问(取值、赋值)了。

然而，即使不使用setter和getter，其他类也可以通过`->`来直接访问，如：

```objective-c
personA->name = @"123";
NSLog(@"personA->name:%@", personA->name);
```

**为什么要getter和setter**

那么，为什么还要如此麻烦地声明和实现setter和getter呢？主要基于三个原因(参考:[Please explain Getter and Setters in Objective C](https://link.jianshu.com/?t=https://stackoverflow.com/questions/10425827/please-explain-getter-and-setters-in-objective-c))：

- 可以在getter和setter中添加额外的代码，实现特定的目的。比如赋值前(set)需要实现一些特定的内部计算，或者更新状态，缓存数据等等。
- KVC和KVO都是基于此实现的。
- 在非ARC时代，可以在在getter和setter中进行内存管理。

因此，写getter和setter，可算是Objective-C中「约定俗成」的做法了。（Swift有类似的「Computed Properties/计算属性」）

所以，在没有**Objective-C2.0**的`@property`之前，我们几乎需要为所有的实例变量，手动写getter和setter——听听就觉得很可怕，对不对？

### Objective-C2.0之后:

庆幸的是，程序员都喜欢「偷懒」，所以就有了2006年Objective-C2.0中的新语法：**Properties**。

**它帮我们自动生成getter和setter**(声明方法，并实现方法。当然，这部分代码并不会出现在你的项目中，是隐藏起来的)。

不过，`@property`的写法，也经过数次变迁(新旧写法混在一起，就更让人困惑了)：

- 最开始，需要作3件事情：
  - 在.h文件，我们用`@property`声明了属性——这只是帮我们在声明了getter和setter；
  - 还需要手动声明实例变量(和Objective-C2.0之前一样)
  - 然后在.m文件，还要用`@synthesize`自动合成getter和setter的实现。
- 后来，不需要为属性声明实例变量了，`@synthesize`会默认自动生成一个「下划线+属性名」的实例变量。比如`@property (copy, nonatomic) NSString *name;`之后，就可以直接使用`_name`这个变量了。
- 再后来(Xcode4.5开始)，`@synthesize`也不需要了。一个`@property`搞定。

所以，现在我们写`@property`声明属性，其实是做了三件事

- .h: 声明了getter和setter方法；
- .h: 声明了实例变量(默认:下划线+属性名)；
- .m: 实现了getter和setter方法。

这就是`@property`为我们所做的事情。

知道它为我们做了什么，自然也就能回答：「为什么要有`@property`？」这个问题了。

## @property后面的括号又是怎么回事？

```
@property (copy, nonatomic) NSString *name;
```

这种写法，大家肯定都写过，不过，后面跟着的这个括号又是什么玩意儿呢？

官方把括号里面的东西，叫做「attribute/特性」。

先试一下，把括号里的两个单词都删掉，你会发现，还能正常工作。而事实上，以下两种写法，是等价的：

```objective-c
@property () NSString *name;// 或者@property NSString *name;
@property (atomic, strong, readwrite) NSString *name;
```

因为attribute主要有三种类型(实际上最多可以写6个特性，后面详述)，每种类型都有默认值。如果什么都不写，系统就会取用默认值（看看，苹果良苦用心，偷偷帮我们做了那么多事情）。

如上所述，attributes有三种类型：

### 1.Atomicity(原子性)

比较简单的一句话理解就是：是否给setter和getter加锁(是否保证setter或者getter的每次访问是完整性的)。

原子性，有atomic和nonatomic两个值可选。默认值是atomic(也就是不写的话，默认是atomic)。

- **atomic**(默认值)

使用atomic，在一定程度上可以保证线程安全，「atomic的作用只是给getter和setter加了个锁」。也就是说，有线程在访问setter，其他线程只能等待完成后才能访问。

它能保证：即使多个线程「同时」访问这个变量，atomic会让你得到一个有意义的值(valid value)。但是不能保证你获得的是哪个值（有可能是被其他线程修改过的值，也有可能是没有修改过的值）。

- **nonatomic**

而用nonatomic，则不保证你获得的是有效值，如果像上面所述，读、写两个线程同时访问变量，有可能会给出一个无意义的垃圾值。

这样对比，atomic就显得比较鸡肋了，因为它并不能完全保证程序层面的线程安全，又有额外的性能耗费(要对getter和setter进行加锁操作，我验证过，在某个小项目中将所有的nonatomic删除，内存占用平均升高1M左右)。

所以，你会见到，几乎所有情况，我们都用nonatomic。

### 2.Access(存取特性)

存取特性有**readwrite**(默认值)和**readonly**。

这个从名字看就很容易理解，定义了这个属性是「只读」，还是「读写」皆可。

如果是**readwrite**，就是告诉编译器，同时生成getter和setter。如果是**readonly**，只生成getter。

### 3.Storage(内存管理特性)(管理对象的生命周期的)

最常用到**strong**、**weak**、**assign**、**copy**4个attributes。（还有一个**retain**，不怎么用了）

- **strong** (默认值)

ARC新增的特性。

表明你需要引用(持有)这个对象(reference to the object)，负责保持这个对象的生命周期。

**注意，基本数据类型(非对象类型,如int, float, BOOL)，默认值并不是strong，strong只能用于对象类型。**

- **weak**

ARC新增的特性。

也会给你一个引用(reference/pointer)，指向对象。但是不会主张所有权(claim ownership)。也不会增加retain count。

如果对象A被销毁，所有指向对象A的弱引用(weak reference)(用weak修饰的属性)，都会自动设置为nil。

在delegate patterns中常用weak解决strong reference cycles(以前叫retain cycles)问题。

- **copy**

为了说明**copy**，我们先举个栗子：

我在某个类(class1)中声明两个字符串属性，一个用copy，一个不用：

```objective-c
@property (copy, nonatomic) NSString *nameCopy;

// 或者可以省略strong, 编译器默认取用strong
@property (strong, nonatomic) NSString *nameNonCopy;
```

在另一个类中，用一个NSMutableString对这两个属性赋值并打印，再修改这个NSMutableString，再打印，看看会发生什么：

```objective-c
Class1 *testClass1 = [[Class1 alloc] init];

NSMutableString *nameString = [NSMutableString  stringWithFormat:@"Antony"];

// 用赋值NSMutableString给NSString赋值
testClass1.nameCopy = nameString;
testClass1.nameNonCopy = nameString;
   
NSLog(@"修改nameString前, nameCopy: %@; nameNonCopy: %@", testClass1.nameCopy, testClass1.nameNonCopy);

[nameString appendString:@".Wong"];
   
NSLog(@"修改nameString后, nameCopy: %@; nameNonCopy: %@", testClass1.nameCopy, testClass1.nameNonCopy);
```

打印结果是：

```objective-c
修改nameString前, nameCopy: Antony; nameNonCopy: Antony
修改nameString后, nameCopy: Antony; nameNonCopy: Antony.Wong
```

我只是修改了`nameString`，为什么`testClass1.nameNonCopy`的值没改，它也跟着变了？

因为`strong`特性，对对象进行引用计数加1，只是对指向对象的指针进行引用计数加1，这时候，`nameString`和`testClass1.nameNonCopy`指向的其实是同一个对象(同一块内存)，`nameString`修改了值，自然影响到`testClass1.nameNonCopy`。

而`copy`这个特性，会在赋值前，复制一个对象，`testClass1.nameCopy`指向了一个新对象，这时候`nameString`怎么修改，也不关它啥事了。应用`copy`特性，系统应该是在setter中进行了如下操作：

```objective-c
- (void)setNameCopy:(NSString *)nameCopy {
    _nameCopy = [nameCopy copy];
}
```

大家了解`copy`的作用了吧，是为了防止属性被意外修改的。那什么时候要用到`copy`呢？

所有有mutable(可变)版本的属性类型，如NSString, NSArray, NSDictionary等等——他们都有可变的版本类型:NSMutableString, NSMutableArray, NSMutableDictionary。这些类型在属性赋值时，右边的值有可能是它们的可变版本。

**扩展**

如果不用`copy`，而是在赋值前，调用copy方法，可以达到同样的目的：

```objc
// 这时候也可以确保nameNonCopy不会被意外修改
testClass1.nameNonCopy = [nameString copy];
```

**如果用copy修饰NSMutableString、NSMutableArray会发生什么?**

如果用`copy`修饰NSMutableString，在赋值的时候会报如下警告：

```objective-c
Incompatible pointer types assigning to 'NSMutableString *' from 'NSString *'
```

而如果用`copy`修饰NSMutableArray，则在调用addObject:时直接crash：

```objective-c
reason: '-[__NSArray0 addObject:]: unrecognized selector sent to instance 0x1700045c0'
```

如果理解了「`copy`特性，就是在setter中，进行了copy操作」，就很容易知道以上报错的原因：属性在赋值时，调用setter，已经将原本mutable的对象，copy成了immutable的对象(NSMutableString变成NSString，NSMutableArray变成NSArray)。

- **assign**

是非ARC时代的特性，

它的作用和**weak**类似，唯一区别是：如果对象A被销毁，所有指向这个对象A的**assign**属性并不会自动设置为nil。这时候这些属性就变成野指针，再访问这些属性，程序就会crash。

因此，在ARC下，**assign**就变成用于修饰基本数据类型(Primitive Type)，也就是非对象/非指针数据类型，如：int、bool、float等。

**注意，在非ARC时代，还没有strong的时候。assign是默认值。ARC下，默认值变成strong了。这个要注意一下，否则会引起困扰。**

- **retain**

**retain**是以前非ARC时代的特性，在ARC下并不常用。

它是**strong**的同义词，两者功能一致。不知道为什么还保留着，这对新手也会造成一定困扰。

所以，总结一下。

- 几乎所有情况，都写上**nonatomic**；
- 对外「只读」的，写上**readonly**
- 一般的对象属性，写上**strong**（用**retain**也可以，比较少用）
- 需要解决strong reference cycles问题的对象属性，strong改为**weak**
- 有mutable(可变)版本的对象属性，strong改为**copy**
- 基本数据类型(int, float, BOOL)(非对象属性)，用**assign**

### 4.扩展

其实，除了上面3种经常用到的特性类型，还有2种不太见到。

- **getter=** 和 **setter=**

按字面意思，很容易理解，就是重命名getter和setter方法。

[Transitioning to ARC Release Notes](https://link.jianshu.com/?t=https://developer.apple.com/library/content/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)中写道：

> You cannot give an accessor a name that begins with new. This in turn means that you can’t, for example, declare a property whose name begins with new unless you specify a different getter

存取方法不能以`new`开头，如果你要以`new`开头命名一个属性：`@property (copy, nonatomic) NSString *newName;`于是会默认生成一个new开头的getter方法：

这时候就会报错：`Property follows Cocoa naming convention for returning 'owned' objects`。

解决办法，就是用**getter=**重命名getter方法：

```objective-c
@property (copy, nonatomic, getter=theNewName) NSString *newName;
```

- Nullability
  - **nullable**：对象「可为空」
  - **nonnull**：对象「不可为空」
  - **null_unspecified**：「未指定」
  - **null_resettable**：稍有点难理解，就是调用setter去reset属性时，可以传入nil，但是getter返回值，不为空。UIView下面的tintColor，就是null_resettable。这样就保证，即使赋值为nil，也会返回一个非空的值。

为了更好地和Swift混编(配合Swift的optional类型)，在Xcode 6.3，Objective-C新增了一个语言特性，nullability。具体就是以上4个新特性。

如果设置为`null_resettable`，则要重写setter或getter其中之一，自己做判断，确保真正返回的值不是nil。否则报警告：`Synthesized setter 'setName:' for null_resettable property 'name' does not handle nil`

Nullability的写法如下：

```objc
@property (copy, nullable) NSString *name;
@property (copy, readonly, nonnull) NSArray *allItems;

// 也可以将nullable, nonnull, null_unspecified, null_resettable三个修饰语前面加双下划线，用于修饰指针、参数、返回值等(null_resettable只能在属性括号中使用)
@property (copy, readonly) NSArray * __nonnull allItems;
```

Nullability的默认值：`null_unspecified`——未指定。如果某个属性填写了Nullability特性(比如写了nonnull)，没有填写Nullability的属性，会出现如下警告：

```
Pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified)
```

但是如果每个属性都一一写上，稍嫌麻烦。而因为大多数属性是`nonnull`的，所以苹果定义了两个宏，`NS_ASSUME_NONNULL_BEGIN`和`NS_ASSUME_NONNULL_END`(两个宏之间，叫做**Audited Regions**)。

将所有属性包在这两个宏中，就无需写**nonnull**修饰语了，只需要在「可为空」的属性里，写上**nullable**即可：

```objective-c
NS_ASSUME_NONNULL_BEGIN
@interface AAPLList : NSObject <NSCoding, NSCopying>
// 只需要为「不可为空」的参数、属性、返回值加上修饰语nullable即可
- (nullable AAPLListItem *)itemWithName:(NSString *)name;
- (NSInteger)indexOfItem:(AAPLListItem *)item;

@property (copy, nullable) NSString *name;
@property (copy, readonly) NSArray *allItems;
// ...
@end
NS_ASSUME_NONNULL_END
```

所以！综上所述，attribute最多可以写6个进去：1.原子性、2.存取特性、3.内存管理特性、4.重命名getter、5.重命名setter，6.nullability：

```objective-c
@property (nonatomic, readonly, copy, getter=theNewTitle, setter=setTheNewTitle:, nullable) NSString *newTitle;
```

不过，应该没有谁闲得蛋疼会这样写的。

最短的写法就是什么都不写，连括号都可以不要：

```objective-c
@property BOOL isOpen;
```

GG

## 参考资料

https://www.jianshu.com/p/035977d1ba89