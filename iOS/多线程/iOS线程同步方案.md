---
title: {{ iOS线程同步方案 }}
date: {{ 2019年08月15日15:05:39 }}
top: false
cover: false
password:
toc: true
mathjax: true
summary:
tags:iOS
categories:iOS
---

# iOS线程同步方案

## 锁

### OSSpinLock

#### 简介

1. OSSpinLock叫做 "自旋锁"，等待锁的线程会处于忙等（busy-wait）状态，一直占用着CPU资源
2. 目前已经不再安全，可能会出现优先级反转问题
3. 如果等待锁的线程优先级较高，它会一直占用着CPU资源，优先级低的线程就无法释放锁
4. 需要导入头文件#import <libkern/OSAtomic.h>

#### API

```objective-c
//初始化锁
OSSpinLock lock = OS_SPINLOCK_INIT;
// 尝试加锁(如果需要等待就不加锁，直接返回false；如果不需要等待就加锁，返回true)
bool result = OSSpinLockTry(&lock);
//加锁
OSSpinLockLock(&lock);
//解锁
OSSpinLockUnlock(&lock);
```

### os_unfair_lock

#### 简介

1. os_unfair_lock用于取代不安全的OSSpinLock ，从iOS10开始才支持
2. 从底层调用看，等待os_unfair_lock锁的线程会处于休眠状态，并非忙等
3. 需要导入头文件#import <os/lock.h>

#### API

```objective-c
// 初始化锁
os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
// 尝试加锁
os_unfair_lock_trylock(&lock);
// 加锁
os_unfair_lock_lock(&lock);
// 解锁
os_unfair_lock_unlock(&lock);
```

### pthread_mutex

#### 简介

1. mutex叫做 "互斥锁"，等待锁的线程会处于休眠状态
2. 需要导入头文件#import <pthread.h>

#### API

