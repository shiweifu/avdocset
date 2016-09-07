





#  Java 数据存储开发指南

数据存储（LeanStorage）是 LeanCloud 提供的核心功能之一，它的使用方法与传统的关系型数据库有诸多不同。下面我们将其与传统数据库的使用方法进行对比，让大家有一个初步了解。

下面这条 SQL 语句在绝大数的关系型数据库都可以执行，其结果是在 Todo 表里增加一条新数据：

```sql
  INSERT INTO Todo (title, content) VALUES ('工程师周会', '每周工程师会议，周一下午2点')
```

使用传统的关系型数据库作为应用的数据源几乎无法避免以下步骤：

- 插入数据之前一定要先创建一个表结构，并且随着之后需求的变化，开发者需要不停地修改数据库的表结构，维护表数据。
- 每次插入数据的时候，客户端都需要连接数据库来执行数据的增删改查（CRUD）操作。

使用 LeanStorage，实现代码如下：



```java
    AVObject todo = new AVObject("Todo");
    todo.put("title", "工程师周会");
    todo.put("content", "每周工程师会议，周一下午2点");
    try {
        todo.save();
        // 保存成功
    } catch (AVException e) {
        // 失败的话，请检查网络环境以及 SDK 配置是否正确
        e.printStackTrace();
    }
```


使用 LeanStorage 的特点在于：

- 不需要单独维护表结构。例如，为上面的 Todo 表新增一个 `location` 字段，用来表示日程安排的地点，那么刚才的代码只需做如下变动：

  

```java
    AVObject todo = new AVObject("Todo");
    todo.put("title", "工程师周会");
    todo.put("content", "每周工程师会议，周一下午2点");
    todo.put("location", "会议室"); // 只要添加这一行代码，服务端就会自动添加这个字段
    try {
        todo.save();
        // 保存成功
    } catch (AVException e) {
        // 失败的话，请检查网络环境以及 SDK 配置是否正确
        e.printStackTrace();
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


请阅读 [Java 安装指南](sdk_setup-java.html)。






## 对象

`AVObject` 是 LeanStorage 对复杂对象的封装，每个 `AVObject` 包含若干属性值对，也称键值对（key-value）。属性的值是与 JSON 格式兼容的数据。通过 REST API 保存对象需要将对象的数据通过 JSON 来编码。这个数据是无模式化的（Schema Free），这意味着你不需要提前标注每个对象上有哪些 key，你只需要随意设置 key-value 对就可以，云端会保存它。

### 数据类型
`AVObject` 支持以下数据类型：



```java
    boolean bool = true;
    int number = 2015;
    String string = number + " 年度音乐排行";
    Date date = new Date();

    byte[] data = "短篇小说".getBytes();
    ArrayList<Object> arrayList = new ArrayList<>();
    arrayList.add(number);
    arrayList.add(string);
    HashMap<Object, Object> hashMap = new HashMap<>();
    hashMap.put("数字", number);
    hashMap.put("字符串", string);

    AVObject object = new AVObject("DataTypes");
    object.put("testBoolean", bool);
    object.put("testInteger", number);
    object.put("testDate", date);
    object.put("testData", data);
    object.put("testArrayList", arrayList);
    object.put("testHashMap", hashMap);
    object.save();
```

此外，HashMap 和 ArrayList 支持嵌套，这样在一个 `AVObject` 中就可以使用它们来储存更多的结构化数据。



我们**不推荐**在 `AVObject` 中使用 `byte[]` 来储存大块的二进制数据，比如图片或整个文件。**每个 `AVObject` 的大小都不应超过 128 KB**。如果需要储存更多的数据，建议使用 [`AVFile`](#文件)。


若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。

### 构建对象
构建一个 `AVObject` 可以使用如下方式：



```java
    // 构造方法传入的参数，对应的就是控制台中的 Class Name
    AVObject todo = new AVObject("Todo");
```


每个 objectId 必须有一个 Class 类名称，这样云端才知道它的数据归属于哪张数据表。

### 保存对象
现在我们保存一个 `TodoFolder`，它可以包含多个 Todo，类似于给行程按文件夹的方式分组。我们并不需要提前去后台创建这个名为 **TodoFolder** 的 Class 类，而仅需要执行如下代码，云端就会自动创建这个类：



```java
    AVObject todoFolder = new AVObject("TodoFolder");// 构建对象
    todoFolder.put("name", "工作");// 设置名称
    todoFolder.put("priority", 1);// 设置优先级
    todoFolder.save();// 保存到服务端
```



创建完成后，打开 [控制台 > 存储](/data.html?appid={{appid}}#/)，点开 `TodoFolder` 类，就可以看到刚才添加的数据。除了 name、priority（优先级）之外，其他字段都是数据表的内置属性。


内置属性|类型|描述
---|---|---
`objectId`|String|该对象唯一的 Id 标识
`ACL`|ACL|该对象的权限控制，实际上是一个 JSON 对象，控制台做了展现优化。
`createdAt`|Date|该对象被创建的 UTC 时间，控制台做了针对当地时间的展现优化。
`updatedAt` |Date|该对象最后一次被修改的时间

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



```java
    // 执行 CQL 语句实现新增一个 TodoFolder 对象
    try {
        AVCloudQueryResult result = AVQuery.doCloudQuery("insert into TodoFolder(name, priority) values('工作', 1)");
        // 保存成功
        AVObject todoFolder = result.getResults().get(0);
    } catch (Exception e) {
        // 失败的话，请检查网络环境以及 SDK 配置是否正确
        e.printStackTrace();
    }
```



#### 保存选项

`AVObject` 对象在保存时可以设置选项来快捷完成关联操作，可用的选项属性有：

选项 | 类型 | 说明
--- | --- | ---
<code class="text-nowrap">fetchWhenSave</code> | BOOL | 对象成功保存后，自动返回该对象在云端的最新数据。用途请参考 [更新计数器](#更新计数器)。
`query` | `AVQuery`  | 当 query 中的条件满足后对象才能成功保存，否则放弃保存，并返回错误码 305。<br/><br/>开发者原本可以通过 `AVQuery` 和 `AVObject` 分两步来实现这样的逻辑，但如此一来无法保证操作的原子性从而导致并发问题。该选项可以用来判断多用户更新同一对象数据时可能引发的冲突。

<a id="saveoption_query_example" name="saveoption_query_example"></a>【示例】一篇 wiki 文章允许任何人来修改，它的数据表字段有：**content**（wiki 内容）、**version**（版本号）。每当 wiki 内容被更新后，其 version 也需要更新（+1）。用户 A 要修改这篇 wiki，从数据表中取出时其 version 值为 3，当用户 A 完成编辑要保存新内容时，如果数据表中的 version 仍为 3，表明这段时间没有其他用户更新过这篇 wiki，可以放心保存；如果不是 3，开发者可以拒绝掉用户 A 的修改，或执行其他自定义的业务逻辑。



```java
    // 获取 version 值
    int version = wiki.getInt("version");
    AVQuery<AVObject> query = new AVQuery<>("Wiki");
    query.whereEqualTo("version", version);
    try {
        wiki.put("content", "Hello Java!");
        wiki.increment("version");
        wiki.save(new AVSaveOption().query(query));
    } catch (AVException e) {
        if (e.getCode() == 305) {
        log.d("无法保存修改，wiki 已被他人更新。");
        } else {
            e.printStackTrace();
        }
    }
```



### 获取对象
每个被成功保存在云端的对象会有一个唯一的 Id 标识 `objectId`，因此获取对象的最基本的方法就是根据 `objectId` 来查询：



```java
    String objectId = "558e20cbe4b060308e3eb36c";
    AVQuery<AVObject> avQuery = new AVQuery<>("Todo");
    AVObject object = avQuery.get(objectId);
    // object 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例
```


如果不想使用查询，还可以通过从本地构建一个 `objectId`，然后调用接口从云端把这个 `objectId` 的数据拉取到本地，示例代码如下：



```java
    // 第一参数是 className,第二个参数是 objectId
    AVObject object = AVObject.createWithoutData("Todo", objectId);
    object.fetch();
    String title = object.getString("title");// 读取 title
    String content = object.getString("content");// 读取 content
```


#### 获取 objectId
每一次对象存储成功之后，云端都会返回 `objectId`，它是一个全局唯一的属性。



```java
    todo = new AVObject("Todo");
    todo.put("title", "工程师周会");
    todo.put("content", "每周工程师会议，周一下午2点");
    todo.save();
    // 保存成功之后，objectId 会自动从服务端加载到本地
    String objectId = todo.getObjectId();
```



#### 访问对象的属性
访问 Todo 的属性的方式为：



```java
    String objectId = "558e20cbe4b060308e3eb36c";
    AVQuery<AVObject> avQuery = new AVQuery<>("Todo");
    AVObject avObject = avQuery.get(objectId);
    // avObject 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例

    int priority = avObject.getInt("priority");
    String location = avObject.getString("location");
    String title = avObject.getString("title");
    String content = avObject.getString("content");

    // 获取三个特殊属性
    String objectId = avObject.getObjectId();
    Date updatedAt = avObject.getUpdatedAt();
    Date createdAt = avObject.getCreatedAt();
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



```java
    String objectId = "5656e37660b2febec4b35ed7";
    // 假如已知了 objectId 可以用如下的方式构建一个 AVObject
    AVObject object = AVObject.createWithoutData("Todo", objectId);
    // 然后调用刷新的方法，将数据从服务端拉到本地
    object.fetchIfNeeded();
    String title = object.getString("title");// 读取 title
    String content = object.getString("content");// 读取 content
```


在更新对象操作后，对象本地的 `updatedAt` 字段（最后更新时间）会被刷新，直到下一次 save 或 fetch 操作，`updatedAt` 的最新值才会被同步到云端，这样做是为了减少网络流量传输。

如果需要在保存或更新之后让本地数据自动与云端保持一致，可以使用 [保存选项 `fetchWhenSave`](#保存选项)：



```java
    todo.setFetchWhenSave(true);// 设置 fetchWhenSave 为 true
    todo.save();// 如此
```


#### 同步指定属性

目前 Todo 这个类已有四个自定义属性：`priority`、`content`、`location` 和 `title`。为了节省流量，现在只想刷新 `priority` 和 `location` 可以使用如下方式：



```java
    String objectId = "5656e37660b2febec4b35ed7";
    // 假如已知了 objectId 可以用如下的方式构建一个 AVObject
    AVObject avObject = AVObject.createWithoutData("Todo", objectId);
    String keys = "priority,location";// 指定刷新的 key 字符串
    // 然后调用刷新的方法，将数据从服务端拉到本地
    avObject.fetch(keys);
    // avObject 的 location 和 content 属性的值就是与服务端一致的
    int priority = avObject.getInt("priority");
    String location = avObject.getString("location");
```


**刷新操作会强行使用云端的属性值覆盖本地的属性**。因此如果本地有属性修改，请慎用这类接口。



### 更新对象

LeanStorage 上的更新对象都是针对单个对象，云端会根据<u>有没有 objectId</u> 来决定是新增还是更新一个对象。

假如 `objectId` 已知，则可以通过如下接口从本地构建一个 `AVObject` 来更新这个对象：



```java
    String objectId = "5656e37660b2febec4b35ed7";
    // 第一参数是 className,第二个参数是 objectId
    AVObject todo = AVObject.createWithoutData("Todo", objectId);
    // 修改 content
    todo.put("content", "每周工程师会议，本周改为周三下午3点半。");
    // 保存到云端
    todo.save();
```


更新操作是覆盖式的，云端会根据最后一次提交到服务器的有效请求来更新数据。更新是字段级别的操作，未更新的字段不会产生变动，这一点请不用担心。

#### 使用 CQL 语法更新对象
LeanStorage 提供了类似 SQL 语法中的 Update 方式更新一个对象，例如更新一个 TodoFolder 对象可以使用下面的代码：



```java
    String objectId = "5656e37660b2febec4b35ed7";
    // 执行 CQL 语句实现更新一个 TodoFolder 对象
    AVQuery.doCloudQuery("update TodoFolder set name='家庭' where objectId=?", objectId);
```


#### 更新计数器

这是原子操作（Atomic Operation）的一种。
为了存储一个整型的数据，LeanStorage 提供对任何数字字段进行原子增加（或者减少）的功能。比如一条微博，我们需要记录有多少人喜欢或者转发了它，但可能很多次喜欢都是同时发生的。如果在每个客户端都直接把它们读到的计数值增加之后再写回去，那么极容易引发冲突和覆盖，导致最终结果不准。此时就需要使用这类原子操作来实现计数器。

假如，现在增加一个记录查看 Todo 次数的功能，一些与他人共享的 Todo 如果不用原子操作的接口，很有可能会造成统计数据不准确，可以使用如下代码实现这个需求：



```java
    String objectId = "5656e37660b2febec4b35ed7";
    final AVObject theTodo = AVObject.createWithoutData("Todo", objectId);
    theTodo.put("views", 0);// 初始值为 0
    theTodo.save();
    // 原子增加查看的次数
    theTodo.increment("views");
    theTodo.setFetchWhenSave(true);
    theTodo.save();
    int views = theTodo.getInt("views"); // 此时为 1
    // 也可以使用 incrementKey:byAmount: 来给 Number 类型字段累加一个特定数值。
    theTodo.increment("views", 5);
    theTodo.save();
    // saveInBackground 调用之后，如果成功的话，对象的计数器字段是当前系统最新值。
    views = theTodo.getInt("views"); // 此时为 6
```



#### 更新数组

这也是原子操作的一种。使用以下方法可以方便地维护数组类型的数据：



* `add()`<br>
  将指定对象附加到数组末尾。
* `addUnique()`<br>
  如果不确定某个对象是否已包含在数组字段中，可以使用此操作来添加。
* `removeAll()`<br>
  从数组字段中删除指定对象的所有实例。


例如，Todo 对象有一个提醒日期 reminders，它是一个数组，代表这个日程会在哪些时间点提醒用户。比如有些拖延症患者会把闹钟设为早上的 7:10、7:20、7:30：



```java
    Date getDateWithDateString(String dateString) {
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    Date date = dateFormat.parse(dateString);
    return date;
    }

    void addReminders() {
        Date reminder1 = getDateWithDateString("2015-11-11 07:10:00");
        Date reminder2 = getDateWithDateString("2015-11-11 07:20:00");
        Date reminder3 = getDateWithDateString("2015-11-11 07:30:00");

        AVObject todo = new AVObject("Todo");
        todo.addAllUnique("reminders", Arrays.asList(reminder1, reminder2, reminder3));
        todo.save();
    }
```




### 删除对象

假如某一个 Todo 完成了，用户想要删除这个 Todo 对象，可以如下操作：



```java
    todo.delete();
```


<div class="callout callout-danger">删除对象是一个较为敏感的操作。在控制台创建对象的时候，默认开启了权限保护，关于这部分的内容请阅读《[Java 权限管理使用指南](acl_guide-java.html)》。</div>

#### 使用 CQL 语法删除对象
LeanStorage 提供了类似 SQL 语法中的 Delete 方式删除一个对象，例如删除一个 Todo 对象可以使用下面的代码：


```java
    String objectId = "5656e37660b2febec4b35ed7";
    // 执行 CQL 语句实现更新一个 Todo 对象
    AVQuery.doCloudQuery("delete from Todo where objectId=?", objectId);
```







### 批量操作

为了减少网络交互的次数太多带来的时间浪费，你可以在一个请求中对多个对象进行创建、更新、删除、获取。接口都在 `AVObject` 这个类下面：



```java
    // 批量创建、更新
    AVObject.saveAll()

    // 批量删除
    AVObject.deleteAll()

    // 批量获取
    AVObject.fetchall()
```


批量设置 Todo 已经完成：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    List<AVObject> todos = query.find();
    for (AVObject todo : todos) {
        todo.put("status", 1);
    }
    AVObject.saveAll(todos);
```


不同类型的批量操作所引发不同数量的 API 调用，具体请参考 [API 调用次数的计算](faq.html#API_调用次数的计算)。


### 后台运行
细心的开发者已经发现，在所有的示例代码中几乎都是用了异步来访问 LeanStorage 云端，形如 `` 的方法都是提供给开发者在主线程调用用以实现后台运行的方法，因此开发者在主线程可以放心的调用这种命名方式的函数。另外，需要强调的是：**回调函数的代码是在主线程执行。**



### 离线存储对象

大多数保存功能可以立刻执行，并通知应用「保存完毕」。不过若不需要知道保存完成的时间，则可使用 saveEventually 来代替。

它的优点在于：如果用户目前尚未接入网络，saveEventually 会缓存设备中的数据，并在网络连接恢复后上传。如果应用在网络恢复之前就被关闭了，那么当它下一次打开时，LeanStorage 会再次尝试保存操作。

所有 saveEventually（或 deleteEventually）的相关调用，将按照调用的顺序依次执行。因此，多次对某一对象使用 saveEventually 是安全的。



### 关联数据

#### `AVRelation`
对象可以与其他对象相联系。如前面所述，我们可以把一个 `AVObject` 的实例 A，当成另一个 `AVObject` 实例 B 的属性值保存起来。这可以解决数据之间一对一或者一对多的关系映射，就像关系型数据库中的主外键关系一样。

例如，一个 TodoFolder 包含多个 Todo ，可以用如下代码实现：



```java
    final AVObject todoFolder = new AVObject("TodoFolder");// 构建对象
    todoFolder.put("name", "工作");
    todoFolder.put("priority", 1);

    final AVObject todo1 = new AVObject("Todo");
    todo1.put("title", "工程师周会");
    todo1.put("content", "每周工程师会议，周一下午2点");
    todo1.put("location", "会议室");

    final AVObject todo2 = new AVObject("Todo");
    todo2.put("title", "维护文档");
    todo2.put("content", "每天 16：00 到 18：00 定期维护文档");
    todo2.put("location", "当前工位");

    final AVObject todo3 = new AVObject("Todo");
    todo3.put("title", "发布 SDK");
    todo3.put("content", "每周一下午 15：00");
    todo3.put("location", "SA 工位");

    AVObject.saveAll(Arrays.asList(todo1, todo2, todo3));
    AVRelation<AVObject> relation = todoFolder.getRelation("containedTodos");// 新建一个 AVRelation
    relation.add(todo1);
    relation.add(todo2);
    relation.add(todo3);
    // 上述 3 行代码表示 relation 关联了 3 个 Todo 对象
    todoFolder.save();
```


#### Pointer
Pointer 只是个描述并没有具象的类与之对应，它与 `AVRelation` 不一样的地方在于：`AVRelation` 是在**一对多**的「一」这一方（上述代码中的一指 TodoFolder）保存一个 `AVRelation` 属性，这个属性实际上保存的是对被关联数据**多**的这一方（上述代码中这个多指 Todo）的一个 Pointer 的集合。而反过来，LeanStorage 也支持在「多」的这一方保存一个指向「一」的这一方的 Pointer，这样也可以实现**一对多**的关系。

简单的说， Pointer 就是一个外键的指针，只是在 LeanCloud 控制台做了显示优化。

现在有一个新的需求：用户可以分享自己的 TodoFolder 到广场上，而其他用户看见可以给与评论，比如某玩家分享了自己想买的游戏列表（TodoFolder 包含多个游戏名字），而我们用 Comment 对象来保存其他用户的评论以及是否点赞等相关信息，代码如下：



```java
    AVObject comment = new AVObject("Comment");// 构建 Comment 对象
    comment.put("like", 1);// 如果点了赞就是 1，而点了不喜欢则为 -1，没有做任何操作就是默认的 0
    comment.put("content", "这个太赞了！楼主，我也要这些游戏，咱们团购么？");// 留言的内容

    // 假设已知了被分享的该 TodoFolder 的 objectId 是 5590cdfde4b00f7adb5860c8
    comment.put("targetTodoFolder", AVObject.createWithoutData("TodoFolder", "5590cdfde4b00f7adb5860c8"));
    // 以上代码就是的执行结果就会在 comment 对象上有一个名为 targetTodoFolder 属性，它是一个 Pointer 类型，指向 objectId 为 5590cdfde4b00f7adb5860c8 的 TodoFolder
```


相关内容可参考 [关联数据查询](#AVRelation_查询)。

#### 地理位置
地理位置是一个特殊的数据类型，LeanStorage 封装了 `AVGeoPoint` 来实现存储以及相关的查询。

首先要创建一个 `AVGeoPoint` 对象。例如，创建一个北纬 39.9 度、东经 116.4 度的 `AVGeoPoint` 对象（LeanCloud 北京办公室所在地）：



``` java
    AVGeoPoint point = new AVGeoPoint(39.9, 116.4);
```


假如，添加一条 Todo 的时候为该 Todo 添加一个地理位置信息，以表示创建时所在的位置：



``` java
    todo.put("whereCreated", point);
```


同时请参考 [地理位置查询](#地理位置查询)。



### 序列化和反序列化
在实际的开发中，把 `AVObject` 当做参数传递的时候，会涉及到复杂对象的拷贝的问题，因此 `AVObject` 也提供了序列化和反序列化的方法：

序列化：


```java
    AVObject todoFolder = new AVObject("TodoFolder");// 构建对象
    todoFolder.put("name", "工作");// 设置名称
    todoFolder.put("priority", 1);// 设置优先级
    todoFolder.put("owner", AVUser.getCurrentUser());// 这里就是一个 Pointer 类型，指向当前登录的用户
    String serializedString = todoFolder.toString();

```


反序列化：


```java
    AVObject deserializedObject = AVObject.parseAVObject(serializedString);
    deserializedObject.save();// 保存到服务端
```








### 数据协议
很多开发者在使用 LeanStorage 初期都会产生疑惑：客户端的数据类型是如何被云端识别的？
因此，我们有必要重点介绍一下 LeanStorage 的数据协议。

先从一个简单的日期类型入手，比如在 Java 中，默认的日期类型是 `Date`，下面会详细讲解一个
 `Date` 是如何被云端正确的按照日期格式存储的。

为一个普通的 `AVObject` 的设置一个 `Date` 的属性，然后调用保存的接口：



Java SDK 在真正调用保存接口之前，会自动的调用一次序列化的方法，将 `Date` 类型的数据，转化为如下格式的数据：

```json
{
  "__type": "Date",
  "iso": "2015-11-21T18:02:52.249Z"
}
```

然后发送给云端，云端会自动进行反序列化，这样自然就知道这个数据类型是日期，然后按照传过来的有效值进行存储。因此，开发者在进阶开发的阶段，最好是能掌握 LeanStorage 的数据协议。如下表介绍的就是一些默认的数据类型被序列化之后的格式：



类型 | 序列化之后的格式|
---|---
`Date` | `{"__type": "Date","iso": "2015-11-21T18:02:52.249Z"}`
`byte[]` |  `{"__type": "Bytes","base64":"utf-8-encoded-string}"`
`Pointer` |`{"__type":"Pointer","className":"Todo","objectId":"55a39634e4b0ed48f0c1845c"}`
`AVRelation`| `{"__type": "Relation","className": "Todo"}`







## 文件
文件存储也是数据存储的一种方式，图像、音频、视频、通用文件等等都是数据的载体，另外很多开发者习惯了把复杂对象序列化之后保存成文件（如 `.json` 或者 `.xml` )。文件存储在 LeanStorage 中被单独封装成一个 `AVFile` 来实现文件的上传、下载等操作。

### 文件上传
文件的上传指的是开发者调用接口将文件存储在云端，并且返回文件最终的 URL 的操作。


#### 从数据流构建文件
`AVFile` 支持图片、视频、音乐等常见的文件类型，以及其他任何二进制数据，在构建的时候，传入对应的数据流即可：



```java
    AVFile file = new AVFile("resume.txt","Working with LeanCloud is great!".getBytes());
```


上例将文件命名为 `resume.txt`，这里需要注意两点：

- 不必担心文件名冲突。每一个上传的文件都有惟一的 ID，所以即使上传多个文件名为 `resume.txt` 的文件也不会有问题。
- 给文件添加扩展名非常重要。云端通过扩展名来判断文件类型，以便正确处理文件。所以要将一张 PNG 图片存到 `AVFile` 中，要确保使用 `.png` 扩展名。



#### 从本地路径构建文件
大多数的客户端应用程序都会跟本地文件系统产生交互，常用的操作就是读取本地文件，如下代码可以实现使用本地文件路径构建一个 `AVFile`：



```java
    AVFile file = AVFile.withAbsoluteLocalPath("LeanCloud.png",  "/tmp/LeanCloud.png");
```





#### 从网络路径构建文件
从一个已知的 URL 构建文件也是很多应用的需求。例如，从网页上拷贝了一个图像的链接，代码如下：



```java
    AVFile file = new AVFile("test.gif", "http://ww3.sinaimg.cn/bmiddle/596b0666gw1ed70eavm5tg20bq06m7wi.gif", new HashMap<String, Object>());
```




我们需要做出说明的是，[从本地路径构建文件](#从本地路径构建文件) 会<u>产生实际上传的流量</u>，并且文件最后是存在云端，而 [从网络路径构建文件](#从网络路径构建文件) 的文件实体并不存储在云端，只是会把文件的物理地址作为一个字符串保存在云端。

#### 执行上传
上传的操作调用方法如下：



```java
    file.save()
```



#### 上传进度监听
一般来说，上传文件都会有一个上传进度条显示用以提高用户体验：



```java
    file.saveInBackground(new SaveCallback() {
        @Override
        public void done(AVException e) {
        // 成功或失败处理...
        }
    }, new ProgressCallback() {
        @Override
        public void done(Integer integer) {
        // 上传进度数据，integer 介于 0 和 100。
        }
    });
```





### 文件下载
客户端 SDK 接口可以下载文件并把它缓存起来，只要文件的 URL 不变，那么一次下载成功之后，就不会再重复下载，目的是为了减少客户端的流量。



```java
    file.getDataInBackground(new GetDataCallback() {
        @Override
        public void done(byte[] bytes, AVException e) {
        // bytes 就是文件的数据流
        }
    }, new ProgressCallback() {
        @Override
        public void done(Integer integer) {
        // 上传进度数据，integer 介于 0 和 100。
        }
    });
```

请注意代码中**下载进度**数据的读取。



### 图像缩略图

保存图像时，如果想在下载原图之前先得到缩略图，方法如下：



```java
    AVFile file = new AVFile("test.jpg", "文件-url", new HashMap<String, Object>());
    file.getThumbnailUrl(true, 100, 100);
```


<div class="callout callout-info">注意：<strong>图片最大不超过 20 M 才可以获取缩略图。</strong> </div>

### 文件元数据

`AVFile` 的 `metaData` 属性，可以用来保存和获取该文件对象的元数据信息：



``` java
    AVFile file = AVFile.withAbsoluteLocalPath("test.jpg", "/tmp/xxx.jpg");
    file.addMetaData("width", 100);
    file.addMetaData("height", 100);
    file.addMetaData("author", "LeanCloud");
    file.save();
```




### 删除

当文件较多时，要把一些不需要的文件从云端删除：



``` java
    file.delete();
```






<div class="callout callout-info">注意：默认情况下，文件的删除权限是关闭的，需要进入控制台，在 [`_File` > 其他 > 权限设置 > delete](/data.html?appid={{appid}}#/_File)  中开启。</div>


## 查询
`AVQuery` 是构建针对 `AVObject` 查询的基础类。


### 创建查询实例



### 根据 id 查询
在 [获取对象](#获取对象) 中我们介绍过如何通过 objectId 来获取对象实例，从而简单的介绍了一下 `AVQuery` 的用法，代码请参考对应的内容，不再赘述。

### 条件查询
在大多数情况下做列表展现的时候，都是根据不同条件来分类展现的，比如，我要查询所有优先级为 0 的 Todo，也就是做列表展现的时候，要展示优先级最高，最迫切需要完成的日程列表，此时基于 priority 构建一个查询就可以查询出符合需求的对象：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereEqualTo("priority", 0);
    List<AVObject> todos = query.find(); // 符合 priority = 0 的 Todo 列表
```


其实，拥有传统关系型数据库开发经验的开发者完全可以翻译成如下的 SQL：

```sql
  select * from Todo where priority = 0
```
LeanStorage 也支持使用这种传统的 SQL 语句查询。具体使用方法请移步至 [Cloud Query Language（CQL）查询](#CQL_查询)。

查询默认最多返回 100 条符合条件的结果，要更改这一数值，请参考 [限定结果返回数量](#限定返回数量)。

当多个查询条件并存时，它们之间默认为 AND 关系，即查询只返回满足了全部条件的结果。建立 OR 关系则需要使用 [组合查询](#组合查询)。

注意：在简单查询中，如果对一个对象的同一属性设置多个条件，那么先前的条件会被覆盖，查询只返回满足最后一个条件的结果。例如，我们要找出优先级为 0 和 1 的所有 Todo，错误写法是：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereEqualTo("priority", 0);
    query.whereEqualTo("priority", 1);
    // 如果这样写，第二个条件将覆盖第一个条件，查询只会返回 priority = 1 的结果
    List<AVObject> todos = query.find();
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



```java
    query.whereLessThan("priority", 2);
```


要查询优先级大于等于 2 的 Todo：



```java
    query.whereGreaterThanOrEqualTo("priority", 2);
```


比较查询**只适用于可比较大小的数据类型**，如整型、浮点等。

#### 正则匹配查询

正则匹配查询是指在查询条件中使用正则表达式来匹配数据，查询指定的 key 对应的 value 符合正则表达式的所有对象。
例如，要查询标题包含中文的 Todo 对象可以使用如下代码：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereMatches("title","[\\u4e00-\\u9fa5]");
```


正则匹配查询**只适用于**字符串类型的数据。

#### 包含查询

包含查询类似于传统 SQL 语句里面的 `LIKE %keyword%` 的查询，比如查询标题包含「李总」的 Todo：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereContains("title", "李总");
```


翻译成 SQL 语句就是：

```sql
  select * from Todo where title LIKE '%李总%'
```
不包含查询与包含查询是对立的，不包含指定关键字的查询，可以使用 [正则匹配方法](#正则匹配查询) 来实现。例如，查询标题不包含「机票」的 Todo，正则表达式为 `^((?!机票).)*$`：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereMatches("title","^((?!机票).)*$");
```


但是基于正则的模糊查询有两个缺点：

- 当数据量逐步增大后，查询效率将越来越低。
- 没有文本相关性排序

因此，你还可以考虑使用 [应用内搜索](#应用内搜索) 功能。它基于搜索引擎技术构建，提供更强大的搜索功能。

还有一个接口可以精确匹配不等于，比如查询标题不等于「出差、休假」的 Todo 对象：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereNotContainedIn("title", Arrays.asList("出差", "休假"));
    // 标题不是「出差」和「休假」的 Todo 对象列表
    List<AVObject> todos = query.find(); 
```


#### 数组查询

当一个对象有一个属性是数组的时候，针对数组的元数据查询可以有多种方式。例如，在 [数组](#更新数组) 一节中我们为 Todo 设置了 reminders 属性，它就是一个日期数组，现在我们需要查询所有在 8:30 会响起闹钟的 Todo 对象：



```java
    Date getDateWithDateString(String dateString) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        Date date = dateFormat.parse(dateString);
        return date;
    }

    void queryRemindersContains() {
        Date reminder = getDateWithDateString("2015-11-11 08:30:00");

        AVQuery<AVObject> query = new AVQuery<>("Todo");

        // equalTo: 可以找出数组中包含单个值的对象
        query.whereEqualTo("reminders", reminder);
    }
```


如果你要查询包含 8:30、9:30 这两个时间点响起闹钟的 Todo，可以使用如下代码：



```java
    Date getDateWithDateString(String dateString) {
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    Date date = dateFormat.parse(dateString);
    return date;
    }

    void queryRemindersWhereContainsAll() {
        Date reminder1 = getDateWithDateString("2015-11-11 08:30:00");
        Date reminder2 = getDateWithDateString("2015-11-11 09:30:00");

        AVQuery<AVObject> query = new AVQuery<>("Todo");
        query.whereContainsAll("reminders", Arrays.asList(reminder1, reminder2));

        List<AVObject> todos = query.find();
    }
```


注意这里是包含关系，假如有一个 Todo 会在 8:30、9:30、10:30 响起闹钟，它仍然是会被查询出来的。

#### 字符串查询
使用 `whereStartsWith()` 可以过滤出以特定字符串开头的结果，这有点像 SQL 的 LIKE 条件。因为支持索引，所以该操作对于大数据集也很高效。



```java
    // 找出开头是「早餐」的 Todo
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereStartsWith("content", "早餐");
```


#### 空值查询
假设我们的 Todo 允许用户上传图片用来帮助用户记录某些特殊的事项，但是有时候用户可能就记得自己给一个 Todo 附加过图片，但是具体又不记得这个 Todo 的关键字是什么，因此我们需要一个接口可以找出那些有图片的 Todo，此时就可以使用到空值查询的接口：



### 组合查询
组合查询就是把诸多查询条件合并成一个查询，再交给 SDK 去云端查询。方式有两种：OR 和 AND。

#### OR 查询
OR 操作表示多个查询条件符合其中任意一个即可。 例如，查询优先级是大于等于 3 或者已经完成了的 Todo：



```java
    final AVQuery<AVObject> priorityQuery = new AVQuery<>("Todo");
    priorityQuery.whereGreaterThanOrEqualTo("priority", 3);

    final AVQuery<AVObject> statusQuery = new AVQuery<>("Todo");
    statusQuery.whereEqualTo("status", 1);

    AVQuery<AVObject> query = AVQuery.or(Arrays.asList(priorityQuery, statusQuery));
    List<AVObject> todos = query.find(); // 返回 priority 大于等于3 或 status 等于 1 的 Todo
```


**注意：OR 查询中，子查询中不能包含地理位置相关的查询。**

#### AND 查询
AND 操作是指只有满足了所有查询条件的对象才会被返回给客户端。例如，查询优先级小于 1 并且尚未完成的 Todo：



```java
    final AVQuery<AVObject> priorityQuery = new AVQuery<>("Todo");
    priorityQuery.whereLessThan("priority", 3);

    final AVQuery<AVObject> statusQuery = new AVQuery<>("Todo");
    statusQuery.whereEqualTo("status", 0);

    AVQuery<AVObject> query = AVQuery.and(Arrays.asList(priorityQuery, statusQuery));
    List<AVObject> list = query.find()  // 返回 priority 小于 3 并且 status 等于 0 的 Todo
```


可以对新创建的 `AVQuery` 添加额外的约束，多个约束将以 AND 运算符来联接。

### 查询结果

#### 获取第一条结果
例如很多应用场景下，只要获取满足条件的一个结果即可，例如获取满足条件的第一条 Todo：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereEqualTo("priority",0);
    AVObject avObject = query.getFirst(); // object 就是符合条件的第一个 AVObject
```


#### 限定返回数量
为了防止查询出来的结果过大，云端默认针对查询结果有一个数量限制，即 `limit`，它的默认值是 100。比如一个查询会得到 10000 个对象，那么一次查询只会返回符合条件的 100 个结果。`limit` 允许取值范围是 1 ~ 1000。例如设置返回 10 条结果：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    Date now = new Date();
    query.whereLessThanOrEqualTo("createdAt", now);//查询今天之前创建的 Todo
    query.limit(10);// 最多返回 10 条结果
```


#### 跳过数量
设置 skip 这个参数可以告知云端本次查询要跳过多少个结果。将 skip 与 limit 搭配使用可以实现翻页效果，这在客户端做列表展现时，尤其在数据量庞大的情况下就使用技术。例如，在翻页中，一页显示的数量是 10 个，要获取第 3 页的对象：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    Date now = new Date();
    query.whereLessThanOrEqualTo("createdAt", now);//查询今天之前创建的 Todo
    query.limit(10);// 最多返回 10 条结果
    query.skip(20);// 跳过 20 条结果
```


尽管我们提供以上接口，但是我们不建议广泛使用，因为它的执行效率比较低。取而代之，我们建议使用 `createdAt` 或者 `updatedAt` 这类的时间戳进行分段查询。

#### 属性限定
通常列表展现的时候并不是需要展现某一个对象的所有属性，例如，Todo 这个对象列表展现的时候，我们一般展现的是 title 以及 content，我们在设置查询的时候，也可以告知云端需要返回的属性有哪些，这样既满足需求又节省了流量，也可以提高一部分的性能，代码如下：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.selectKeys(Arrays.asList("title", "content"));
    List<AVObject> list = query.find();
    for (AVObject avObject : list) {
        String title = avObject.getString("title");
        String content = avObject.getString("content");

        // 如果访问没有指定返回的属性（key），则会报错，在当前这段代码中访问 location 属性就会报错
        String location = avObject.getString("location");
    }
```


#### 统计总数量
通常用户在执行完搜索后，结果页面总会显示出诸如「搜索到符合条件的结果有 1020 条」这样的信息。例如，查询一下今天一共完成了多少条 Todo：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    query.whereEqualTo("status", 0);
    int i = query.count();
    // 查询成功，输出计数
```


#### 排序

对于数字、字符串、日期类型的数据，可对其进行升序或降序排列。



``` java
    // 按时间，升序排列
    query.orderByAscending("createdAt");

    // 按时间，降序排列
    query.orderByDescending("createdAt");
```


一个查询可以附加多个排序条件，如按 priority 升序、createdAt 降序排列：



```java
    query.addAscendingOrder("priority");
    query.addDescendingOrder("createdAt");
```


<!-- #### 限定返回字段 -->

### 关系查询
关联数据查询也可以通俗地理解为关系查询，关系查询在传统型数据库的使用中是很常见的需求，因此我们也提供了相关的接口来满足开发者针对关联数据的查询。

首先，我们需要明确关系的存储方式，再来确定对应的查询方式。

#### Pointer 查询
基于在 [Pointer](#Pointer) 小节介绍的存储方式：每一个 Comment 都会有一个 TodoFolder 与之对应，用以表示 Comment 属于哪个 TodoFolder。现在我已知一个 TodoFolder，想查询所有的 Comnent 对象，可以使用如下代码：



```java
    AVQuery<AVObject> query = new AVQuery<>("Comment");
    query.whereEqualTo("targetTodoFolder", AVObject.createWithoutData("TodoFolder", "5590cdfde4b00f7adb5860c8"));
```


#### `AVRelation` 查询
假如用户可以给 TodoFolder 增加一个 Tag 选项，用以表示它的标签，而为了以后拓展 Tag 的属性，就新建了一个 Tag 对象，如下代码是创建 Tag 对象：



```java
    AVObject tag = new AVObject("Tag");// 构建对象
    tag.put("name", "今日必做");// 设置名称
    tag.save();
```


而 Tag 的意义在于一个 TodoFolder 可以拥有多个 Tag，比如「家庭」（TodoFolder） 拥有的 Tag 可以是：今日必做，老婆吩咐，十分重要。实现创建「家庭」这个 TodoFolder 的代码如下：



```java
    AVObject tag1 = new AVObject("Tag");// 构建对象
    tag1.put("name", "今日必做");// 设置 Tag 名称

    AVObject tag2 = new AVObject("Tag");// 构建对象
    tag2.put("name", "老婆吩咐");// 设置 Tag 名称

    AVObject tag3 = new AVObject("Tag");// 构建对象
    tag3.put("name", "十分重要");// 设置 Tag 名称

    AVObject todoFolder = new AVObject("TodoFolder");// 构建对象
    todoFolder.put("name", "家庭");// 设置 Todo 名称
    todoFolder.put("priority", 1);// 设置优先级

    AVRelation<AVObject> relation = todoFolder.getRelation("tags");
    relation.add(tag1);
    relation.add(tag2);
    relation.add(tag3);

    todoFolder.save();// 保存到云端
```


查询一个 TodoFolder 的所有 Tag 的方式如下：



```java
    AVObject todoFolder = AVObject.createWithoutData("TodoFolder", "5661047dddb299ad5f460166");
    AVRelation<AVObject> relation = todoFolder.getRelation("tags");
    AVQuery<AVObject> query = relation.getQuery();
    List<AVObject> list = query.find(); // list 是一个 AVObject 的 List，它包含所有当前 todoFolder 的 tags
```


反过来，现在已知一个 Tag，要查询有多少个 TodoFolder 是拥有这个 Tag 的，可以使用如下代码查询：



```java
    AVObject tag = AVObject.createWithoutData("Tag", "5661031a60b204d55d3b7b89");
    AVQuery<AVObject> query = new AVQuery<>("TodoFolder");
    query.whereEqualTo("tags", tag);
    List<AVObject> list = query.find(); // list 指的就是所有包含当前 tag 的 TodoFolder
```


关于关联数据的建模是一个复杂的过程，很多开发者因为在存储方式上的选择失误导致最后构建查询的时候难以下手，不但客户端代码冗余复杂，而且查询效率低，为了解决这个问题，我们专门针对关联数据的建模推出了一个详细的文档予以介绍，详情请阅读 

[Java 数据模型设计指南](relation_guide-java.html)
。

#### 关联属性查询
正如在 [Pointer](#Pointer) 中保存 Comment 的 targetTodoFolder 属性一样，假如查询到了一些 Comment 对象，想要一并查询出每一条 Comment 对应的 TodoFolder 对象的时候，可以加上 include 关键字查询条件。同理，假如 TodoFolder 表里还有 pointer 型字段 targetAVUser 时，再加上一个递进的查询条件，形如 include(b.c)，即可一并查询出每一条 TodoFolder 对应的 AVUser 对象。代码如下：



```java
    AVQuery<AVObject> commentQuery = new AVQuery<>("Comment");
    commentQuery.orderByDescending("createdAt");
    commentQuery.limit(10);
    commentQuery.include("targetTodoFolder");// 关键代码，用 includeKey 告知服务端需要返回的关联属性对应的对象的详细信息，而不仅仅是 objectId
    List<AVObject> list = commentQuery.find(); // list 是最近的十条评论, 其 targetTodoFolder 字段也有相应数据
    for (AVObject comment : list) {
        // 并不需要网络访问
        AVObject todoFolder = comment.getAVObject("targetTodoFolder");
    }
```


#### 内嵌查询
假如现在有一个需求是展现点赞超过 20 次的 TodoFolder 的评论（Comment）查询出来，注意这个查询是针对评论（Comment），要实现一次查询就满足需求可以使用内嵌查询的接口：



```java
    // 构建内嵌查询
    AVQuery<AVObject> innerQuery = new AVQuery<>("TodoFolder");
    innerQuery.whereGreaterThan("liks", 20);
    // 将内嵌查询赋予目标查询
    AVQuery<AVObject> query = new AVQuery<>("Comment");
    // 执行内嵌操作
    query.whereMatchesQuery("targetTodoFolder", innerQuery);
    List<AVObject> list = query.find(); // list 就是符合超过 20 个赞的 TodoFolder 这一条件的 Comment 对象集合

    // 注意如果要做相反的查询可以使用
    query.whereDoesNotMatchQuery("targetTodoFolder", innerQuery);
    // 如此做将查询出 likes 小于或者等于 20 的 TodoFolder 的 Comment 对象
```


### CQL 查询
Cloud Query Language（CQL）是 LeanStorage 独创的使用类似 SQL 语法来实现云端查询功能的语言，具有 SQL 开发经验的开发者可以方便地使用此接口实现查询。

分别找出 status = 1 的全部 Todo 结果，以及 priority = 0 的 Todo 的总数：



```java
    String cql = "select * from Todo where status = 1";
    AVCloudQueryResult avCloudQueryResult = AVQuery.doCloudQuery(cql);
    avCloudQueryResult.getResults();

    cql = "select count(*) from Todo where priority = 0";
    AVCloudQueryResult avCloudQueryResult = AVQuery.doCloudQuery(cql);
    avCloudQueryResult.getCount();
```


通常查询语句会使用变量参数，为此我们提供了与 Java JDBC 所使用的 PreparedStatement 占位符查询相类似的语法结构。

查询 status = 0、priority = 1 的 Todo：



```java
    String cql = " select * from Todo where status = ? and priority = ?";
    AVCloudQueryResult avCloudQueryResult = AVQuery.doCloudQuery(cql, Arrays.asList(0, 1));
```


目前 CQL 已经支持数据的更新 update、插入 insert、删除 delete 等 SQL 语法，更多内容请参考 [Cloud Query Language 详细指南](cql_guide.html)。


### 缓存查询
缓存一些查询的结果到磁盘上，这可以让你在离线的时候，或者应用刚启动，网络请求还没有足够时间完成的时候可以展现一些数据给用户。当缓存占用了太多空间的时候，LeanStorage 会自动清空缓存。

默认情况下的查询不会使用缓存，除非你调用接口明确设置启用。例如，尝试从网络请求，如果网络不可用则从缓存数据中获取，可以这样设置：



#### 缓存策略
为了满足多变的需求，SDK 默认提供了以下几种缓存策略：



Java SDK 不支持缓存策略。


#### 缓存相关的操作




### 地理位置查询
地理位置查询是较为特殊的查询，一般来说，常用的业务场景是查询距离 xx 米之内的某个位置或者是某个建筑物，甚至是以手机为圆心，查找方圆多少范围内餐厅等等。LeanStorage 提供了一系列的方法来实现针对地理位置的查询。

#### 查询位置附近的对象
Todo 的 `whereCreated`（创建 Todo 时的位置）是一个 `AVGeoPoint` 对象，现在已知了一个地理位置，现在要查询 `whereCreated` 靠近这个位置的 Todo 对象可以使用如下代码：



```java
    AVQuery<AVObject> query = new AVQuery<>("Todo");
    AVGeoPoint point = new AVGeoPoint(39.9, 116.4);
    query.limit(10);
    query.whereNear("whereCreated", point);
    List<AVObject> list ＝ query.find(); // 离这个位置最近的 10 个 Todo 对象
```

在上面的代码中，`list` 返回的是与 `point` 这一点按距离排序（由近到远）的对象数组。注意：**如果在此之后又使用了 `orderByAscending` 或 `orderByDescending` 方法，则按距离排序会被新排序覆盖。**


#### 查询指定范围内的对象
要查找指定距离范围内的数据，可使用 `whereWithinKilometers` 、 `whereWithinMiles` 或 `whereWithinRadians` 方法。
例如，我要查询距离指定位置，2 千米范围内的 Todo：



```java
    query.whereWithinKilometers("whereCreated", point, 2.0);
```


#### 注意事项

使用地理位置需要注意以下方面：

* 每个 `AVObject` 数据对象中只能有一个 `AVGeoPoint` 对象的属性。
* 地理位置的点不能超过规定的范围。纬度的范围应该是在 `-90.0` 到 `90.0` 之间，经度的范围应该是在 `-180.0` 到 `180.0` 之间。如果添加的经纬度超出了以上范围，将导致程序错误。




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



```java
    String currentUsername = AVUser.getCurrentUser().getUsername();
    String currentEmail = AVUser.getCurrentUser().getEmail();

    // 请注意，以下代码无法获取密码
    String currentPassword = AVUser.getCurrentUser().getPassword();// 无 getPassword() 此方法
```


请注意代码中，密码是仅仅是在注册的时候可以设置的属性（这部分代码可参照 [用户名和密码注册](#用户名和密码注册)），它在注册完成之后并不会保存在本地（SDK 不会以明文保存密码这种敏感数据），所以在登录之后，再访问密码这个字段是为**空的**。

#### 自定义属性
用户对象和普通对象一样也支持添加自定义属性。例如，为当前用户添加年龄属性：



```java
    AVUser.getCurrentUser().put("age", 25);
    AVUser.getCurrentUser().save();
```


#### 属性的修改

很多开发者都有这样的疑问：为什么我不能修改任意一个用户的属性？原因如下。

> 很多时候，就算是开发者也不要轻易修改用户的基本信息，例如用户的手机号、社交账号等个人信息都比较敏感，应该由用户在 App 中自行修改。所以为了保证用户的数据仅在用户自己已登录的状态下才能修改，云端对所有针对 `AVUser` 对象的数据操作都要做验证。

假如，刚才我们为当前用户添加了一个 age 属性，现在我们来修改它：



```java
    AVUser.getCurrentUser().put("age", 25);
    AVUser.getCurrentUser().save();
    AVUser.getCurrentUser().put("age", 27);
    AVUser.getCurrentUser().save();
```


细心的开发者应该已经发现 `AVUser` 在自定义属性上的使用与一般的 `AVObject` 没本质区别。

### 注册





#### 手机号码登录

一些应用为了提高首次使用的友好度，一般会允许用户浏览一些内容，直到用户发起了一些操作才会要求用户输入一个手机号，而云端会自动发送一条验证码的短信给用户的手机号，最后验证一下，完成一个用户注册并且登录的操作，例如很多团购类应用都有这种用户场景。

首先调用发送验证码的接口：



```java
    try {
        AVOSCloud.requestSMSCode("13577778888");
    } catch (AVException e) {
        // 发送失败可以查看 e 里面提供的信息
        e.printStackTrace();
    }
```


然后在 UI 上给与用户输入验证码的输入框，用户点击登录的时候调用如下接口：



```java
    AVUser avUser = AVUser.signUpOrLoginByMobilePhone("13577778888", "123456");
    // 如果没有抛异常就表示登录成功了，并且 user 是一个全新的用户
```


#### 用户名和密码注册

采用「用户名 + 密码」注册时需要注意：密码是以明文方式通过 HTTPS 加密传输给云端，云端会以密文存储密码，并且我们的加密算法是无法通过所谓「彩虹表撞库」获取的，这一点请开发者放心。换言之，用户的密码只可能用户本人知道，开发者不论是通过控制台还是 API 都是无法获取。另外我们需要强调<u>在客户端，应用切勿再次对密码加密，这会导致重置密码等功能失效</u>。

例如，注册一个用户的示例代码如下（用户名 `Tom` 密码 `cat!@#123`）：



```java
    try {
        AVUser user = new AVUser();// 新建 AVUser 对象实例
        user.setUsername("Tom");// 设置用户名
        user.setPassword("cat!@#123");// 设置密码
        user.setEmail("tom@leancloud.cn");// 设置邮箱
        user.signUp();
    } catch (AVException e) {
        // 失败的原因可能有多种，常见的是用户名已经存在。
        e.printStackTrace();
    }
```



我们建议在可能的情况下尽量使用异步版本的方法，这样就不会影响到应用程序主 UI 线程的响应。


如果注册不成功，请检查一下返回的错误对象。最有可能的情况是用户名已经被另一个用户注册，错误代码 [202](error_code.html#_202)，即 `_User` 表中的 `username` 字段已存在相同的值，此时需要提示用户尝试不同的用户名来注册。同样，邮件 `email` 和手机号码 `mobilePhoneNumber` 字段也要求在各自的列中不能有重复值出现，否则会出现 [203](error_code.html#_203)、[214](error_code.html#_214) 错误。

开发者也可以要求用户使用 Email 做为用户名注册，即在用户提交信息后将 `_User` 表中的 `username` 和 `email` 字段都设为相同的值，这样做的好处是用户在忘记密码的情况下可以直接使用「[邮箱重置密码](#重置密码)」功能，无需再额外绑定电子邮件。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。



#### 设置手机号码

微信、陌陌等流行应用都会建议用户将账号和一个手机号绑定，这样方便进行身份认证以及日后的密码找回等安全模块的使用。我们也提供了一整套发送短信验证码以及验证手机号的流程，这部分流程以及代码演示请参考 。

#### 验证邮箱

许多应用会通过验证邮箱来确认用户注册的真实性。如果在 [应用控制台 > 应用设置 > 应用选项](https://leancloud.cn/app.html?appid={{appid}}#/permission) 中勾选了 **用户注册时，发送验证邮件**，那么当一个 `AVUser` 在注册时设置了邮箱，云端就会向该邮箱自动发送一封包含了激活链接的验证邮件，用户打开该邮件并点击激活链接后便视为通过了验证。有些用户可能在注册之后并没有点击激活链接，而在未来某一个时间又有验证邮箱的需求，这时需要调用如下接口让云端重新发送验证邮件：



```java
  AVUser.requestEmailVerfiy("abc@xyz.com", new RequestEmailVerifyCallback() {
            @Override
            public void done(AVException e) {
                if (e == null) {
                    // 求重发验证邮件成功
                }
            }
        });
```


### 登录

我们提供了多种登录方式，以满足不同场景的应用。



#### 用户名和密码登录



```java
    AVUser avUser = AVUser.logIn("Tom", "cat!@#123");
```


#### 手机号和密码登录

请确保已详细阅读了  这一小节的内容，才可以顺利理解手机号匹配密码登录的流程以及适用范围。

用户的手机号只要经过了验证，就可以使用手机号密码登录的功能，否则登录会失败。



```java
    AVUser avUser = AVUser.loginByMobilePhoneNumber("13577778888", "cat!@#123");
```


#### 手机号和验证码登录

中国电信、中国联通、中国移动，这三大运营商的官网均支持「手机号 + 密码」和「手机号 + 随机验证码」的登录方式，我们也提供了这些方式。

首先，调用发送登录验证码的接口：



```java
    AVUser.requestLoginSmsCode("13577778888");
```


然后在界面上引导用户输入收到的 6 位短信验证码：



```java
    AVUser avUser = AVUser.signUpOrLoginByMobilePhone("13577778888", "238825");
```



#### 当前用户

打开微博或者微信，它不会每次都要求用户都登录，这是因为它将用户数据缓存在了客户端。
同样，只要是调用了登录相关的接口，LeanCloud SDK 都会自动缓存登录用户的数据。
例如，判断当前用户是否为空，为空就跳转到登录页面让用户登录，如果不为空就跳转到首页：



```java
    AVUser currentUser = AVUser.getCurrentUser();
    if (currentUser != null) {
        // 跳转到首页
    } else {
        //用户对象为空时，可打开用户注册界面…
    }
```



如果不调用 [登出](#登出) 方法，当前用户的缓存将永久保存在客户端。


#### SessionToken

所有登录接口调用成功之后，云端会返回一个 SessionToken 给客户端，客户端在发送 HTTP 请求的时候，Java SDK 会在 HTTP 请求的 Header 里面自动添加上当前用户的 SessionToken 作为这次请求发起者 `AVUser` 的身份认证信息。

如果在控制台的 [应用选项](/app.html?appid={{appid}}#/permission) 中勾选了 **密码修改后，强制客户端重新登录**，那么当用户密码再次被修改后，已登录的用户对象就会失效，开发者需要使用更改后的密码重新调用登录接口，使 SessionToken 得到更新，否则后续操作会遇到 [403 (Forbidden)](error_code.html#_403) 的错误。

#### 账户锁定

输入错误的密码或验证码会导致用户登录失败。如果在 15 分钟内，同一个用户登录失败的次数大于 6 次，该用户账户即被云端暂时锁定，此时云端会返回错误码 `{"code":1,"error":"登录失败次数超过限制，请稍候再试，或者通过忘记密码重设密码。"}`，开发者可在客户端进行必要提示。

锁定将在最后一次错误登录的 15 分钟之后由云端自动解除，开发者无法通过 SDK 或 REST API 进行干预。在锁定期间，即使用户输入了正确的验证信息也不允许登录。这个限制在 SDK 和云引擎中都有效。

### 重置密码

#### 邮箱重置密码

我们都知道，应用一旦加入账户密码系统，那么肯定会有用户忘记密码的情况发生。对于这种情况，我们为用户提供了一种安全重置密码的方法。

重置密码的过程很简单，用户只需要输入注册的电子邮件地址即可：



```java
    AVUser.requestPasswordReset("myemail@example.com");
```


密码重置流程如下：

1. 用户输入注册的电子邮件，请求重置密码；
2. LeanStorage 向该邮箱发送一封包含重置密码的特殊链接的电子邮件；
3. 用户点击重置密码链接后，一个特殊的页面会打开，让他们输入新密码；
4. 用户的密码已被重置为新输入的密码。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。

#### 手机号码重置密码



与使用 [邮箱重置密码](#邮箱重置密码) 类似，「手机号码重置密码」使用下面的方法来获取短信验证码：



```java
    AVUser.requestPasswordResetBySmsCode("18612340000");
```


注意！用户需要先绑定手机号码，然后使用短信验证码来重置密码：



```java
    AVUser.resetPasswordBySmsCode("123456", "password");
```


#### 登出

用户登出系统时，SDK 会自动清理缓存信息。



```java
    AVUser.logOut();// 清除缓存用户对象
    AVUser currentUser = AVUser.getCurrentUser();// 现在的 currentUser 是 null 了
```



### 用户的查询
请注意，**新创建的应用的用户表 `_User` 默认关闭了查询权限**。你可以通过 Class 权限设置打开查询权限，请参考 [数据与安全 · Class 级别的权限](data_security.html#Class_级别的_ACL)。我们推荐开发者在 [云引擎](leanengine_overview.html) 中封装用户查询，只查询特定条件的用户，避免开放用户表的全部查询权限。

查询用户代码如下：


```java
    AVQuery<AVUser> userQuery = new AVQuery<>("_User");
```


### 浏览器中查看用户表

用户表是一个特殊的表，专门存储用户对象。在浏览器端，你会看到一个 `_User` 表。

## 角色
关于用户与角色的关系，我们有一个更为详尽的文档介绍这部分的内容，并且针对权限管理有深入的讲解，详情请点击 [Java 权限管理使用指南](acl_guide-java.html)。



## 子类化
LeanCloud 希望设计成能让人尽快上手并使用。你可以通过 `AVObject.get` 方法访问所有的数据。但是在很多现有成熟的代码中，子类化能带来更多优点，诸如简洁、可扩展性以及 IDE 提供的代码自动完成的支持等等。子类化不是必须的，你可以将下列代码转化：

```
    AVObject student = new AVObject("Student");
    student.put("name", "小明");
    student.save();
```

可改写成:

```
    Student student = new Student();
    student.put("name", "小明");
    student.save();
```

这样代码看起来是不是更简洁呢？

### 子类化 AVObject

要实现子类化，需要下面几个步骤：

1. 首先声明一个子类继承自 `AVObject`；
2. 添加 `@AVClassName` 注解。它的值必须是一个字符串，也就是你过去传入 `AVObject` 构造函数的类名。这样以来，后续就不需要再在代码中出现这个字符串类名；
3. 确保你的子类有一个 public 的默认（参数个数为 0）的构造函数。切记不要在构造函数里修改任何 `AVObject` 的字段；
4. 在你的应用初始化的地方，在调用 `AVOSCloud.initialize()` 之前注册子类 `AVObject.registerSubclass(YourClass.class)`。

下面是实现 `Student` 子类化的例子:

``` java
// Student.java
import com.avos.avoscloud.AVClassName;
import com.avos.avoscloud.AVObject;

@AVClassName("Student")
public class Student extends AVObject {
}

// App.java
import com.avos.avoscloud.AVOSCloud;
import android.app.Application;

public class App extends Application {
  @Override
  public void onCreate() {
    super.onCreate();

    AVObject.registerSubclass(Student.class);
    AVOSCloud.initialize(this, "...", "...");
  }
}
```

### 访问器、修改器和方法

添加方法到 AVObject 的子类有助于封装类的逻辑。你可以将所有跟子类有关的逻辑放到一个地方，而不是分成多个类来分别处理商业逻辑和存储/转换逻辑。

你可以很容易地添加访问器和修改器到你的 AVObject 子类。像平常那样声明字段的`getter` 和 `setter` 方法，但是通过 AVObject 的 `get` 和 `put` 方法来实现它们。下面是这个例子为 `Student` 类创建了一个 `content` 的字段：

``` java
// Student.java
@AVClassName("Student")
public class Student extends AVObject {
  public String getContent() {
    return getString("content");
  }
  public void setContent(String value) {
    put("content", value);
  }
}
```

现在你就可以使用 `student.getContent()` 方法来访问 `content` 字段，并通过 `student.setContent("blah blah blah")` 来修改它。这样就允许你的 IDE 提供代码自动完成功能，并且可以在编译时发现到类型错误。
+

各种数据类型的访问器和修改器都可以这样被定义，使用各种 `get()` 方法的变种，例如 `getInt()`，`getAVFile()` 或者 `getMap()`。
+

如果你不仅需要一个简单的访问器，而是有更复杂的逻辑，你可以实现自己的方法，例如：

``` java
ublic void takeAccusation() {
  // 处理用户举报，当达到某个条数的时候，自动打上屏蔽标志
  increment("accusation", 1);
  if (getAccusation() > 50) {
    setSpam(true);
  }
}
```

### 初始化子类

你可以使用你自定义的构造函数来创建你的子类对象。你的子类必须定义一个公开的默认构造函数，并且不修改任何父类 AVObject 中的字段，这个默认构造函数将会被 SDK 使用来创建子类的强类型的对象。


要创建一个到现有对象的引用，可以使用 `AVObject.createWithoutData()`:

```java
Student postReference = AVObject.createWithoutData(Student.class, student.getObjectId());
```

### 子类的序列化与反序列化

如果希望 AVObject 子类也支持 Parcelable，则需要至少满足以下几个要求：
1. 确保子类有一个 public 并且参数为 Parcel 的构造函数，并且在内部调用父类的该构造函数。
2. 内部需要有一个静态变量 CREATOR 实现 `Parcelable.Creator`。

```java
// Stduent.java
@AVClassName("Student")
public class Student extends AVObject {
  public Student(){
    super();
  }

  public Student(Parcel in){
    super(in);
  }
  //此处为我们的默认实现，当然你也可以自行实现
  public static final Creator CREATOR = AVObjectCreator.instance;
}
```

### 查询子类

你可以通过 `AVObject.getQuery()` 或者 `AVQuery.getQuery` 的静态方法获取特定的子类的查询对象。下面的例子就查询了用户发表的所有微博列表：

```java
AVQuery<Student> query = AVObject.getQuery(Student.class);
query.whereEqualTo("pubUser", AVUser.getCurrentUser().getUsername());
List<Student> results = query.find();
for (Student a : results) {
    // ...
}
```

### AVUser 的子类化

AVUser 作为 AVObject 的子类，同样允许子类化，你可以定义自己的 User 对象，不过比起 AVObject 子类化会更简单一些，只要继承 AVUser 就可以了：

```java
import com.avos.avoscloud.AVObject;
import com.avos.avoscloud.AVUser;

public class MyUser extends AVUser {
    public void setNickName(String name) {
  this.put("nickName", name);
    }

    public String getNickName() {
  return this.getString("nickName");
    }
}
```

不需要添加 @AVClassname 注解，所有 AVUser 的子类的类名都是内建的 `_User`。同样也不需要注册 MyUser。

当用户子类化 AVUser 后，如果希望以后查询 AVUser 所得到的对象会自动转化为用户子类化的对象，则需要在调用 AVOSCloud.initialize() 之前添加：

```java
AVUser.alwaysUseSubUserClass(subUser.class);
```

注册跟普通的 AVUser 对象没有什么不同，但是登录如果希望返回自定义的子类，必须这样：

```java
MyUser cloudUser = AVUser.logIn(username, password,
    MyUser.class);
```

<div class="callout callout-info">由于 fastjson 内部的 bug，请在定义 AVUser 时<u>不要定义</u>跟 AVRelation 相关的 `get` 方法。如果一定要定义的话，请通过在 Class 上添加 `@JSONType(ignores = {"属性名"})` 的方式，将其注释为非序列化字段。</div>



## 应用内搜索
应用内搜索是一个针对应用数据进行全局搜索的接口，它基于搜索引擎构建，提供更强大的搜索功能。要深入了解其用法和阅读示例代码，请阅读 
（**Java 暂不支持**）
。



## 应用内社交
应用内社交，又称「事件流」，在应用开发中出现的场景非常多，包括用户间关注（好友）、朋友圈（时间线）、状态、互动（点赞）、私信等常用功能，请参考 
（**Java 暂不支持**）
。



## 第三方账户登录
社交账号的登录方便了应用开发者在提升用户体验，我们特地开发了一套支持第三方账号登录的组件，请参考 。




## 用户反馈
用户反馈是一个非常轻量的模块，可以用最少两行的代码来实现一个支持文字和图片的用户反馈系统，并且能够方便的在我们的移动 App 中查看用户的反馈，请参考 。





