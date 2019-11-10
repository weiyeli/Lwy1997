# iOS逆向入门实战

## 砸壳

### 什么是壳？

加壳就是利用特殊的算法，对可执行文件的编码进行改变（比如压缩、加密），以达到保护程序代码的目的。从 App Store 下载的 App 会被 Apple 使用 FairPlay 技术加密，使得程序无法在其他未登录相同 AppleID 的设备上运行，起到 DRM 的作用。

### 脱壳的大致原理：

iOS/macOS 系统中，可执行文件、动态库等，都使用 DYLD 加载执行。在 iOS 系统中使用 DYLD 载入 App 时，会先进行 DRM 检查，检查通过则从 App 的可执行文件中，选择适合当前设备架构的 Mach-O 镜像进行解密，然后载入内存执行。dumpdecrypted 等脱壳工具，就是利用这一原理，从内存中将已解密的镜像 “dump” 出来，再生成新的镜像文件，从而达到解密的效果。

![1](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2a33bwmj30zc0oe41a.jpg)

- 静态脱壳：怎么加密就用相应的方法解密

- 动态脱壳：绕开加密过程，让MachO加载到内存，从而dump出镜像。

## 主流的方法有以下：

- Clutch砸壳

- frida-ios-dump砸壳

- dumpdecrypted砸壳

以上三种都试过了，都有很多坑要踩，而且最后只有frida-ios-dump成功砸壳了。

## 前提条件

越狱机（当前用的是12.1的版本，只能不完美越狱）

越狱机器通过Cydia安装OpenSSH，就可以在Mac通过ssh访问手机。

### [Clutch](https://github.com/KJCracks/Clutch)

1. 方法是先下载Clutch的[二进制文件](https://github.com/KJCracks/Clutch/releases)。

1. 然后通过SSH拷贝到手机的 /usr/bin 文件夹中。

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2ojskiyj30xc052ac7.jpg)

1. 给Clutch开权限

```
chmod +x Clutch
```

1. 使用Clutch -i可以查看所有APP的名称以及对应的bundle id。

1. 如果出现Killed: 9，可以使用以下方式解决这个问题

```
# safe place to work in
cd /private/var/mobile/Documents
# Get the ent from bash and save it
ldid -e `which bash` > ent.xml
# sign Clutch with the ent. "-Sent.xml" is the correct usage
```

`ldid -Sent.xml `which Clutch``

```
# inject into trust cache
```

`inject `which Clutch``

1. 使用以下命令进行砸壳，如果砸壳成功，则会显示生成的ipa所在的目录

```
Clutch -d --dump <value>        Dump specified bundleID into .ipa file 
```

测试了几个APP后一直会报could not obtain mach port either the process is dead这个问题，导致无法dump出ipa，在github的issue上也没有找到相应的方法来解决。估计是因为iOS12.1版本比较新的问题，没有做很好的兼容。所以放弃这个方式。

### dumpdecrypted

https://github.com/stefanesser/dumpdecrypted

使用这个工具需要ssh到自己手机，将dumpdecrypted.dylib放到需要砸壳的APP的沙盒路径。

先root到自己手机，执行以下命令：

```
ps -e //(打印所有进程,找到目标app)
cycript -p TargetApp // 附加该进程 
cy# [[NSFileManager defaultManager ] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]      // 利用cy语言找到目标app的沙盒路径
//将dumpdecrypted.dylib放入到指定的沙盒路径后执行
DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib /var/containers/Bundle/Application/0E619483-4AC3-430E-AADB-AD2B164FF1B3/Eyepetizer.app/Eyepetizer
```

不过问题就出在cycript -p TargetApp // 附加该进程 。iOS11以后在Cydia无法下载Cycript插件。所以执行cycript后会出现-sh: cycript: command not found。

代替方案是使用bfinject。具体方式参考：http://www.gandalf.site/2019/05/ios-bfinject-ios11cycript.html。个人感觉太过繁琐，估计还有很多坑，所以也没有使用这个方案。（有兴趣的可以试试）

镜像的操作原理可以参考这一篇：https://www.tylinux.com/2018/03/12/how-dumpdecrypted-dylib-works/

### frida-ios-dump

号称是操作最简单的，其实要做的还是有坑多坑。

1. 首先是在越狱机上面的操作。

需要在越狱机上面添加cydia源：http://build.frida.re 

通过刚才的源添加Frida。

然后通过命令frida-ps -U测试下。显示了手机上的进程则证明安装成功了

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2ohelgaj30as0rn77d.jpg)

1. MAC端需要clone Frida的工程下来。通过py脚本给APP注入js代码。具体步骤：

- 安装pip，用于安装python的包

```
wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
```

- 安装matplotlib。

```
sudo pip install matplotlib
```

- 安装usbmuxd（用于USB实现TCP多路协议）

```
brew install usbmuxd
```

- 安装Frida (一款基于python + javascript 的hook与调试框架，它允许你将 JavaScript 的部分代码或者你自己的库注入到 windows、macos、linux、iOS、Android，以及 QNX 的原生应用中，同时能完全访问内存和功能。)

```
sudo pip install frida --ignore-installed six -i http://pypi.douban.com/simple/--trusted-host pypi.douban.com
```

- 安装frida-dump-iOS

```
sudo mkdir /opt/dump && cd /opt/dump && sudo git clonehttps://github.com/AloneMonkey/frida-ios-dump
```

- 安装脚本依赖环境

```
sudo pip install -r /opt/dump/frida-ios-dump/requirements.txt --upgrade
```

- 修改dump.py参数 (如果都是默认的话可以省略)

```
open /opt/dump/frida-ios-dump/dump.py
```

``

```
User = 'root'
Password = 'alpine'
Host = 'localhost'
Port = 2222
```

- 设置别名（可以省略）

```
在终端输入：
open ~/.bash_profile
在末尾新增下面一段：alias dump.py="/opt/dump/frida-ios-dump/dump.py"
```



1. 开始砸壳

```
//先代理到自己的手机22端口
iproxy 2222 22
// 新建窗口
ssh -p 2222 root@127.0.0.1
// 确保执行脚本的python版本跟Frida支持的python版本一致。master使用的是python2.7
dump.py -l  //查看需要砸壳的应用。
dump.py //应用名或bundle id进行砸壳.
```

！！坑：

出现：

```
Traceback (most recent call last):
File "./dump.py", line 19, in 
import paramiko
ImportError: No module named paramiko
```

一般解决方式是：sudo pip install paramiko

安装之后也依旧报错。

解决方式是切换到frida-ios-dump 的3.x 分支，使用python3.x版本可以解决。

砸壳成功后：

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2mmfyrsj30xc04rwg5.jpg)

## class-dump获取头文件

可以用来查看某个APP头文件。需要砸壳后的app。先下载class-dump，导入到/usr/local/bin。然后执行sudo chmod 777/usr/local/bin/class-dump。就可以直接使用。

导出头文件的命令：

```
class-dump -H [xxx.app所在的位置] -o [头文件导出的位置]
```

## otool分析动态库

依赖库查询：

```
otool -L [可执行文件]
```

需要砸壳后的MachO文件，使用这个命令后就可以输出相关的动态库。

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2ocw2zdj30xc0g2qhd.jpg)

**查看该应用是否砸壳**

```
otool -l [可执行文件] | grep -B 2 crypt
```

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2oaxmsjj30xc04rgmx.jpg)

cryptid 0（砸壳） 1（未砸壳）

## Reveal分析UI层级

Reveal工作原理很简单的，就是在指定工程里引用并加载 Reveal.framework 文件，这样就能通过这个动态库提供的能力查看系统层级。

使用的方式有下面三种：

- 如果是自己的工程，很简单，直接pod install Reveal-SDK就可以了

- 如果是他人的APP，越狱机上调试，也很容易。现在越狱机上安装OpenSSH，Reveal2Loader。接着设置Reveal2Loader的Enable Applications，选中需要Reveal的应用。接着启动Reveal就可以使用了。注意的是，手机里的Reveal的动态库版本需要跟着Reveal的版本走，如果版本不相同，则需要scp一个Reveal的framework到手机里的指定目录/Library/MobileSubstrate/DynamicLibraries/。然后重启设备。

- 如果是他人的APP，然后又没有越狱机，只能通过一个砸壳后的ipa，然后配合[**MonkeyDev**](https://github.com/AloneMonkey/MonkeyDev)使用。

## Hopper分析符号表

## MachO

结构如下：

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2o7tbxpj30rq1gm7fp.jpg)

主要有以下4部分：

Header （头部）

LoadCommands （加载命令）：告诉loader如何加载二进制

Data （数据段 segment）：存放代码，类，方法（Text段）和字符常量（Data段）等

Loader Info （链接信息）：例如有符号表，签名信息等

内存静态分配的主要区域：

![img](https://tva1.sinaimg.cn/large/006y8mN6gy1g8t2o4tsvkj30xc088q3g.jpg)

## 参考文档

https://www.jianshu.com/p/6eb62eabb988

[https://blog.aberlt.com/2017/12/14/%E8%AE%B0%E7%A0%B8%E5%A3%B3%E5%B7%A5%E5%85%B7-frida-ios-dump-%E7%9A%84%E4%BD%BF%E7%94%A8/](https://blog.aberlt.com/2017/12/14/记砸壳工具-frida-ios-dump-的使用/)