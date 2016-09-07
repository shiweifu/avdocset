





#  Swift 数据存储开发指南

数据存储（LeanStorage）是 LeanCloud 提供的核心功能之一，它的使用方法与传统的关系型数据库有诸多不同。下面我们将其与传统数据库的使用方法进行对比，让大家有一个初步了解。

下面这条 SQL 语句在绝大数的关系型数据库都可以执行，其结果是在 Todo 表里增加一条新数据：

```sql
  INSERT INTO Todo (title, content) VALUES ('工程师周会', '每周工程师会议，周一下午2点')
```

使用传统的关系型数据库作为应用的数据源几乎无法避免以下步骤：

- 插入数据之前一定要先创建一个表结构，并且随着之后需求的变化，开发者需要不停地修改数据库的表结构，维护表数据。
- 每次插入数据的时候，客户端都需要连接数据库来执行数据的增删改查（CRUD）操作。

使用 LeanStorage，实现代码如下：



```swift
    // className 参数对应控制台中的 Class Name
    let todo = LCObject(className: "Todo")
    todo.set("title", object:"工作")
    todo.set("content", object: "每周工程师会议，周一下午2点")
    
    todo.save { result in
      // 读取 result.isSuccess 可以判断是否操作成功
    }
```


使用 LeanStorage 的特点在于：

- 不需要单独维护表结构。例如，为上面的 Todo 表新增一个 `location` 字段，用来表示日程安排的地点，那么刚才的代码只需做如下变动：

  

```swift
    // className 参数对应控制台中的 Class Name
    let todo = LCObject(className: "Todo")
    todo.set("title", object:"工作")
    todo.set("content", object: "每周工程师会议，周一下午2点")
    // 设置 location 的值为「会议室」
    todo.set("location", object: "会议室")
    
    todo.save { result in
      // 读取 result.isSuccess 可以判断是否操作成功
      
    }
```


- 数据可以随用随加，这是一种无模式化（Schema Free）的存储方式。
- 所有对数据的操作请求都通过 HTTPS 访问标准的 REST API 来实现。
- 我们为各个平台或者语言开发的 SDK 在底层都是调用统一的 REST API，并提供完整的接口对数据进行增删改查。

LeanStorage 在结构化数据存储方面，与 DB 的区别在于：

1. Schema Free／Not free 的差异；
2. 数据接口上，LeanStorage 是面向对象的（数据操作接口都是基于 Object 的），开放的（所有移动端都可以直接访问），DB 是面向结构的，封闭的（一般在 Server 内部访问）；
3. 数据之间关联的方式，DB 是主键外键模型，LeanStorage 则有自己的关系模型（Pointer、Relation 等）；

LeanStorage 支持两种存储类型：

* 对象
* 文件

我们将按照顺序逐一介绍各类的使用方法。


## SDK 安装


请阅读 [Swift 安装指南](sdk_setup-swift.html)。






## 对象

`LCObject` 是 LeanStorage 对复杂对象的封装，每个 `LCObject` 包含若干属性值对，也称键值对（key-value）。属性的值是与 JSON 格式兼容的数据。通过 REST API 保存对象需要将对象的数据通过 JSON 来编码。这个数据是无模式化的（Schema Free），这意味着你不需要提前标注每个对象上有哪些 key，你只需要随意设置 key-value 对就可以，云端会保存它。

### 数据类型
`LCObject` 支持以下数据类型：



```swift
    let bool = true
    let number = 123
    let str = "abc"
    let date = NSDate()
    let data = "短篇小说".dataUsingEncoding(NSUTF8StringEncoding)
    let array:[String] = ["Eggs", "Milk"]
    let dictionary: [String: String] = ["YYZ": "Toronto Pearson", "DUB": "Dublin"]
    
    let testObject = LeanCloud.LCObject(className: "Todo")
    testObject.set("testBoolean", object: bool)
    testObject.set("testNumber", object: number)
    testObject.set("testString", object: str)
    testObject.set("testDate", object: date)
    testObject.set("testData", object: data)
    testObject.set("testArray", object: array)
    testObject.set("testDictionary", object: dictionary)
    
    testObject.save({ (result) in
    })
```

若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。



我们**不推荐**在 `LCObject` 中使用 `NSData` 来储存大块的二进制数据，比如图片或整个文件。**每个 `LCObject` 的大小都不应超过 128 KB**。如果需要储存更多的数据，建议使用 [`LCFile`](#文件)。


若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。

### 构建对象
构建一个 `LCObject` 可以使用如下方式：



```swift
    // className 参数对应控制台中的 Class Name
     let todo = LCObject(className: "Todo")
```


每个 objectId 必须有一个 Class 类名称，这样云端才知道它的数据归属于哪张数据表。

### 保存对象
现在我们保存一个 `TodoFolder`，它可以包含多个 Todo，类似于给行程按文件夹的方式分组。我们并不需要提前去后台创建这个名为 **TodoFolder** 的 Class 类，而仅需要执行如下代码，云端就会自动创建这个类：



```swift
    // className 参数对应控制台中的 Class Name
    let todoFolder = LCObject(className: "TodoFolder")
    todoFolder.set("name", object:"工作")
    todoFolder.set("priority", object: 1)
    
    // 保存到云端
    todoFolder.save { result in
    }
```



创建完成后，打开 [控制台 > 存储](/data.html?appid={{appid}}#/)，点开 `TodoFolder` 类，就可以看到刚才添加的数据。除了 name、priority（优先级）之外，其他字段都是数据表的内置属性。


内置属性|类型|描述
---|---|---
`objectId`|String|该对象唯一的 Id 标识
`ACL`|ACL|该对象的权限控制，实际上是一个 JSON 对象，控制台做了展现优化。
`createdAt`|NSDate|该对象被创建的 UTC 时间，控制台做了针对当地时间的展现优化。
`updatedAt` |NSDate|该对象最后一次被修改的时间

<dl>
  <dt>属性名</dt>
  <dd>也叫键或 key，必须是由字母、数字或下划线组成的字符串；自定义的属性名，不能以 `__`（双下划线）开头。</dd>
  <dt>属性值</dt>
  <dd>可以是字符串、数字、布尔值、数组或字典。</dd>
</dl>

<div class="callout callout-danger"><p>以下为系统保留字段，不能作为属性名来使用。</p>
<samp style="color:#666;">acl             error            pendingKeys
ACL             fetchWhenSave    running
className       id               updatedAt
code            isDataReady      uuid
createdAt       keyValues
description     objectId
</samp>
</div>

为提高代码的可读性和可维护性，建议使用驼峰式命名法（CamelCase）为类和属性来取名。类，采用大驼峰法，如 `CustomData`。属性，采用小驼峰法，如 `imageUrl`。

#### 使用 CQL 语法保存对象
LeanStorage 提供了类似 SQL 语法中的 Insert 方式保存一个对象，例如保存一个 TodoFolder 对象可以使用下面的代码：



```swift
    // 执行 CQL 语句实现新增一个 TodoFolder 对象
    LeanCloud.CQLClient.execute("insert into TodoFolder(name, priority) values('工作', 1)") { (result) in
        if(result.isFailure){
            print(result.error)
        } else {
            if(result.objects.count > 0){
                let todoFolder = result.objects[0]
                // 打印 objectId
                print("objectId",todoFolder.objectId?.value)
            }
        }
    }

//https://github.com/leancloud/Swift-Sample-Code/blob/master/Swift-Sample-CodeTests/LCObject%23saveByCQL.swift
```




### 获取对象
每个被成功保存在云端的对象会有一个唯一的 Id 标识 `objectId`，因此获取对象的最基本的方法就是根据 `objectId` 来查询：



```swift
    let query = LCQuery(className: "Todo")
    query.get("575cf743a3413100614d7d75", completion: { (result) in
        if(result.isSuccess) {
            let todo = result.object
            print(todo?.objectId?.value)
            print( todo?.get("title"))
        }
    })
```


如果不想使用查询，还可以通过从本地构建一个 `objectId`，然后调用接口从云端把这个 `objectId` 的数据拉取到本地，示例代码如下：



```swift
    let todo = LCObject(className: "Todo", objectId: "575cf743a3413100614d7d75")
    
    todo.fetch({ (result ) in
        if(result.error != nil){
            print(result.error)
        }
        // 读取 title 属性
        let title = todo.get("title")
        // 读取 content 属性
        let content = todo.get("content")
    })
```



#### 获取 objectId
每一次对象存储成功之后，云端都会返回 `objectId`，它是一个全局唯一的属性。



```swift
    let todo = LCObject(className: "Todo")
    todo.set("title", object: "工程师周会")
    todo.set("content", object: "每周工程师会议，周一下午2点")
    todo.set("location", object: "会议室")
    
    todo.save { (result) in
        if(result.isSuccess){
            print(todo.objectId)
        } else {
            // 失败的话，请检查网络环境以及 SDK 配置是否正确
        }
    }
```



#### 访问对象的属性
访问 Todo 的属性的方式为：



```swift
    let query = LCQuery(className: "Todo")
    query.get("558e20cbe4b060308e3eb36c") { (result) in
        // todoObj 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例
        let todoObj = result.object
        let location = todoObj?.get("location") as! LCString
        let title = todoObj?.get("title") as! LCString
        let content = todoObj?.get("content") as! LCString
        
        // 获取三个特性
        let objectId = todoObj?.objectId
        let updatedAt = todoObj?.updatedAt
        let createdAt = todoObj?.createdAt
    }
```


请注意以上代码中访问三个特殊属性 `objectId`、`createdAt`、`updatedAt` 的方式。

如果访问了并不存在的属性，SDK 并不会抛出异常，而是会返回空值。

#### 默认属性
默认属性是所有对象都会拥有的属性，它包括 `objectId`、`createdAt`、`updatedAt`。

<dl>
  <dt>`createdAt`</dt>
  <dd>对象第一次保存到云端的时间戳。该时间一旦被云端创建，在之后的操作中就不会被修改。它采用国际标准时区 UTC，开发者可能需要根据客户端当前的时区做转化。</dd>
  <dt>`updatedAt`</dt>
  <dd>对象最后一次被修改（或最近一次被更新）的时间。</dd>
</dl>




### 更新对象

LeanStorage 上的更新对象都是针对单个对象，云端会根据<u>有没有 objectId</u> 来决定是新增还是更新一个对象。

假如 `objectId` 已知，则可以通过如下接口从本地构建一个 `LCObject` 来更新这个对象：



```swift
    let todo = LCObject(className: "Todo", objectId: "575cf743a3413100614d7d75")
    todo.set("content", object: "每周工程师会议，本周改为周三下午3点半。")
    
    todo.save({ (result) in
        if(result.isSuccess){
            print("保存成功")
        }
    })
```



更新操作是覆盖式的，云端会根据最后一次提交到服务器的有效请求来更新数据。更新是字段级别的操作，未更新的字段不会产生变动，这一点请不用担心。

#### 使用 CQL 语法更新对象
LeanStorage 提供了类似 SQL 语法中的 Update 方式更新一个对象，例如更新一个 TodoFolder 对象可以使用下面的代码：



```swift
    LeanCloud.CQLClient.execute("update TodoFolder set name='家庭' where objectId='575d2c692e958a0059ca3558'", completion: { (result) in
        if(result.isSuccess){
            // 成功执行了 CQL
        }
    })
```


#### 更新计数器

这是原子操作（Atomic Operation）的一种。
为了存储一个整型的数据，LeanStorage 提供对任何数字字段进行原子增加（或者减少）的功能。比如一条微博，我们需要记录有多少人喜欢或者转发了它，但可能很多次喜欢都是同时发生的。如果在每个客户端都直接把它们读到的计数值增加之后再写回去，那么极容易引发冲突和覆盖，导致最终结果不准。此时就需要使用这类原子操作来实现计数器。

假如，现在增加一个记录查看 Todo 次数的功能，一些与他人共享的 Todo 如果不用原子操作的接口，很有可能会造成统计数据不准确，可以使用如下代码实现这个需求：



```swift
    let todo = LCObject(className: "Todo", objectId: "575cf743a3413100614d7d75")
    todo.set("views", object: 50)
    todo.save({ (saveResult) in
        todo.increase("views", by: LCNumber(1));
        todo.save({ (increaseResult) in
            if(increaseResult.isSuccess){
                print(todo.get("views"))
            }
        })
    })
```



#### 更新数组

这也是原子操作的一种。使用以下方法可以方便地维护数组类型的数据：



* `append(String, element: LCType)`<br>
  将指定对象附加到数组末尾。
* `append(String, element: LCType, unique: Bool)`<br>
   将指定对象附加到数组末尾，并且可以设置一个 `unique` 的 `bool` 值表示只是确保唯一，不会重复添加
* `append(String, elements: [LCType])`<br>
   将指定对象数组附加到数组末尾。
* `append(String, elements: [LCType], unique: Bool)`<br>
   将指定对象附加到数组末尾，并且可以设置一个 `unique` 的 `bool` 值表示只是确保唯一，不会重复添加
* `remove(String, element: LCType)`<br>
   从数组字段中删除指定的对象。
* `remove(String, elements: [LCType])`<br>
   从数组字段中删除指定的对象数组。



例如，Todo 对象有一个提醒日期 reminders，它是一个数组，代表这个日程会在哪些时间点提醒用户。比如有些拖延症患者会把闹钟设为早上的 7:10、7:20、7:30：



```swift
func getDateWithDateString(dateString:String) -> LCDate {
    let dateStringFormatter = NSDateFormatter()
    dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    let date = dateStringFormatter.dateFromString(dateString)!
    let lcDate = LCDate(date);
    return lcDate;
}

func testSetArray() {

    let renminder1 = self.getDateWithDateString("2015-11-11 07:10:00")
    let renminder2 = self.getDateWithDateString("2015-11-11 07:20:00")
    let renminder3 = self.getDateWithDateString("2015-11-11 07:30:00")
    
    let reminders = LCArray(arrayLiteral: renminder1,renminder2,renminder3)
    
    let todo = LCObject(className: "Todo")
    todo.set("reminders", value: reminders)
    
    todo.save({ (result) in
        // 新增一个闹钟时间
        let todo4 = self.getDateWithDateString("2015-11-11 07:40:00")
        // 使用 append 方法添加
        todo.append("reminders", element: todo4, unique: true)
        todo.save({ (updateResult) in
            if(result.isSuccess){
                // 成功执行了 CQL
            }
        })
    })
}

//https://github.com/BenBBear/cordova-plugin-leanpush
```




### 删除对象

假如某一个 Todo 完成了，用户想要删除这个 Todo 对象，可以如下操作：



```swift
    // 调用实例方法删除对象
    todo.delete { (result) in
        if(result.isSuccess){
            // 根据 result.isSuccess 可以判断是否删除成功
        } else {
            if (result.error != nil){
                print(result.error?.reason)
                // 如果删除失败，可以查看是否当前正确使用了 ACL
            }
        }
    }
```


<div class="callout callout-danger">删除对象是一个较为敏感的操作。在控制台创建对象的时候，默认开启了权限保护，关于这部分的内容请阅读《[iOS / OS X 权限管理使用指南](acl_guide-ios.html)》。</div>

#### 使用 CQL 语法删除对象
LeanStorage 提供了类似 SQL 语法中的 Delete 方式删除一个对象，例如删除一个 Todo 对象可以使用下面的代码：


```swift
    // 执行 CQL 语句实现删除一个 Todo 对象
    LeanCloud.CQLClient.execute("delete from Todo where objectId='558e20cbe4b060308e3eb36c'") { (result) in
        if(result.isSuccess){
            // 删除成功
        } else {
            // 删除失败，打印错误信息
            print(result.error?.reason)
        }
```








### 后台运行
细心的开发者已经发现，在所有的示例代码中几乎都是用了异步来访问 LeanStorage 云端，如下代码：

```swift
    todo.save({ (result) in
        if(result.isSuccess){
            // 操作成功
        }
    })
``` 
上述用法都是提供给开发者在主线程调用用来实现后台运行的方法，因此开发者可以放心地在主线程调用这种命名方式的函数。另外，需要强调的是：**回调函数的代码是在主线程执行。**




### 关联数据

#### `LCRelation`
对象可以与其他对象相联系。如前面所述，我们可以把一个 `LCObject` 的实例 A，当成另一个 `LCObject` 实例 B 的属性值保存起来。这可以解决数据之间一对一或者一对多的关系映射，就像关系型数据库中的主外键关系一样。

例如，一个 TodoFolder 包含多个 Todo ，可以用如下代码实现：



```swift
    // 以下代码需要同步执行
    // 新建一个 TodoFolder 对象
    let todoFolder = LCObject(className: "TodoFolder")
    todoFolder.set("name", object: "工作")
    todoFolder.set("priority", object: 1)
    todoFolder.save()
    
    // 新建 3 个 Todo 对象
    let todo1 = LCObject(className: "Todo")
    todo1.set("title", object: "工程师周会")
    todo1.set("content", object: "每周工程师会议，周一下午2点")
    todo1.set("location", object: "会议室")
    todo1.save()
    
    let todo2 = LCObject(className: "Todo")
    todo2.set("title", object: "维护文档")
    todo2.set("content", object: "每天 16：00 到 18：00 定期维护文档")
    todo2.set("location", object: "当前工位")
    todo2.save()
    
    let todo3 = LCObject(className: "Todo")
    todo3.set("title", object: "发布 SDK")
    todo3.set("content", object: "每周一下午 15：00")
    todo3.set("location", object: "SA 工位")
    todo3.save()
    
    // 使用接口 insertRelation 建立 todoFolder 与 todo1,todo2,todo3 的一对多的关系
    todoFolder.insertRelation("containedTodos", object: todo1)
    todoFolder.insertRelation("containedTodos", object: todo2)
    todoFolder.insertRelation("containedTodos", object: todo3)
    
    todoFolder.save()
    
    // 保存完毕之后，读取 LCRelation 对象
    let relation : LCRelation = todoFolder.get("containedTodos")
```


#### Pointer
Pointer 只是个描述并没有具象的类与之对应，它与 `LCRelation` 不一样的地方在于：`LCRelation` 是在**一对多**的「一」这一方（上述代码中的一指 TodoFolder）保存一个 `LCRelation` 属性，这个属性实际上保存的是对被关联数据**多**的这一方（上述代码中这个多指 Todo）的一个 Pointer 的集合。而反过来，LeanStorage 也支持在「多」的这一方保存一个指向「一」的这一方的 Pointer，这样也可以实现**一对多**的关系。

简单的说， Pointer 就是一个外键的指针，只是在 LeanCloud 控制台做了显示优化。

现在有一个新的需求：用户可以分享自己的 TodoFolder 到广场上，而其他用户看见可以给与评论，比如某玩家分享了自己想买的游戏列表（TodoFolder 包含多个游戏名字），而我们用 Comment 对象来保存其他用户的评论以及是否点赞等相关信息，代码如下：



```swift
    // 新建一条留言
    let comment = LCObject(className: "Comment")
    // 如果点了赞就是 1，而点了不喜欢则为 -1，没有做任何操作就是默认的 0
    comment.set("like", object: 1)
    // 留言的内容
    comment.set("content", object: "这个太赞了！楼主，我也要这些游戏，咱们团购么？")
    
    // 假设已知了被分享的该 TodoFolder 的 objectId 是 5590cdfde4b00f7adb5860c8
    let todoFolder = LCObject(className: "TodoFolder", objectId: "5590cdfde4b00f7adb5860c8")
    comment.set("targetTodoFolder", object: todoFolder)
    // 以上代码的执行结果是在 comment 对象上有一个名为 targetTodoFolder 属性，它是一个 Pointer 类型，指向 objectId 为 5590cdfde4b00f7adb5860c8 的 TodoFolder
    comment.save {_ in}
```


相关内容可参考 [关联数据查询](#LCRelation_查询)。

#### 地理位置
地理位置是一个特殊的数据类型，LeanStorage 封装了 `LCGeoPoint` 来实现存储以及相关的查询。

首先要创建一个 `LCGeoPoint` 对象。例如，创建一个北纬 39.9 度、东经 116.4 度的 `LCGeoPoint` 对象（LeanCloud 北京办公室所在地）：



```swift
  let leancloudOffice  = LCGeoPoint(latitude: 39.9, longitude: 116.4)
```


假如，添加一条 Todo 的时候为该 Todo 添加一个地理位置信息，以表示创建时所在的位置：



```swift
  todo.set("whereCreated", object: leancloudOffice)
```


同时请参考 [地理位置查询](#地理位置查询)。



### 序列化和反序列化
在实际的开发中，把 `LCObject` 当做参数传递的时候，会涉及到复杂对象的拷贝的问题，因此 `LCObject` 也提供了序列化和反序列化的方法：

序列化：


```swift
    let todoFolder = LeanCloud.LCObject(className: "TodoFolder")
    todoFolder.set("priority", object: 1)
    todoFolder.set("name", object: "工作")
    todoFolder.set("owner", object: LCUser.current)
    
    let serializeObject = NSKeyedArchiver.archivedDataWithRootObject(todoFolder)
    // serializeObject 可以存在本地当做缓存或者作为参数传递
```


反序列化：


```swift
    // 假设 serializeObject 是一个已经被序列化之后的 NSData
    let serializeObject = NSKeyedArchiver.archivedDataWithRootObject(todoFolder)
    
    // 反序列化的方式如下
    let deserializeObject = NSKeyedUnarchiver.unarchiveObjectWithData(serializeObject) as! LCObject
```








### 数据协议
很多开发者在使用 LeanStorage 初期都会产生疑惑：客户端的数据类型是如何被云端识别的？
因此，我们有必要重点介绍一下 LeanStorage 的数据协议。

先从一个简单的日期类型入手，比如在 Swift 中，默认的日期类型是 `NSDate`，下面会详细讲解一个
 `NSDate` 是如何被云端正确的按照日期格式存储的。

为一个普通的 `LCObject` 的设置一个 `NSDate` 的属性，然后调用保存的接口：



Swift SDK 在真正调用保存接口之前，会自动的调用一次序列化的方法，将 `NSDate` 类型的数据，转化为如下格式的数据：

```json
{
  "__type": "Date",
  "iso": "2015-11-21T18:02:52.249Z"
}
```

然后发送给云端，云端会自动进行反序列化，这样自然就知道这个数据类型是日期，然后按照传过来的有效值进行存储。因此，开发者在进阶开发的阶段，最好是能掌握 LeanStorage 的数据协议。如下表介绍的就是一些默认的数据类型被序列化之后的格式：



类型 | 序列化之后的格式|
---|---
`NSDate` | `{"__type": "Date","iso": "2015-11-21T18:02:52.249Z"}`
`NSData` |  `{"__type": "Bytes","base64":"utf-8-encoded-string}"`
`Pointer` |`{"__type":"Pointer","className":"Todo","objectId":"55a39634e4b0ed48f0c1845c"}`
`LCRelation`| `{"__type": "Relation","className": "Todo"}`





#### LCString
`LCString` 是 Swift SDK 针对 String 对象的封装，它与 String 相互转化的代码如下：

```swift
    // String 转化成 LCString
    let lcString = LCString("abc")
    // 从 LCString 获取 String
    let abc  = lcString.value
```

#### LCNumber
`LCNumber` 是 Swift SDK 针对 Double 数据类型的封装，它与 Double 相互转化的代码如下：

```swift
    // Double 转化成 LCNumber
    let number123 : Double = 123
    let lcNumber  = LCNumber(number123)
    // 从 LCNumber 获取 Double
    let testNumber = lcNumber.value
    
    // 从 LCObject 中读取 Double
    let priority = todo.get("priority") as! LCNumber
    let priorityDoubule = priority.value
```
#### LCArray
`LCArray` 是 Swift SDK 针对  Array 类型的封装，它的构造方式如下：

```swift
    let lcNumberArray = LCArray(arrayLiteral: LCNumber(1),LCNumber(2),LCNumber(3))
    let lcStringArray: LCArray = [LCString("a"), LCString("b"), LCString("c")]
```

#### LCDate
`LCDate` 是 Swift SDK 针对  日期类型的封装，它的使用方式如下：

```swift
    let dateStringFormatter = NSDateFormatter()
    dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    let date = dateStringFormatter.dateFromString("2016-07-09 22:15:16")!
    
    // 使用 NSDate 构造 LCDate
    let lcDate = LCDate(date);
    // 从 LCDate 读取 NSDate
    let nativeDate = lcDate.value
```



## 查询
`LCQuery` 是构建针对 `LCObject` 查询的基础类。


### 创建查询实例


```swift
  let query = LCQuery(className: "Todo")
```



### 根据 id 查询
在 [获取对象](#获取对象) 中我们介绍过如何通过 objectId 来获取对象实例，从而简单的介绍了一下 `LCQuery` 的用法，代码请参考对应的内容，不再赘述。

### 条件查询
在大多数情况下做列表展现的时候，都是根据不同条件来分类展现的，比如，我要查询所有优先级为 0 的 Todo，也就是做列表展现的时候，要展示优先级最高，最迫切需要完成的日程列表，此时基于 priority 构建一个查询就可以查询出符合需求的对象：



```swift
    // 构建 LCQuery 对象
    let query = LCQuery(className: "Todo")
    // 查询所有 priority 等于 0 的 Todo
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    // 执行查找
    query.find({ (result) in
        if(result.isSuccess){
            // 获取 Todo 数组
            let todos = result.objects
            // 遍历数组
            for todo in todos! {
                // 打印 title
                print(todo.get("title"))
            }
        }
    })
```


其实，拥有传统关系型数据库开发经验的开发者完全可以翻译成如下的 SQL：

```sql
  select * from Todo where priority = 0
```
LeanStorage 也支持使用这种传统的 SQL 语句查询。具体使用方法请移步至 [Cloud Query Language（CQL）查询](#CQL_查询)。

查询默认最多返回 100 条符合条件的结果，要更改这一数值，请参考 [限定结果返回数量](#限定返回数量)。

当多个查询条件并存时，它们之间默认为 AND 关系，即查询只返回满足了全部条件的结果。建立 OR 关系则需要使用 [组合查询](#组合查询)。

注意：在简单查询中，如果对一个对象的同一属性设置多个条件，那么先前的条件会被覆盖，查询只返回满足最后一个条件的结果。例如，我们要找出优先级为 0 和 1 的所有 Todo，错误写法是：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(1)))
    // 如果这样写，第二个条件将覆盖第一个条件，查询只会返回 priority = 1 的结果
    query.find({ (result) in
        if(result.isSuccess){
            let todos = result.objects
            for todo in todos! {
                if(todo.get("priority") == LCNumber(1)){
                  // todos 集合里面所有的 Todo 的 priority 属性都应该是 1
                }
            }
        }
    })

```


正确作法是使用 [OR 关系](#OR_查询) 来构建条件。

#### 比较查询



逻辑操作 | AVQuery 方法|
---|---
等于 | `whereKey("key", LCQuery.Constraint.EqualTo(value: LCType()))`
不等于 |  `whereKey("key", LCQuery.Constraint.NotEqualTo(value: LCType))`
大于 | `whereKey("key", LCQuery.Constraint.GreaterThan(value: LCType))`
大于等于 | `whereKey("key", LCQuery.Constraint.GreaterThanOrEqualTo(value: LCType))`
小于 | `whereKey("key", LCQuery.Constraint.LessThan(value: LCType))`
小于等于 | `whereKey("key", LCQuery.Constraint.LessThanOrEqualTo(value: LCType))`


利用上述表格介绍的逻辑操作的接口，我们可以很快地构建条件查询。

例如，查询优先级小于 2 的所有 Todo ：



```swift
  query.whereKey("priority", LCQuery.Constraint.LessThan(value: LCNumber(2)))
```


要查询优先级大于等于 2 的 Todo：



```swift
  query.whereKey("priority", LCQuery.Constraint.GreaterThanOrEqualTo(value: LCNumber(2)))
```


比较查询**只适用于可比较大小的数据类型**，如整型、浮点等。

#### 正则匹配查询

正则匹配查询是指在查询条件中使用正则表达式来匹配数据，查询指定的 key 对应的 value 符合正则表达式的所有对象。
例如，要查询标题包含中文的 Todo 对象可以使用如下代码：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("title", LCQuery.Constraint.MatchedPattern(pattern: "[\\u4e00-\\u9fa5]", option:nil))
```


正则匹配查询**只适用于**字符串类型的数据。

#### 包含查询

包含查询类似于传统 SQL 语句里面的 `LIKE %keyword%` 的查询，比如查询标题包含「李总」的 Todo：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("title", LCQuery.Constraint.MatchedSubstring(string: "李总"))
```


翻译成 SQL 语句就是：

```sql
  select * from Todo where title LIKE '%李总%'
```
不包含查询与包含查询是对立的，不包含指定关键字的查询，可以使用 [正则匹配方法](#正则匹配查询) 来实现。例如，查询标题不包含「机票」的 Todo，正则表达式为 `^((?!机票).)*$`：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("title", LCQuery.Constraint.MatchedPattern(pattern: "^((?!机票).)*$", option: nil))
```


但是基于正则的模糊查询有两个缺点：

- 当数据量逐步增大后，查询效率将越来越低。
- 没有文本相关性排序

因此，你还可以考虑使用 [应用内搜索](#应用内搜索) 功能。它基于搜索引擎技术构建，提供更强大的搜索功能。

还有一个接口可以精确匹配不等于，比如查询标题不等于「出差、休假」的 Todo 对象：



```swift
    let query = LCQuery(className: "Todo")
    let filterArray = LCArray([ LCString("休假"),LCString("出差")])
    query.whereKey("title", LCQuery.Constraint.NotContainedIn(array: filterArray))
```


#### 数组查询

当一个对象有一个属性是数组的时候，针对数组的元数据查询可以有多种方式。例如，在 [数组](#更新数组) 一节中我们为 Todo 设置了 reminders 属性，它就是一个日期数组，现在我们需要查询所有在 8:30 会响起闹钟的 Todo 对象：



```swift
    func queryRemindersContains(){
        let reminder = self.getDateWithDateString("2015-11-11 08:30:00")
        let query = LCQuery(className: "Todo")
        query.whereKey("reminders", LCQuery.Constraint.EqualTo(value: reminder))
    }
    func getDateWithDateString(dateString:String) -> LCDate {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let date = dateStringFormatter.dateFromString(dateString)!
        let lcDate = LCDate(date)
        return lcDate
    }
```


如果你要查询包含 8:30、9:30 这两个时间点响起闹钟的 Todo，可以使用如下代码：



```swift
    func testArrayContainsAll() {
        let reminder1 = self.getDateWithDateString("2015-11-11 08:30:00")
        let reminder2 = self.getDateWithDateString("2015-11-11 09:30:00")
        
        // 构建查询时间点数组
        let reminders: LCArray = [reminder1, reminder2]
        let query = LCQuery(className: "Todo")
        query.whereKey("reminders", LCQuery.Constraint.ContainedAllIn(array: reminders))
        
    }
    
    func getDateWithDateString(dateString:String) -> LCDate {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let date = dateStringFormatter.dateFromString(dateString)!
        let lcDate = LCDate(date)
        return lcDate
    }
```


注意这里是包含关系，假如有一个 Todo 会在 8:30、9:30、10:30 响起闹钟，它仍然是会被查询出来的。

#### 字符串查询
使用 `whereKey:hasPrefix:` 可以过滤出以特定字符串开头的结果，这有点像 SQL 的 LIKE 条件。因为支持索引，所以该操作对于大数据集也很高效。



```swift
    // 找出开头是「早餐」的 Todo
    let query = LCQuery(className: "Todo")
    query.whereKey("content", LCQuery.Constraint.PrefixedBy(string: "早餐"))
```


#### 空值查询
假设我们的 Todo 允许用户上传图片用来帮助用户记录某些特殊的事项，但是有时候用户可能就记得自己给一个 Todo 附加过图片，但是具体又不记得这个 Todo 的关键字是什么，因此我们需要一个接口可以找出那些有图片的 Todo，此时就可以使用到空值查询的接口：



```swift
    // 使用非空值查询获取有图片的 Todo
    query.whereKey("images", LCQuery.Constraint.Existed)

    // 使用空值查询获取没有图片的 Todo
    query.whereKey("images", LCQuery.Constraint.NotExisted)
```


### 组合查询
组合查询就是把诸多查询条件合并成一个查询，再交给 SDK 去云端查询。方式有两种：OR 和 AND。

#### OR 查询
OR 操作表示多个查询条件符合其中任意一个即可。 例如，查询优先级是大于等于 3 或者已经完成了的 Todo：



```swift
    let priorityQuery = LCQuery(className: "Todo")
    priorityQuery.whereKey("priority", LCQuery.Constraint.GreaterThanOrEqualTo(value: LCNumber(3)))
    
    let statusQuery = LCQuery(className: "Todo")
    statusQuery.whereKey("status", LCQuery.Constraint.EqualTo(value: LCNumber(1)))
    
    let query = priorityQuery.or(statusQuery)
    
    query.find { (result) in
        // 返回 priority 大于等于 3 或 status 等于 1 的 Todo
        let todos = result.objects
    }
```


**注意：OR 查询中，子查询中不能包含地理位置相关的查询。**

#### AND 查询
AND 操作是指只有满足了所有查询条件的对象才会被返回给客户端。例如，查询优先级小于 1 并且尚未完成的 Todo：



```swift
    let priorityQuery = LCQuery(className: "Todo")
    priorityQuery.whereKey("priority", LCQuery.Constraint.LessThan(value: LCNumber(3)))
    
    let statusQuery = LCQuery(className: "Todo")
    statusQuery.whereKey("status", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    
    let query = priorityQuery.and(statusQuery)
    
    query.find { (result) in
        // 返回 priority 小于 3 并且 status 等于 0 的 Todo
        let todos = result.objects
    }
```


可以对新创建的 `LCQuery` 添加额外的约束，多个约束将以 AND 运算符来联接。

### 查询结果

#### 获取第一条结果
例如很多应用场景下，只要获取满足条件的一个结果即可，例如获取满足条件的第一条 Todo：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    query.getFirst { (result) in
        // result.object 就是符合条件的第一个 LCObject
    }
```


#### 限定返回数量
为了防止查询出来的结果过大，云端默认针对查询结果有一个数量限制，即 `limit`，它的默认值是 100。比如一个查询会得到 10000 个对象，那么一次查询只会返回符合条件的 100 个结果。`limit` 允许取值范围是 1 ~ 1000。例如设置返回 10 条结果：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    query.limit = 10
    query.find { (result) in
        if(result.objects?.count <= 10){
            // 因为设置了 limit，因此返回的结果数量一定小于等于 10
        }
    }
```


#### 跳过数量
设置 skip 这个参数可以告知云端本次查询要跳过多少个结果。将 skip 与 limit 搭配使用可以实现翻页效果，这在客户端做列表展现时，尤其在数据量庞大的情况下就使用技术。例如，在翻页中，一页显示的数量是 10 个，要获取第 3 页的对象：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("priority", LCQuery.Constraint.EqualTo(value: LCNumber(0)))
    query.limit = 10 // 返回 10 条数据
    query.skip = 20 // 跳过 20 条数据
    query.find { (result) in
        // 每一页 10 条数据，跳过了 20 条数据，因此获取的是第 3 页的数据
    }
```



尽管我们提供以上接口，但是我们不建议广泛使用，因为它的执行效率比较低。取而代之，我们建议使用 `createdAt` 或者 `updatedAt` 这类的时间戳进行分段查询。

#### 属性限定
通常列表展现的时候并不是需要展现某一个对象的所有属性，例如，Todo 这个对象列表展现的时候，我们一般展现的是 title 以及 content，我们在设置查询的时候，也可以告知云端需要返回的属性有哪些，这样既满足需求又节省了流量，也可以提高一部分的性能，代码如下：



```swift
    let query = LCQuery(className: "Todo")
    // 指定返回 title 属性
    query.whereKey("title", LCQuery.Constraint.Selected)
    // 指定返回 content 属性
    query.whereKey("content", LCQuery.Constraint.Selected)
    query.find { (result) in
        for todo in result.objects!{
            let title = todo.get("title") // 读取 title
            let content = todo.get("content") // 读取 content
            
            // 如果访问没有指定返回的属性（key），则会报错，在当前这段代码中访问 location 属性就会报错
            let location = todo.get("location")
        }
    }```


#### 统计总数量
通常用户在执行完搜索后，结果页面总会显示出诸如「搜索到符合条件的结果有 1020 条」这样的信息。例如，查询一下今天一共完成了多少条 Todo：



```swift
    let query = LCQuery(className: "Todo")
    query.whereKey("status", LCQuery.Constraint.EqualTo(value: LCNumber(1)))
    query.count()
```


#### 排序

对于数字、字符串、日期类型的数据，可对其进行升序或降序排列。



``` swift
    // 按时间，升序排列
    query.whereKey("createdAt", LCQuery.Constraint.Ascending)

    // 按时间，降序排列
    query.whereKey("createdAt", LCQuery.Constraint.Descending)
```


一个查询可以附加多个排序条件，如按 priority 升序、createdAt 降序排列：



```swift
    query.whereKey("priority", LCQuery.Constraint.Ascending)
    query.whereKey("createdAt", LCQuery.Constraint.Descending)
```


<!-- #### 限定返回字段 -->

### 关系查询
关联数据查询也可以通俗地理解为关系查询，关系查询在传统型数据库的使用中是很常见的需求，因此我们也提供了相关的接口来满足开发者针对关联数据的查询。

首先，我们需要明确关系的存储方式，再来确定对应的查询方式。

#### Pointer 查询
基于在 [Pointer](#Pointer) 小节介绍的存储方式：每一个 Comment 都会有一个 TodoFolder 与之对应，用以表示 Comment 属于哪个 TodoFolder。现在我已知一个 TodoFolder，想查询所有的 Comnent 对象，可以使用如下代码：



```swift
    let query = LCQuery(className: "Comment")
    let targetTodoFolder = LCObject(className: "TodoFolder", objectId: "5590cdfde4b00f7adb5860c8")
    query.whereKey("targetTodoFolder", LCQuery.Constraint.EqualTo(value: targetTodoFolder))
```


#### `LCRelation` 查询
假如用户可以给 TodoFolder 增加一个 Tag 选项，用以表示它的标签，而为了以后拓展 Tag 的属性，就新建了一个 Tag 对象，如下代码是创建 Tag 对象：



```swift
    let tag = LCObject(className: "Tag")
    tag.set("name", object: "今日必做")
    tag.save(){ _ in }
```


而 Tag 的意义在于一个 TodoFolder 可以拥有多个 Tag，比如「家庭」（TodoFolder） 拥有的 Tag 可以是：今日必做，老婆吩咐，十分重要。实现创建「家庭」这个 TodoFolder 的代码如下：



```swift
    let tag1 = LCObject(className: "Tag")
    tag1.set("name", object: "今日必做")
    
    let tag2 = LCObject(className: "Tag")
    tag2.set("name", object: "老婆吩咐")
    
    let tag3 = LCObject(className: "Tag")
    tag3.set("name", object: "十分重要")
    
    let todoFolder = LCObject(className: "TodoFolder") // 新建 TodoFolder 对象
    todoFolder.set("name", object: "家庭")
    todoFolder.set("priority", object: 1)
    
    // 分别将 tag1,tag2,tag3 分别插入到关系中
    todoFolder.insertRelation("tags", object: tag1)
    todoFolder.insertRelation("tags", object: tag2)
    todoFolder.insertRelation("tags", object: tag3)
    
    todoFolder.save(){_ in} //保存到云端
```


查询一个 TodoFolder 的所有 Tag 的方式如下：



```swift
    let targetTodoFolder = LCObject(className: "TodoFolder", objectId: "5590cdfde4b00f7adb5860c8")
    let relation = todoFolder.relationForKey("tags")
    let realationQuery = relation.query;
    realationQuery.find { (result) in
        let tags = result.objects
    }
```


反过来，现在已知一个 Tag，要查询有多少个 TodoFolder 是拥有这个 Tag 的，可以使用如下代码查询：



```swift
    let tag = LCObject(className: "Tag",objectId: "5661031a60b204d55d3b7b89")
    let todoFolderQuery = LCQuery(className: "TodoFolder")
    todoFolderQuery.whereKey("Tags", LCQuery.Constraint.EqualTo(value: tag))
    todoFolderQuery.find { (result) in
        // objects 指的就是所有包含当前 tag 的 TodoFolder
        let objects = result.objects
    }
```


关于关联数据的建模是一个复杂的过程，很多开发者因为在存储方式上的选择失误导致最后构建查询的时候难以下手，不但客户端代码冗余复杂，而且查询效率低，为了解决这个问题，我们专门针对关联数据的建模推出了一个详细的文档予以介绍，详情请阅读 [iOS / OS X 数据模型设计指南](relation_guide-ios.html)。

#### 关联属性查询
正如在 [Pointer](#Pointer) 中保存 Comment 的 targetTodoFolder 属性一样，假如查询到了一些 Comment 对象，想要一并查询出每一条 Comment 对应的 TodoFolder 对象的时候，可以加上 include 关键字查询条件。同理，假如 TodoFolder 表里还有 pointer 型字段 targetAVUser 时，再加上一个递进的查询条件，形如 include(b.c)，即可一并查询出每一条 TodoFolder 对应的 AVUser 对象。代码如下：



```swift
    let query = LCQuery(className: "Comment")
    query.whereKey("targetTodoFolder", LCQuery.Constraint.Included)// 关键代码，用 LCQuery.Constraint.Included 告知云端需要返回的关联属性对应的对象的详细信息，而不仅仅是 objectId
    query.whereKey("targetTodoFolder.targetAVUser", LCQuery.Constraint.Included)// 关键代码，同上，会返回 targetAVUser 对应的对象的详细信息，而不仅仅是 objectId
    query.whereKey("createdAt", LCQuery.Constraint.Descending)
    query.limit = 10
    query.find { (result) in
        let comments = result.objects
        // comments 是最近的十条评论, 其 targetTodoFolder 字段也有相应数据
        for comment in comments!{
            print(comment.objectId?.value)
            let todoFolder = comment.get("targetTodoFolder")
            let avUser = todoFolder.get("targetAVUser")
        }
    }
```


#### 内嵌查询
假如现在有一个需求是展现点赞超过 20 次的 TodoFolder 的评论（Comment）查询出来，注意这个查询是针对评论（Comment），要实现一次查询就满足需求可以使用内嵌查询的接口：



```swift
    // 构建内嵌查询
    let innerQuery = LCQuery(className: "TodoFolder")
    innerQuery.whereKey("likes", LCQuery.Constraint.GreaterThan(value: LCNumber(20)))
    // 将内嵌查询赋予目标查询
    let query = LCQuery(className: "Comment")
    // 执行内嵌操作
    query.whereKey("targetTodoFolder", LCQuery.Constraint.MatchedQuery(query: innerQuery))
    query.find { (result) in
        let comments = result.objects
    }
    
    // 注意如果要做相反的查询可以使用
    query.whereKey("targetTodoFolder", LCQuery.Constraint.NotMatchedQuery(query: innerQuery))
    // 如此做将查询出 likes 小于或者等于 20 的 TodoFolder 的 Comment 对象
```


### CQL 查询
Cloud Query Language（CQL）是 LeanStorage 独创的使用类似 SQL 语法来实现云端查询功能的语言，具有 SQL 开发经验的开发者可以方便地使用此接口实现查询。

分别找出 status = 1 的全部 Todo 结果，以及 priority = 0 的 Todo 的总数：



```swift
    LCCQLClient.execute("select * from Todo where status = 1") { (result) in
         // result.objects 就是满足条件的 Todo 对象
        for todo in result.objects {
            let title = todo.get("title")
        }
    }

    LCCQLClient.execute("select count(*) from Todo where priority = 0") { (result) in
        // result.count 就是 priority = 0 的 Todo 的数量
    }
```


通常查询语句会使用变量参数，为此我们提供了与 Java JDBC 所使用的 PreparedStatement 占位符查询相类似的语法结构。

查询 status = 0、priority = 1 的 Todo：



```swift
    let cql = "select * from Todo where status = ? and priority = ?"
    let pvalues = [0,1]
    LCCQLClient.execute(cql, parameters: pvalues) { (result) in
        // result.objects 就是满足条件(status = 0 and priority = 1)的 Todo 对象
    }
```


目前 CQL 已经支持数据的更新 update、插入 insert、删除 delete 等 SQL 语法，更多内容请参考 [Cloud Query Language 详细指南](cql_guide.html)。



### 地理位置查询
地理位置查询是较为特殊的查询，一般来说，常用的业务场景是查询距离 xx 米之内的某个位置或者是某个建筑物，甚至是以手机为圆心，查找方圆多少范围内餐厅等等。LeanStorage 提供了一系列的方法来实现针对地理位置的查询。

#### 查询位置附近的对象
Todo 的 `whereCreated`（创建 Todo 时的位置）是一个 `LCGeoPoint` 对象，现在已知了一个地理位置，现在要查询 `whereCreated` 靠近这个位置的 Todo 对象可以使用如下代码：



```swift
    let query = LCQuery(className: "Todo")
    let point = LCGeoPoint(latitude: 39.9, longitude: 116.4)
    
    query.whereKey("whereCreated", LCQuery.Constraint.NearbyPoint(point: point))
    query.limit = 10
    query.find { (result) in
        // 离这个位置最近的 10 个 Todo 对象
        let todos = result.objects
    }
```

在上面的代码中，`nearbyTodos` 返回的是与 `point` 这一点按距离排序（由近到远）的对象数组。注意：**如果在此之后又使用了排序方法，则按距离排序会被新排序覆盖。**



#### 查询指定范围内的对象
要查找指定距离范围内的数据，可使用 `whereWithinKilometers` 、 `whereWithinMiles` 或 `whereWithinRadians` 方法。
例如，我要查询距离指定位置，2 千米范围内的 Todo：



```swift
    let query = LCQuery(className: "Todo")
    let point = LCGeoPoint(latitude: 39.9, longitude: 116.4)
    let from = LCGeoPoint.Distance(value: 1.0, unit: LCGeoPoint.Unit.Kilometer)
    let to = LCGeoPoint.Distance(value: 2.0, unit: LCGeoPoint.Unit.Kilometer)
    // 查询离指定 point 距离在 1.0 和 2.0 公里的 Todo
    query.whereKey("whereCreated", LCQuery.Constraint.NearbyPointWithRange(point: point, from: from, to: to))
```


#### 注意事项

使用地理位置需要注意以下方面：

* 每个 `LCObject` 数据对象中只能有一个 `LCGeoPoint` 对象的属性。
* 地理位置的点不能超过规定的范围。纬度的范围应该是在 `-90.0` 到 `90.0` 之间，经度的范围应该是在 `-180.0` 到 `180.0` 之间。如果添加的经纬度超出了以上范围，将导致程序错误。

* iOS 8.0 之后，使用定位服务之前，需要调用 `[locationManager requestWhenInUseAuthorization]` 或 `[locationManager requestAlwaysAuthorization]` 来获取用户的「使用期授权」或「永久授权」，而这两个请求授权需要在 `info.plist` 里面对应添加 `NSLocationWhenInUseUsageDescription` 或 `NSLocationAlwaysUsageDescription` 的键值对，值为开启定位服务原因的描述。SDK 内部默认使用的是「使用期授权」。




### 查询性能优化

影响查询性能的因素很多。特别是当查询结果的数量超过 10 万，查询性能可能会显著下降或出现瓶颈。以下列举一些容易降低性能的查询方式，开发者可以据此进行有针对性的调整和优化，或尽量避免使用。

- 不等于和不包含查询（无法使用索引）
- 通配符在前面的字符串查询（无法使用索引）
- 有条件的 count（需要扫描所有数据）
- skip 跳过较多的行数（相当于需要先查出被跳过的那些行）
- 无索引的排序（另外除非复合索引同时覆盖了查询和排序，否则只有其中一个能使用索引）
- 无索引的查询（另外除非复合索引同时覆盖了所有条件，否则未覆盖到的条件无法使用索引，如果未覆盖的条件区分度较低将会扫描较多的数据）

## 用户

用户系统几乎是每款应用都要加入的功能。除了基本的注册、登录和密码重置，移动端开发还会使用手机号一键登录、短信验证码登录等功能。LeanStorage 提供了一系列接口来帮助开发者快速实现各种场景下的需求。

`LCUser` 是用来描述一个用户的特殊对象，与之相关的数据都保存在 `_User` 数据表中。

### 用户的属性

#### 默认属性
用户名、密码、邮箱是默认提供的三个属性，访问方式如下：



<div class="callout callout-info">当前版本的 Swift SDK 尚未实现本地的持久化存储， 因此只能在登录成功之后访问 `LCUser.current`。</div>

```swift
    let username = LCUser.current?.username // 当前用户名
    let email = LCUser.current?.email // 当前用户的邮箱

    // 请注意，以下代码无法获取密码
    let password = LCUser.current?.password
```


请注意代码中，密码是仅仅是在注册的时候可以设置的属性（这部分代码可参照 [用户名和密码注册](#用户名和密码注册)），它在注册完成之后并不会保存在本地（SDK 不会以明文保存密码这种敏感数据），所以在登录之后，再访问密码这个字段是为**空的**。

#### 自定义属性
用户对象和普通对象一样也支持添加自定义属性。例如，为当前用户添加年龄属性：



```swift
    LCUser.current?.set("age", object: "27")
    LCUser.current?.save(){ _ in }
```


#### 属性的修改

很多开发者都有这样的疑问：为什么我不能修改任意一个用户的属性？原因如下。

> 很多时候，就算是开发者也不要轻易修改用户的基本信息，例如用户的手机号、社交账号等个人信息都比较敏感，应该由用户在 App 中自行修改。所以为了保证用户的数据仅在用户自己已登录的状态下才能修改，云端对所有针对 `LCUser` 对象的数据操作都要做验证。

假如，刚才我们为当前用户添加了一个 age 属性，现在我们来修改它：



```swift
    LCUser.current?.set("age", object: "25")
    LCUser.current?.save(){ _ in }
```


细心的开发者应该已经发现 `LCUser` 在自定义属性上的使用与一般的 `LCObject` 没本质区别。

### 注册


#### 用户名和密码注册

采用「用户名 + 密码」注册时需要注意：密码是以明文方式通过 HTTPS 加密传输给云端，云端会以密文存储密码，并且我们的加密算法是无法通过所谓「彩虹表撞库」获取的，这一点请开发者放心。换言之，用户的密码只可能用户本人知道，开发者不论是通过控制台还是 API 都是无法获取。另外我们需要强调<u>在客户端，应用切勿再次对密码加密，这会导致重置密码等功能失效</u>。

例如，注册一个用户的示例代码如下（用户名 `Tom` 密码 `cat!@#123`）：



```swift
    let randomUser = LCUser()
    randomUser.username = LCString("Tom")
    randomUser.password = LCString("leancloud")
    randomUser.signUp()
```



我们建议在可能的情况下尽量使用异步版本的方法，这样就不会影响到应用程序主 UI 线程的响应。


如果注册不成功，请检查一下返回的错误对象。最有可能的情况是用户名已经被另一个用户注册，错误代码 [202](error_code.html#_202)，即 `_User` 表中的 `username` 字段已存在相同的值，此时需要提示用户尝试不同的用户名来注册。同样，邮件 `email` 和手机号码 `mobilePhoneNumber` 字段也要求在各自的列中不能有重复值出现，否则会出现 [203](error_code.html#_203)、[214](error_code.html#_214) 错误。

开发者也可以要求用户使用 Email 做为用户名注册，即在用户提交信息后将 `_User` 表中的 `username` 和 `email` 字段都设为相同的值，这样做的好处是用户在忘记密码的情况下可以直接使用「[邮箱重置密码](#重置密码)」功能，无需再额外绑定电子邮件。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。



#### 设置手机号码

微信、陌陌等流行应用都会建议用户将账号和一个手机号绑定，这样方便进行身份认证以及日后的密码找回等安全模块的使用。我们也提供了一整套发送短信验证码以及验证手机号的流程，这部分流程以及代码演示请参考 [iOS / OS X 短信服务使用指南](sms_guide-ios.html#注册验证)。

#### 验证邮箱

许多应用会通过验证邮箱来确认用户注册的真实性。如果在 [应用控制台 > 应用设置 > 应用选项](https://leancloud.cn/app.html?appid={{appid}}#/permission) 中勾选了 **用户注册时，发送验证邮件**，那么当一个 `AVUser` 在注册时设置了邮箱，云端就会向该邮箱自动发送一封包含了激活链接的验证邮件，用户打开该邮件并点击激活链接后便视为通过了验证。有些用户可能在注册之后并没有点击激活链接，而在未来某一个时间又有验证邮箱的需求，这时需要调用如下接口让云端重新发送验证邮件：



```swift
    LCUser.requestVerificationMail(email: "abc@xyz.com") { result in
        switch result {
        case .Success:
            // ...
            break
        case .Failure(let error):
            // ...
            break
        }
    }
```


### 登录

我们提供了多种登录方式，以满足不同场景的应用。



#### 用户名和密码登录



```swift
LCUser.logIn(username: "Tom", password: "leancloud", completion: { ( result ) in
        let user = result.object! as LCUser
    })
```


#### 手机号和密码登录

请确保已详细阅读了 [iOS / OS X 短信服务使用指南](sms_guide-ios.html#注册验证) 这一小节的内容，才可以顺利理解手机号匹配密码登录的流程以及适用范围。

用户的手机号只要经过了验证，就可以使用手机号密码登录的功能，否则登录会失败。



```swift
    LCUser.logIn(mobilePhoneNumber: "13577778888", password: "leancloud") { _ in }
```


#### 手机号和验证码登录

中国电信、中国联通、中国移动，这三大运营商的官网均支持「手机号 + 密码」和「手机号 + 随机验证码」的登录方式，我们也提供了这些方式。

首先，调用发送登录验证码的接口：



```swift
    LCUser.requestLoginShortCode(mobilePhoneNumber: "13577778888") { _ in }
```


然后在界面上引导用户输入收到的 6 位短信验证码：



```swift
    LCUser.logIn(mobilePhoneNumber: "13577778888", shortCode: "238825"){ _ in }
```



### 用户的查询
请注意，**新创建的应用的用户表 `_User` 默认关闭了查询权限**。你可以通过 Class 权限设置打开查询权限，请参考 [数据与安全 · Class 级别的权限](data_security.html#Class_级别的_ACL)。我们推荐开发者在 [云引擎](leanengine_overview.html) 中封装用户查询，只查询特定条件的用户，避免开放用户表的全部查询权限。

查询用户代码如下：


```objc
  let query = LCQuery(className: "_User")
```


### 浏览器中查看用户表

用户表是一个特殊的表，专门存储用户对象。在浏览器端，你会看到一个 `_User` 表。

## 角色
关于用户与角色的关系，我们有一个更为详尽的文档介绍这部分的内容，并且针对权限管理有深入的讲解，详情请点击 [iOS / OS X 权限管理使用指南](acl_guide-ios.html)。


## 子类化

子类化推荐给进阶的开发者在进行代码重构的时候做参考。 你可以用 `LCObject` 访问到所有的数据，用 `get` 方法获取任意字段。 在成熟的代码中，子类化有很多优势，包括降低代码量，具有更好的扩展性，和支持自动补全。

子类化是可选的，请对照下面的例子来加深理解：

```swift
let student = LCObject(className:"Student")
student.set("name", object: "小明")
student.save()
```

可改写成:

```swift
let student = Student()
student.name = "小明"
student.save()
```

这样代码看起来是不是更简洁呢？

### 子类化的实现

要实现子类化，需要下面两个步骤：

1. 继承 `LCObject`；
2. 重载静态方法 `objectClassName`，返回的字符串是原先要传递给 `LCObject(className:)` 初始化方法的参数。如果不实现，默认返回的是类的名字。**请注意：`LCUser` 子类化后必须返回 `_User`**。

下面是实现 Student 子类化的例子：

```swift
import LeanCloud

class Student: LCObject {
    dynamic var name: LCString?

    override static func objectClassName() -> String {
        return "Student"
    }
}
```

### 属性

为 `LCObject` 的子类添加自定义的属性和方法，可以更好地将这个类的逻辑封装起来。

自定义属性必须使用 `dynamic var` 来声明，请看下面的例子是怎么添加一个「年龄」属性：


```swift
import LeanCloud

class Student: LCObject {
    dynamic var age: LCNumber?
}
```

这样就可以通过 `student.age = 19` 这样的方式来读写 `age` 字段了，当然也可以写成：

```swift
student.set("age", object: 19)
```














