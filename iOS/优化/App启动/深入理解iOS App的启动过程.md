# 背景

众所周知：App的启动时间是衡量App品质的重要指标之一。本文首先会从原理出发，讲解iOS系统是如何启动App的，然后从main函数之前和main函数之后两个角度去分析如何优化启动时间。

## 背景知识

### Mach-O

哪些名词指的是Mach-o

+ Executable 可执行文件
+ Dylib 动态库
+ Bundle 无法被连接的动态库，只能通过dlopen()加载
+ Image 指的是Executable，Dylib或者Bundle的一种，文中会多次使用Image这个名词。
+ Framework 动态库(可以是静态库)和对应的头文件和资源文件的集合

Apple出品的操作系统的可执行文件格式几乎都是mach-o，iOS当然也不例外。
mach-o的组成可以大致的分为三部分：

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t51ukd6fj30pe0rs40e.jpg)

+ Header 头部，包含可以执行的CPU架构，比如x86,arm64
+ Load commands 加载命令，包含文件的组织架构和在虚拟内存中的布局方式
+ Data，数据，包含load commands中需要的各个段(segment)的数据，每一个Segment都得大小是Page的整数倍。

我们用MachOView打开Demo工程的可以执行文件，来验证下mach-o的文件布局：


图中分析的mach-o文件来源于PullToRefreshKit，这是一个纯Swift的编写的工程。

那么Data部分又包含哪些segment呢？绝大多数mach-o包括以下三个段（支持用户自定义Segment，但是很少使用）

+ __TEXT代码段，只读，包括函数，和只读的字符串，上图中类似__TEXT ,__text的都是代码段
+ __DATA数据段，读写，包括可读写的全局变量等，上图中类似__DATA，__data都是数据段
+ __LINKEDIT，包含了方法和变量的元数据(位置，偏移量)，以及代码签名等信息

关于mach-o更多细节，可以看看文档：《[Mac OS X ABI Mach-O File Format Reference](https://github.com/LeoMobileDeveloper/React-Native-Files/blob/master/Mac OS X ABI Mach-O File Format Reference.pdf)》。

### dyld

> dyld的全称是[dynamic loader](https://developer.apple.com/library/content/releasenotes/DeveloperTools/RN-dyld/)，它的作用是加载一个进程所需要的image，dyld是[开源的](https://opensource.apple.com/source/dyld/)。

## Virtual Memory
虚拟内存是在物理内存上建立的一个逻辑地址空间，它向上（应用）提供了一个连续的逻辑地址空间，向下隐藏了物理内存的细节。
虚拟内存使得逻辑地址可以没有实际的物理地址，也可以让多个逻辑地址对应到一个物理地址。
虚拟内存被划分为一个个大小相同的Page（64位系统上是16KB），提高管理和读写的效率。 Page又分为只读和读写的Page。

虚拟内存是建立在物理内存和进程之间的中间层。在iOS上，当内存不足的时候，会尝试释放那些只读的Page，因为只读的Page在下次被访问的时候，可以再从磁盘读取。如果没有可用内存，会通知在后台的App（也就是在这个时候收到了memory warning），如果在这之后仍然没有可用内存，则会杀死在后台的App。

## Page fault
在应用执行的时候，它被分配的逻辑地址空间都是可以访问的，当应用访问一个逻辑Page，而在对应的物理内存中并不存在的时候，这时候就发生了一次Page fault。当Page fault发生的时候，会中断当前的程序，在物理内存中寻找一个可用的Page，然后从磁盘中读取数据到物理内存，接着继续执行当前程序。

## Dirty Page & Clean Page
如果一个Page可以从磁盘上重新生成，那么这个Page称为Clean Page
如果一个Page包含了进程相关信息，那么这个Page称为Dirty Page
像代码段这种只读的Page就是Clean Page。而像数据段(_DATA)这种读写的Page，当写数据发生的时候，会触发COW(Copy on write)，也就是写时复制，Page会被标记成Dirty，同时会被复制。

想要了解更多细节，可以阅读文档：[Memory Usage Performance Guidelines](https://developer.apple.com/library/content/documentation/Performance/Conceptual/ManagingMemory/ManagingMemory.html#//apple_ref/doc/uid/10000160-SW1)

## 启动过程

使用dyld2启动应用的过程如图：

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t6tvbjacj311s0bk3z8.jpg)

大致的过程如下：

> 加载dyld到App进程
> 加载动态库（包括所依赖的所有动态库）
> Rebase
> Bind
> 初始化Objective C Runtime
> 其它的初始化代码

### 加载动态库

> dyld会首先读取mach-o文件的Header和load commands。
> 接着就知道了这个可执行文件依赖的动态库。例如加载动态库A到内存，接着检查A所依赖的动态库，就这样的递归加载，直到所有的动态库加载完毕。通常一个App所依赖的动态库在100-400个左右，其中大多数都是系统的动态库，它们会被缓存到dyld shared cache，这样读取的效率会很高。

查看mach-o文件所依赖的动态库，可以通过MachOView的图形化界面(展开Load Command就能看到)，也可以通过命令行otool。

