# 什么是序列图( Sequence Diagram)？

## 前言

UML Sequence Diagrams是交互图，详细说明了如何执行操作。 它们捕获协作环境中对象之间的交互。 序列图是时间焦点，它们通过使用图表的垂直轴来直观地显示交互的顺序，以表示消息的发送时间和时间。

![Sequence Diagram in UML Diagram Hierarchy](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/sequence-diagram-in-uml-diagram-hierarchy.png)

序列图捕获：

+ 在实现用例或操作的协作中发生的交互（实例图或通用图）
+ 系统用户与系统之间，系统与其他系统之间或子系统之间的高级交互（有时称为系统序列图）

## 序列图的目的

+ 模拟系统中生成的对象之间的高级交互
+ 对实现用例的协作中的对象实例之间的交互建模
+ 对实现操作的协作中的对象之间的交互建模
+ 模拟通用交互（显示通过交互的所有可能路径）或交互的特定实例（仅显示交互中的一条路径）

## 初识序列图

序列图显示元素随着时间的推移而相互作用，它们根据对象（水平）和时间（垂直）组织：

### 对象维度
+ 横轴表示交互中涉及的元素
+ 传统上，操作中涉及的对象根据它们何时参与消息序列从左到右列出。 但是，横轴上的元素可以按任何顺序出现

### 时间维度

纵轴表示页面下的时间进程（或进展）。

> 注意：序列图中的时间都是关于排序的，而不是持续时间。 交互图中的垂直空间与交互持续时间无关。
>

## 序列图例子：旅店系统

序列图是一个交互图，详细说明了如何执行操作 - 发送什么消息以及何时发送消息。 序列图根据时间进行组织。 当你走下页面时，时间会进行。 操作中涉及的对象根据它们何时参与消息序列从左到右列出。

以下是进行酒店预订的序列图。 启动消息序列的对象是预留窗口。

![Sequence Diagram Example](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/01-sequence-diagram-example.png)

> 注意：类和对象图是静态模型视图。 交互图是动态的。 它们描述了对象如何协作。

## 序列图表示法

 **Actor**

![Actor](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/02-actor.png)

+ 与主体交互的实体所扮演的一种角色（例如，通过交换信号和数据）
+ 在主题外部（即，在某个意义上，Actor的实例不是其相应主题的实例的一部分）。
+ 表示人类用户，外部硬件或其他主题所扮演的角色。

> 参与者不一定代表特定的物理实体，而仅仅代表某个实体的特定角色
> 一个对象可以扮演几个不同Actor的角色，相反，一个Actor可以由多个不同的对象来表示

**Lifeline**

![Lifeline](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/03-lifeline.png)

生命线代表交互中的个体参与者

**Activations**

![Activation](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/04-activation.png)

+ 生命线上的细长矩形表示元素执行操作的时间段
+ 矩形的顶部和底部分别与启动和完成时间对齐

**Call Message**

![Call Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/05-call-message.png)

+ Message定义了交互的生命线之间的特定通信。
+ call message是一种表示目标生命线操作调用的消息

> 注意：call message里面出现的函数调用时**目标对象**的函数，而不是调用者的函数

**Return Message**

![Return Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/06-return-message.png)

+ 返回消息是一种消息，表示将信息传递回相应的前消息的调用者。

**Self Message**

![Self-Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/07-self-message.png)

+ self message是一种表示同一生命线的消息调用的消息(可以理解为调用自己的方法)

**Recursive Message(递归消息)**

![Recursive Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/08-recursive-message.png)

+ 递归消息是一种表示同一生命线的消息调用的消息。 它的目标指向在调用消息的激活之上进行激活。

**Create Message**

![Create Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/09-create-message.png)

+ 创建消息是一种表示（目标）生命线实例化的消息(初始化一个目标对象)

**Destroy Message**

![Destroy Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/10-destroy-message.png)

销毁消息是一种消息，表示破坏目标生命线生命周期的请求(销毁一个目标对象)

**Duration Message**

![Duration Message](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/11-duration-message.png)

持续时间消息显示消息调用的两个时间点之间的距离

**Note**

![Note](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/12-note.png)

注释（注释）使得能够将各种备注附加到元素。 注释不带语义力，但可能包含对建模者有用的信息。

## 消息和控制焦点

+ 事件是发生事情的交互中的任何一点。
+ Focus of control: also called execution occurrence, an execution occurrence
+ 它在生命线上显示为高而薄的矩形
+ 它表示元素执行操作的时间段。 矩形的顶部和底部分别与启动和完成时间对齐

![Message and Focus of Control](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/13-message-and-focus-of-control.png)

## 序列片段(Sequence Fragments)

+ UML 2.0引入了序列（或交互）片段。 序列片段可以更轻松地创建和维护准确的序列图
+ 序列片段表示为一个框，称为组合片段，它包含序列图中的一部分相互作用
+ 片段运算符（在左上角的短号）表示片段的类型
+ 片段类型：ref，assert，loop，break，alt，opt，neg

![Fragment](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/14-fragment.png)

|  Operator  |                        Fragment Type                         |
| :--------: | :----------------------------------------------------------: |
|  **alt**   |              备用多个片段：只执行条件为真的片段              |
|  **opt**   | 可选：仅当提供的条件为真时才执行片段。 相当于只有一条迹线的alt。 |
|  **par**   |                    并行：每个片段并行运行                    |
|  **loop**  |        循环：片段可以执行多次，并且防护指示迭代的基础        |
| **region** |            关键区域：片段只能有一个线程一次执行它            |
|  **neg**   |                   否定：片段显示无效的交互                   |
|  **ref**   | 参考：指在另一个图上定义的交互。 绘制框架以覆盖交互中涉及的生命线。 您可以定义参数和返回值。 |
|   **sd**   |                  序列图：用于包围整个序列图                  |

> 可以组合帧以捕获例如循环或分支。
> 组合片段关键字：alt，opt，break，par，seq，strict，neg，critical，ignore，consideration，assert和loop。
> 约束通常用于显示消息的时序约束。 它们可以应用于一条消息的时间或消息之间的间隔。

### 例子

![Combined Fragment example](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/15-combined-fragment-example.png)

## 用例场景建模的序列图

用户需求被捕获为精简为方案的用例。 用例是外部参与者与系统之间交互的集合。 在UML中，用例是：

“系统（或实体）可以执行的一系列动作（包括变体）的规范，与系统的参与者进行交互。”

场景是通过用例的一个路径或流程，该用例描述在系统的一个特定执行期间发生的事件序列，其通常由序列图表示。

![Sequence Diagram for Use Case](https://cdn.visual-paradigm.com/guide/uml/what-is-sequence-diagram/16-sequence-diagram-for-use-case.png)

## 序列图 - 代码前的模型

序列图可能有点接近代码级别，那么为什么不编码该算法而不是将其绘制为序列图？

+ 一个好的序列图仍然比实际代码的水平高一点
+ 序列图是语言中立的
+ 非编码人员可以做序列图
+ 作为一个团队，更容易做序列图
+ 可用于测试和/或UX线框图

## 原文链接

[What is Sequence Diagram?](https://www.visual-paradigm.com/guide/uml-unified-modeling-language/what-is-sequence-diagram/)

