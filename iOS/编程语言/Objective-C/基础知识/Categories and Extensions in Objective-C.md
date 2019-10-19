# 前言

类别是Objective-C语言的一种特性，允许程序员向现有类添加新方法，就像C#的extension一样。 但是，不要将C#中的extension和Objective-C的extension混淆。 Objective-C的extension是categories的特例，extension必须定义在.m文件中。

extension和categories功能强大，具有许多潜在用途。 主要有以下三种：

1. 首先，categories可以将类的接口和实现分成几个文件，这为大型项目提供了模块化的可能。
2.  其次，categories允许程序员修复现有类（例如，NSString）中的错误，而无需对其进行子类化。
3.  第三，实现了类似于C#和其他Simula类语言中的protected和private方法。

# Categories

categories是同一个类的一组相关方法，categories中定义的所有方法都可以通过类获得，就好像它们是在.h文件中定义的一样。 举个例子，参考Person类。 如果这是一个大型项目，Person可能有许多方法，从基本行为到与其他人的交互到身份检查。 API可能要求通过单个类提供所有这些方法，但如果每个组都存储在单独的文件中，则开发人员可以更轻松地进行维护。 此外，categories消除了每次更改单个方法时重新编译整个类的需要，这可以节省大型项目的时间。

我们来看看如何使用categories来实现这一目标。 我们从一个普通的类接口和相应的实现开始：

```objective-c
// Person.h
@interface Person : NSObject
 
@property (readonly) NSMutableArray* friends;
@property (copy) NSString* name;
 
- (void)sayHello;
- (void)sayGoodbye;
 
@end
 
 
// Person.m
#import "Person.h"
 
@implementation Person
 
@synthesize name = _name;
@synthesize friends = _friends;
 
-(id)init{
    self = [super init];
    if(self){
        _friends = [[NSMutableArray alloc] init];
    }
 
    return self;
}
 
- (void)sayHello {
    NSLog(@"Hello, says %@.", _name);
}
 
- (void)sayGoodbye {
    NSLog(@"Goodbye, says %@.", _name);
}
@end
```

这里没什么新东西 - 只有一个具有两个属性的Person类（我们的categories将使用friends属性）和两个方法。 接下来，我们将使用一个categories来存储一些与其他Person实例交互的方法。 创建一个新文件，但不使用类，而是使用Objective-C Category模板。

![Figure 28 Creating the PersonRelations class](http://pwzyjov6e.bkt.clouddn.com/blog/2019-09-16-022054.jpg)

正如所料，这将创建两个文件：用于保存接口的头文件和实现文件。 但是，这些看起来与我们一直在使用的略有不同。 首先，我们来看看界面：

```objective-c
// Person+Relations.h
#import <Foundation/Foundation.h>
#import "Person.h"
 
@interface Person (Relations)
 
- (void)addFriend:(Person *)aFriend;
- (void)removeFriend:(Person *)aFriend;
- (void)sayHelloToFriends;
 
@end
```

我们在扩展的类名后面的括号中包含了categories名称，而不是正常的@interface声明。 categories名称可以是任何名称，只要它不与同一个类的其他categories冲突即可。 categories的文件名应该是类名，后跟加号，后跟categories的名称（例如，Person + Relations.h）。

所以，这定义了我们categories的接口。 我们在这里添加的任何方法都将在运行时添加到原始的Person类中。 例如`addFriend`、`removeFriend`和`sayHelloToFriends`方法都在Person.h中定义，但我们可以保持我们的功能封装和可维护。 另请注意，您必须导入原始类Person.h的标头。 categories实现遵循类似的模式：

```objective-c
// Person+Relations.m
#import "Person+Relations.h"
 
@implementation Person (Relations)
 
- (void)addFriend:(Person *)aFriend {
    [[self friends] addObject:aFriend];
}
 
- (void)removeFriend:(Person *)aFriend {
    [[self friends] removeObject:aFriend];
}
 
- (void)sayHelloToFriends {
    for (Person *friend in [self friends]) {
        NSLog(@"Hello there, %@!", [friend name]);
    }
}
 
@end
```

上述代码实现了Person + Relations.h中的所有方法。 就像categories的接口文件一样，categories名称出现在类名后面的括号中。 实现中的categories名称应与接口文件中的categories名称匹配。

另请注意，无法在categories中定义其他属性或实例变量。 categories必须使用存储在主类中的数据（在此实例中为Friend）。

也可以通过简单地重新定义Person + Relations.m中的方法来覆盖Person.m中包含的实现。 这可以用来修补现有的类; 但是，如果您有问题的替代解决方案，则不建议使用，因为无法覆盖categories中定义的实现。 也就是说，与类层次结构不同，categories是一个扁平的组织结构 - 如果在两个单独的categories中实现相同的方法，则运行时无法确定使用哪个categories。

要使用categories，您必须进行的唯一更改是导入categories的头文件。 正如您在下面的示例中所看到的，Person类可以访问Person.h中定义的方法以及Person + Relations.h类别中定义的方法：

```objective-c
// main.m
#import <Foundation/Foundation.h>
#import "Person.h"
#import "Person+Relations.h"
 
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *joe = [[Person alloc] init];
        joe.name = @"Joe";
        Person *bill = [[Person alloc] init];
        bill.name = @"Bill";
        Person *mary = [[Person alloc] init];
        mary.name = @"Mary";
 
        [joe sayHello];
        [joe addFriend:bill];
        [joe addFriend:mary];
        [joe sayHelloToFriends];
    }
    return 0;
}
```

这就是在Objective-C中创建categories的全部内容。

# Protected Methods

重申一下，所有Objective-C方法都是public的，没有语法可以将它们标记为private或protected。Objective-C程序可以将categories与.h/.m的范式结合起来，而不是使用所谓真正的protected方法，以实现相同的结果。

这个想法很简单：将“protected”方法声明为单独头文件中的categories。 这使得子类能够“选择加入”protected的方法，而不相关的类像往常一样使用“public”头文件。 例如，采用标准的Ship接口：

```objective-c
// Ship.h
#import <Foundation/Foundation.h>
 
@interface Ship : NSObject
 
- (void)shoot;
 
@end
```

正如我们多次看到的那样，这定义了一种名为shoot的公共方法。 要声明受保护的方法，我们需要在专用头文件中创建Ship categories：

```objective-c
// Ship_Protected.h
#import <Foundation/Foundation.h>
 
@interface Ship(Protected)
 
- (void)prepareToShoot;
 
@end
```

任何需要访问受保护方法的类（即父类和任何子类）都可以简单地导入Ship_Protected.h。 例如，Ship实现应该为受保护的方法定义默认实现：

```objective-c
// Ship.m
#import "Ship.h"
#import "Ship_Protected.h"
 
@implementation Ship {
    BOOL _gunIsReady;
}
 
- (void)shoot {
    if (!_gunIsReady) {
        [self prepareToShoot];
        _gunIsReady = YES;
    }
    NSLog(@"Firing!");
}
 
- (void)prepareToShoot {
    // Execute some private functionality.
    NSLog(@"Preparing the main weapon...");
}
@end
```

请注意，如果我们没有导入Ship_Protected.h，则此prepareToShoot实现将是一个私有方法。 如果没有导入Ship_Protected.h，子类将无法访问此方法。 让我们将Ship子类化，看看它是如何工作的。 我们称之为ResearchShip：

```objective-c
// ResearchShip.h
#import "Ship.h"
 
@interface ResearchShip : Ship
 
- (void)extendTelescope;
 
@end
```

这是一个普通的子类接口 - 它不应该导入Ship_Protected.h，因为这会使受保护的方法对任何导入ResearchShip.h的人都可用，这正是我们试图避免的。 最后，子类的实现导入受保护的方法，并（可选）覆盖它们：

```objective-c
// ResearchShip.m
#import "ResearchShip.h"
#import "Ship_Protected.h"
 
@implementation ResearchShip
 
- (void)extendTelescope {
    NSLog(@"Extending the telescope");
}
 
// Override protected method
- (void)prepareToShoot {
    NSLog(@"Oh shoot! We need to find some weapons!");
}
 
@end
```

要在Ship_Protected.h中强制执行方法的受保护状态，不允许其他类导入它。 他们只会导入超类和子类的普通“公共”接口：

```objective-c
// main.m
#import <Foundation/Foundation.h>
#import "Ship.h"
#import "ResearchShip.h"
 
int main(int argc, const char * argv[]) {
    @autoreleasepool {
 
        Ship *genericShip = [[Ship alloc] init];
        [genericShip shoot];
 
        Ship *discoveryOne = [[ResearchShip alloc] init];
        [discoveryOne shoot];
 
    }
    return 0;
}
```

由于main.m，Ship.h和ResearchShip.h都没有导入受保护的方法，因此该代码无法访问它们。 尝试添加[discoveryOne prepareToShoot]方法 - 它会抛出编译器错误，因为找不到prepareToShoot声明。

总而言之，可以通过将受保护的方法放在专用的头文件中并将该头文件导入需要访问受保护方法的实现文件来模拟受保护的方法。 没有其他文件应该导入受保护的header。

虽然此处介绍的工作流程是一个完全有效的组织工具，但请记住，Objective-C从未打算支持受保护的方法。 可以将其视为构建Objective-C方法的替代方法，而不是直接替换C# / Simula样式的受保护方法。 寻找构建类的另一种方法通常更好，而不是强迫Objective-C代码像C#程序一样运行。

# 说明

category的一个最大问题是您无法可靠地覆盖同一类的categories中定义的方法。 例如，如果您在Person（Relations）中定义了一个`addFriend：`方法，后来决定通过Person（Security）类别更改`addFriend：` 实现，那么运行时无法知道它应该使用哪种方法，因为categories 根据定义是一个扁平的组织结构。 对于这些情况，您需要恢复到传统的子类化范例。

此外，重要的是要注意categories不能添加实例变量。 这意味着您无法在categories中声明新属性，因为它们只能在主实现中合成。 此外，尽管categories在技术上确实可以访问其类的实例变量，但最好通过其公共接口访问它们，以保护categories免受主实现文件中的潜在更改。

# Extensions

**Extensions**（也称为**class extensions**）是一种特殊类型的类，它要求在关联类的主实现块中定义它们的方法，而不是在category中定义的实现。 这可以用于覆盖公开声明的属性属性。 例如，有时可以方便地将只读属性更改为类实现中的读写属性。 考虑Ship类的普通接口：

```objective-c
// Ship.h
#import <Foundation/Foundation.h>
#import "Person.h"
 
@interface Ship : NSObject
 
@property (strong, readonly) Person *captain;
 
- (id)initWithCaptain:(Person *)captain;
 
@end
```

类扩展可以覆盖class中的@property定义。 这使您有机会在实现文件中将该属性重新声明为readwrite。 从语法上讲，扩展看起来像一个空的category声明：

```objective-c
// Ship.m
#import "Ship.h"
 
 
// The class extension.
@interface Ship()
 
@property (strong, readwrite) Person *captain;
 
@end
 
 
// The standard implementation.
@implementation Ship
 
@synthesize captain = _captain;
 
- (id)initWithCaptain:(Person *)captain {
    self = [super init];
    if (self) {
        // This WILL work because of the extension.
        [self setCaptain:captain];
    }
    return self;
}
 
@end
```

注意@interface指令后附加到类名的`()`。 这是将其标记为扩展而不是普通接口或category的原因。 必须在类的主实现块中声明扩展中出现的任何属性或方法。 在这种情况下，我们不会添加任何新字段 - 我们会覆盖现有字段。 但是与category不同，扩展可以向类中添加额外的实例变量，这就是为什么我们能够在类扩展中声明属性而不是category。

因为我们使用readwrite属性重新声明了captain属性，所以initWithCaptain：方法可以在自身上使用setCaptain：accessor。 如果要删除扩展名，属性将返回其只读状态，编译器会报错。 使用Ship类的客户端不应该导入实现文件，因此captain属性将保持只读。

```objective-c
#import <Foundation/Foundation.h>
#import "Person.h"
#import "Ship.h"
 
int main(int argc, const char * argv[]) {
    @autoreleasepool {
 
        Person *heywood = [[Person alloc] init];
        heywood.name = @"Heywood";
        Ship *discoveryOne = [[Ship alloc] initWithCaptain:heywood];
        NSLog(@"%@", [discoveryOne captain].name);
 
        Person *dave = [[Person alloc] init];
        dave.name = @"Dave";
        // This will NOT work because the property is still read-only.
        [discoveryOne setCaptain:dave];
 
    }
    return 0;
}
```

# Private Methods

扩展的另一个常见用例是声明私有方法。 在上一章中，我们看到了如何通过在实现文件中的任何位置添加私有方法来声明私有方法。 但是，在Xcode 4.3之前，情况并非如此。 创建私有方法的规范方法是使用类扩展来向前声明它。 让我们通过稍微改变前一个示例中的Ship的头文件来看一下这个：

```objective-c
// Ship.h
#import <Foundation/Foundation.h>
 
@interface Ship : NSObject
 
- (void)shoot;
 
@end
```

接下来，我们将重新创建讨论私有方法时使用的示例。 我们需要在类扩展中向前声明它，而不是简单地将私有prepareToShoot方法添加到实现中。

```objective-c
// Ship.m
#import "Ship.h"
 
// The class extension.
@interface Ship()
 
- (void)prepareToShoot;
 
@end
 
// The rest of the implementation.
@implementation Ship {
    BOOL _gunIsReady;
}
 
- (void)shoot {
    if (!_gunIsReady) {
        [self prepareToShoot];
        _gunIsReady = YES;
    }
    NSLog(@"Firing!");
}
 
- (void)prepareToShoot {
    // Execute some private functionality.
    NSLog(@"Preparing the main weapon...");
}
 
@end
```

编译器确保扩展方法在主实现块中实现，这就是它作为forward-declaration的原因。 然而，因为扩展被封装在实现文件中，所以其他对象不应该知道它，为我们提供了另一种模拟私有方法的方法。 虽然较新的编译器可以为您节省这些麻烦，但了解类扩展的工作原理仍然很重要，因为它是直到最近才开始利用Objective-C程序中的私有方法的常用方法。

# 总结

本章介绍了Objective-C编程语言中两个更独特的概念：category和extension。 category是扩展现有类的API的一种方式，extension是一种在主接口文件的API之外添加所需方法的方法。 这两个最初都是为了减轻维护大型代码库的负担而设计的。