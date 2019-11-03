# iOS存储之沙盒存储常用方法

目前网上很多关于沙盒存储的文章，其实文章里大部分方法可能我们用不上，今天我给大家提一下重点。
开始，我们还是得说说iOS本地存储的问题，列举几种常见的SQLite、Core Data、Plist、NSUserDefault等等，但是对于图片视频等数据存储推荐还是用SQLite和Core Data 。但用起来还是比较麻烦的。沙盒比较简单，就相当于往文件夹里拖文件，只不过用代码实现而已。这里对沙盒简单说明一下，它是应用程序的文件目录机制，就相当于我们常见的系统内部文件夹一样，不过这些文件夹有不同的权限。

![alt text](https://upload-images.jianshu.io/upload_images/1648731-14267a2236996654.png?imageMogr2/auto-orient/ "title")
由上面这张图我们可以清楚地看到各部分目录的权限。说白了，正常情况下我们只操作Documents这个目录，本地存储的东西都放这里。下面我们就看具体代码了。

## 沙盒Documents路径在哪
首先我们得找到沙盒的Documents路径在哪，这个太常用了，建议直接封装一个类方法。

```
//沙盒路径
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentDirectory = [paths objectAtIndex:0];
NSLog(@"SandBoxPath--->%@",documentDirectory);
```

### 给沙盒Documents目录下添加文件夹
有时我们想给我们存储的文件分个类，放到各自的文件下（我也是有强迫症的），那么我们可以在Documents目录下新建一个目录。

```
//创建目录
NSString *createPath = [NSString stringWithFormat:@"%@/Image", documentDirectory];

// 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        RZLog(@"FileImage is exists.");
    }
```

### 删除目录
可能你的APP上有清除缓存的功能，那么把你的目录删掉就相当于清除缓存了；但你需要注意的是，这时候你的目录结构被破坏了，你如果要把你的文件保存在你所创建的目录下，这时候就不可行了，你需要重新创建一下目录。

```
NSFileManager * fileManager = [[NSFileManager alloc]init];
[fileManager removeItemAtPath: createPath error:nil]
```

## c存储文件至目录下
有了目录，我们就可以把文件丢到对应的目录下

```
sandBoxFilePath = [createPath stringByAppendingPathComponent:filename];
[fileData writeToFile:sandBoxFilePath atomically:YES];
```
这里需要解释一下，这里filename是一个标识，最好加上文件的后缀，例如图片加“.png”,视频加“.mp4”,方便你取时能够找到，名字部分随意，什么随机数、什么英文随便你。怎么随便怎么来，只要你能找到。
fileData 是文件的NSData，在上一节我已经将视频和图片的NSData获取方式拿出来了。

## 读取文件
最后就是文件的读取了

### 图片你就这样拿
`cell.imageView.image = [UIImage imageWithContentsOfFile:sandBoxFilePath];`
### 视频你就这样拿
```
MPMoviePlayerViewController* playerView = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:sandBoxFilePath]];
```

### 结语
我们常用的方法大致都放在这了，其他的方法大家百度还是可以找到的，我只是总结自己比较常用的。文中有不对的或者描述不详细的欢迎大家指点，我会积极改正的。

