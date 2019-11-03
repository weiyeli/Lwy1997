# CMTime in iOS
## 官方定义
在iOS平台上使用iOS8及以上系统的VideoToolbox进行硬编码，会涉及到CMTime，CMTimeMake，CMTimeMakeWithSeconds的使用。下面说下这几个结构体的作用。

CoreMedia.framework的CMTime.h中CMTime，CMTimeMake，CMTimeMakeWithSeconds的定义如下

> http://developer.apple.com/library/mac/#documentation/CoreMedia/Reference/CMTime/Reference/reference.html）

**CMTime**

```
/*!
	@typedef	CMTime
	@abstract	Rational time value represented as int64/int32.
*/
typedef struct
{
	CMTimeValue	value;		/*! @field value The value of the CMTime. value/timescale = seconds. */
	CMTimeScale	timescale;	/*! @field timescale The timescale of the CMTime. value/timescale = seconds.  */
	CMTimeFlags	flags;		/*! @field flags The flags, eg. kCMTimeFlags_Valid, kCMTimeFlags_PositiveInfinity, etc. */
	CMTimeEpoch	epoch;		/*! @field epoch Differentiates between equal timestamps that are actually different because
												 of looping, multi-item sequencing, etc.  
												 Will be used during comparison: greater epochs happen after lesser ones. 
												 Additions/subtraction is only possible within a single epoch,
												 however, since epoch length may be unknown/variable. */
} CMTime;
```

**CMTimeMake**

```
/*!
	@function	CMTimeMake
	@abstract	Make a valid CMTime with value and timescale.  Epoch is implied to be 0.
	@result		The resulting CMTime.
*/
CM_EXPORT 
CMTime CMTimeMake(
				int64_t value,		/*! @param value		Initializes the value field of the resulting CMTime. */
				int32_t timescale)	/*! @param timescale	Initializes the timescale field of the resulting CMTime. */
							__OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);
```

**CMTimeMakeWithSeconds**

```
/*!
    @function    CMTimeMakeWithSeconds
    @abstract    Make a CMTime from a Float64 number of seconds, and a preferred timescale.
    @discussion    The epoch of the result will be zero.  If preferredTimeScale is <= 0, the result
                will be an invalid CMTime.  If the preferred timescale will cause an overflow, the
                timescale will be halved repeatedly until the overflow goes away, or the timescale
                is 1.  If it still overflows at that point, the result will be +/- infinity.  The
                kCMTimeFlags_HasBeenRounded flag will be set if the result, when converted back to
                seconds, is not exactly equal to the original seconds value.
    @result        The resulting CMTime.
*/
CM_EXPORT 
CMTime CMTimeMakeWithSeconds(
                Float64 seconds,
                int32_t preferredTimeScale)
                            __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);
```

## 示例代码

```
CMTime firstframe=CMTimeMake(1,10);		    // 第一帧
CMTime lastframe=CMTimeMake(10, 10);		// 最后一帧
```

CMTime是专门用来表示影片事件用的类别，用法为：CMTimeMake(time, timeScale)。其中，time指的是第几帧，而不是秒，而时间要换算成秒，此时就要用到第二个参数timeScale。timeScale指的是1秒需要有几个frame构成（可以看作为fps），因此真正要表达的时间就是 time/timeScale，才会是秒。

上面的代码可以理解为，视频的fps（帧率）是10，firstframe是第一帧，在视频中的时间为0.1秒，lastframe是第10帧，在视频中的时间为1秒。

```
firstframe=CMTimeMake(32，16);
CMTime lastframe=CMTimeMake(48, 24); 
```

这两个都表示2秒的时间。但是帧率是完全不同的。

CMTimeMakeWithSeconds和CMTimeMake区别在于，第一个函数的第一个参数可以是float，其他一样。

以上解释的比较清楚了，为加深印象，可看下stackoverflow上[Trying to understand CMTime](https://stackoverflow.com/questions/12902410/trying-to-understand-cmtime)一文。

## 综述

```
CMTimeMake(a,b)                   // a当前第几帧, b每秒钟多少帧.当前播放时间a/b
CMTimeMakeWithSeconds(a,b)        // a当前时间,b每秒钟多少帧.
```