# iOS视频压缩存储至本地并上传至服务器

这里关于视频转码存储我整理了两个方法，这两个方法都是针对相册内视频进行处理的。

1、该方法没有对视频进行压缩，只是将视频原封不动地从相册拿出来放到沙盒路径下，目的是拿到视频的NSData以便上传####
这里我传了一个URL，这个URL有点特别，是相册文件URL，所以我说过只针对相册视频进行处理

```
    //将原始视频的URL转化为NSData数据,写入沙盒
    + (void)videoWithUrl:(NSString *)url withFileName:(NSString *)fileName
    {
          ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            if (url) {
             [assetLibrary assetForURL:[NSURL URLWithString:url] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *imagePath = [NSString stringWithFormat:@"%@/Image", pathDocuments];
            NSString *dbFilePath = [imagePath stringByAppendingPathComponent:fileName];
            char const *cvideoPath = [dbFilePath UTF8String];
            FILE *file = fopen(cvideoPath, "a+");
            if (file) {
                const int bufferSize = 11024 * 1024;
                // 初始化一个1M的buffer
                Byte *buffer = (Byte*)malloc(bufferSize);
                NSUInteger read = 0, offset = 0, written = 0;
                NSError* err = nil;
                if (rep.size != 0)
                {
                    do {
                        read = [rep getBytes:buffer fromOffset:offset length:bufferSize error:&err];
                        written = fwrite(buffer, sizeof(char), read, file);
                        offset += read;
                    } while (read != 0 && !err);//没到结尾，没出错，ok继续
                }
                // 释放缓冲区，关闭文件
                free(buffer);
                buffer = NULL;
                fclose(file);
                file = NULL;
            }
        } failureBlock:nil];
    }
});
}
```

2、推荐使用该方法，该方法对视频进行压缩处理，压缩的程度可调####
这里我传的是模型过去，将我的URL带过去的，然后压缩完毕用模型把NSData带出来，数据大家根据自己需求自由发挥

```
+ (void) convertVideoWithModel:(RZProjectFileModel *) model
{
    model.filename = [NSString stringWithFormat:@"%ld.mp4",RandomNum];
    //保存至沙盒路径
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *videoPath = [NSString stringWithFormat:@"%@/Image", pathDocuments];
    model.sandBoxFilePath = [videoPath stringByAppendingPathComponent:model.filename];
    
    //转码配置
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:model.assetFilePath options:nil];
    AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = [NSURL fileURLWithPath:model.sandBoxFilePath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
         int exportStatus = exportSession.status;
        RZLog(@"%d",exportStatus);
        switch (exportStatus)
        {
            case AVAssetExportSessionStatusFailed:
            {
                // log error to text view
                NSError *exportError = exportSession.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                break;
            }
            case AVAssetExportSessionStatusCompleted:
            {
                RZLog(@"视频转码成功");
                NSData *data = [NSData dataWithContentsOfFile:model.sandBoxFilePath];
                model.fileData = data;
            }
        }
        }];

}
```
在这里你可以修改压缩比例，苹果官方都封装好了，根据需求调整

```
AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
在这里修改输出类型，正常情况下选MP4不会有什么问题的

exportSession.outputFileType = AVFileTypeMPEG4;
Mark一下图片压缩用这个，image是图片，0.4是比例，大小可调

model.fileData = UIImageJPEGRepresentation(image, 0.4);
这样你就很愉快地拿到转码过后的NSData了，然后播放一下试试

 MPMoviePlayerViewController* playerView = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:sandBoxFilePath]];
[superVC presentViewController:playerView animated:YES completion:nil];
```

### 备注一下
可以发现我这里使用了沙盒存储，在下一节我整理一下用代码管理应用沙盒。

# 更新
最近发现好多人联系我，问我要Demo，最近我也整理了一下，目前挂在github上，望大神们指正。https://github.com/Snoopy008/SelectVideoAndConvert
（如果我的代码对你有帮助，请你不忘在github上给我个Star，谢谢）。

# 2017-3-23
偶然间帮一位好友看代码，发现了一个更简单的获取本地视频的NSData的方法，大家自己看，我就不解释了。代码放在github上https://github.com/Snoopy008/videoData