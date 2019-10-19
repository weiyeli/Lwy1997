## 需求

在图片选择器中可以标记哪些资源是在iCloud里面的，点击对应的资源，会显示下载的动画。具体可以参考这个QQ的实现：

https://jira.bytedance.com/secure/attachment/134989/iCloud.mp4

## 如何判断一个图片是在本地还是在iCloud？

https://stackoverflow.com/questions/31966571/check-given-phasset-is-icloud-asset

逸众分享的代码：

```swift
func async_isICloudImageAsset(complete:((_ isICloudImageAsset: Bool) -> Void)?) -> Void {
        var callBack = complete
        var requestid: PHAssetResourceDataRequestID?
        
        let completeBlock: ((_ isICloudImageAsset: Bool) -> Void) = { (isICloud) in
            callBack?(isICloud)
            callBack = nil
            if let requestid = requestid {
                PHAssetResourceManager.default().cancelDataRequest(requestid)
            }
        }
        
        let resourceArray = PHAssetResource.assetResources(for: self)
        guard let resouce = resourceArray.first else {
            completeBlock(false)
            return
        }
        if let number = (resouce.value(forKey: "locallyAvailable") as? NSNumber) {
            //直接取属性
            let isLocalAvailable = number.boolValue
            completeBlock(!isLocalAvailable)
        } else {
            //取属性失败，使用网络请求
            let resoureOption = PHAssetResourceRequestOptions.init()
            resoureOption.isNetworkAccessAllowed = false
            requestid = PHAssetResourceManager.default().requestData(for: resouce, options: resoureOption, dataReceivedHandler: { (data) in
                completeBlock(false)
            }) { (err) in
                if err != nil {
                    completeBlock(true)
                }
            }
        }
    }
```

