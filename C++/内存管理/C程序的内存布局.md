# C程序的内存布局

# 总述

一个典型的可执行的C语言程序在内存中应该有以下几部份组成：
（1）代码段
（2）初始化数据段（数据段）
（3）未初始化数据段（BSS段）
（4）栈
（5）堆

![memory-layout](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t67x1k7vj30dy0dcmxr.jpg)





# 代码段

代码段中存放可执行的指令，在内存中，为了保证不会因为堆栈溢出被覆盖，将其放在了堆栈段下面（从上图可以看出）。通常来讲代码段是共享的，这样多次反复执行的指令只需要在内存中驻留一个副本即可，比如C编译器，文本编辑器等。代码段一般是只读的，程序执行时不能随意更改指令，也是为了进行隔离保护。

# 初始化数据段

初始化数据段有时就称之为数据段。数据段是一个程序虚拟地址空间的一部分，包括一全局变量和静态变量，这些变量在编程时就已经被初始化。数据段是可以修改的，不然程序运行时变量就无法改变了，这一点和代码段不同。

数据段可以细分为初始化只读区和初始化读写区。这一点和编程中的一些特殊变量吻合。比如全局变量int global = 1就被放在了初始化读写区，因为global是可以修改的。而const int flag = 2就会被放在只读区，很明显，flag是不能修改的。

# 未初始化数据段

未初始化数据段有时称之为BSS段，BSS是英文Block Started by Symbol的简称，BSS段属于静态内存分配。存放在这里的数据都由内核初始化为0。未初始化数据段从数据段的末尾开始，存放有全部的全局变量和静态变量并被，默认初始化为0，或者代码中没有显式初始化。比如static int i; 或者全局int j;都会被放到BSS段。

# 栈

栈区和堆区一般相邻，但沿着相反方向增长。当栈指针和堆指针相等就说明堆栈内存耗尽。（现代大地址空间和虚拟内存技术可以将栈和堆放在任何地方，但是二者增长方向也是相反的）。栈区存放程序的栈，一种LIFO结构，一般都在内存的高地址段。在X86架构中栈地址是向0地址增长，其他一些架构中相反。栈指针寄存器记录栈顶地址，每次有值push进栈就会对栈指针进行修改。一个函数push进栈的一组值被称做堆栈帧，堆栈帧保存有返回地址的最小的返回地址。

栈中存放有自动变量和每次函数调用时的信息。每次函数调用返回地址，一些调用者环境信息（比如寄存器）都被存放在栈中。然后新调用的函数就在栈中为他们的自动或者临时变量分配内存空间，这就是C中递归函数调用的过程。每次递归函数调用自己，新的堆栈帧就被创建，这样新的变量集合就不会被其他函数实例的变量集合影响了。

# 堆

堆是动态内存分配区，堆地址起始于BSS段末端，然后从这里向高地址增长。堆中内存分配管理由malloc，remalloc和free标准库函数来完成（这些库函数的实现原理后续会讨论）。堆可以被进程的所有共享库以及动态加载模块共享。

# 例子

用size命令来看代码的内存布局，下面看一个最简单的程序：

```c
#include <stdio.h>

int main(int argc, char* argv[])
{
	printf("Hello world!\n");
	return 0;
}
```

下面编译并查看其分配内存大小

```
[root@node216 tmp]# gcc hello.c -o hello
[root@node216 tmp]# size hello
   text	   data	    bss	    dec	    hex	filename
   1156	    492	     16	   1664	    680	hello
```

增加一个全局变量global不进行初始化：

```
#include <stdio.h>
int global;
int main(int argc, char* argv[])
{
	printf("Hello world!\n");
	return 0;
}
```

编译查看分配情况：

```
[root@node216 tmp]# gcc hello.c  -o hello
[root@node216 tmp]# size hello
   text	   data	    bss	    dec	    hex	filename
   1156	    492	     24	   1672	    688	hello
```

现在对global初始化为1：

```c
#include <stdio.h>
int global=1;
int main(int argc, char* argv[])
{
	printf("Hello world!\n");
	return 0;
}
```

再看段分配：

```
[root@node216 tmp]# gcc hello.c -o hello
[root@node216 tmp]# size hello
   text	   data	    bss	    dec	    hex	filename
   1156	    496	     16	   1668	    684	hello
```

