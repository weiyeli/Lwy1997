# UITableView(一)
## 官方解释
### UITableView
单列一行一行显示数据的视图(A view that presents data using rows arranged in a single column)。UITableView是UIScrollView的子类，但是UITableView只允许纵向滚动。TableView中各个项的单元格是UITableViewCell对象，cells具有内容标题和图像并且可以在右边缘附近具有附件视图。

#### Section
TableView由零个或多个section组成，每个section都有自己的行。section在表视图中由其索引号标识，行由section中的索引号标识。 

#### 样式
TableView有两种样式

1. UITableView.Style.plain
2. UITableView.Style.grouped

当你创建一个UITableView实例必须指定其的style，并且这种style是不能被改变的。

plain样式参考iOS通讯录，grouped样式参考iOS设置

[UITableView.Style.plain和UITableView.Style.grouped的区别](http://www.hangge.com/blog/cache/detail_1598.html)

#### NSIndexPath
TableView的很多方法都使用NSIndexPath作为参数和返回值，可以通过section索引和row索引获取到索引路径，特别是在有多个section的TableView中，必须先求出section的值。

#### UITableViewDataSource
一个TableView对象必须具有充当数据源的对象。数据源提供UITableView在插入，删除或重新排序表的行时构造表和管理数据模型所需的信息。（The data source provides information that UITableView needs to construct tables and manages the data model when rows of a table are inserted, deleted, or reordered. ）

#### UITableViewDelegate
一个TableView对象必须具有充当委托的对象。委托管理表行配置和选择，行重新排序，突出显示，附件视图和编辑操作。（The delegate manages table row configuration and selection, row reordering, highlighting, accessory views, and editing operations.）

#### 常用方法
```
setEditing(_:animated:)              // 进入编辑模式
tableView(_:commit:forRowAt:).       // 右侧出现删除的默认样式
deleteRows(at:with:)  							 // 删除行
insertRows(at:with:)					       // 插入行
tableView(_:canMoveRowAt:)				   // 允许重排序 
```

### UITableViewCell
[对于Cell的更详细的解释](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/TableView_iPhone/TableViewCells/TableViewCells.html#//apple_ref/doc/uid/TP40007451-CH7)

UITableViewDataSource的实现对象通过`tableView:cellForRowAtIndexPath:`方法提供cell对象


