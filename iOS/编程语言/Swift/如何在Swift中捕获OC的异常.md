# 背景

很多著名的第三方开源库都是Objective-C编写，很容易出现的一个问题就是开源库中通过Objective-C抛出的异常无法被Swift捕获，这时候会引发Crash。本文将会讲解如何在Swift中捕获Objective-C抛出的异常。

# 实现方式

新增一个Objective-C的头文件：

```objective-c
#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
```

实现如下：

```objective-c
#import "ObjC.h"

@implementation ObjC 

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
```

在Swift中就可以愉快的使用了：

```swift
do {
    try ObjC.catchException {

       /* calls that might throw an NSException */
    }
}
catch {
    print("An error ocurred: \(error)")
}
```

# 踩坑记

如果是在主项目中创建了Objective-C头文件，不要忘记创建"*-Bridging-Header.h"桥接文件。如果是在Framework中创建的，需要在Framework的`umbrella header`里面添加：

```objective-c
#import "ObjC.h"
```

并且把头文件的访问权限设置为`public`

# 参考文档

https://stackoverflow.com/questions/32758811/catching-nsexception-in-swift/36454808#36454808

https://stackoverflow.com/questions/31238761/what-is-an-umbrella-header/31238936