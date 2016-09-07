





#  iOS / OS X 数据存储开发指南

数据存储（LeanStorage）是 LeanCloud 提供的核心功能之一，它的使用方法与传统的关系型数据库有诸多不同。下面我们将其与传统数据库的使用方法进行对比，让大家有一个初步了解。

下面这条 SQL 语句在绝大数的关系型数据库都可以执行，其结果是在 Todo 表里增加一条新数据：

```sql
  INSERT INTO Todo (title, content) VALUES ('工程师周会', '每周工程师会议，周一下午2点')
```

使用传统的关系型数据库作为应用的数据源几乎无法避免以下步骤：

- 插入数据之前一定要先创建一个表结构，并且随着之后需求的变化，开发者需要不停地修改数据库的表结构，维护表数据。
- 每次插入数据的时候，客户端都需要连接数据库来执行数据的增删改查（CRUD）操作。

使用 LeanStorage，实现代码如下：



```objc
    AVObject *todo = [AVObject objectWithClassName:@"Todo"];
    [todo setObject:@"工程师周会" forKey:@"title"];
    [todo setObject:@"每周工程师会议，周一下午2点" forKey:@"content"];
    [todo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // 存储成功
        } else {
            // 失败的话，请检查网络环境以及 SDK 配置是否正确
        }
    }];
```


使用 LeanStorage 的特点在于：

- 不需要单独维护表结构。例如，为上面的 Todo 表新增一个 `location` 字段，用来表示日程安排的地点，那么刚才的代码只需做如下变动：

  

```objc
    AVObject *todo = [AVObject objectWithClassName:@"Todo"];
    [todo setObject:@"工程师周会" forKey:@"title"];
    [todo setObject:@"每周工程师会议，周一下午2点" forKey:@"content"];
    [todo setObject:@"会议室" forKey:@"location"];// 只要添加这一行代码，云端就会自动添加这个字段
    [todo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // 存储成功
        } else {
            // 失败的话，请检查网络环境以及 SDK 配置是否正确
        }
    }];
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


请阅读 [iOS / OS X 安装指南](sdk_setup-ios.html)。






## 对象

`AVObject` 是 LeanStorage 对复杂对象的封装，每个 `AVObject` 包含若干属性值对，也称键值对（key-value）。属性的值是与 JSON 格式兼容的数据。通过 REST API 保存对象需要将对象的数据通过 JSON 来编码。这个数据是无模式化的（Schema Free），这意味着你不需要提前标注每个对象上有哪些 key，你只需要随意设置 key-value 对就可以，云端会保存它。

### 数据类型
`AVObject` 支持以下数据类型：


```objc
NSNumber     *boolean    = @(YES);
NSNumber     *number     = [NSNumber numberWithInt:2015];
NSString     *string     = [NSString stringWithFormat:@"%@ 年度音乐排行", number];
NSDate       *date       = [NSDate date];

NSData       *data       = [@"短篇小说" dataUsingEncoding:NSUTF8StringEncoding];
NSArray      *array      = [NSArray arrayWithObjects:
                              string,
                              number,
                              nil];
NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                              number, @"数字",
                              string, @"字符串",
                              nil];

AVObject     *object     = [AVObject objectWithClassName:@"DataTypes"];
[object setObject:boolean    forKey:@"testBoolean"];
[object setObject:number     forKey:@"testInteger"];
[object setObject:string     forKey:@"testString"];
[object setObject:date       forKey:@"testDate"];
[object setObject:data       forKey:@"testData"];
[object setObject:array      forKey:@"testArray"];
[object setObject:dictionary forKey:@"testDictionary"];
[object saveInBackground];
```

此外，NSDictionary 和 NSArray 支持嵌套，这样在一个 `AVObject` 中就可以使用它们来储存更多的结构化数据。



我们**不推荐**在 `AVObject` 中使用 `NSData` 来储存大块的二进制数据，比如图片或整个文件。**每个 `AVObject` 的大小都不应超过 128 KB**。如果需要储存更多的数据，建议使用 [`AVFile`](#文件)。


若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。

### 构建对象
构建一个 `AVObject` 可以使用如下方式：



```objc
    // objectWithClassName 参数对应控制台中的 Class Name
    AVObject *todo = [AVObject objectWithClassName:@"Todo"];

    // 或调用实例方法创建一个对象
    AVObject *todo = [[AVObject alloc] initWithClassName:@"Todo"];

    // 以上两行代码完全等价
```


每个 objectId 必须有一个 Class 类名称，这样云端才知道它的数据归属于哪张数据表。

### 保存对象
现在我们保存一个 `TodoFolder`，它可以包含多个 Todo，类似于给行程按文件夹的方式分组。我们并不需要提前去后台创建这个名为 **TodoFolder** 的 Class 类，而仅需要执行如下代码，云端就会自动创建这个类：



```objc
    AVObject *todoFolder = [[AVObject alloc] initWithClassName:@"TodoFolder"];// 构建对象
    [todoFolder setObject:@"工作" forKey:@"name"];// 设置名称
    [todoFolder setObject:@1 forKey:@"priority"];// 设置优先级
    [todoFolder saveInBackground];// 保存到云端
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



```objc
    // 执行 CQL 语句实现新增一个 TodoFolder 对象
    [AVQuery doCloudQueryInBackgroundWithCQL:@"insert into TodoFolder(name, priority) values('工作', 1) " callback:^(AVCloudQueryResult *result, NSError *error) {
        // 如果 error 为空，说明保存成功

    }];
```



#### 保存选项

`AVObject` 对象在保存时可以设置选项来快捷完成关联操作，可用的选项属性有：

选项 | 类型 | 说明
--- | --- | ---
<code class="text-nowrap">fetch_when_save</code> | BOOL | 对象成功保存后，自动返回该对象在云端的最新数据。用途请参考 [更新计数器](#更新计数器)。
`where` | `AVQuery`  | 当 query 中的条件满足后对象才能成功保存，否则放弃保存，并返回错误码 305。<br/><br/>开发者原本可以通过 `AVQuery` 和 `AVObject` 分两步来实现这样的逻辑，但如此一来无法保证操作的原子性从而导致并发问题。该选项可以用来判断多用户更新同一对象数据时可能引发的冲突。

<a id="saveoption_query_example" name="saveoption_query_example"></a>【示例】一篇 wiki 文章允许任何人来修改，它的数据表字段有：**content**（wiki 内容）、**version**（版本号）。每当 wiki 内容被更新后，其 version 也需要更新（+1）。用户 A 要修改这篇 wiki，从数据表中取出时其 version 值为 3，当用户 A 完成编辑要保存新内容时，如果数据表中的 version 仍为 3，表明这段时间没有其他用户更新过这篇 wiki，可以放心保存；如果不是 3，开发者可以拒绝掉用户 A 的修改，或执行其他自定义的业务逻辑。



```objc
// 获取 version 值
NSNumber *version = [object objectForKey:@"version"];

AVSaveOption *option = [[AVSaveOption alloc] init];

AVQuery *query = [[AVQuery alloc] init];
[query whereKey:@"version" equalTo:version];

option.query = query;

[object saveInBackgroundWithOption:option block:^(BOOL succeeded, NSError *error) {
    if ( error.code == 305 ){
      NSLog(@"无法保存修改，wiki 已被他人更新。");
    }
}];
```



### 获取对象
每个被成功保存在云端的对象会有一个唯一的 Id 标识 `objectId`，因此获取对象的最基本的方法就是根据 `objectId` 来查询：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query getObjectInBackgroundWithId:@"558e20cbe4b060308e3eb36c" block:^(AVObject *object, NSError *error) {
        // object 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例
    }];
```


如果不想使用查询，还可以通过从本地构建一个 `objectId`，然后调用接口从云端把这个 `objectId` 的数据拉取到本地，示例代码如下：



```objc
    // 第一个参数是 className，第二个参数是 objectId
    AVObject *todo =[AVObject objectWithClassName:@"Todo" objectId:@"558e20cbe4b060308e3eb36c"];
    [todo fetchInBackgroundWithBlock:^(AVObject *avObject, NSError *error) {
        NSString *title = avObject[@"title"];// 读取 title
        NSString *content = avObject[@"content"]; // 读取 content
    }];
```



#### 获取 objectId
每一次对象存储成功之后，云端都会返回 `objectId`，它是一个全局唯一的属性。



```objc
    AVObject *todo = [AVObject objectWithClassName:@"Todo"];
    [todo setObject:@"工程师周会" forKey:@"title"];
    [todo setObject:@"每周工程师会议，周一下午2点" forKey:@"content"];
    [todo setObject:@"会议室" forKey:@"location"];// 只要添加这一行代码，云端就会自动添加这个字段
    [todo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // 存储成功
            NSLog(@"%@",todo.objectId);// 保存成功之后，objectId 会自动从云端加载到本地
        } else {
            // 失败的话，请检查网络环境以及 SDK 配置是否正确
        }
    }];
```



#### 访问对象的属性
访问 Todo 的属性的方式为：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query getObjectInBackgroundWithId:@"558e20cbe4b060308e3eb36c" block:^(AVObject *object, NSError *error) {
        // object 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例
        int priority = [[object objectForKey:@"priority"] intValue];
        NSString *location = [object objectForKey:@"location"];
        NSString *title = object[@"title"];
        NSString *content = object[@"content"];

        // 获取三个特殊属性
        NSString *objectId = object.objectId;
        NSDate *updatedAt = object.updatedAt;
        NSDate *createdAt = object.createdAt;
    }];
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



#### 同步对象
多终端共享一个数据时，为了确保当前客户端拿到的对象数据是最新的，可以调用刷新接口来确保本地数据与云端的同步：


```objc
    // 使用已知 objectId 构建一个 AVObject
    AVObject *anotherTodo = [AVObject objectWithClassName:@"Todo" objectId:@"5656e37660b2febec4b35ed7"];
    // 然后调用刷新的方法，将数据从云端拉到本地
    [anotherTodo fetchIfNeededInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        // 此处调用 fetchIfNeededInBackgroundWithBlock 和 refreshInBackgroundWithBlock 效果一样。
    }];
```


在更新对象操作后，对象本地的 `updatedAt` 字段（最后更新时间）会被刷新，直到下一次 save 或 fetch 操作，`updatedAt` 的最新值才会被同步到云端，这样做是为了减少网络流量传输。

如果需要在保存或更新之后让本地数据自动与云端保持一致，可以使用 [保存选项 `fetch_when_save`](#保存选项)：


```
    todo.fetchWhenSave = true;// 设置 fetchWhenSave 为 true
    [todo saveInBackground];
```


#### 同步指定属性

目前 Todo 这个类已有四个自定义属性：`priority`、`content`、`location` 和 `title`。为了节省流量，现在只想刷新 `priority` 和 `location` 可以使用如下方式：



```objc
    AVObject *theTodo = [AVObject objectWithClassName:@"Todo" objectId:@"564d7031e4b057f4f3006ad1"];
    NSArray *keys = [NSArray arrayWithObjects:@"priority", @"location",nil];// 指定刷新的 key 数组
    [theTodo fetchInBackgroundWithKeys:keys block:^(AVObject *object, NSError *error) {
        // theTodo 的 priority 和 location 属性的值就是与云端一致的
        NSString *priority = [object objectForKey:@"priority"];
        NSString *location = object[@"location"];
    }];
```


**刷新操作会强行使用云端的属性值覆盖本地的属性**。因此如果本地有属性修改，请慎用这类接口。



### 更新对象

LeanStorage 上的更新对象都是针对单个对象，云端会根据<u>有没有 objectId</u> 来决定是新增还是更新一个对象。

假如 `objectId` 已知，则可以通过如下接口从本地构建一个 `AVObject` 来更新这个对象：



```objc
    // 第一个参数是 className，第二个参数是 objectId
    AVObject *todo =[AVObject objectWithClassName:@"Todo" objectId:@"558e20cbe4b060308e3eb36c"];
    // 修改属性
    [todo setObject:@"每周工程师会议，本周改为周三下午3点半。" forKey:@"content"];
    // 保存到云端
    [todo saveInBackground];
```



更新操作是覆盖式的，云端会根据最后一次提交到服务器的有效请求来更新数据。更新是字段级别的操作，未更新的字段不会产生变动，这一点请不用担心。

#### 使用 CQL 语法更新对象
LeanStorage 提供了类似 SQL 语法中的 Update 方式更新一个对象，例如更新一个 TodoFolder 对象可以使用下面的代码：



```objc
    // 执行 CQL 语句实现更新一个 TodoFolder 对象
    [AVQuery doCloudQueryInBackgroundWithCQL:@"update TodoFolder set name='家庭' where objectId='558e20cbe4b060308e3eb36c'" callback:^(AVCloudQueryResult *result, NSError *error) {
        // 如果 error 为空，说明保存成功

    }];
```


#### 更新计数器

这是原子操作（Atomic Operation）的一种。
为了存储一个整型的数据，LeanStorage 提供对任何数字字段进行原子增加（或者减少）的功能。比如一条微博，我们需要记录有多少人喜欢或者转发了它，但可能很多次喜欢都是同时发生的。如果在每个客户端都直接把它们读到的计数值增加之后再写回去，那么极容易引发冲突和覆盖，导致最终结果不准。此时就需要使用这类原子操作来实现计数器。

假如，现在增加一个记录查看 Todo 次数的功能，一些与他人共享的 Todo 如果不用原子操作的接口，很有可能会造成统计数据不准确，可以使用如下代码实现这个需求：


```objc
    AVObject *theTodo = [AVObject objectWithClassName:@"Todo" objectId:@"564d7031e4b057f4f3006ad1"];
    [theTodo setObject:[NSNumber numberWithInt:0] forKey:@"views"]; //初始值为 0
    [theTodo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // 原子增加查看的次数
        [theTodo incrementKey:@"views"];
        // 保存时自动取回云端最新数据
        theTodo.fetchWhenSave = true;

        [theTodo saveInBackground];

        // 也可以使用 incrementKey:byAmount: 来给 Number 类型字段累加一个特定数值。
        [theTodo incrementKey:@"views" byAmount:@(5)];
        [theTodo saveInBackground];
        // 因为使用了 fetchWhenSave 选项，saveInBackground 调用之后，如果成功的话，对象的计数器字段是当前系统最新值。
    }];
```



#### 更新数组

这也是原子操作的一种。使用以下方法可以方便地维护数组类型的数据：



* `addObject:forKey:`<br>
  `addObjectsFromArray:forKey:`<br>
  将指定对象附加到数组末尾。
* `addUniqueObject:forKey:`<br>
  `addUniqueObjectsFromArray:forKey:`<br>
  如果不确定某个对象是否已包含在数组字段中，可以使用此操作来添加。对象的插入位置是随机的。  
* `removeObject:forKey:`<br>
  `removeObjectsInArray:forKey:`<br>
  从数组字段中删除指定对象的所有实例。



例如，Todo 对象有一个提醒日期 reminders，它是一个数组，代表这个日程会在哪些时间点提醒用户。比如有些拖延症患者会把闹钟设为早上的 7:10、7:20、7:30：



```objc
-(NSDate*) getDateWithDateString:(NSString*) dateString{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:dateString];
    return date;
}

-(void)addReminders{
    NSDate *reminder1= [self getDateWithDateString:@"2015-11-11 07:10:00"];
    NSDate *reminder2= [self getDateWithDateString:@"2015-11-11 07:20:00"];
    NSDate *reminder3= [self getDateWithDateString:@"2015-11-11 07:30:00"];

    NSArray *reminders =[NSArray arrayWithObjects:reminder1, reminder1,reminder3, nil];// 添加提醒时间

    AVObject *todo = [AVObject objectWithClassName:@"Todo"];
    [todo addUniqueObjectsFromArray:reminders forKey:@"reminders"];
    [todo saveInBackground];
}
```




### 删除对象

假如某一个 Todo 完成了，用户想要删除这个 Todo 对象，可以如下操作：



```objc
    [todo deleteInBackground];
```


<div class="callout callout-danger">删除对象是一个较为敏感的操作。在控制台创建对象的时候，默认开启了权限保护，关于这部分的内容请阅读《[iOS / OS X 权限管理使用指南](acl_guide-ios.html)》。</div>

#### 使用 CQL 语法删除对象
LeanStorage 提供了类似 SQL 语法中的 Delete 方式删除一个对象，例如删除一个 Todo 对象可以使用下面的代码：


```objc
    // 执行 CQL 语句实现删除一个 Todo 对象
    [AVQuery doCloudQueryInBackgroundWithCQL:@"delete from Todo where objectId='558e20cbe4b060308e3eb36c'" callback:^(AVCloudQueryResult *result, NSError *error) {
        // 如果 error 为空，说明保存成功

    }];
```







### 批量操作

为了减少网络交互的次数太多带来的时间浪费，你可以在一个请求中对多个对象进行创建、更新、删除、获取。接口都在 `AVObject` 这个类下面：



```objc
// 批量创建、更新
+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error;
+ (void)saveAllInBackground:(NSArray *)objects
              block:(AVBooleanResultBlock)block;

// 批量删除
+ (BOOL)deleteAll:(NSArray *)objects error:(NSError **)error;
+ (void)deleteAllInBackground:(NSArray *)objects
                        block:(AVBooleanResultBlock)block;

// 批量获取
+ (BOOL)fetchAll:(NSArray *)objects error:(NSError **)error;
+ (void)fetchAllInBackground:(NSArray *)objects
                       block:(AVArrayResultBlock)block;                        
```


批量设置 Todo 已经完成：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSArray<AVObject *> *todos = objects;
        for (AVObject *todo in todos) {
            todo[@"status"] = @1;
        }

        [AVObject saveAllInBackground:todos block:^(BOOL succeeded, NSError *error) {
            if (error) {
                // 网络错误
            } else {
                // 保存成功
            }
        }];
    }];
```



不同类型的批量操作所引发不同数量的 API 调用，具体请参考 [API 调用次数的计算](faq.html#API_调用次数的计算)。


### 后台运行
细心的开发者已经发现，在所有的示例代码中几乎都是用了异步来访问 LeanStorage 云端，形如 `xxxxInBackground` 的方法都是提供给开发者在主线程调用用以实现后台运行的方法，因此开发者在主线程可以放心的调用这种命名方式的函数。另外，需要强调的是：**回调函数的代码是在主线程执行。**



### 离线存储对象

大多数保存功能可以立刻执行，并通知应用「保存完毕」。不过若不需要知道保存完成的时间，则可使用 saveEventually 来代替。

它的优点在于：如果用户目前尚未接入网络，saveEventually 会缓存设备中的数据，并在网络连接恢复后上传。如果应用在网络恢复之前就被关闭了，那么当它下一次打开时，LeanStorage 会再次尝试保存操作。

所有 saveEventually（或 deleteEventually）的相关调用，将按照调用的顺序依次执行。因此，多次对某一对象使用 saveEventually 是安全的。



### 关联数据

#### `AVRelation`
对象可以与其他对象相联系。如前面所述，我们可以把一个 `AVObject` 的实例 A，当成另一个 `AVObject` 实例 B 的属性值保存起来。这可以解决数据之间一对一或者一对多的关系映射，就像关系型数据库中的主外键关系一样。

例如，一个 TodoFolder 包含多个 Todo ，可以用如下代码实现：



```objc
    AVObject *todoFolder = [[AVObject alloc] initWithClassName:@"TodoFolder"];// 构建对象
    [todoFolder setObject:@"工作" forKey:@"name"];// 设置名称
    [todoFolder setObject:@1 forKey:@"priority"];// 设置优先级

    AVObject *todo1 = [[AVObject alloc] initWithClassName:@"Todo"];
    [todo1 setObject:@"工程师周会" forKey:@"title"];
    [todo1 setObject:@"每周工程师会议，周一下午2点" forKey:@"content"];
    [todo1 setObject:@"会议室" forKey:@"location"];

    AVObject *todo2 = [[AVObject alloc] initWithClassName:@"Todo"];
    [todo2 setObject:@"维护文档" forKey:@"title"];
    [todo2 setObject:@"每天 16：00 到 18：00 定期维护文档" forKey:@"content"];
    [todo2 setObject:@"当前工位" forKey:@"location"];

    AVObject *todo3 = [[AVObject alloc] initWithClassName:@"Todo"];
    [todo3 setObject:@"发布 SDK" forKey:@"title"];
    [todo3 setObject:@"每周一下午 15：00" forKey:@"content"];
    [todo3 setObject:@"SA 工位" forKey:@"location"];

    [AVObject saveAllInBackground:@[todo1,todo2,todo3] block:^(BOOL succeeded, NSError *error) {
        if (error) {
            // 出现错误
        } else {
            // 保存成功
            AVRelation *relation = [todoFolder relationForKey:@"containedTodos"];// 新建一个 AVRelation
            [relation addObject:todo1];
            [relation addObject:todo2];
            [relation addObject:todo3];
            // 上述 3 行代码表示 relation 关联了 3 个 Todo 对象

            [todoFolder saveInBackground];// 保存到云端
        }
    }];
```


#### Pointer
Pointer 只是个描述并没有具象的类与之对应，它与 `AVRelation` 不一样的地方在于：`AVRelation` 是在**一对多**的「一」这一方（上述代码中的一指 TodoFolder）保存一个 `AVRelation` 属性，这个属性实际上保存的是对被关联数据**多**的这一方（上述代码中这个多指 Todo）的一个 Pointer 的集合。而反过来，LeanStorage 也支持在「多」的这一方保存一个指向「一」的这一方的 Pointer，这样也可以实现**一对多**的关系。

简单的说， Pointer 就是一个外键的指针，只是在 LeanCloud 控制台做了显示优化。

现在有一个新的需求：用户可以分享自己的 TodoFolder 到广场上，而其他用户看见可以给与评论，比如某玩家分享了自己想买的游戏列表（TodoFolder 包含多个游戏名字），而我们用 Comment 对象来保存其他用户的评论以及是否点赞等相关信息，代码如下：



```objc
    AVObject *comment = [[AVObject alloc] initWithClassName:@"Comment"];// 构建 Comment 对象
    [comment setObject:@1 forKey:@"like"];// 如果点了赞就是 1，而点了不喜欢则为 -1，没有做任何操作就是默认的 0
    [comment setObject:@"这个太赞了！楼主，我也要这些游戏，咱们团购么？" forKey:@"content"];// 留言的内容

    // 假设已知了被分享的该 TodoFolder 的 objectId 是 5590cdfde4b00f7adb5860c8
    [comment setObject:[AVObject objectWithClassName:@"TodoFolder" objectId:@"5590cdfde4b00f7adb5860c8"] forKey:@"targetTodoFolder"];
    // 以上代码的执行结果是在 comment 对象上有一个名为 targetTodoFolder 属性，它是一个 Pointer 类型，指向 objectId 为 5590cdfde4b00f7adb5860c8 的 TodoFolder
```


相关内容可参考 [关联数据查询](#AVRelation_查询)。

#### 地理位置
地理位置是一个特殊的数据类型，LeanStorage 封装了 `AVGeoPoint` 来实现存储以及相关的查询。

首先要创建一个 `AVGeoPoint` 对象。例如，创建一个北纬 39.9 度、东经 116.4 度的 `AVGeoPoint` 对象（LeanCloud 北京办公室所在地）：



``` objc
AVGeoPoint *point = [AVGeoPoint geoPointWithLatitude:39.9 longitude:116.4];
```


假如，添加一条 Todo 的时候为该 Todo 添加一个地理位置信息，以表示创建时所在的位置：


``` objc
[todo setObject:point forKey:@"whereCreated"];
```


同时请参考 [地理位置查询](#地理位置查询)。



### 序列化和反序列化
在实际的开发中，把 `AVObject` 当做参数传递的时候，会涉及到复杂对象的拷贝的问题，因此 `AVObject` 也提供了序列化和反序列化的方法：

序列化：


```objc
    AVObject *todoFolder = [[AVObject alloc] initWithClassName:@"TodoFolder"];// 构建对象
    [todoFolder setObject:@"工作" forKey:@"name"];// 设置名称
    [todoFolder setObject:@1 forKey:@"priority"];// 设置优先级
    [todoFolder setObject:[AVUser currentUser] forKey:@"owner"];// 这里就是一个 Pointer 类型，指向当前登录的用户

    NSMutableDictionary *serializedJSONDictionary = [todoFolder dictionaryForObject];//获取序列化后的字典
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serializedJSONDictionary options:0 error:&err];//获取 JSON 数据
    NSString *serializedString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];// 获取 JSON 字符串
    // serializedString 的内容是：{"name":"工作","className":"TodoFolder","priority":1}
```


反序列化：


```objc
    NSMutableDictionary *objectDictionary = [NSMutableDictionary dictionaryWithCapacity:10];// 声明一个 NSMutableDictionary
    [objectDictionary setObject:@"工作" forKey:@"name"];
    [objectDictionary setObject:@1 forKey:@"priority"];
    [objectDictionary setObject:@"TodoFolder" forKey:@"className"];

    AVObject *todoFolder = [AVObject objectWithDictionary:objectDictionary];// 由 NSMutableDictionary 转化一个 AVObject

    [todoFolder saveInBackground];// 保存到云端
```








### 数据协议
很多开发者在使用 LeanStorage 初期都会产生疑惑：客户端的数据类型是如何被云端识别的？
因此，我们有必要重点介绍一下 LeanStorage 的数据协议。

先从一个简单的日期类型入手，比如在 iOS / OS X 中，默认的日期类型是 `NSDate`，下面会详细讲解一个
 `NSDate` 是如何被云端正确的按照日期格式存储的。

为一个普通的 `AVObject` 的设置一个 `NSDate` 的属性，然后调用保存的接口：




iOS / OS X SDK 在真正调用保存接口之前，会自动的调用一次序列化的方法，将 `NSDate` 类型的数据，转化为如下格式的数据：

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
`AVRelation`| `{"__type": "Relation","className": "Todo"}`







## 文件
文件存储也是数据存储的一种方式，图像、音频、视频、通用文件等等都是数据的载体，另外很多开发者习惯了把复杂对象序列化之后保存成文件（如 `.json` 或者 `.xml` )。文件存储在 LeanStorage 中被单独封装成一个 `AVFile` 来实现文件的上传、下载等操作。

### 文件上传
文件的上传指的是开发者调用接口将文件存储在云端，并且返回文件最终的 URL 的操作。


#### 从数据流构建文件
`AVFile` 支持图片、视频、音乐等常见的文件类型，以及其他任何二进制数据，在构建的时候，传入对应的数据流即可：



```objc
    NSData *data = [@"我的工作经历" dataUsingEncoding:NSUTF8StringEncoding];
    AVFile *file = [AVFile fileWithName:@"resume.txt" data:data];
```


上例将文件命名为 `resume.txt`，这里需要注意两点：

- 不必担心文件名冲突。每一个上传的文件都有惟一的 ID，所以即使上传多个文件名为 `resume.txt` 的文件也不会有问题。
- 给文件添加扩展名非常重要。云端通过扩展名来判断文件类型，以便正确处理文件。所以要将一张 PNG 图片存到 `AVFile` 中，要确保使用 `.png` 扩展名。



#### 从本地路径构建文件
大多数的客户端应用程序都会跟本地文件系统产生交互，常用的操作就是读取本地文件，如下代码可以实现使用本地文件路径构建一个 `AVFile`：



```objc
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"LeanCloud.png"];
    AVFile *file = [AVFile fileWithName:fileName contentsAtPath: imagePath];
```





#### 从网络路径构建文件
从一个已知的 URL 构建文件也是很多应用的需求。例如，从网页上拷贝了一个图像的链接，代码如下：


```objc
    AVFile *file =[AVFile fileWithURL:@"http://ww3.sinaimg.cn/bmiddle/596b0666gw1ed70eavm5tg20bq06m7wi.gif"];
    [file getData];// 注意这一步很重要，这是把图片从原始地址拉去到本地
    [file save];
```




我们需要做出说明的是，[从本地路径构建文件](#从本地路径构建文件) 会<u>产生实际上传的流量</u>，并且文件最后是存在云端，而 [从网络路径构建文件](#从网络路径构建文件) 的文件实体并不存储在云端，只是会把文件的物理地址作为一个字符串保存在云端。

#### 执行上传
上传的操作调用方法如下：


```objc
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(file.url);//返回一个唯一的 Url 地址
    }];
```



#### 上传进度监听
一般来说，上传文件都会有一个上传进度条显示用以提高用户体验：



```objc
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
      // 成功或失败处理...
    } progressBlock:^(int percentDone) {
      // 上传进度数据，percentDone 介于 0 和 100。
    }];
```





### 文件下载
客户端 SDK 接口可以下载文件并把它缓存起来，只要文件的 URL 不变，那么一次下载成功之后，就不会再重复下载，目的是为了减少客户端的流量。


```objc
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        // data 就是文件的数据流
    } progressBlock:^(NSInteger percentDone) {
        //下载的进度数据，percentDone 介于 0 和 100。
    }];
```

请注意代码中**下载进度**数据的读取。



### 图像缩略图

保存图像时，如果想在下载原图之前先得到缩略图，方法如下：


```objc
AVFile *file = [AVFile fileWithURL:@"文件-url"];
[file getThumbnail:YES width:100 height:100 withBlock:^(UIImage *image, NSError *error) {
    }];
```


<div class="callout callout-info">注意：<strong>图片最大不超过 20 M 才可以获取缩略图。</strong> </div>

### 文件元数据

`AVFile` 的 `metaData` 属性，可以用来保存和获取该文件对象的元数据信息：


``` objc
AVFile *file = [AVFile fileWithName:@"test.jpg" contentsAtPath:@"文件-本地-路径"];
[file.metaData setObject:@(100) forKey:@"width"];
[file.metaData setObject:@(100) forKey:@"height"];
[file.metaData setObject:@"LeanCloud" forKey:@"author"];
NSError *error = nil;
[file save:&error];
```




### 删除

当文件较多时，要把一些不需要的文件从云端删除：


``` objc
[file deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
}];
```




### 清除缓存

`AVFile` 也提供了清除缓存的方法：

``` objc
//清除当前文件缓存
- (void)clearCachedFile;

//类方法, 清除所有缓存
+ (BOOL)clearAllCachedFiles;

//类方法, 清除多久以前的缓存
+ (BOOL)clearCacheMoreThanDays:(NSInteger)numberOfDays;
```



### iOS 9 适配

iOS 9 默认屏蔽了 HTTP 访问，只支持 HTTPS 访问。LeanCloud 除了文件的 getData 之外的 API 都是支持 HTTPS 访问的。 现有两种方式解决这个问题。

#### 项目中配置访问策略

一是在项目中额外配置一下该接口的访问策略。选择项目的 Info.plist，右击以 Source Code 的方式打开。在 plist -> dict 节点中加入以下文本：

```
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSExceptionDomains</key>
    <dict>
      <key>clouddn.com</key>
      <dict>
        <key>NSIncludesSubdomains</key>
        <true/>
        <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
        <true/>
      </dict>
    </dict>
  </dict>
```

或者在 Target 的 Info 标签中修改配置：

![Info.plist Setting](images/ios_qiniu_http.png)

如果是美国节点，请把上面的 `clouddn.com` 换成 `amazonaws.com`。

也可以根据项目需要，允许所有的 HTTP 访问，更多可参考 [iOS 9 适配系列教程](https://github.com/ChenYilong/iOS9AdaptationTips)。

#### 启用文件 SSL 域名

另外一种方法是在网站控制台中进入相关的应用，点击上方的设置选项卡，勾选「启用文件 SSL 域名（对应 _File 中存储的文件）」选项。这样便启用了文件 SSL 域名，支持 HTTPS 访问。如图所示：

![File SSL Config](images/ios_file_ssl_config.png)

如果启用文件 SSL 域名前已经保存了许多文件，启用之后，这些文件的 URL 也会跟着变化，来支持 HTTPS 访问。

这两种方式都能解决这个问题。但需要注意的是，实时通信组件 LeanMessage 也用了 AVFile 来保存消息的图片、音频等文件，并且把文件的地址写入到了消息内容中。开启了文件 SSL 域名后，历史消息中的文件地址将不会像控制台里 _File 表那样跟着改变。所以如果使用了实时通信组件并已上线，推荐使用方式一。


<div class="callout callout-info">注意：默认情况下，文件的删除权限是关闭的，需要进入控制台，在 [`_File` > 其他 > 权限设置 > delete](/data.html?appid={{appid}}#/_File)  中开启。</div>


## 查询
`AVQuery` 是构建针对 `AVObject` 查询的基础类。


### 创建查询实例


```objc
AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
```



### 根据 id 查询
在 [获取对象](#获取对象) 中我们介绍过如何通过 objectId 来获取对象实例，从而简单的介绍了一下 `AVQuery` 的用法，代码请参考对应的内容，不再赘述。

### 条件查询
在大多数情况下做列表展现的时候，都是根据不同条件来分类展现的，比如，我要查询所有优先级为 0 的 Todo，也就是做列表展现的时候，要展示优先级最高，最迫切需要完成的日程列表，此时基于 priority 构建一个查询就可以查询出符合需求的对象：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"priority" equalTo:@0];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSArray<AVObject *> *priorityEqualsZeroTodos = objects;// 符合 priority = 0 的 Todo 数组
    }];
```


其实，拥有传统关系型数据库开发经验的开发者完全可以翻译成如下的 SQL：

```sql
  select * from Todo where priority = 0
```
LeanStorage 也支持使用这种传统的 SQL 语句查询。具体使用方法请移步至 [Cloud Query Language（CQL）查询](#CQL_查询)。

查询默认最多返回 100 条符合条件的结果，要更改这一数值，请参考 [限定结果返回数量](#限定返回数量)。

当多个查询条件并存时，它们之间默认为 AND 关系，即查询只返回满足了全部条件的结果。建立 OR 关系则需要使用 [组合查询](#组合查询)。

注意：在简单查询中，如果对一个对象的同一属性设置多个条件，那么先前的条件会被覆盖，查询只返回满足最后一个条件的结果。例如，我们要找出优先级为 0 和 1 的所有 Todo，错误写法是：


```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"priority" equalTo:@0];
    [query whereKey:@"priority" equalTo:@1];
   // 如果这样写，第二个条件将覆盖第一个条件，查询只会返回 priority = 1 的结果
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       ...
    }];
```


正确作法是使用 [OR 关系](#OR_查询) 来构建条件。

#### 比较查询


逻辑操作 | AVQuery 方法|
---|---
等于 | `equalTo`
不等于 |  `notEqualTo`
大于 | `greaterThan`
大于等于 | `greaterThanOrEqualTo`
小于 | `lessThan`
小于等于 | `lessThanOrEqualTo`


利用上述表格介绍的逻辑操作的接口，我们可以很快地构建条件查询。

例如，查询优先级小于 2 的所有 Todo ：



```objc
[query whereKey:@"priority" lessThan:@2];
```


要查询优先级大于等于 2 的 Todo：



```objc
[query whereKey:@"priority" greaterThanOrEqualTo:@2];
```

另外，因为 Objective-C 语言本身特定的设定，boolean 值的查询很多开发者**错误地**使用了 0 和 1 进行查询。
正确的构建方式如下：

```
[query whereKey:@"booleanTest" equalTo:@(YES)];
```


比较查询**只适用于可比较大小的数据类型**，如整型、浮点等。

#### 正则匹配查询

正则匹配查询是指在查询条件中使用正则表达式来匹配数据，查询指定的 key 对应的 value 符合正则表达式的所有对象。
例如，要查询标题包含中文的 Todo 对象可以使用如下代码：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"title" matchesRegex:@"[\u4e00-\u9fa5]"];
```


正则匹配查询**只适用于**字符串类型的数据。

#### 包含查询

包含查询类似于传统 SQL 语句里面的 `LIKE %keyword%` 的查询，比如查询标题包含「李总」的 Todo：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"title" containsString:@"李总"];
```


翻译成 SQL 语句就是：

```sql
  select * from Todo where title LIKE '%李总%'
```
不包含查询与包含查询是对立的，不包含指定关键字的查询，可以使用 [正则匹配方法](#正则匹配查询) 来实现。例如，查询标题不包含「机票」的 Todo，正则表达式为 `^((?!机票).)*$`：


```objc
  AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
  [query whereKey:@"title" matchesRegex:@"^((?!机票).)*$"];
```


但是基于正则的模糊查询有两个缺点：

- 当数据量逐步增大后，查询效率将越来越低。
- 没有文本相关性排序

因此，你还可以考虑使用 [应用内搜索](#应用内搜索) 功能。它基于搜索引擎技术构建，提供更强大的搜索功能。

还有一个接口可以精确匹配不等于，比如查询标题不等于「出差、休假」的 Todo 对象：


```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    NSArray *filterArray = [NSArray arrayWithObjects:@"出差", @"休假", nil]; // NSArray
    [query whereKey:@"title" notContainedIn:filterArray];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // 标题不是「出差」和「休假」的 Todo 对象列表
        NSArray<AVObject *> *todos = objects;
    }];
```


#### 数组查询

当一个对象有一个属性是数组的时候，针对数组的元数据查询可以有多种方式。例如，在 [数组](#更新数组) 一节中我们为 Todo 设置了 reminders 属性，它就是一个日期数组，现在我们需要查询所有在 8:30 会响起闹钟的 Todo 对象：



```objc
-(NSDate*) getDateWithDateString:(NSString*) dateString{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:dateString];
    return date;
}
-(void)queryRemindersContains{
    NSDate *reminder= [self getDateWithDateString:@"2015-11-11 08:30:00"];

    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];

    // equalTo: 可以找出数组中包含单个值的对象
    [query whereKey:@"reminders" equalTo:reminder];
}
```


如果你要查询包含 8:30、9:30 这两个时间点响起闹钟的 Todo，可以使用如下代码：



```objc
-(NSDate*) getDateWithDateString:(NSString*) dateString{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:dateString];
    return date;
}

-(void)queryRemindersContainsAll{
    NSDate *reminder1= [self getDateWithDateString:@"2015-11-11 08:30:00"];
    NSDate *reminder2= [self getDateWithDateString:@"2015-11-11 09:30:00"];

    // 构建查询时间点数组
    NSArray *reminders =[NSArray arrayWithObjects:reminder1, reminder1, nil];

    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"reminders" containsAllObjectsInArray:reminders];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

    }];
}
```


注意这里是包含关系，假如有一个 Todo 会在 8:30、9:30、10:30 响起闹钟，它仍然是会被查询出来的。

#### 字符串查询
使用 `whereKey:hasPrefix:` 可以过滤出以特定字符串开头的结果，这有点像 SQL 的 LIKE 条件。因为支持索引，所以该操作对于大数据集也很高效。



```objc
    // 找出开头是「早餐」的 Todo
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"content" hasPrefix:@"早餐"];
```


#### 空值查询
假设我们的 Todo 允许用户上传图片用来帮助用户记录某些特殊的事项，但是有时候用户可能就记得自己给一个 Todo 附加过图片，但是具体又不记得这个 Todo 的关键字是什么，因此我们需要一个接口可以找出那些有图片的 Todo，此时就可以使用到空值查询的接口：



```objc
    // 存储一个带有图片的 Todo 到 LeanCloud 云端
    AVFile *aTodoAttachmentImage = [AVFile fileWithURL:@("http://www.zgjm.org/uploads/allimg/150812/1_150812103912_1.jpg")];
    AVObject *todo = [AVObject objectWithClassName:@"Todo"];
    [todo setObject:aTodoAttachmentImage forKey:@"images"];
    [todo setObject:@"记得买过年回家的火车票！！！" forKey:@"content"];
    [todo saveInBackground];

    // 使用非空值查询获取有图片的 Todo
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKeyExists:@"images"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       // objects 返回的就是有图片的 Todo 集合
    }];

    // 使用空值查询获取没有图片的 Todo
    [query whereKeyDoesNotExist:@"images"];
```


### 组合查询
组合查询就是把诸多查询条件合并成一个查询，再交给 SDK 去云端查询。方式有两种：OR 和 AND。

#### OR 查询
OR 操作表示多个查询条件符合其中任意一个即可。 例如，查询优先级是大于等于 3 或者已经完成了的 Todo：


```objc
    AVQuery *priorityQuery = [AVQuery queryWithClassName:@"Todo"];
    [priorityQuery whereKey:@"priority" greaterThanOrEqualTo:[NSNumber numberWithInt:3]];

    AVQuery *statusQuery = [AVQuery queryWithClassName:@"Todo"];
    [statusQuery whereKey:@"status" equalTo:[NSNumber numberWithInt:1]];

    AVQuery *query = [AVQuery orQueryWithSubqueries:[NSArray arrayWithObjects:statusQuery,priorityQuery,nil]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        // 返回 priority 大于等于 3 或 status 等于 1 的 Todo
    }];
```


**注意：OR 查询中，子查询中不能包含地理位置相关的查询。**

#### AND 查询
AND 操作是指只有满足了所有查询条件的对象才会被返回给客户端。例如，查询优先级小于 1 并且尚未完成的 Todo：



```objc
    AVQuery *priorityQuery = [AVQuery queryWithClassName:@"Todo"];
    [priorityQuery whereKey:@"priority" lessThan:[NSNumber numberWithInt:3]];

    AVQuery *statusQuery = [AVQuery queryWithClassName:@"Todo"];
    [statusQuery whereKey:@"status" equalTo:[NSNumber numberWithInt:0]];

    AVQuery *query = [AVQuery andQueryWithSubqueries:[NSArray arrayWithObjects:statusQuery,priorityQuery,nil]];

    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        // 返回 priority 小于 3 并且 status 等于 0 的 Todo
    }];
```


可以对新创建的 `AVQuery` 添加额外的约束，多个约束将以 AND 运算符来联接。

### 查询结果

#### 获取第一条结果
例如很多应用场景下，只要获取满足条件的一个结果即可，例如获取满足条件的第一条 Todo：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"priority" equalTo:@0];
    [query getFirstObjectInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        // object 就是符合条件的第一个 AVObject
    }];
```


#### 限定返回数量
为了防止查询出来的结果过大，云端默认针对查询结果有一个数量限制，即 `limit`，它的默认值是 100。比如一个查询会得到 10000 个对象，那么一次查询只会返回符合条件的 100 个结果。`limit` 允许取值范围是 1 ~ 1000。例如设置返回 10 条结果：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    NSDate *now = [NSDate date];
    [query whereKey:@"createdAt" lessThanOrEqualTo:now];//查询今天之前创建的 Todo
    query.limit = 10; // 最多返回 10 条结果
```


#### 跳过数量
设置 skip 这个参数可以告知云端本次查询要跳过多少个结果。将 skip 与 limit 搭配使用可以实现翻页效果，这在客户端做列表展现时，尤其在数据量庞大的情况下就使用技术。例如，在翻页中，一页显示的数量是 10 个，要获取第 3 页的对象：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    NSDate *now = [NSDate date];
    [query whereKey:@"createdAt" lessThanOrEqualTo:now];//查询今天之前创建的 Todo
    query.limit = 10; // 最多返回 10 条结果
    query.skip = 20;  // 跳过 20 条结果
```



尽管我们提供以上接口，但是我们不建议广泛使用，因为它的执行效率比较低。取而代之，我们建议使用 `createdAt` 或者 `updatedAt` 这类的时间戳进行分段查询。

#### 属性限定
通常列表展现的时候并不是需要展现某一个对象的所有属性，例如，Todo 这个对象列表展现的时候，我们一般展现的是 title 以及 content，我们在设置查询的时候，也可以告知云端需要返回的属性有哪些，这样既满足需求又节省了流量，也可以提高一部分的性能，代码如下：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query selectKeys:@[@"title", @"content"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for(AVObject *avObject in objects){

            NSString *title = avObject[@"title"];// 读取 title
            NSString *content = avObject[@"content"]; // 读取 content

            // 如果访问没有指定返回的属性（key），则会报错，在当前这段代码中访问 location 属性就会报错
            NSString *location = [avObject objectForKey:@"location"];
        }
    }];
```


#### 统计总数量
通常用户在执行完搜索后，结果页面总会显示出诸如「搜索到符合条件的结果有 1020 条」这样的信息。例如，查询一下今天一共完成了多少条 Todo：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    [query whereKey:@"status" equalTo:@"1"];
    [query countObjectsInBackgroundWithBlock:^(NSInteger number, NSError *error) {
        if (!error) {
            // 查询成功，输出计数
            NSLog(@"今天完成了 %ld 条待办事项。", number);
        } else {
            // 查询失败
        }
    }];
```


#### 排序

对于数字、字符串、日期类型的数据，可对其进行升序或降序排列。


``` objc
// 按时间，升序排列
[query orderByAscending:@"createdAt"];

// 按时间，降序排列
[query orderByDescending:@"createdAt"];
```


一个查询可以附加多个排序条件，如按 priority 升序、createdAt 降序排列：



```objc
[query addAscendingOrder:@"priority"];
[query addDescendingOrder:@"createdAt"];
```


<!-- #### 限定返回字段 -->

### 关系查询
关联数据查询也可以通俗地理解为关系查询，关系查询在传统型数据库的使用中是很常见的需求，因此我们也提供了相关的接口来满足开发者针对关联数据的查询。

首先，我们需要明确关系的存储方式，再来确定对应的查询方式。

#### Pointer 查询
基于在 [Pointer](#Pointer) 小节介绍的存储方式：每一个 Comment 都会有一个 TodoFolder 与之对应，用以表示 Comment 属于哪个 TodoFolder。现在我已知一个 TodoFolder，想查询所有的 Comnent 对象，可以使用如下代码：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Comment"];
    [query whereKey:@"targetTodoFolder" equalTo:[AVObject objectWithClassName:@"TodoFolder" objectId:@"5590cdfde4b00f7adb5860c8"]];
```


#### `AVRelation` 查询
假如用户可以给 TodoFolder 增加一个 Tag 选项，用以表示它的标签，而为了以后拓展 Tag 的属性，就新建了一个 Tag 对象，如下代码是创建 Tag 对象：



```objc
    AVObject *tag = [[AVObject alloc] initWithClassName:@"Tag"];// 构建对象
    [tag setObject:@"今日必做" forKey:@"name"];// 设置名称
    [tag saveInBackground];
```


而 Tag 的意义在于一个 TodoFolder 可以拥有多个 Tag，比如「家庭」（TodoFolder） 拥有的 Tag 可以是：今日必做，老婆吩咐，十分重要。实现创建「家庭」这个 TodoFolder 的代码如下：



```objc
    AVObject *tag1 = [[AVObject alloc] initWithClassName:@"Tag"];// 构建对象
    [tag1 setObject:@"今日必做" forKey:@"name"];// 设置 Tag 名称

    AVObject *tag2 = [[AVObject alloc] initWithClassName:@"Tag"];// 构建对象
    [tag2 setObject:@"老婆吩咐" forKey:@"name"];// 设置 Tag 名称

    AVObject *tag3 = [[AVObject alloc] initWithClassName:@"Tag"];// 构建对象
    [tag3 setObject:@"十分重要" forKey:@"name"];// 设置 Tag 名称


    AVObject *todoFolder = [[AVObject alloc] initWithClassName:@"TodoFolder"];// 构建对象
    [todoFolder setObject:@"家庭" forKey:@"name"];// 设置 Todo 名称
    [todoFolder setObject:@1 forKey:@"priority"];// 设置优先级

    AVRelation *relation = [todoFolder relationForKey:@"tags"];// 新建一个 AVRelation
    [relation addObject:tag1];
    [relation addObject:tag2];
    [relation addObject:tag3];

    [todoFolder saveInBackground];// 保存到云端
```


查询一个 TodoFolder 的所有 Tag 的方式如下：



```objc
    AVObject *todoFolder = [AVObject objectWithClassName:@"TodoFolder" objectId:@"5661047dddb299ad5f460166"];
    AVRelation *relation = [todoFolder relationForKey:@"tags"];
    AVQuery *query = [relation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       // objects 是一个 AVObject 的 NSArray，它包含所有当前 todoFolder 的 tags
    }];
```


反过来，现在已知一个 Tag，要查询有多少个 TodoFolder 是拥有这个 Tag 的，可以使用如下代码查询：



```objc
    AVObject *tag = [AVObject objectWithClassName:@"Tag" objectId:@"5661031a60b204d55d3b7b89"];

    AVQuery *query = [AVQuery queryWithClassName:@"TodoFolder"];

    [query whereKey:@"tags" equalTo:tag];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // objects 是一个 AVObject 的 NSArray
        // objects 指的就是所有包含当前 tag 的 TodoFolder
    }];
```


关于关联数据的建模是一个复杂的过程，很多开发者因为在存储方式上的选择失误导致最后构建查询的时候难以下手，不但客户端代码冗余复杂，而且查询效率低，为了解决这个问题，我们专门针对关联数据的建模推出了一个详细的文档予以介绍，详情请阅读 [iOS / OS X 数据模型设计指南](relation_guide-ios.html)。

#### 关联属性查询
正如在 [Pointer](#Pointer) 中保存 Comment 的 targetTodoFolder 属性一样，假如查询到了一些 Comment 对象，想要一并查询出每一条 Comment 对应的 TodoFolder 对象的时候，可以加上 include 关键字查询条件。同理，假如 TodoFolder 表里还有 pointer 型字段 targetAVUser 时，再加上一个递进的查询条件，形如 include(b.c)，即可一并查询出每一条 TodoFolder 对应的 AVUser 对象。代码如下：



```objc
    AVQuery *commentQuery = [AVQuery queryWithClassName:@"Comment"];
    [commentQuery orderByDescending:@"createdAt"];
    commentQuery.limit = 10;
    [commentQuery includeKey:@"targetTodoFolder"];// 关键代码，用 includeKey 告知云端需要返回的关联属性对应的对象的详细信息，而不仅仅是 objectId
    [commentQuery includeKey:@"targetTodoFolder.targetAVUser"];// 关键代码，同上，会返回 targetAVUser 对应的对象的详细信息，而不仅仅是 objectId
    [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *comments, NSError *error) {
        // comments 是最近的十条评论, 其 targetTodoFolder 字段也有相应数据
        for (AVObject *comment in comments) {
            // 并不需要网络访问
            AVObject *todoFolder = [comment objectForKey:@"targetTodoFolder"];
            AVUser *avUser = [todoFolder objectForKey:@"targetAVUser"];
        }
    }];
```


#### 内嵌查询
假如现在有一个需求是展现点赞超过 20 次的 TodoFolder 的评论（Comment）查询出来，注意这个查询是针对评论（Comment），要实现一次查询就满足需求可以使用内嵌查询的接口：



```objc
    // 构建内嵌查询
    AVQuery *innerQuery = [AVQuery queryWithClassName:@"TodoFolder"];
    [innerQuery whereKey:@"likes" greaterThan:@20];
    // 将内嵌查询赋予目标查询
    AVQuery *query = [AVQuery queryWithClassName:@"Comment"];
    // 执行内嵌操作
    [query whereKey:@"targetTodoFolder" matchesQuery:innerQuery];
    [query findObjectsInBackgroundWithBlock:^(NSArray *comments, NSError *error) {
        // comments 就是符合超过 20 个赞的 TodoFolder 这一条件的 Comment 对象集合
    }];

    // 注意如果要做相反的查询可以使用
    [query whereKey:@"targetTodoFolder" doesNotMatchQuery:innerQuery];
    // 如此做将查询出 likes 小于或者等于 20 的 TodoFolder 的 Comment 对象
```


### CQL 查询
Cloud Query Language（CQL）是 LeanStorage 独创的使用类似 SQL 语法来实现云端查询功能的语言，具有 SQL 开发经验的开发者可以方便地使用此接口实现查询。

分别找出 status = 1 的全部 Todo 结果，以及 priority = 0 的 Todo 的总数：



```objc
    NSString *cql = [NSString stringWithFormat:@"select * from %@ where status = 1", @"Todo"];
    [AVQuery doCloudQueryInBackgroundWithCQL:cql callback:^(AVCloudQueryResult *result, NSError *error)
    {
        NSLog(@"results:%@", result.results);
    }];


    cql = [NSString stringWithFormat:@"select count(*) from %@ where priority = 0", @"Todo"];
    [AVQuery doCloudQueryInBackgroundWithCQL:cql callback:^(AVCloudQueryResult *result, NSError *error)
    {
       NSLog(@"count:%lu", (unsigned long)result.count);
    }];
```


通常查询语句会使用变量参数，为此我们提供了与 Java JDBC 所使用的 PreparedStatement 占位符查询相类似的语法结构。

查询 status = 0、priority = 1 的 Todo：



```objc
    NSString *cql = [NSString stringWithFormat:@"select * from %@ where status = ? and priority = ?", @"Todo"];
    NSArray *pvalues =  @[@0, @1];
    [AVQuery doCloudQueryInBackgroundWithCQL:cql pvalues:pvalues callback:^(AVCloudQueryResult *result, NSError *error) {
        if (!error) {
            // 操作成功
        } else {
            NSLog(@"%@", error);
        }
    }];
```


目前 CQL 已经支持数据的更新 update、插入 insert、删除 delete 等 SQL 语法，更多内容请参考 [Cloud Query Language 详细指南](cql_guide.html)。


### 缓存查询
缓存一些查询的结果到磁盘上，这可以让你在离线的时候，或者应用刚启动，网络请求还没有足够时间完成的时候可以展现一些数据给用户。当缓存占用了太多空间的时候，LeanStorage 会自动清空缓存。

默认情况下的查询不会使用缓存，除非你调用接口明确设置启用。例如，尝试从网络请求，如果网络不可用则从缓存数据中获取，可以这样设置：



```objc
  AVQuery *query = [AVQuery queryWithClassName:@"Post"];
  query.cachePolicy = kAVCachePolicyNetworkElseCache;

  //设置缓存有效期
  query.maxCacheAge = 24*3600;

  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      // 成功找到结果，先找网络再访问磁盘
    } else {
      // 无法访问网络，本次查询结果未做缓存
    }
  }];
```


#### 缓存策略
为了满足多变的需求，SDK 默认提供了以下几种缓存策略：



策略枚举 | 含义及解释|
---|---
`kAVCachePolicyIgnoreCache`| **（默认缓存策略）**查询行为不从缓存加载，也不会将结果保存到缓存中。
`kAVCachePolicyCacheOnly` |  查询行为忽略网络状况，只从缓存加载。如果没有缓存结果，该策略会产生 `AVError`。
`kAVCachePolicyCacheElseNetwork` |  查询行为首先尝试从缓存加载，若加载失败，则通过网络加载结果。如果缓存和网络获取行为均为失败，则产生 `AVError`。
`kAVCachePolicyNetworkElseCache` | 查询行为先尝试从网络加载，若加载失败，则从缓存加载结果。如果缓存和网络获取行为均为失败，则产生 `AVError`。
<code class="text-nowrap">`kAVCachePolicyCacheThenNetwork`</code> | 查询先从缓存加载，然后从网络加载。在这种情况下，回调函数会被调用两次，第一次是缓存中的结果，然后是从网络获取的结果。因为它会在不同的时间返回两个结果，所以该策略不能与 `findObjects` 同时使用。


#### 缓存相关的操作


* 检查是否存在缓存查询结果：

  ``` objc
  BOOL isInCache = [query hasCachedResult];
  ```

* 删除某一查询的任何缓存结果：

  ``` objc
  [query clearCachedResult];
  ```

* 删除查询的所有缓存结果：

  ``` objc
  [AVQuery clearAllCachedResults];
  ```

* 设定缓存结果的最长时限：

  ``` objc
  query.maxCacheAge = 60 * 60 * 24; // 一天的总秒数
  ```

查询缓存也适用于 `AVQuery` 的辅助方法，包括 `getFirstObject` 和 `getObjectInBackground`。




### 地理位置查询
地理位置查询是较为特殊的查询，一般来说，常用的业务场景是查询距离 xx 米之内的某个位置或者是某个建筑物，甚至是以手机为圆心，查找方圆多少范围内餐厅等等。LeanStorage 提供了一系列的方法来实现针对地理位置的查询。

#### 查询位置附近的对象
Todo 的 `whereCreated`（创建 Todo 时的位置）是一个 `AVGeoPoint` 对象，现在已知了一个地理位置，现在要查询 `whereCreated` 靠近这个位置的 Todo 对象可以使用如下代码：



```objc
    AVQuery *query = [AVQuery queryWithClassName:@"Todo"];
    AVGeoPoint *point = [AVGeoPoint geoPointWithLatitude:39.9 longitude:116.4];
    query.limit = 10;
    [query whereKey:@"whereCreated" nearGeoPoint:point];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSArray<AVObject *> *nearbyTodos = objects;// 离这个位置最近的 10 个 Todo 对象
    }];
```

在上面的代码中，`nearbyTodos` 返回的是与 `point` 这一点按距离排序（由近到远）的对象数组。注意：**如果在此之后又使用了 `orderByAscending:` 或 `orderByDescending:` 方法，则按距离排序会被新排序覆盖。**


#### 查询指定范围内的对象
要查找指定距离范围内的数据，可使用 `whereWithinKilometers` 、 `whereWithinMiles` 或 `whereWithinRadians` 方法。
例如，我要查询距离指定位置，2 千米范围内的 Todo：



```objc
    [query whereKey:@"whereCreated"  nearGeoPoint:point withinKilometers:2.0];
```


#### 注意事项

使用地理位置需要注意以下方面：

* 每个 `AVObject` 数据对象中只能有一个 `AVGeoPoint` 对象的属性。
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

`AVUser` 是用来描述一个用户的特殊对象，与之相关的数据都保存在 `_User` 数据表中。

### 用户的属性

#### 默认属性
用户名、密码、邮箱是默认提供的三个属性，访问方式如下：



```objc
    NSString *currentUsername = [AVUser currentUser].username;// 当前用户名
    NSString *currentEmail = [AVUser currentUser].email; // 当前用户的邮箱

    // 请注意，以下代码无法获取密码
    NSString *currentPassword = [AVUser currentUser].password;//  currentPassword 是 nil
```


请注意代码中，密码是仅仅是在注册的时候可以设置的属性（这部分代码可参照 [用户名和密码注册](#用户名和密码注册)），它在注册完成之后并不会保存在本地（SDK 不会以明文保存密码这种敏感数据），所以在登录之后，再访问密码这个字段是为**空的**。

#### 自定义属性
用户对象和普通对象一样也支持添加自定义属性。例如，为当前用户添加年龄属性：



```objc
    [[AVUser currentUser] setObject:[NSNumber numberWithInt:25] forKey:@"age"];
    [[AVUser currentUser] saveInBackground];
```


#### 属性的修改

很多开发者都有这样的疑问：为什么我不能修改任意一个用户的属性？原因如下。

> 很多时候，就算是开发者也不要轻易修改用户的基本信息，例如用户的手机号、社交账号等个人信息都比较敏感，应该由用户在 App 中自行修改。所以为了保证用户的数据仅在用户自己已登录的状态下才能修改，云端对所有针对 `AVUser` 对象的数据操作都要做验证。

假如，刚才我们为当前用户添加了一个 age 属性，现在我们来修改它：



```objc
    [[AVUser currentUser] setObject:[NSNumber numberWithInt:25] forKey:@"age"];
    [[AVUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [[AVUser currentUser] setObject:[NSNumber numberWithInt:27] forKey:@"age"];
        [[AVUser currentUser] saveInBackground];
    }];
```


细心的开发者应该已经发现 `AVUser` 在自定义属性上的使用与一般的 `AVObject` 没本质区别。

### 注册





#### 手机号码登录

一些应用为了提高首次使用的友好度，一般会允许用户浏览一些内容，直到用户发起了一些操作才会要求用户输入一个手机号，而云端会自动发送一条验证码的短信给用户的手机号，最后验证一下，完成一个用户注册并且登录的操作，例如很多团购类应用都有这种用户场景。

首先调用发送验证码的接口：



```objc
    [AVOSCloud requestSmsCodeWithPhoneNumber:@"13577778888" callback:^(BOOL succeeded, NSError *error) {
        // 发送失败可以查看 error 里面提供的信息
    }];
```


然后在 UI 上给与用户输入验证码的输入框，用户点击登录的时候调用如下接口：



```objc
    [AVUser signUpOrLoginWithMobilePhoneNumberInBackground:@"13577778888" smsCode:@"123456" block:^(AVUser *user, NSError *error) {
       // 如果 error 为空就可以表示登录成功了，并且 user 是一个全新的用户
    }];
```


#### 用户名和密码注册

采用「用户名 + 密码」注册时需要注意：密码是以明文方式通过 HTTPS 加密传输给云端，云端会以密文存储密码，并且我们的加密算法是无法通过所谓「彩虹表撞库」获取的，这一点请开发者放心。换言之，用户的密码只可能用户本人知道，开发者不论是通过控制台还是 API 都是无法获取。另外我们需要强调<u>在客户端，应用切勿再次对密码加密，这会导致重置密码等功能失效</u>。

例如，注册一个用户的示例代码如下（用户名 `Tom` 密码 `cat!@#123`）：



```objc
    AVUser *user = [AVUser user];// 新建 AVUser 对象实例
    user.username = @"Tom";// 设置用户名
    user.password =  @"cat!@#123";// 设置密码
    user.email = @"tom@leancloud.cn";// 设置邮箱

    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            // 注册成功
        } else {
            // 失败的原因可能有多种，常见的是用户名已经存在。
        }
    }];
```



我们建议在可能的情况下尽量使用异步版本的方法，这样就不会影响到应用程序主 UI 线程的响应。


如果注册不成功，请检查一下返回的错误对象。最有可能的情况是用户名已经被另一个用户注册，错误代码 [202](error_code.html#_202)，即 `_User` 表中的 `username` 字段已存在相同的值，此时需要提示用户尝试不同的用户名来注册。同样，邮件 `email` 和手机号码 `mobilePhoneNumber` 字段也要求在各自的列中不能有重复值出现，否则会出现 [203](error_code.html#_203)、[214](error_code.html#_214) 错误。

开发者也可以要求用户使用 Email 做为用户名注册，即在用户提交信息后将 `_User` 表中的 `username` 和 `email` 字段都设为相同的值，这样做的好处是用户在忘记密码的情况下可以直接使用「[邮箱重置密码](#重置密码)」功能，无需再额外绑定电子邮件。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。



#### 设置手机号码

微信、陌陌等流行应用都会建议用户将账号和一个手机号绑定，这样方便进行身份认证以及日后的密码找回等安全模块的使用。我们也提供了一整套发送短信验证码以及验证手机号的流程，这部分流程以及代码演示请参考 [iOS / OS X 短信服务使用指南](sms_guide-ios.html#注册验证)。

#### 验证邮箱

许多应用会通过验证邮箱来确认用户注册的真实性。如果在 [应用控制台 > 应用设置 > 应用选项](https://leancloud.cn/app.html?appid={{appid}}#/permission) 中勾选了 **用户注册时，发送验证邮件**，那么当一个 `AVUser` 在注册时设置了邮箱，云端就会向该邮箱自动发送一封包含了激活链接的验证邮件，用户打开该邮件并点击激活链接后便视为通过了验证。有些用户可能在注册之后并没有点击激活链接，而在未来某一个时间又有验证邮箱的需求，这时需要调用如下接口让云端重新发送验证邮件：



```objc
    [AVUser requestEmailVerify:@"abc@xyz.com" withBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"请求重发验证邮件成功");
        }
    }];
```


### 登录

我们提供了多种登录方式，以满足不同场景的应用。



#### 用户名和密码登录



```objc
  [AVUser logInWithUsernameInBackground:@"Tom" password:@"cat!@#123" block:^(AVUser *user, NSError *error) {
      if (user != nil) {

      } else {

      }
  }];
```


#### 手机号和密码登录

请确保已详细阅读了 [iOS / OS X 短信服务使用指南](sms_guide-ios.html#注册验证) 这一小节的内容，才可以顺利理解手机号匹配密码登录的流程以及适用范围。

用户的手机号只要经过了验证，就可以使用手机号密码登录的功能，否则登录会失败。



```objc
    [AVUser logInWithMobilePhoneNumberInBackground:@"13577778888" password:@"cat!@#123" block:^(AVUser *user, NSError *error) {

    }];
```


#### 手机号和验证码登录

中国电信、中国联通、中国移动，这三大运营商的官网均支持「手机号 + 密码」和「手机号 + 随机验证码」的登录方式，我们也提供了这些方式。

首先，调用发送登录验证码的接口：



```objc
    [AVUser requestLoginSmsCode:@"13577778888" withBlock:^(BOOL succeeded, NSError *error) {

    }];
```


然后在界面上引导用户输入收到的 6 位短信验证码：



```objc
    [AVUser logInWithMobilePhoneNumberInBackground:@"13577778888" smsCode:@"238825" block:^(AVUser *user, NSError *error) {

    }];
```



#### 当前用户

打开微博或者微信，它不会每次都要求用户都登录，这是因为它将用户数据缓存在了客户端。
同样，只要是调用了登录相关的接口，LeanCloud SDK 都会自动缓存登录用户的数据。
例如，判断当前用户是否为空，为空就跳转到登录页面让用户登录，如果不为空就跳转到首页：



```objc
  AVUser *currentUser = [AVUser currentUser];
  if (currentUser != nil) {
      // 跳转到首页
  } else {
      //缓存用户对象为空时，可打开用户注册界面…
  }
```



如果不调用 [登出](#登出) 方法，当前用户的缓存将永久保存在客户端。


#### SessionToken

所有登录接口调用成功之后，云端会返回一个 SessionToken 给客户端，客户端在发送 HTTP 请求的时候，iOS / OS X SDK 会在 HTTP 请求的 Header 里面自动添加上当前用户的 SessionToken 作为这次请求发起者 `AVUser` 的身份认证信息。

如果在控制台的 [应用选项](/app.html?appid={{appid}}#/permission) 中勾选了 **密码修改后，强制客户端重新登录**，那么当用户密码再次被修改后，已登录的用户对象就会失效，开发者需要使用更改后的密码重新调用登录接口，使 SessionToken 得到更新，否则后续操作会遇到 [403 (Forbidden)](error_code.html#_403) 的错误。

#### 账户锁定

输入错误的密码或验证码会导致用户登录失败。如果在 15 分钟内，同一个用户登录失败的次数大于 6 次，该用户账户即被云端暂时锁定，此时云端会返回错误码 `{"code":1,"error":"登录失败次数超过限制，请稍候再试，或者通过忘记密码重设密码。"}`，开发者可在客户端进行必要提示。

锁定将在最后一次错误登录的 15 分钟之后由云端自动解除，开发者无法通过 SDK 或 REST API 进行干预。在锁定期间，即使用户输入了正确的验证信息也不允许登录。这个限制在 SDK 和云引擎中都有效。

### 重置密码

#### 邮箱重置密码

我们都知道，应用一旦加入账户密码系统，那么肯定会有用户忘记密码的情况发生。对于这种情况，我们为用户提供了一种安全重置密码的方法。

重置密码的过程很简单，用户只需要输入注册的电子邮件地址即可：



``` objc
[AVUser requestPasswordResetForEmailInBackground:@"myemail@example.com" block:^(BOOL succeeded, NSError *error) {
    if (succeeded) {

    } else {

    }
}];
```


密码重置流程如下：

1. 用户输入注册的电子邮件，请求重置密码；
2. LeanStorage 向该邮箱发送一封包含重置密码的特殊链接的电子邮件；
3. 用户点击重置密码链接后，一个特殊的页面会打开，让他们输入新密码；
4. 用户的密码已被重置为新输入的密码。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。

#### 手机号码重置密码



与使用 [邮箱重置密码](#邮箱重置密码) 类似，「手机号码重置密码」使用下面的方法来获取短信验证码：



``` objc
[AVUser requestPasswordResetWithPhoneNumber:@"18612340000" block:^(BOOL succeeded, NSError *error) {
    if (succeeded) {

    } else {

    }
}];
```


注意！用户需要先绑定手机号码，然后使用短信验证码来重置密码：



``` objc
[AVUser resetPasswordWithSmsCode:@"123456" newPassword:@"password" block:^(BOOL succeeded, NSError *error) {
    if (succeeded) {

    } else {

    }
}];
```


#### 登出

用户登出系统时，SDK 会自动清理缓存信息。



```objc
  [AVUser logOut];  //清除缓存用户对象
  AVUser *currentUser = [AVUser currentUser]; // 现在的currentUser是nil了
```



### 用户的查询
请注意，**新创建的应用的用户表 `_User` 默认关闭了查询权限**。你可以通过 Class 权限设置打开查询权限，请参考 [数据与安全 · Class 级别的权限](data_security.html#Class_级别的_ACL)。我们推荐开发者在 [云引擎](leanengine_overview.html) 中封装用户查询，只查询特定条件的用户，避免开放用户表的全部查询权限。

查询用户代码如下：


```objc
  AVQuery *userQuery = [AVQuery queryWithClassName:@"_User"];
```


### 浏览器中查看用户表

用户表是一个特殊的表，专门存储用户对象。在浏览器端，你会看到一个 `_User` 表。

## 角色
关于用户与角色的关系，我们有一个更为详尽的文档介绍这部分的内容，并且针对权限管理有深入的讲解，详情请点击 [iOS / OS X 权限管理使用指南](acl_guide-ios.html)。


## 子类化
子类化推荐给进阶的开发者在进行代码重构的时候做参考。
你可以用 `AVObject` 访问到所有的数据，用 `objectForKey:` 获取任意字段。 在成熟的代码中，子类化有很多优势，包括降低代码量，具有更好的扩展性，和支持自动补全。

子类化是可选的，请对照下面的例子来加深理解：

```
AVObject *student = [AVObject objectWithClassName:@"Student"];
[student setObject:@"小明" forKey:@"name"];
[student saveInBackground];
```

可改写成:

```
Student *student = [Student object];
student.name = @"小明";
[student saveInBackground];
```

这样代码看起来是不是更简洁呢？

### 子类化的实现

要实现子类化，需要下面几个步骤：

1. 导入 `AVObject+Subclass.h`；
2. 继承 `AVObject` 并实现 `AVSubclassing` 协议；
3. 实现类方法 `parseClassName`，返回的字符串是原先要传给 `initWithClassName:` 的参数，这样后续就不必再进行类名引用了。如果不实现，默认返回的是类的名字。**请注意： `AVUser` 子类化后必须返回 `_User`**；
4. 在实例化子类之前调用 [YourClass registerSubclass]（**在应用当前生命周期中，只需要调用一次**。可在子类的 +load 方法或者 UIApplication 的 -application:didFinishLaunchingWithOptions: 方法里面调用）。

下面是实现 `Student` 子类化的例子:

``` objc
  //Student.h
  #import <AVOSCloud/AVOSCloud.h>

  @interface Student : AVObject <AVSubclassing>

  @property(nonatomic,copy) NSString *name;

  @end


  //Student.m
  #import "Student.h"

  @implementation Student

  @dynamic name;

  + (NSString *)parseClassName {
      return @"Student";
  }

  @end


  // AppDelegate.m
  #import <AVOSCloud/AVOSCloud.h>
  #import "Student.h"

  - (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Student registerSubclass];
    [AVOSCloud setApplicationId:appid clientKey:appkey];
  }
```

### 属性

为 `AVObject` 的子类添加自定义的属性和方法，可以更好地将这个类的逻辑封装起来。用 `AVSubclassing` 可以把所有的相关逻辑放在一起，这样不必再使用不同的类来区分业务逻辑和存储转换逻辑了。

`AVObject` 支持动态 synthesizer，就像 `NSManagedObject` 一样。先正常声明一个属性，只是在 .m 文件中把 `@synthesize` 变成 `@dynamic`。

请看下面的例子是怎么添加一个「年龄」属性：

``` objc
  //Student.h
  #import <AVOSCloud/AVOSCloud.h>

  @interface Student : AVObject <AVSubclassing>

  @property int age;

  @end


  //Student.m
  #import "Student.h"

  @implementation Student

  @dynamic age;

  ......
```

这样就可以通过 `student.age = 19` 这样的方式来读写 `age` 字段了，当然也可以写成：

``` objc
[student setAge:19]
```

**注意：属性名称保持首字母小写！**（错误：`student.Age` 正确：`student.age`）。

`NSNumber` 类型的属性可用 `NSNumber` 或者是它的原始数据类型（`int`、 `long` 等）来实现。例如， `[student objectForKey:@"age"]` 返回的是 `NSNumber` 类型，而实际被设为 `int` 类型。

你可以根据自己的需求来选择使用哪种类型。原始类型更为易用，而 `NSNumber` 支持 `nil` 值，这可以让结果更清晰易懂。

**注意** 子类中，对于 `BOOL` 类型的字段，SDK 在 3.1.3.2 之前会将其保存为 Number 类型，3.1.3.2 之后将其正确保存为 Bool 类型。详情请参考[这里](https://leancloud.cn/docs/ios_os_x_faq.html#为什么升级到_3_1_3_2_以上的版本时_BOOL_类型数据保存错误_)。

注意：`AVRelation` 同样可以作为子类化的一个属性来使用，比如：

``` objc
@interface Student : AVUser <AVSubclassing>
@property(retain) AVRelation *friends;
  ......
@end

@implementation Student
@dynamic friends;
  ......
```

另外，值为 Pointer 的实例可用 `AVObject*` 来表示。例如，如果 `Student` 中 `bestFriend` 代表一个指向另一个 `Student` 的键，由于 Student 是一个 AVObject，因此在表示这个键的值的时候，可以用一个 `AVObject*` 来代替：

``` objc
@interface Student : AVUser <AVSubclassing>
@property(nonatomic, strong) AVObject *bestFriend;
 ......
@end

@implementation Student
@dynamic bestFriend;
  ......
```

提示：当需要更新的时候，最后都要记得加上 `[student save]` 或者对应的后台存储函数进行更新，才会同步至服务器。

如果要使用更复杂的逻辑而不是简单的属性访问，可以这样实现:

``` objc
  @dynamic iconFile;

  - (UIImageView *)iconView {
    UIImageView *view = [[UIImageView alloc] initWithImage:kPlaceholderImage];
    view.image = [UIImage imageNamed:self.iconFile];
    return [view autorelease];
  }

```

### 针对 AVUser 子类化的特别说明

假如现在已经有一个基于 `AVUser` 的子类，如上面提到的 `Student`:

``` objc
@interface Student : AVUser<AVSubclassing>
@property (retain) NSString *displayName;
@end


@implementation Student
@dynamic displayName;
+ (NSString *)parseClassName {
    return @"_User";
}
@end
```

登录时需要调用 `Student` 的登录方法才能通过 `currentUser` 得到这个子类:

``` objc
[Student logInWithUsernameInBackground:@"USER_NAME" password:@"PASSWORD" block:^(AVUser *user, NSError *error) {
        Student *student = [Student currentUser];
        student.displayName = @"YOUR_DISPLAY_NAME";
    }];
```

同样需要调用 `[Student registerSubclass];`，确保在其它地方得到的对象是 Student，而非 AVUser 。

### 初始化子类

创建一个子类实例，要使用 `object` 类方法。要创建并关联到已有的对象，请使用 `objectWithObjectId:` 类方法。

### 子类查询

使用类方法 `query` 可以得到这个子类的查询对象。

例如，查询年龄小于 21 岁的学生：

``` objc
  AVQuery *query = [Student query];
  [query whereKey:@"age" lessThanOrEqualTo:@(21)];
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      Student *stu1 = [objects objectAtIndex:0];
      // ...
    }
  }];
```



## 应用内搜索
应用内搜索是一个针对应用数据进行全局搜索的接口，它基于搜索引擎构建，提供更强大的搜索功能。要深入了解其用法和阅读示例代码，请阅读 [iOS / OS X 应用内搜索指南](app_search_guide.html)。



## 应用内社交
应用内社交，又称「事件流」，在应用开发中出现的场景非常多，包括用户间关注（好友）、朋友圈（时间线）、状态、互动（点赞）、私信等常用功能，请参考 [iOS / OS X 应用内社交模块](status_system.html#iOS_SDK)。



## 第三方账户登录
社交账号的登录方便了应用开发者在提升用户体验，我们特地开发了一套支持第三方账号登录的组件，请参考 [iOS / OS X SNS 开发指南](sns.html#iOS_SNS_组件)。




## 用户反馈
用户反馈是一个非常轻量的模块，可以用最少两行的代码来实现一个支持文字和图片的用户反馈系统，并且能够方便的在我们的移动 App 中查看用户的反馈，请参考 [iOS / OS X 用户反馈指南](feedback.html#iOS_反馈组件)。





