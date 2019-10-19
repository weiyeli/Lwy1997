# Objective-C中的Getter和Setter

## 栗子

**Customer.h**

```objective-c
@interface Customer : NSObject
@property (nonatomic) NSString* name;
@end
```

**Customer.m**

```objective-c
#import "Customer.h"

@implementation Customer

@synthesize name = _name;

- (void)setName:(NSString *)name {
    NSLog(@"Setting name to: %@", name);
    _name = [name uppercaseString];
}

- (NSString *)name {
    NSLog(@"Returning name: %@", _name);
    return _name;
}

- (void) test {
    self.name = @"Joan of arc";
    NSLog(@"Name is %@", self.name);
}

@end
```

##  @synthesize的作用

1. 一个作用就是让编译器为你自动生成setter与getter方法 。
2. 可以指定与属性对应的实例变量，如@synthesize height = HH（如果.m文件中写了@synthesize str = xxx;那么生成的实例变量就是xxx；如果没写@synthesize str;那么生成的实例变量就是_str）。
3. 从 4.5及以后的版本中，@property独揽了@property和@synthesize的功能。

@property (nonatomic, copy) NSString *str;这句话完成了3个功能：

1. 生成_str成员变量的get和set方法的声明
2. 生成_str成员变量set和get方法的实现
3. 生成一个_str的成员变量。(注意：这种方式生成的成员变量是private的)

**总结：属性重写****setter****和****getter****方法**

使用属性@property能够帮我们省去了很多繁杂的工作，但有的时候我们在使用属性的时候还是需要去重写一下其setter和getter方法，这个时候我们应该怎么做呢？

**如果只重写`setter`和`getter`其中之一**

可以直接重写

**如果同时重写`setter`和`getter**`

需要加上@synthesize propertyName = _propertyName;不然系统会不认_str。因为如果你同时重写了getter和setter方法，系统就不会帮你自动生成这个_str变量，所以当然报错说不认识这个变量。所以得手动指定成员变量，然后再同时重写了getter和setter方法。