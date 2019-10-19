> 开发中经常需要从集合中查找到某个或某些值，或者通过过滤得到想要的内容，这都是家常便饭的事儿。所以，我们常见的就是需要遍历集合，加条件判断，然后得到符合条件的结果。然而，遍历是件很耗内存的事儿，特别是在移动端开发，多重的for循环遍历，是要尽量避免的。此文主要是来介绍`NSPredicate`类，这种类似于SQL语句通过过滤集合内容的方式，来避免进行集合遍历的方法。

# 1. NSPredicate

> The NSPredicate class is used to define logical conditions used to constrain a search either for a fetch or for in-memory filtering.

NSPredicate类是用来定义逻辑条件约束的获取或内存中的过滤搜索。

# 2. 基本语法

## 2.1 比较运算符

- `= , ==`: 判断两个表达式是否`相等`
- `>= , =>`: 判断左边表达式的值是否`大于或等于`右边表达式的值
- `<= , =<`: 判断左边表达式的值是否`小于或等于`右边表达式的值
- `>`: 判断左边表达式的值是否`大于`右边表达式的值
- `<`: 判断左边表达式的值是否`小于`右边表达式的值
- `!= , <>`: 判断左边表达式的值是否`不相等`右边表达式的值

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age >= 55"];
```

## 2.2 集合运算符

- `BETWEEN`：必须满足`表达式 BETWEEN {下限, 上限}`的格式，要求该表达式必须`大于或等于`下限，并`小于或等于`上限。

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age BETWEEN {11, 55}"];
```

`age`代表了集合中对象的一个实例属性，此时集合中的对象是一个个的实体。

- `IN`：必须满足`表达式 IN {元素0, 元素1, 元素2...}`的格式，要求该表达式必须包含有`{}`中的任一元素。

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name IN {'Seven', 'Eight'}"];
```

- `ANY , SOME`: 集合中任意一个元素满足条件，就返回YES
- `ALL`: 集合所有元素满足条件，才返回YES
- `NONE`: 集合中没有任何元素元素满足条件，就返回YES

## 2.3 逻辑运算符

- `&& , AND`: 逻辑与，要求左右表达式的值都为YES，结果才为YES
- `|| , OR`: 逻辑或，要求只要左右表达式中有一个的值都为YES，结果就为YES
- `! , NOT`: 逻辑非，对原有表达式取反

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = 'One' && age = 11"];
```

## 2.4 字符串间运算符

- `BEGINSWITH`: 检查某个字符串是否以指定的字符串
- `ENDSWITH`: 检查某个字符串是否以指定的字符结尾
- `CONTAINS`: 检查某个字符串是否包含指定的字符串

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] 'F'"];
```

> 注： 字符串比较都是区分大小写和重音符号的。如：café和cafe是不一样的，Cafe和cafe也是不一样的。如果希望字符串比较运算不区分大小写和重音符号，请在这些运算符后使用[c]，[d]选项。其中[c]是不区分大小写，[d]是不区分重音符号，其写在字符串比较运算符之后，比如：name LIKE[cd] 'cafe'，那么不论name是cafe、Cafe还是café上面的表达式都会返回YES。

- `LIKE`: 检查某个字符串是否匹配指定的字符串模板
- 通配符`?`代表一个任意字符
- 通配符`*`代表任意多个字符

```
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] 'T*'"];
```

- `MATCHES`: 检查某个字符串是否匹配指定的正则表达式。虽然正则表达式的执行效率是最低的，但其功能是最强大的，也是我们最常用的。

## 2.5 %K、%@、$VALUE的用法

- `%K`: 字段占位符 (K必须是大写)
- `%@`: 值占位符
- `$VALUE`: VALUE只是一个普通字符串，当做标识使用，可以任意替换，但要统一

```
NSString *nameStr = @"name";
NSString *valueStr = @"Seven";
NSPredicate *predicate0 = [NSPredicate predicateWithFormat:@"%K CONTAINS %@", nameStr, valueStr];
NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"%K > $VALUE", @"age"];
NSPredicate *predicate1 = [pred1 predicateWithSubstitutionVariables:@{@"VALUE" : @1}];
```

## 2.6 实例运用

```
// 取出self.array2中  self.array2 & self.array1都不包含的元素
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.array1];
NSLog(@"%@", [self.array2 filteredArrayUsingPredicate:predicate]);
    
// 取出self.array1 & self.array2 都包含的元素
predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", self.array1];
NSLog(@"%@", [self.array2 filteredArrayUsingPredicate:predicate]);
    
// 取出self.array1中  self.array2 & self.array1都不包含的元素
predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.array2];
NSLog(@"%@", [self.array1 filteredArrayUsingPredicate:predicate]);
```

# 3. 谓词过滤集合

其实谓词本身就代表了一个逻辑条件，计算谓词之后返回的结果永远为BOOL类型的值。而谓词最常用的功能就是对集合进行过滤。当程序使用谓词对集合元素进行过滤时，程序会自动遍历其元素，并根据集合元素来计算谓词的值，当这个集合中的元素计算谓词并返回YES时，这个元素才会被保留下来。请注意程序会自动遍历其元素，它会将自动遍历过之后返回为YES的值重新组合成一个集合返回。

- `NSArray`提供了如下方法使用谓词来过滤集合`- (NSArray<ObjectType>*)filteredArrayUsingPredicate:(NSPredicate *)predicate:`使用指定的谓词过滤`NSArray`集合，返回符合条件的元素组成的新集合
- `NSMutableArray`提供了如下方法使用谓词来过滤集合`- (void)filterUsingPredicate:(NSPredicate *)predicate：`使用指定的谓词过滤`NSMutableArray`，剔除集合中不符合条件的元素
- `NSSet`提供了如下方法使用谓词来过滤集合`- (NSSet<ObjectType> *)filteredSetUsingPredicate:(NSPredicate *)predicate NS_AVAILABLE(10_5, 3_0)：`作用同`NSArray`中的方法
- `NSMutableSet`提供了如下方法使用谓词来过滤集合`- (void)filterUsingPredicate:(NSPredicate *)predicate NS_AVAILABLE(10_5, 3_0)：`作用同`NSMutableArray`中的方法。通过上面的描述可以看出，使用谓词过滤不可变集合和可变集合的区别是：过滤不可变集合时，会返回符合条件的集合元素组成的新集合；过滤可变集合时，没有返回值，会直接剔除不符合条件的集合元素

# 4. GitHub

- [NSPredicateDemo](https://link.jianshu.com/?t=https://github.com/tinynil/iOS-Diaries-Demo/tree/master/NSPredicateDemo)

# 5. References

- [谓词(NSPredicate)](https://www.jianshu.com/p/01c191ff0dda)
- [iOS中的谓词（NSPredicate）使用](https://www.jianshu.com/p/88be28860cde)