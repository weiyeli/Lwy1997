# PhotoKit In iOS
## 什么是PhotoKit
PhotoKit是iOS 8.0后苹果提供给开发者使用管理、访问系统的图片资源和视频资源的框架。使用PhotoKit，开发者可以获取和缓存assets(资源)用来显示和播放，编辑图片和视频的内容，或者管理aseets的集合，比如相册、精彩时刻、或者共享相册。

![PhotoKit](http://ww3.sinaimg.cn/large/006tNc79gy1g4b8ftu512j30ui0i2aci.jpg)

## PhotoKit中重要的类
+ PHAsset: 单个资源，可以是照片/视频/动态图片
+ PHCollection：PHAssetCollection和PHCollectionList的抽象类
+ PHAssetCollection：PHCollection的子类，单个资源的集合，如相册、时刻等
+ PHCollectionList：PHCollection的子类，集合的集合，如相册文件夹
+ PHPhotoLibrary：类似于总管理，负责注册通知、检查和请求获取权限
+ PHImageManager：按照要求获取指定的图片的管理者
+ PHCachingImageManager：PHImageManager的子类
+ PHAssetResourceManager：专门用于Photos资源存储的管理类
+ PHAssetChangeRequest：编辑相册，增删改查
+ PHFetchResult: 一个保存PHAsset或者PHCollection的数组

**关系图**如下：

![PhotoKit](http://ww3.sinaimg.cn/large/006tNc79gy1g4b8vwzbyfj30ms0iqgo9.jpg)、

## 主要API

### PHCollection
该类有两个类方法：

```swift
// 根据指定的PHCollectionList获取PHCollection集合
class func fetchCollections(in: PHCollectionList, options: PHFetchOptions?) -> PHFetchResult<PHCollection>

// 从照片库的用户创建的相册和文件夹的层次结构中检索集合。
class func fetchTopLevelUserCollections(with: PHFetchOptions?) -> PHFetchResult<PHCollection>
```

### PHAssetCollection
一个该实例对象代表一个相册，是PHCollection的子类。它的所有属性都是只读的，另外有8个类方法，用来获取想要的结果。

```swift
class func fetchAssetCollections(with type: PHAssetCollectionType, 
								 subtype: PHAssetCollectionSubtype, 
								 options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection>
```

Demo代码：利用PHAssetCollection获取Assets资源

```swift
private func startFetch() {
    let options = PHFetchOptions()
    options.predicate = self.predicate()
    if let collect = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                             subtype: .smartAlbumUserLibrary,
                                                             options: nil).firstObject {
        fetchResult = PHAsset.fetchAssets(in: collect, options: options)
    } else {
        fetchResult = PHFetchResult<PHAsset>()
    }

    self.imageManager = PhotoScrollPickerImageManager()
    PHPhotoLibrary.shared().register(self)
}
```

该方法是该类的主要访问方法，主要用于在未知相册的情况下，直接通过type和subtype从相册获取相应的相册。type和subtype如下所示：

#### Photos type

##### PHAssetCollectionType

```swift
enum PHAssetCollectionType : Int {
    case Album       // 从 iTunes 同步来的相册，以及用户在 Photos 中自己建立的相册
    case SmartAlbum  // 经由相机得来的相册
    case Moment      // Photos 为我们自动生成的时间分组的相册
}
```

##### PHAssetCollectionSubtype

```swift
enum PHAssetCollectionSubtype : Int {
    case AlbumRegular            //用户在 Photos 中创建的相册，也就是我所谓的逻辑相册
    case AlbumSyncedEvent        //使用 iTunes 从 Photos 照片库或者 iPhoto 照片库同步过来的事件。然而，在iTunes 12 以及iOS 9.0 beta4上，选用该类型没法获取同步的事件相册，而必须使用AlbumSyncedAlbum。
    case AlbumSyncedFaces        //使用 iTunes 从 Photos 照片库或者 iPhoto 照片库同步的人物相册。
    case AlbumSyncedAlbum        //做了 AlbumSyncedEvent 应该做的事
    case AlbumImported           //从相机或是外部存储导入的相册，完全没有这方面的使用经验，没法验证。
    case AlbumMyPhotoStream      //用户的 iCloud 照片流
    case AlbumCloudShared        //用户使用 iCloud 共享的相册
    case SmartAlbumGeneric       //文档解释为非特殊类型的相册，主要包括从 iPhoto 同步过来的相册。由于本人的 iPhoto 已被 Photos 替代，无法验证。不过，在我的 iPad mini 上是无法获取的，而下面类型的相册，尽管没有包含照片或视频，但能够获取到。
    case SmartAlbumPanoramas     //相机拍摄的全景照片
    case SmartAlbumVideos        //相机拍摄的视频
    case SmartAlbumFavorites     //收藏文件夹
    case SmartAlbumTimelapses    //延时视频文件夹，同时也会出现在视频文件夹中
    case SmartAlbumAllHidden     //包含隐藏照片或视频的文件夹
    case SmartAlbumRecentlyAdded //相机近期拍摄的照片或视频
    case SmartAlbumBursts        //连拍模式拍摄的照片，在 iPad mini 上按住快门不放就可以了，但是照片依然               没有存放在这个文件夹下，而是在相机相册里。
    case SmartAlbumSlomoVideos   //Slomo 是 slow motion 的缩写，高速摄影慢动作解析，在该模式下，iOS 设备以120帧拍摄。不过我的 iPad mini 不支持，没法验证。
    case SmartAlbumUserLibrary   //这个命名最神奇了，就是相机相册，所有相机拍摄的照片或视频都会出现在该相册中，而且使用其他应用保存的照片也会出现在这里。
    case Any                    //包含所有类型
```

##### PHCollectionListType

```objective-c
typedef NS_ENUM(NSInteger, PHCollectionListType) {
    PHCollectionListTypeMomentList    = 1, // 包含了PHAssetCollectionTypeMoment类型的资源集合的列表
    PHCollectionListTypeFolder        = 2, // 包含了PHAssetCollectionTypeAlbum类型或PHAssetCollectionTypeSmartAlbum类型的资源集合的列表
    PHCollectionListTypeSmartFolder   = 3, // 同步到设备的智能文件夹的列表
} PHOTOS_ENUM_AVAILABLE_IOS_TVOS(8_0, 10_0);
```

##### PHCollectionListSubtype

```objective-c
typedef NS_ENUM(NSInteger, PHCollectionListSubtype) {
    // PHCollectionListTypeMomentList的子类型
    PHCollectionListSubtypeMomentListCluster    = 1, // 时刻
    PHCollectionListSubtypeMomentListYear       = 2, // 年度
    // PHCollectionListTypeFolder的子类型
    PHCollectionListSubtypeRegularFolder        = 100, // 包含了其他文件夹或者相簿的文件夹
    // PHCollectionListTypeSmartFolder的子类型
    PHCollectionListSubtypeSmartFolderEvents    = 200, // 包含了一个或多个从iPhone同步的事件的智能文件夹
    PHCollectionListSubtypeSmartFolderFaces     = 201, // 包含了一个或多个从iPhone同步的面孔（人物）的智能文件夹
    // 如果你不关心子类型是什么，则使用下面这个
    PHCollectionListSubtypeAny = NSIntegerMax
} PHOTOS_ENUM_AVAILABLE_IOS_TVOS(8_0, 10_0);
```

##### PHCollectionEditOperation

```objc
typedef NS_ENUM(NSInteger, PHCollectionEditOperation) {
    PHCollectionEditOperationDeleteContent    = 1, // 删除集合中包含的内容，删除的东西会永久的从照片库中删除
    PHCollectionEditOperationRemoveContent    = 2, // 移除集合中包含的内容，但移除的东西不会从照片库中删除
    PHCollectionEditOperationAddContent       = 3, // 从其他的集合中添加内容
    PHCollectionEditOperationCreateContent    = 4, // 创建新的内容或者从其他的容器中复制内容到这个容器中
    PHCollectionEditOperationRearrangeContent = 5, // 改变内容的顺序
    PHCollectionEditOperationDelete           = 6, // 删除容器但不删除内容
    PHCollectionEditOperationRename           = 7, // 重命名容器的名字
} PHOTOS_AVAILABLE_IOS_TVOS(8_0, 10_0);
```

### PHPhotoLibrary
一个单例对象，用于管理对用户照片库的访问和更改。PHPhotoLibrary代表了由Photos应用程序管理的整套媒体资源和集合，包括存储在本地设备上的asset和存储在iCould Photos中的assets(如果用户已经开启iCould)。可以通过这个对象来：
1. 获取或者验证用户对当前App访问照片内容的权限
2. 对asset和媒体资源集合进行管理，比如：编辑asset元数据或内容，插入新的asset或者重新排列集合的成员
3. 注册某个类作为当library发生改变时候的接受者

### PHFetchResult
从某个获取Aseet的方法返回的有序的asset或者collections的列表(可以理解为一个数组)

### PHAsset
该类表示具体的资源信息，如宽度、高度、时长、是否是收藏的等等。同上面提到的几个类一样，该类的属性也都是只读的，所以我们主要是用它的方法来获取资源。

```swift
// 用来判断该资源是否可以做某些操作，比如增删改查。也从另一个方面暗示了，
// 在对该资源做一些操作之前有必要先做一下判断，这可以省去一些不必要的麻烦。
func canPerform(PHAssetEditOperation) -> Bool

// 该方法是从相册中获取单个资源的主要途径
class func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions?) -> PHFetchResult<PHAsset>
```

### PHImageManager
便于检索或生成预览缩略图和asset数据的对象。

### PHAssetResourceManager
Assets可以具有多个基础数据资源 - 例如，原始版本和编辑版本 - 每个都由PHAssetResource对象表示。 与PHImageManager类不同，PHImageManager类以缩略图，图像对象或视频对象的形式提供和缓存资产的主要表示，PHAssetResourceManager提供对这些底层数据资源的直接访问。

**主要方法**

```swift
// 获取一个单例对象
class func `default`() -> PHAssetResourceManager

// 异步请求指定资产资源的基础数据
func requestData(for: PHAssetResource, 
				 options: PHAssetResourceRequestOptions?, 
				 dataReceivedHandler: (Data) -> Void, 
				 completionHandler: (Error?) -> Void) -> PHAssetResourceDataRequestID
				 
// 取消异步请求
func cancelDataRequest(PHAssetResourceDataRequestID)

// 请求Asset的基础数据，异步写入本地文件
func writeData(for: PHAssetResource, 
			   toFile: URL, 
			   options: PHAssetResourceRequestOptions?, 
			   completionHandler: (Error?) -> Void)
```

## Assets存储
Assets的存储方式主要有以下几种:

1. 利用PHAssetResourceManager进行存储
2. 利用Data进行存储
3. 利用FileManager进行存储