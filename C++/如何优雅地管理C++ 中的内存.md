# 如何优雅地管理C++ 中的内存

## C++的内存管理

C++是一门Native Language，而说到Native Languages就不得不说资源管理，其中内存管理又是资源管理中的一个大问题，由于堆内存需要手动分配和释放，所以必须确保申请的内存得到正确的释放。对此一般的原则是"**谁分配的谁释放**"，但即便如此仍然会出现内存泄漏，野指针等问题。

托管语言们为了解决这个问题引入了GC（Garbage Collection），它们认为**内存太重要了，不能交给程序员来做**。但GC对于Native开发常常有它自己的问题。而其另一方面Native界也常常诟病GC，说**内存太重要了，不能交给机器做**。

C++提供了一种折中的解决方案，即：既不是完全交给机器做，也不是完全交给程序员做，而是程序员现在代码中指定怎么做，至于什么时候做，如何确保一定会得到执行，则交给编译器来确定。

首先是**C++98**提供了语言机制：对象在超出作用域的时候其析构函数会自动被调用。接着，C++之父Bjarne Stroustrup定义了**RAII**(Resoure Acquisition is Initialization)范式（即：对象构造的时候所需的资源应该在构造函数中初始化，而对象析构的时候应该释放资源）。**RAII 告诉我们应该应用类来封装和管理资源。**

沿着这一思想，首先要介绍的内存管理小技巧便是使用**智能指针**

## 智能指针

对于内存管理而言，Boost第一个实现了工业强度的智能指针，如今的智能指针（shared_ptr和unique_ptr)已经是**C++11**中的一部分，简单来说有了智能指针，你的C++代码几乎就不应该出现delete了。

虽然智能指针被称为”指针“，它的行为像一个指针，但本质上它其实是个类。正如前面所说的：

> RAII 告诉我们应该应用类来封装和管理资源

智能指针在对象初始化的时候获取内存的控制权，在析构的的时候自动释放内存，来正确的管理内存。

C++11中，`shared_ptr`和`unique_ptr`是最常用的两个智能指针，都需要包含头文件`<memory>`

### unique_ptr

`unique_ptr`是唯一的，适用于存储动态分配的旧C风格的数组。
在声明变量的时候，使用`auto`和`make_unique`搭配效率更高。此外，`unique_ptr`正如它的名字一样，一个资源应该只有一个`unique_ptr`进行控制，在需要转移控制权时，应该使用`std::move`，失去控制权的指针无法再继续访问资源。

```c++
#include <iostream>
#include <memory>

using namespace std;

int main()
{
    int size = 5;
    auto x1 = make_unique<int[]>(size);
    unique_ptr<int[]> x2(new int[size]);        // 两种声明unique_ptr的方式

    x1[0] = 5;
    x2[0] = 10;                                 // 像指针一样赋值

    for(int i = 0; i < size; ++i)
        cout << x1[i] << endl;                  // 输出: 5 0 0 0 0

    auto x3 = std::move(x1);                    // 转移x1的所有权
    for(int i = 0; i < size; ++i)
        cout << x3[i] << endl;                  // 输出: 5 0 0 0 0

}
```

`unique_ptr`对象在析构的时候释放所控制的资源，当发生控制权转移的时，有一种情况特别要注意，即千万不要将控制权转移给一个局部变量。因为局部变量退出作用域后会被析构，从而释放资源，此时外部再要访问一个被释放的资源时，就会出错。
下面的例子说明了这种情况

```c++
#include <iostream>
#include <memory>

using namespace std;

class A
{
public:
    A():a(new int(10))                      // 初始化a为10
    {
        cout << "Create A..." << endl;
    }

    ~A()
    {
        cout << "Destroy A..." << endl;
        delete a;                           // 释放a
    }

    int* a;
};

void move_unique_ptr_to_local_unique_ptr(unique_ptr<A>& uptr)
{
    auto y(std::move(uptr));                // 转移所有权
}                                           // 函数结束，y进行析构，便释放了A的资源

int main()
{
    auto x = make_unique<A>();
    move_unique_ptr_to_local_unique_ptr(x);

    cout << *(x->a) << endl;                  // 内存访问错误，x中的资源以及被局部变量释放了
}
```

### shared_ptr

`shared_ptr`的用法与`unique_ptr`类似。使用`auto`和`make_shared`搭配效率更高。此外，与`unique_ptr`不同的是，`shared_ptr`采用引用计数的方式管理内存，因此一个资源可以有多个`shared_ptr`同时引用，并且在引用计数为0时，释放资源（引用计数可以用`use_count`来查看）

```
void copy_shared_ptr_to_local_shared_ptr(shared_ptr<A>& sptr)
{
    auto y(sptr);                                                         // 复制shared_ptr，拥有同一片资源
    cout << "After copy, use_count : " << sptr.use_count() << endl;       // After copy, use_count : 2
}

int main()
{
    auto x = make_shared<A>();
    cout << "use_count: " << x.use_count() << endl;          // use_count: 1
    copy_shared_ptr_to_local_shared_ptr(x);
    cout << *(x->a) << endl;                                 // 内存未被释放，可以正常访问
}
```

`unique_ptr`和`shared_ptr`还可以指定如何释放内存，这大大方便了我们对文件、socket等资源的管理

```
#include <iostream>
#include <memory>

using namespace std;

void fclose_deletor(FILE* f)
{
    cout << "close a file" << endl;
    fclose(f);
}

int main()
{
    unique_ptr<FILE, decltype(&fclose_deletor)> file_uptr( fopen("abc.txt", "w"),  &fclose_deletor);
    shared_ptr<FILE> file_sptr( fopen("abc.txt", "w"),  fclose_deletor);
}
```

智能指针`unique_ptr`和`shared_ptr`利用RAII范式，为我们的内存管理提供极大的方便，但是在使用时，存在一些弊端（[C++ shared_ptr四宗罪](https://www.jianshu.com/p/f1925247c14f)），其中我觉得最令人头痛的问题就是：接口污染。

例如，我想传一个`int*`到函数中去，由于所有权在智能指针上，为了保证所有权的正确转移，我就不得不将函数的参数类型改为`unique_ptr<int>`。同样的，返回值也有类似的情况。

上述这种情况，如果在开发初期，明确所有指针都使用智能指针的话，并不是什么大问题。但是目前多数代码都是建立在旧代码的基础上，在调用旧代码时，你需要用智能指针中的`get`方法来返回所控制的资源。调用了`get`也就意味着智能指针失去了对资源的完全控制，也就是说，它再也无法保证资源的正确释放了。

## Scope Guard

RAII范式虽然好，但是还不够易用，很多时候我们并不想为了一个closeHandle，ReleaseDC等去大张旗鼓的写一个类出来；智能指针方便了我们对内存的管理，但仍属于“指针”的范畴，对非指针的资源使用起来不太方便，另外加上接口污染的问题，所以这些时候我们往往会因为怕麻烦而直接手动去释放函数，手动调的一个坏处就是，如果在资源申请和资源释放之间发生了异常，那么释放将不会发生。此外，手动释放需要在函数所有可能的出口都去调用释放函数，万一某天有人修改了代码，多了一个处`return`，而`return`之前忘记了调用释放函数，资源就泄露了。理想情况，我们希望能够这样使用：

```
#include <fstream>
using namespace std;

void foo()
{
    fstream file("abc.txt", ios::binary);
    ON_SCOPE_EXIT{ file.close() };
}
```

`ON_SCOPE_EXIT`里面的代码就像在析构函数一样：无论是以怎样的方式退出，都比如会被执行

最开始，这种`ScopeGuard`的想法被提出的时候，由于**C++没有太好的机制来支持这个想法，其实现非常的繁琐和不完美。再后来，C++11发布了，结合C++11**的Lambda Function和tr1::function就能够简化其实现

```
class ScopeGuard
{
public:
    explicit ScopeGuard(std::function<void()> onExitScope)
        : onExitScope_(onExitScope)
    { }

    ~ScopeGuard()
    {
        onExitScope_();
    }

private:
    std::function<void()> onExitScope_;

private: // noncopyable
    ScopeGuard(ScopeGuard const&) = delete;
    ScopeGuard& operator=(ScopeGuard const&) = delete;
};
```

这个类使用非常简单，你交给他一个std::function，它负责在析构的时候执行，绝大多数这个std::function是一个lambda，例如：

```
void foo()
{
    fstream file("abc.txt", ios::binary);
    ScopeGuard on_exit([&]{
        file.close();
    });
}
```

`on_exit`在析构的时候会执行`file.close`。为了避免给这个对象起名字的麻烦，可以定义一个宏，把行号混入其中，这样每次定义一个`ScopeGuard`对象都是唯一命名的：

```
#define SCOPEGUARD_LINENAME_CAT(name, line) name##line
#define SCOPEGUARD_LINENAME(name, line) SCOPEGUARD_LINENAME_CAT(name, line)
#define ON_SCOPE_EXIT(callback) ScopeGuard SCOPEGUARD_LINENAME(EXIT, __LINE__)(callback)
```

自从有了`ON_SCOPE_EXIT`之后，在C++中申请和释放资源就变得非常方便啦

```
fstream file("abc.txt", ios::binary);
ON_SCOPE_EXIT( [&] { file.close(); })

auto* x = new A()
ON_SCOPE_EXIT( [&] { delete x; })
```

这么做的好处在于申请资源和释放资源的代码紧紧的靠在一起,永远不会忘记.更不用说只要在一个地方写释放的代码,下文无论发生什么错误,导致该作用域退出,我们都能够正确的释放资源啦.

## Leaked Object Detector

内存泄露最常见的原因就是new了一个资源,忘记delete了,虽然智能指针和scope guard能够有效地帮助我们正确地释放内存,但由于种种原因和限制,还是会出现忘记释放内存的问题,如何监控没有正确释放的内存呢? 也许我们需要一个Leaked Object Detector,让它在发生泄漏的时候通知我们.

具体的,我们希望能它有这样的作用:

```
int main()
{
   auto* x = new A();
} // 报错，因为没有delete
```

在JUCE的源码中，我发现了一个`LeakedObjectDetector`类，它能够实现我们想要的。`LeakedObjectDetector`内部维护了一个计数器，在`OwnerClass`被创建时，计数器+1，`OwnerClass`析构时，计数器-1

```
template <typename OwnerClass>
class LeakedObjectDetector
{
public:
    LeakedObjectDetector() noexcept
    {
        ++(getCounter().num_objects);
    }

    LeakedObjectDetector(const LeakedObjectDetector&) noexcept
    {
        ++(getCounter().num_objects);
    }

    ~LeakedObjectDetector()
    {
        if(--(getCounter().num_objects) < 0)
        {
            cerr << "*** Dangling pointer deletion! Class: " << getLeakedObjectClassName() << endl;

            assert(false);
        }
    }

private:
    class LeakCounter
    {
    public:
        LeakCounter() = default;

        ~LeakCounter()
        {
            if(num_objects > 0)
            {
                cerr << "*** Leaked object detected: " << num_objects << " instance(s) of class" << getLeakedObjectClassName() << endl;
                assert(false);
            }
        }

        atomic<int> num_objects{0};
    };

    static const char* getLeakedObjectClassName()
    {
        return OwnerClass::getLeakedObjectClassName();
    }

    static LeakCounter& getCounter() noexcept
    {
        static LeakCounter counter;
        return counter;
    }
};
```

因为计数器是静态的，它的生命周期是从程序开始到程序结束，因此在程序结束时，计数器做析构，析构函数进行判断，如果计数器>0，说明有实例被创建但是没有释放。

另一个判断在`LeakedObjectDetector`的析构函数中，如果计数器<0，说明被delete了多次

另外只要出现了内存泄露或者多次delete,就用`assert`来强制中断

配合宏，使用起来就非常方便

```
#define LINENAME_CAT(name, line) name##line
#define LEAK_DETECTOR(OwnerClass) \
        friend class LeakedObjectDetector<OwnerClass>;  \
        static const char* getLeakedObjectClassName() noexcept { return #OwnerClass; } \
        LeakedObjectDetector<OwnerClass>  LINENAME_CAT(leakDetector, __LINE__);

class A
{
public:
    A() = default;

private:
    LEAK_DETECTOR(A);
};
```

只要用上`LEAK_DETECTOR(ClassName)`，就可以监控类的内存释放被正确释放了，例如

```
int main()
{
    auto* x = new A();
    return 0;
}
// 忘记delete，出现警告：
// *** Leaked object detected: 1 instance(s) of classA
// Assertion failed: (false), function ~LeakCounter, file /Users/hw/Development/work/leaked_object_detector/main.cpp, line 44.
int main()
{
    auto* x = new A();

    delete x;
    delete x;
    return 0;
}
// 多次delete，出现警告
// *** Dangling pointer deletion! Class: A
// Assertion failed: (false), function ~LeakedObjectDetector, file /Users/hw/Development/work/leaked_object_detector/main.cpp, line 29.
```

## 总结

在C++中，内存管理是半自动的，你需要告诉程序如何如何做，编译器保证正确做。在介绍完以上三种内存管理的技巧后，这里做一个小小的总结

- RAII告诉我们，应该用类将资源进行封装，保证类初始化时资源得到初始化，类析构时资源得到释放.因此考虑用vector这样的类来替代原生的数组指针
- 尽可能的使用智能指针,但是要注意所有权的转移
- 用scope guard来管理局部资源，它能够保证无论以什么方式退出作用域，资源都能够被正确地释放
- `LeakedObjectDetector`能够监控内存释放正确释放，在资源泄露时给出警告，如果你担心它会造成运行效率降低，那么不必要在所有类上添加它，而是当你怀疑某个类出现了内存泄漏时，再加上它