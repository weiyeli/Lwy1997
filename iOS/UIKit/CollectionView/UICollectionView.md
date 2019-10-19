# UICollectionView
## 官方解释
一个管理有序数据项集合并使用可自定义布局呈现它们的对象。

## UICollectionViewLayout
UICollectionViewLayout是UICollectionView比UITableView强大的原因，通过 UICollectionViewLayoutAttributes类来管理 cell 、 Supplementary View 和 Decoration View的位置、transform、alpha、hidden等等。
UICollectionViewLayout这个类只是一个基类，我们给UICollectionView使用的都是它的子类 。系统为我们提供了一个最常用的layout为 UICollectionViewFlowLayout。当UICollectionViewLayout满足不了我们的需求时，我们可以 子类化UICollectionViewLayout或者自定义layout。

我们先来了解它内部的常用的属性：

```
//同一组当中，行与行之间的最小行间距，但是不同组之间的不同行cell不受这个值影响。
var minimumLineSpacing: CGFloat { get set }
//同一行的cell中互相之间的最小间隔，设置这个值之后，那么cell与cell之间至少为这个值
var minimumInteritemSpacing: CGFloat { get set }
//每个cell统一尺寸
var itemSize: CGSize { get set }
//滑动反向，默认滑动方向是垂直方向滑动
var scrollDirection: NSCollectionView.ScrollDirection { get set }
//每一组头视图的尺寸。如果是垂直方向滑动，则只有高起作用；如果是水平方向滑动，则只有宽起作用。
var headerReferenceSize: NSSize { get set }
//每一组尾部视图的尺寸。如果是垂直方向滑动，则只有高起作用；如果是水平方向滑动，则只有宽起作用。
var footerReferenceSize: NSSize { get set }
//每一组的内容缩进
var sectionInset: UIEdgeInsets { get set }
```

## 示例代码
```
import UIKit
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 80, height: 80)
        
        let myCollectionView:UICollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        myCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        myCollectionView.backgroundColor = UIColor.white
        self.view.addSubview(myCollectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
        myCell.backgroundColor = UIColor.blue
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        print("User tapped on item \(indexPath.row)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
```

## 视图
UICollectionView上面显示内容的视图有三种
1. Cell视图
2. Supplementary View
3. Decoration View。

**Cell视图**

CollectionView只要内容由他展示数据从数据源获取出来，类似于UITableView中的cell；

**Supplementary View**

他展示的是每一组的信息类似于cell，他也是从数据员获取的数据，但是与cell有一点不同，他并不是强烈需要的。如flow layout中的header 和 footer；

**Decoration View**

这个视图是一个装饰视图，它没有什么功能性，它不跟数据源有任何关系，它完全属于layout对象。

## 数据源和代理方法
**注册cell**

在使用数据源返回cell给collectionView之前，我们必须先要注册，用来进行重用。

```
registerClass: forCellWithReuseIdentifier:
registerNib: forCellWithReuseIdentifier:
```
显而易见，前面两个方法是注册cell，其中，注册的方式有两种，第一种是直接注册class，它重用的时候会调用[[UICollectionView alloc] init]这样的初始化方法创建cell；另外一种是注册nib，它会自动加载nib文件。
注册的之后，我们如何重用？在数据源方法当中返回 cell的方法当中通过`dequeueReusableCellWithReuseIdentifier:forIndexPath:`方法获取cell。

**数据源方法**

数据源方法与UITableView类似，主要有：

```
numberOfSectionsInCollectionView:
collectionView: numberOfItemsInSection:
collectionView: cellForItemAtIndexPath:
collectionView: viewForSupplementaryElementOfKind: atIndexPath:
```

**代理方法**

数据源为UICollectionView提供数据相关的内容，而代理则主要负责用户交互、与数据无关的视图外形。主要分成两部分：

**通过调用代理方法，管理视图的选中、高亮**

```
collectionView:shouldDeselectItemAtIndexPath:
collectionView:didSelectItemAtIndexPath:
collectionView:didDeselectItemAtIndexPath:
collectionView:shouldHighlightItemAtIndexPath:
collectionView:didHighlightItemAtIndexPath:
collectionView:didUnhighlightItemAtIndexPath:
```

**长按cell，显示编辑菜单 当用户长按cell时，collection view视图会显示一个编辑菜单。这个编辑菜单可以用来剪切、复制和粘贴cell。不过，要显示这个编辑菜单需要满足很多条件，代理对象必须实现下面三个方法：**

```
collectionView:shouldShowMenuForItemAtIndexPath:
collectionView:canPerformAction:forItemAtIndexPath:withSender:
collectionView:performAction:forItemAtIndexPath:withSender:
```

对于指定要编辑的cell，`collectionView:shouldShowMenuForItemAtIndexPath:`
方法需要返回YES

`collectionView:canPerformAction:forItemAtIndexPath:withSender:`
方法中，对于剪切、复制、粘贴三种action至少有一个返回YES。其实，编辑菜单是有很多种action的，但是对于UICollectionView来说，它仅仅支持的剪切、复制、粘贴三个，所以说这个代理方法至少支持这三种的一种。
剪切、复制、粘贴的方法名是：

```
cut:
copy:
paste:
```

当上面的条件都满足了，用户就可以长按cell显示出编辑菜单，然后选择对应的action，从而就会回调delegate的`collectionView:performAction:forItemAtIndexPath:withSender: `方法去做对应的事情。
当我们想控制编辑菜单仅仅显示复制和粘贴时，我们就可以在`collectionView:canPerformAction:forItemAtIndexPath:withSender:`
方法中进行操作。

## 参考教程

https://www.raywenderlich.com/9334-uicollectionview-tutorial-getting-started

https://www.raywenderlich.com/9477-uicollectionview-tutorial-reusable-views-selection-and-reordering