# iOS Runtime浅析

完整的程序生命阶段可以大致分为编辑，编译，链接，分发，安装，加载和运行这几个阶段。 Runtime 在广义上是指程序正在运行的阶段。但是在iOS开发中提到 Runtime 则更多的是指 Objective-C 中用汇编和C语言写的 Runtime 库以及它带来的一些特性与功能。

Objective-C 是基于面向过程开发的 C语言的，它通过 Runtime 库维护了一个运行时系统，可以在程序运行时动态地创建类和对象，在方法调用时进行消息的传递和转发进而找出方法的最终执行代码等等，使得Object-C 的代码更为灵活，赋予了 Objective-C 面向对象的特性以及动态性。

由于Runtime在Objective-C 中的运用十分广泛，本文只针对基础的类对象结构和消息传递机制进行分析。

## Class

在 Objective-C 中类用 Class 类型表示，它实际上是一个指向 objc_class 结构体的指针。而 objc_class 结构体定义在Runtime 库中。

NSObject 是 Objectiv-C 语言中几乎所有对象的根类。它的定义如下

```
@interface NSObject <NSObject> {
    Class isa  OBJC_ISA_AVAILABILITY; 
}
```

Class 实际上是一个指向 objc_class 结构体的指针。它定义在 Obsolete Source/Object.mm 中：

```
typedef struct objc_class *Class;
```

其实不只是类，Objective-C 中类的实例对象，方法，分类，协议等，在 Runtime 库中都是用结构体表示。因为 Objectiv-C 是一门面向对象开发的高级编程语言。在转变成计算机能够识别的机器语言之前，它需要先转换成纯C语言，进而再进行编译和汇编操作。 Runtime 库 实现了Objective-C 到 C 语言的转换。

查看 objc-runtime-new.h 中 objc_class 结构体的定义：

```
//对象结构体（类对象和实例对象都是这个类型，类本身是一个类对象）
struct objc_object {
private:
    isa_t isa; //类对象的isa指向元类，实例对象的isa指向类对象
    //省略objc_objec的方法
    .......
 };
 
//objc_class继承于objc_object,因此类其实也是一个对象
struct objc_class : objc_object {
    Class superclass;           //指向父类
    cache_t cache;             //实例方法缓存  
    class_data_bits_t bits;    // 存储与类有关的信息
    class_rw_t* data() {     //存储实例对象的属性，方法，协议等信息
   return bits.data();
}
    //省略objc_class的方法
    .......
};
```

以下介绍一下objc_class结构体中的比较重要的几个属性。

- ### 元类(Meta Class)

在 objc_class 结构体继承自objc_object, objc_object 中有定义了一个isa属性。类对象的isa指向的是它的元类meta-class。objc-runtime.mm中提供了根据类名获取 meta-class 的方法。从方法的中可以看出实际返回的就是类指针。并且从返回值类型表明了 meta-class 其实也是一个 Class 类型，即一个 objc_class 类型的结构体。

//获取元类的方法实现如下：

```
Class objc_getMetaClass(const char *aClassName)
{
    Class cls;
    if (!aClassName) return Nil;
    cls = objc_getClass (aClassName);
    if (!cls)
    {
        _objc_inform ("class `%s' not linked into application", aClassName);
        return Nil;
    }
    return cls->ISA();
}
```

meta-class 存储着一个类的所有类方法。所有直接或者间接继承自 NSObject 的类都会有一个自己的 meta-class ，因为每个类的类方法基本不可能完全相同。

现有Person类，本类中有类方法fire以及在分类中声明的类方法growUp。以下为查找类方法的存储位置的过程

```
(lldb) p (objc_class *)0x1000013f8  //Person类在内存中的地址
(objc_class *) $0 = 0x00000001000013f8
(lldb) p $0->isa  //获取Person的isa
warning: could not find Objective-C class data in the process. This may reduce the quality of type information available.
(Class) $1 = 0x00000001000013d0
(lldb) p (class_data_bits_t *)0x00000001000013f0 //person元类对象的bits
(class_data_bits_t *) $12 = 0x00000001000013f0
(lldb) p $12->data()  //获取元类对象的class_rw_t *
(class_rw_t *) $13 = 0x00000001000011e8
(lldb) p (class_ro_t *)$13
(class_ro_t *) $14 = 0x00000001000011e8
(lldb) p *$14
(class_ro_t) $15 = {
  flags = 389
  instanceStart = 40
  instanceSize = 40
  reserved = 0
  ivarLayout = 0x0000000000000000 <no value available>
  name = 0x0000000100000f03 "Person"  
  baseMethodList = 0x00000001000011b0
  baseProtocols = 0x0000000000000000
  ivars = 0x0000000000000000
  weakIvarLayout = 0x0000000000000000 <no value available>
  baseProperties = 0x0000000000000000
}
(lldb) p $15.baseMethodList  //元类对象的方法列表
(method_list_t *) $16 = 0x00000001000011b0
(lldb) p $16->get(0)   //###### Person的类方法fire  ########
(method_t) $17 = {
  name = "fire"
  types = 0x0000000100000f72 "v16@0:8"
  imp = 0x0000000100000e10 (testRuntime`+[Person(SuperMan) fire] at Person+SuperMan.m:15)
}
(lldb) p $16->get(1)
(method_t) $18 = {
  name = "growUp"   //Person的类方法grpwUp
  types = 0x0000000100000f72 "v16@0:8"
  imp = 0x0000000100000be0 (testRuntime`+[Person growUp] at Person.m:18)
}
(lldb) p $16->get(2)
Assertion failed: (i < count), function get, file /Users/gwj/Downloads/RuntimeSourceCode-master/objc4-750.1/runtime/objc-runtime-new.h, line 116.
error: Execution was interrupted, reason: signal SIGABRT.
The process has been returned to the state before expression evaluation.
```

- ### isa与superclass

objc_object 结构体的定义：

```
//对象结构体（类和实例对象都是这个类型，类本身是一个类对象）
struct objc_object {
private:
    isa_t isa; //类的isa指向元类，实例对象的isa指向类对象
    //省略objc_objec的方法
    .......
 };
```

实例对象是 objc_object类型，类 objc_class 继承自 objc_object 类型，因此类和实例对象都有一个 isa 属性。

实例对象的 isa 指向的是类对象，类的isa指向的是 meta-class，meta-class 的isa指向的是NSObject的meta-class。而NSObject的meta-class的isa指向的是它本身，整个体系构成了一个闭环。

类还有一个的supperclass属性，它指向父类，meta-class的superclass指向父类的meta-class。

Objective - C 消息传递机制与这样的继承体系是密不可分的。具体在消息传递的章节中再做介绍。

![img](https://sf3-ttcdn-tos.pstatp.com/img/tos-cn-v-0000/3134e49c03aa4ccaa496b3b914e0db88~noop.png)

为了验证的isa指针的指向， 现有Person，Student，NSObject3个类，Person与Student分别继承自NSObject

```
(lldb) p (objc_class *)0x1000013f8 
(objc_class *) $0 = 0x00000001000013f8
(lldb) p $0->isa  //获取Person的isa
warning: could not find Objective-C class data in the process. This may reduce the quality of type information available.
(Class) $1 = 0x00000001000013d0
(lldb) p (objc_class *)$1  //获取Person的meta-class
(objc_class *) $2 = 0x00000001000013d0 
(lldb) p $2->isa     //获取Person的meta-class的isa
(Class) $3 = 0x0000000100afd0f0  //#####Person的meta-class的isa#######
(lldb) p (objc_class *)0x100001448
(objc_class *) $4 = 0x0000000100001448
(lldb) p $4->isa  //获取Student的isa
(Class) $5 = 0x0000000100001420
(lldb) p (objc_class *)$5
(objc_class *) $6 = 0x0000000100001420
(lldb) p $6->isa
(Class) $7 = 0x0000000100afd0f0  //#####Student的meta-class的isa#######
(lldb) p (objc_class *)0x100afd140
(objc_class *) $8 = 0x0000000100afd140
(lldb) p $8->isa 
(Class) $9 = 0x0000000100afd0f0 //NSObject的meta-class
(lldb) p (objc_class *)$9
(objc_class *) $10 = 0x0000000100afd0f0 //NSObject的meta-class的isa
(lldb) p $10->isa
(Class) $11 = 0x0000000100afd0f0
```

- #### 成员变量(ivar)及属性（Property）

在 objc_class 中实例对象相关的很多信息都存储在了 class_rw_t 类型的数据结构中，其中包括了属性列表和成员列表，因此在介绍class_rw_t 之前先介绍一下这两种数据类型。

```
//属性
struct property_t {
    const char *name;
    const char *attributes;
};

//成员变量
struct ivar_t {
    int32_t *offset;
    const char *name;
    const char *type;
    // alignment is sometimes -1; use alignment() instead
    uint32_t alignment_raw;
    uint32_t size;
    uint32_t alignment() const {
        if (alignment_raw == ~(uint32_t)0) return 1U << WORD_SHIFT;
        return 1 << alignment_raw;
    }
};
```

成员变量

在类的 .m 文件中直接声明的则只会生成带下划线的成员变量，没有 set 和get方法。成员变量结构体中的信息中包括了属性在内存中的位置，大小等。

属性

在一个类中用 @property 声明的是属性，会自动生成对应的 set 和 get 方法用于属性的赋值和取值，以及一个带下划线的同名成员变量。属性存储在 class_ro_t 结构的baseProperties以及 class_rw_t property_array_t中。

本类中的所有成员变量的信息会存放在 class_ro_t 的 ivars 中的。一个类的实例对象大小在编译时期就确定了，就是根据每个成员变量的大小，进行内存对齐后计算得出的。

- ### class_rw_t 与class_ro_t

class_rw_t 与 class_ro_t 的定义如下：

```
// 类的方法、属性、协议等信息都保存在class_rw_t结构体中
struct class_rw_t {
    // Be warned that Symbolication knows the layout of this structure.
    uint32_t flags;
    uint32_t version; //版本信息
    const class_ro_t *ro;//存储了类在编译期就已经确定的属性、方法以及遵循的协议等，是只读类型
    method_array_t methods;   // 方法信息
    property_array_t properties; // 属性信息
    protocol_array_t protocols;  // 协议信息
    Class firstSubclass;
    Class nextSiblingClass;

    char *demangledName;
     //省略class_rw_t的方法
    .......
  };

struct class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize; //实例对象的大小
#ifdef __LP64__
    uint32_t reserved;
#endif
    const uint8_t * ivarLayout; //成员变量布局
    const char * name; //类名
    method_list_t * baseMethodList; // 方法列表
    protocol_list_t * baseProtocols; // 协议列表
    const ivar_list_t * ivars;  // 成员变量列表
    const uint8_t * weakIvarLayout; 
    property_list_t *baseProperties; // 属性列表
    method_list_t *baseMethods() const {
        return baseMethodList;
    }
};
```

在前面介绍 objc_class 时可以看到它有一个 class_rw_t* data()，这个方法返回了一个指向 class_rw_t 类型的指针，而类的实例对象相关的信息大部分都存储在这个指针指向的内存中。例如实例对象的属性，实例方法以及分类中添加信息，协议信息等等。class_rw_t 的数据都是在运行时才确定下来的。

class_rw_t 中有一个指向class_ro_t 类型的指针 ro，其中存储了当前类在编译期就确定的一些信息。通过class_rw_t 和 class_ro_t 的定义可以发现，它们都存储的信息有部分的重合。那么它们之间具体是有什么联系呢？我们可以通过下列的例子做一个论证。

现有Person类，及它的分类。在分类中添加了方法，且使用Runtime库提供 方法添加了一个title属性。

```
//Person类
@interface Person : NSObject
@property NSString *name;
@property int sex;
- (void)eat;
+ (void)growUp;
@end

#import "Person.h"
@implementation Person
float _height;
//省略方法实现
@end

//Person分类
#import "Person.h"
NS_ASSUME_NONNULL_BEGIN

@interface Person (SuperMan)
@property(nonatomic,copy) NSString *title;
- (void)fly;
+ (void)fire;
@end
//省略分类的.m


//获取类对象地址
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Class p = [Person class];
        NSLog(@"%p", p); //0x100002540
    }
    return 0;
}
```

在 Runtime库的入口方法 _objc_init() 中打断点，这个时候整个运行时系统还未初始化，类对象的初始化方法也还没走，此时拿到的 Person类对象是编译后的产物，它有一部分数据，但是并不是一个完整的类对象。

![img](https://sf3-ttcdn-tos.pstatp.com/img/tos-cn-v-0000/97e1f00e92cf464b83d3f82d2b53d3f2~noop.png)

因为类在内存中的地址在编译时就已经确定，不更改类的信息或者添加新的类，地址不会改变。所以可以先打印一遍Person类的地址，然后在重新运行项目，在上述断点位置使用该地址获取Person类对象的详细信息。

```
(lldb) p (objc_class *)0x100002540  
(objc_class *) $0 = 0x0000000100002540
(lldb) p (class_data_bits_t *)0x0000000100002560  //类对象地址偏移32位获取class_data_bits_t *
(class_data_bits_t *) $1 = 0x0000000100002560
(lldb) p $1->data()  //调用bits.data()获取class_rw_t *
(class_rw_t *) $2 = 0x00000001000023c8
(lldb) p *$2 //此时直接读取class_rw_t *的内容会报警告说没有数据
warning: could not find Objective-C class data in the process. This may reduce the quality of type information available.
(class_rw_t) $3 = {
  flags = 388
  version = 8
  ro = 0x0000000000000018
  methods = {
    list_array_tt<method_t, method_list_t> = {
       = {
        list = 0x0000000100001ebe
        arrayAndFlag = 4294975166
      }
    }
  }
  properties = {
    list_array_tt<property_t, property_list_t> = {
       = {
        list = 0x0000000100001eb7
        arrayAndFlag = 4294975159
      }
    }
  }
  protocols = {
    list_array_tt<unsigned long, protocol_list_t> = {
       = {
        list = 0x00000001000021c8
        arrayAndFlag = 4294975944
      }
    }
  }
  firstSubclass = nil
  nextSiblingClass = 0x0000000100002360
  demangledName = 0x0000000000000000 <no value available>
}
(lldb) p $3.ro  //访问class_rw_t *中ro，发现并不能访问
(const class_ro_t *) $4 = 0x0000000000000018
(lldb) p *$4
error: Couldn't apply expression side effects : Couldn't dematerialize a result variable: couldn't read its memory
(lldb) p $3.methods   //访问class_rw_t *中methods，最终发现里面没有方法
(method_array_t) $6 = {
  list_array_tt<method_t, method_list_t> = {
     = {
      list = 0x0000000100001ebe
      arrayAndFlag = 4294975166
    }
  }
}
(lldb) p $6.list
(method_list_t *) $7 = 0x0000000100001ebe
(lldb) p $7->get(0)
(method_t) $8 = {
  name = <no value available>
  types = 0x55776f726700746e <no value available>
  imp = 0x632e007461650070 (0x632e007461650070)
}
(lldb) p $7->get(1)
error: Couldn't apply expression side effects : Couldn't dematerialize a result variable: couldn't read its memory
(lldb) p (class_ro_t *)$2  //将上面调用bits.data()获取的class_rw_t *强转成class_ro_t *
(class_ro_t *) $10 = 0x00000001000023c8
(lldb) p *$10  //读取class_ro_t *中的数据
(class_ro_t) $11 = {
  flags = 388
  instanceStart = 8
  instanceSize = 24
  reserved = 0
  ivarLayout = 0x0000000100001ebe "\x11"
  name = 0x0000000100001eb7 "Person"
  baseMethodList = 0x00000001000021c8
  baseProtocols = 0x0000000000000000
  ivars = 0x0000000100002360
  weakIvarLayout = 0x0000000000000000 <no value available>
  baseProperties = 0x00000001000022e0
}
(lldb) p $11.ivars //ivars中有用Person类中声明的属性与成员变量
(const ivar_list_t *) $12 = 0x0000000100002360
(lldb) p $12->get(0)
(ivar_t) $13 = {
  offset = 0x0000000100002510
  name = 0x0000000100001f04 "_height"
  type = 0x0000000100001f9c "f"
  alignment_raw = 2
  size = 4
}
(lldb) p $12->get(1)
(ivar_t) $14 = {
  offset = 0x0000000100002508
  name = 0x0000000100001f0c "_sex"
  type = 0x0000000100001f9e "i"
  alignment_raw = 2
  size = 4
}
(lldb) p $12->get(2)
(ivar_t) $15 = {
  offset = 0x0000000100002500
  name = 0x0000000100001f11 "_name"
  type = 0x0000000100001fa0 "@"NSString""
  alignment_raw = 3
  size = 8
}
(lldb) p $12->get(3)
error: Execution was interrupted, reason: signal SIGABRT.
The process has been returned to the state before expression evaluation.
Assertion failed: (i < count), function get, file /Users/gwj/Desktop/RuntimeSourceCode-master/objc4-750.1/runtime/objc-runtime-new.h, line 116.
(lldb) p $10.baseProperties  //basePRoperties中有用@property声明的属性以及用分类中添加的属性
(property_list_t *) $16 = 0x00000001000022e0
  Fix-it applied, fixed expression was: 
    $10->baseProperties
(lldb) p $10->baseProperties
(property_list_t *) $17 = 0x00000001000022e0
(lldb) p $17->get(0)
(property_t) $18 = (name = "title", attributes = "T@"NSString",C,N")
(lldb) p $17->get(1)
(property_t) $19 = (name = "name", attributes = "T@"NSString",&,V_name")
(lldb) p $17->get(2)
(property_t) $20 = (name = "sex", attributes = "Ti,V_sex")
(lldb) p $17->get(3)
error: Execution was interrupted, reason: signal SIGABRT.
The process has been returned to the state before expression evaluation.
Assertion failed: (i < count), function get, file /Users/gwj/Desktop/RuntimeSourceCode-master/objc4-750.1/runtime/objc-runtime-new.h, line 116.
(lldb) p $10.baseMethodList  //方法列表中有Person本类及分类中声明的对象方法，以及属性的set，get方法
(method_list_t *) $21 = 0x00000001000021c8
  Fix-it applied, fixed expression was: 
    $10->baseMethodList
(lldb) p $10->baseMethodList
(method_list_t *) $22 = 0x00000001000021c8
(lldb) p $22->get(0)
(method_t) $23 = {
  name = "setTitle:"
  types = 0x0000000100001f7e "v24@0:8@16"
  imp = 0x0000000100001bd0 (testRuntime`-[Person(SuperMan) setTitle:] at Person+SuperMan.m:14)
}
(lldb) p $22->get(1)
(method_t) $24 = {
  name = "title"
  types = 0x0000000100001f76 "@16@0:8"
  imp = 0x0000000100001c40 (testRuntime`-[Person(SuperMan) title] at Person+SuperMan.m:18)
}
(lldb) p $22->get(2)
(method_t) $25 = {
  name = "fly"
  types = 0x0000000100001f6e "v16@0:8"
  imp = 0x0000000100001ca0 (testRuntime`-[Person(SuperMan) fly] at Person+SuperMan.m:24)
}
(lldb) p $22->get(3)
(method_t) $26 = {
  name = "eat"
  types = 0x0000000100001f6e "v16@0:8"
  imp = 0x00000001000018a0 (testRuntime`-[Person eat] at Person.m:14)
}
(lldb) p $22->get(4)
(method_t) $27 = {
  name = ".cxx_destruct"
  types = 0x0000000100001f6e "v16@0:8"
  imp = 0x00000001000019c0 (testRuntime`-[Person .cxx_destruct] at Person.m:10)
}
(lldb) p $22->get(5)
(method_t) $28 = {
  name = "name"
  types = 0x0000000100001f76 "@16@0:8"
  imp = 0x0000000100001900 (testRuntime`-[Person name] at Person.h:13)
}
(lldb) p $22->get(6)
(method_t) $29 = {
  name = "setName:"
  types = 0x0000000100001f7e "v24@0:8@16"
  imp = 0x0000000100001930 (testRuntime`-[Person setName:] at Person.h:13)
}
(lldb) p $22->get(7)
(method_t) $30 = {
  name = "sex"
  types = 0x0000000100001f89 "i16@0:8"
  imp = 0x0000000100001970 (testRuntime`-[Person sex] at Person.h:14)
}
(lldb) p $22->get(8)
(method_t) $31 = {
  name = "setSex:"
  types = 0x0000000100001f91 "v20@0:8i16"
  imp = 0x0000000100001990 (testRuntime`-[Person setSex:] at Person.h:14)
}
(lldb) p $22->get(9)
error: Execution was interrupted, reason: signal SIGABRT.
The process has been returned to the state before expression evaluation.
Assertion failed: (i < count), function get, file /Users/gwj/Desktop/RuntimeSourceCode-master/objc4-750.1/runtime/objc-runtime-new.h, line 116.
(lldb)
```

综上可以确定，编译完成后，每个类会有一个信息并不完整的类对象。这个类对象的class_rw_t * 指向的真实类型是class_ro_t ，它里面存储了类对象在编译时就能确定的信息，如instancesize，属性列表，成员列表，方法列表，以及遵循的协议信息等。

在runtime的初始化方法（objc_init）中会调用_dyld_objc_notify_register 方法，接着会执行类对象的初始化方法。这个方法将使用编译时产生 class_ro_t中数据来完成类对象真正的初始化，并且会将 class_ro_t 中的方法列表，属性列表，协议列表等赋值给类对象的class_rw_t 的对应属性，并且将这个 class_ro_t 赋值给它的ro赋值，作为一个只读属性。如果后期在运行时为类对象动态添加方法和属性的话，都是添加到 class_rw_t 中，不会影响只读结构ro。

以下是 objc-runtime-new.mm 中有类对象的初始化方法。

```
// 类对象的初始化方法
static Class realizeClass(Class cls)
{
    runtimeLock.assertLocked();
    const class_ro_t *ro;
    class_rw_t *rw;
    Class supercls;
    Class metacls;
    bool isMeta;
    //省略无关代码
    //........
  
    //通过类对象调用data(),并将返回结果从class_rw_t *强转成 class_ro_t *
    ro = (const class_ro_t *)cls->data();
    //省略无关代码
    //........
    if (ro->flags & RO_FUTURE) {
        // rw结构体已经被初始化（正常不会执行到这里）
        // This was a future class. rw data is already allocated.
        rw = cls->data();
        ro = cls->data()->ro;
        cls->changeInfo(RW_REALIZED|RW_REALIZING, RW_FUTURE);
    } else {
        // 绝大部分的类都是执行到这里
        // 初始化一个新的class_rw_t结构体
        rw = (class_rw_t *)calloc(sizeof(class_rw_t), 1);
        //给rw的ro赋值
        rw->ro = ro;
        rw->flags = RW_REALIZED|RW_REALIZING;
        // cls->data 指向class_rw_t结构体
        cls->setData(rw);
    }
    //省略无关代码
    //........
    isMeta = ro->flags & RO_META;
    rw->version = isMeta ? 7 : 0;  // old runtime went up to 6
   
    supercls = realizeClass(remapClass(cls->superclass));
    metacls = realizeClass(remapClass(cls->ISA()));
    //省略无关代码
    //........
    cls->superclass = supercls;
    cls->initClassIsa(metacls);
    //省略无关代码
    //........
    // 此时cls里的rw.ro已经有值了，在这个方法里就会用将ro中的类实现的方法（包括分类）、属性和遵循的协议添加到class_rw_t结构体中的methods、properties、protocols列表中
    methodizeClass(cls);
    return cls;
}

// 设置类的方法列表、协议列表、属性列表，包括category的方法
static void methodizeClass(Class cls)
{
    runtimeLock.assertLocked();
    bool isMeta = cls->isMetaClass();
    auto rw = cls->data();
    auto ro = rw->ro;
    // 省略无关代码
    //........
    // 将class_ro_t中的baseMethods添加到class_rw_t中的methods
    method_list_t *list = ro->baseMethods();
    if (list) {
        prepareMethodLists(cls, &list, 1, YES, isBundleClass(cls));
        rw->methods.attachLists(&list, 1);
    }
    // 将class_ro_t中的baseProperties添加到class_rw_t中的properties
    property_list_t *proplist = ro->baseProperties;
    if (proplist) {
        rw->properties.attachLists(&proplist, 1);
    }
    // 将class_ro_t中的baseProtocols添加到class_rw_t的protocols
    protocol_list_t *protolist = ro->baseProtocols;
    if (protolist) {
        rw->protocols.attachLists(&protolist, 1);
    }
    // 省略无关代码
    //........
    // 添加category方法
    category_list *cats = unattachedCategoriesForClass(cls, true /*realizing*/);
    attachCategories(cls, cats, false /*don't flush caches*/);
    // 省略无关代码
    //........
    if (cats) free(cats);
}
```

在realizeClass方法最后return cls的地方打断点，设置断点条件是当cls为Person对象时会执行断点。当获取到Person类对象cls时，再一次打印其中的数据就会发现里面的 class_rw_t * 中的ro以及methods等数据已经有内容了。因为类对象的初始化已经完成了。

```
//省略其余打印
//.....
(lldb) p $1048->data()
(class_rw_t *) $1050 = 0x00000001014384d0
(lldb) p *$1050
(class_rw_t) $1051 = {
  flags = 2148139008
  version = 0
  ro = 0x00000001000012c0
  methods = {
    list_array_tt<method_t, method_list_t> = {
       = {
        list = 0x0000000100001100
        arrayAndFlag = 4294971648
      }
    }
  }
  properties = {
    list_array_tt<property_t, property_list_t> = {
       = {
        list = 0x0000000100001298
        arrayAndFlag = 4294972056
      }
    }
  }
  protocols = {
    list_array_tt<unsigned long, protocol_list_t> = {
       = {
        list = 0x0000000000000000
        arrayAndFlag = 0
      }
    }
  }
  firstSubclass = nil
  nextSiblingClass = 0x00007fff87b3dc80
  demangledName = 0x0000000000000000 <no value available>
}
(lldb) p $1051.ro
(const class_ro_t *) $1052 = 0x00000001000012c0
(lldb) p *$1052
(const class_ro_t) $1053 = {
  flags = 388
  instanceStart = 8
  instanceSize = 24
  reserved = 0
  ivarLayout = 0x0000000100000f0a "\x11"
  name = 0x0000000100000f03 "Person"
  baseMethodList = 0x0000000100001100
  baseProtocols = 0x0000000000000000
  ivars = 0x0000000100001230
  weakIvarLayout = 0x0000000000000000 <no value available>
  baseProperties = 0x0000000100001298
}
(lldb) p $1051.methods
(method_array_t) $1054 = {
  list_array_tt<method_t, method_list_t> = {
     = {
      list = 0x0000000100001100
      arrayAndFlag = 4294971648
    }
  }
}
(lldb) p $1054.list
(method_list_t *) $1055 = 0x0000000100001100
(lldb) p $1055->get(0)
(method_t) $1056 = {
  name = "eat"
  types = 0x0000000100000f72 "v16@0:8"
  imp = 0x0000000100000bb0 (testRuntime`-[Person eat] at Person.m:14)
}
//省略其余打印
//.....
```

- ### cache

上面提到了objc_class结构体中的cache字段，它用于缓存调用过的方法。这个字段是一个指向 cache_t 结构体的指针，其定义如下：

```
struct cache_t {
   struct bucket_t *_buckets; //缓存方法的哈希桶数组指针，桶的数量 = mask + 1
    mask_t _mask; //桶的数量 - 1
    mask_t _occupied; //已经缓存的方法数量。
};
```

该结构体的字段描述如下：

1. buckets：缓存Method指针的数组。这个数组可能包含不超过mask+1个元素。需要注意的是，当这个指针为NULL时，表示此时缓存bucket没有被占用，另外被占用的bucket可能是不连续的。这个数组可能会随着时间而增长。一个类初始缓存中的桶的数量是4，每次桶数量扩容时都乘2。
2. mask：一个整数，指定分配的缓存bucket的总数。在方法查找过程中，Objective-C runtime 用指向方法selector的指针和这个字段进行一个 AND操作确定开始线性查找数组的索引位置(index = (mask & selector)。是一个简单的hash散列算法
3. occupied：一个整数，指定实际占用的缓存bucket的总数。每当将一个方法的缓存信息保存到桶中时occupied的数量加1，如果数量到达桶容量的3/4时，系统就会将桶的容量增大2倍变，并按照这个规则依次继续扩展下去。

- ## category

在runtime中分类的定义如下，从定义中就可以看出，分类可以给类添加对象方法，类方法，协议，以及属性等。

```
struct category_t {
    const char *name;
    classref_t cls;
    struct method_list_t *instanceMethods; //对象方法列表
    struct method_list_t *classMethods; //类方法列表
    struct protocol_list_t *protocols; //协议
    struct property_list_t *instanceProperties; //对象的属性列表
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;

    method_list_t *methodsForMeta(bool isMeta) {
        
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);
};
```

以下是Person类的一个分类的声明与实现。

![img](https://sf3-ttcdn-tos.pstatp.com/img/tos-cn-v-0000/a39bbd0650fe4dc8911cbeb5085c92e5~noop.png)

![img](https://sf3-ttcdn-tos.pstatp.com/img/tos-cn-v-0000/2c49b13452a940799ea0a16409f81e6c~noop.png)

正如文章前面打印结果显示的，自定义类的category中的数据在编译时就已经存在了类对象的 class_ro_t 中对应的属性里，例如方法与本类的方法放在同一个方法列表里等。在类对象初始化时，再存储到class_rw_t中。

需要注意的一点是，在分类中添加的方法与本类的方法存储在同一个方法列表，即使方法名相同，也不会替换掉本类的方法，只是分类的方法是放在列表中的最前。因此当分类中添加的方法与本类方法同名时，分类方法会先被找到并调用，随即结束查找，造成了一种分类方法覆盖了本类方法的错觉。但其实本类方法依然存在在方法列表中。

```
(lldb) p (objc_class *)0x100002518
(objc_class *) $0 = 0x0000000100002518
(lldb) p (class_data_bits_t *)0x0000000100002538
(class_data_bits_t *) $1 = 0x0000000100002538
(lldb) p $1->data()
(class_rw_t *) $2 = 0x00000001000023a0
(lldb) p (class_ro_t *)$2
(class_ro_t *) $3 = 0x00000001000023a0
(lldb) p *$3
(class_ro_t) $4 = {
  flags = 388
  instanceStart = 8
  instanceSize = 24
  reserved = 0
  ivarLayout = 0x0000000100001eca "\x11"
  name = 0x0000000100001ec3 "Person"
  baseMethodList = 0x0000000100002188
  baseProtocols = 0x0000000000000000
  ivars = 0x0000000100002338
  weakIvarLayout = 0x0000000000000000 <no value available>
  baseProperties = 0x00000001000022b8
}
(lldb) p $3->baseMethodList
(method_list_t *) $5 = 0x0000000100002188
(lldb) p $5->get(0)
(method_t) $6 = {
  name = "setTitle:"  
  types = 0x0000000100001f63 "v24@0:8@16"
  imp = 0x0000000100001c00 (testRuntime`-[Person(SuperMan) setTitle:] at Person+SuperMan.m:14)
}
(lldb) p $5->get(1)
(method_t) $7 = {
  name = "title"
  types = 0x0000000100001f5b "@16@0:8"
  imp = 0x0000000100001c70 (testRuntime`-[Person(SuperMan) title] at Person+SuperMan.m:18)
}
(lldb) p $5->get(2)
(method_t) $8 = {
  name = "eat"   //分类中添加的eat方法
  types = 0x0000000100001f53 "v16@0:8"
  imp = 0x0000000100001cd0 (testRuntime`-[Person(SuperMan) eat] at Person+SuperMan.m:23)
}
(lldb) p $5->get(3)
(method_t) $9 = {
  name = "fly"
  types = 0x0000000100001f53 "v16@0:8"
  imp = 0x0000000100001d00 (testRuntime`-[Person(SuperMan) fly] at Person+SuperMan.m:26)
}
(lldb) p $5->get(4)
(method_t) $10 = {
  name = "eat"    //本类中的eat方法
  types = 0x0000000100001f53 "v16@0:8"
  imp = 0x0000000100001990 (testRuntime`-[Person eat] at Person.m:14)
}
(lldb) 
```

在分类中利用 runtime 添加的属性也是在编译时期就已经存在了类对象的 class_ro_t 的baseProperties列表中，但是并不会生成对应的成员变量ivar，在class_ro_t的ivars里找不到它。类对象初始化完成以后，它会被存储在class_rw_t的properties中。它的set和get方法会跟着分类的其他方法一起存储在类对象的方法列表中。

```
(lldb) p $4.ivars
(const ivar_list_t *) $11 = 0x0000000100002338
(lldb) p $11->get(0)
(ivar_t) $12 = {
  offset = 0x00000001000024e8 //内存偏移量
  name = 0x0000000100001f10 "_height"
  type = 0x0000000100001f81 "f"
  alignment_raw = 2
  size = 4
}
(lldb) p $11->get(1)
(ivar_t) $13 = {
  offset = 0x00000001000024e0
  name = 0x0000000100001f18 "_sex"
  type = 0x0000000100001f83 "i"
  alignment_raw = 2
  size = 4
}
(lldb) p $11->get(2)
(ivar_t) $14 = {
  offset = 0x00000001000024d8
  name = 0x0000000100001f1d "_name"
  type = 0x0000000100001f85 "@"NSString""
  alignment_raw = 3
  size = 8
}
(lldb) p $4.baseProperties
(property_list_t *) $16 = 0x00000001000022b8
(lldb) p $16->get(0)
(property_t) $17 = (name = "title", attributes = "T@"NSString",C,N")  //runtime添加的title
(lldb) p $16->get(1)
(property_t) $18 = (name = "name", attributes = "T@"NSString",&,V_name")
(lldb) p $16->get(2)
(property_t) $19 = (name = "sex", attributes = "Ti,V_sex")
(lldb) p $16->get(3)
```

成员变量ivar_t 结构体中有一个offset属性，是该成员变量对于该对象的内存地址偏移了多少，给成员变量赋值或者取值的时候都是使用的这个地址来访问成员变量的，包括set 和 get 方法。而runtime添加的属性不会生成对应的成员变量。

因此runtime 提供了objc_setAssociatedObject 方法和 objc_getAssociatedObject方法 。查看这两个方法的实现就能看到，runtime 中定义了 AssociationsManager 管理所有的关联对象，它有一个静态AssociationsHashMap来存储所有的关联对象。并且会根据指定对内存管理策略进行内存管理。

简单而言就是通过AssociationsManager 确定了属性的存储地址。所以说属性的set 和 get 方法里调用这两个方法是将属性与对象进行了绑定后，就能正常访问这个属性了。

从前面的调试结果，已经证明了其实分类中添加的属性也是在编译时就能确定的，为什么不同时也为它生成ivar属性和set，get方法呢？其实在runtime 初始化时，有一部分分类信息是还未被加载到本类中的。例如在类的初始化方法会再获取一次未加载的分类，添加到本类中。（经打印发现读取到的分类，都不是自定义类相关的，而是例如NSSet，NSArray等类）。

以下为类对象的初始化时会调用的方法

```
// 设置类的方法列表、协议列表、属性列表，包括category的方法
static void methodizeClass(Class cls)
{
    // 添加category方法
    category_list *cats = unattachedCategoriesForClass(cls, true /*realizing*/);
    attachCategories(cls, cats, false /*don't flush caches*/);
    // 省略无关代码
    //........
    if (cats) free(cats);
}
```

而Objective-C 在编译时期就会根据类的ivars里的变量进行内存对齐，计算出instancesize，作为初始化类的实例对象时实例对象的内存大小。

个人推测正是因为有一部分分类的数据是在运行期间才添加到本类中的, 但此时类对象内存的分布已经确定，若此时再添加成员变量则会改变内存的分布情况，这在编译性语言中是不允许的。所以不允许分类改变本类的内存分布情况，即声明的属性是通过AssociationsManager 管理管理，而不会生成成员变量。反观扩展(extension)，它是为一个已知的类添加一些私有的信息，都是写在本类的.m文件中，所以必须有这个类的源码，才能写扩展。它是在编译时期生效的，所以能直接为类添加成员变量。

## Runtime消息传递

编译型语言有三种基础的函数派发方式: 直接派发(Direct Dispatch)**, **函数表派发(Table Dispatch)和消息机制派发(Message Dispatch)。 大多数语言都会支持一到两种, Java 默认使用函数表派发, 也可以使用直接派发. C++ 默认使用直接派发, 但可以通过修饰符改成函数表派发. 而 Objective-C 则总是使用消息机制派发, 但是也允许开发者使用 C 直接派发来提高性能。swift则是直接派发和函数表派发为主，objc显示或者隐式修饰的方法则使用消息派发机制。

在 Objective-C 中，编译时期并不能决定最终执行时调用哪个函数（Objective-C 中函数调用称为消息传递），而是在运行时才能最终确定。Objective-C 的这种动态绑定机制正是通过 Runtime 库实现的。以下就介绍一下在Objective-C中调用方法后，消息传递的过程。

#### Method(objc_method)

Objectiv-C中方法的定义如下

```
//objc-runtime-new.h
struct method_t {
    SEL name; 
    const char *types;
    MethodListIMP imp; 
    ......
}
```

SEL叫方法选择器，简单而言就是方法的名字，Objective-C在编译时，会依据每一个方法的名字、参数序列，生成一个唯一的整型标识(Int类型的地址)，这个标识就是SEL。IMP实际上是一个函数指针，指向方法实现的首地址。

在 Objective-C 里面调用一个方法的时候，Runtime 库会将这个调用翻译成 objc_msgSend 形式进行调用，它定义在 Objc-msg-arm.s 中，是所有OC方法调用的核心引擎。在这个方法里会去查找真正需要调用的方法，并执行该方法。为了追求高效率，objc_msgSend 函数的内部代码实现是用汇编语言。

objc_msgSend的声明如下

```
objc_msgSend(id self, SEL op, ...)
```

该方法有两个参数 self 和 op，分别是方法的调用者与方法选择器。它们也会作为参数传递给每个方法实现。ps：我们可以在每个方法实现中使用self，就是因为`self`作为隐式参数传递进来了。

objc_msgSend 的执行的流程是这样的：

1. 判断方法调用者（self）否为nil，如果是nil则函数直接返回。因此在OC中用一个nil对象调用方法时，不会崩溃也不会执行被调用的方法。
2. 获取调用者的isa，查找类对象/meta-class。
3. 在2中查找到的类对象/meta-class中的cache中查找方法实现。用传入的SEL类型的op的指针地址和mask进行一个哈希运算，获得一个索引。从bucket_t *中取出这个索引对应的bucket_t结构体，比照这个结构体中的key与sel是否相等。相等的话就表示命中缓存，则调用方法实现并结束查找。
4. 如果在缓存列表中没有找到对应的方法，则在方法列表中查到，找到后在cache中缓存一份，并调用。如果方法列表中也没有找到，则通过superclass指针找到父类，在父类中进行同样的查找，找到后调用方法实现并将其存储到子类的cache中。
5. 如果在步骤4中，一直追溯到了基类依然没有找到方法的话，进入方法决议以及消息转发。
6. 如果最终都找不到方法，则报错，抛出异常。

## 方法决议（method resolve）

在objc_msgSend的执行过程中，如果在方法调用者的所属的继承体系中无法找到方法的话，就会进入方法决议阶段。

比如以下这两种情况，编译都不会报错，但是运行会奔溃，因为person对象实际是Animal类型的，它并没有实现eat方法

![img](https://sf3-ttcdn-tos.pstatp.com/img/tos-cn-v-0000/d440ccc3683a4aabbe95c1a0b1725680~noop.png)

可以在类中实现下列方法，作为当对象无法响应方法时的处理。如果不实现该方法的话，方法决议的默认返回值为NO，则会进入消息转发阶段

```
//类方法的方法决议
+ (BOOL)resolveClassMethod:(SEL)sel {
    return NO;
}
//实例方法的方法决议
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    return NO;
}


//例子
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self performSelector:@selector(sayHello) withObject:nil];
}

+ (BOOL)resolveInstanceMethod: (SEL) sel {
    if (sel == @selector(sayHello)) {
        Class cls = [self class];
        BOOL isAdd =  class_addMethod(cls, sel, (IMP)test, "v@:");
        if (isAdd){
            return YES;
        } else {
            return [super resolveInstanceMethod:sel];
        }
    }
   return [super resolveInstanceMethod:sel];
}


void test(id obj,SEL _cmd){
    NSLog(@"调用了test方法");
}

@end
```

## 消息转发

如果方法的调用者没有重写上述的方法，则会进入消息转发阶段，尝试找到一个能响应该消息的对象。如果获取到，则直接转发给它。如果返回了 nil，继续下面的动作。消息转发的方法定义和执行步骤如下：

```
//1.可以在这个用法里提供一个新的对象作为方法的接收者，从新对象开始重新执行查找方法实现的流程，找到了也同样会在 object 的类对象的 _buckets 里缓存起来。如果这个方法返回nil的话 则进入下一步（方法默认返回nil）
这一步合适于我们将消息转发到另一个能处理该消息的对象上。在这一步无法对消息进行进一步的处理，如操作消息的参数和返回值。
+ (id)forwardingTargetForSelector:(SEL)sel { //这个方法现在在编译器里调用已经没有提示了
    return nil;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return nil;
}

//2.尝试获得一个方法签名。如果获取不到，则直接调用 doesNotRecognizeSelector 抛出异常。
//如果获取到了，则将签名作为参数传给下个方法。这条消息有关的全部细节都封装在anInvocation中，包括selector，目标(target)和参数。不手动实现这个方法，系统也会尝试获取签名传递给下个方法
// Replaced by CF (returns an NSMethodSignature)
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    _objc_fatal("+[NSObject methodSignatureForSelector:] "
                "not available without CoreFoundation");
}

// Replaced by CF (returns an NSMethodSignature)
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    _objc_fatal("-[NSObject methodSignatureForSelector:] "
                "not available without CoreFoundation");
}

//3.从获取到的方法签名中，可以拿到sel，然后可以在这个方法中做相应的处理
+ (void)forwardInvocation:(NSInvocation *)invocation {
    [self doesNotRecognizeSelector:(invocation ? [invocation selector] : 0)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [self doesNotRecognizeSelector:(invocation ? [invocation selector] : 0)];
}

//例子
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL sel = anInvocation.selector;

    Person *person = [Person new];
    if([p respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:person];
    } else {
        [self doesNotRecognizeSelector:sel];  //抛出异常
    }
}
```

至此方法的调用就全部结束了。如果以上方法都没有实现，那么程序就会抛出异常，提示找不到方法实现。

## 总结

本文只是介绍了Runtime中类对象的数据结构和初始化过程中的一些细节，以及消息传递和转发的基本机制。Runtime在oc中运用其实非常广泛，例如KVO键值监听，Method Swizzling方法交换，动态创建类，等等知识值得深入的了解和探索，介于篇幅问题在本文就不一一展开了。第一次写，写的不好，如果错误，欢迎指正。

参考链接：

https://www.jianshu.com/p/91bfe3f11eec 深入理解 Swift 派发机制

https://juejin.im/post/5b70ec3351882560fc512fc4 深入解构objc_msgSend函数的实现

https://tech.meituan.com/2015/08/12/deep-understanding-object-c-of-method-caching.html 深入理解 Objective-C：方法缓存

https://www.jianshu.com/p/6ebda3cd8052 iOS Runtime详解