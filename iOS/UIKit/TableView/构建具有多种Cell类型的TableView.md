# 构建具有多种Cell类型的TableView

## 前言

TableView是iOS开发中最为常用的组件，iPhone手机的屏幕尺寸有限，所以对于数据的展现不可避免的使用TableView这种滑动的方式。在毕业设计的开发中，遇到一个问题，在一个TableView中需要展示不同类型的Cell，Cell的样式不同。

![image-20190425170519690](https://ws3.sinaimg.cn/large/006tNc79gy1g2ezo60tn0j30m61be41k.jpg)

![image-20190425170620847](https://ws4.sinaimg.cn/large/006tNc79gy1g2ezp87ohzj30ne1bg43n.jpg)

这样我们在TableView的代理方法中需要加入很多的逻辑判断，如下：

```swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
   if indexPath.row == 0 {
        //configure cell type 1
   } else if indexPath.row == 1 {
        //configure cell type 2
   }
   ....
}
```

同样的，numberOfRowsInSection也是同样的会出现这样的代码，因为医生和患者同一个section的number不同：

```swift
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return settings.count - 2
        } else {
            return 1
        }
    }
```

