





#  PHP 数据存储开发指南

数据存储（LeanStorage）是 LeanCloud 提供的核心功能之一，它的使用方法与传统的关系型数据库有诸多不同。下面我们将其与传统数据库的使用方法进行对比，让大家有一个初步了解。

下面这条 SQL 语句在绝大数的关系型数据库都可以执行，其结果是在 Todo 表里增加一条新数据：

```sql
  INSERT INTO Todo (title, content) VALUES ('工程师周会', '每周工程师会议，周一下午2点')
```

使用传统的关系型数据库作为应用的数据源几乎无法避免以下步骤：

- 插入数据之前一定要先创建一个表结构，并且随着之后需求的变化，开发者需要不停地修改数据库的表结构，维护表数据。
- 每次插入数据的时候，客户端都需要连接数据库来执行数据的增删改查（CRUD）操作。

使用 LeanStorage，实现代码如下：



```php
use LeanCloud\Object;

$todo = new Object("Todo");
$todo->set("title", "工程师周会");
$todo->set("content", "每周工程师会议，周一下午2点");
try {
    $todo->save();
    // 存储成功
} catch (CloudException $ex) {
    // 失败的话，请检查网络环境以及 SDK 配置是否正确
}
```


使用 LeanStorage 的特点在于：

- 不需要单独维护表结构。例如，为上面的 Todo 表新增一个 `location` 字段，用来表示日程安排的地点，那么刚才的代码只需做如下变动：

  

```php
$todo = new Object("Todo");
$todo->set("title", "工程师周会");
$todo->set("content", "每周工程师会议，周一下午2点");
$todo->set("location", "会议室"); // 只要添加这一行代码，服务端就会自动添加这个字段
try {
    $todo->save();
    // 存储成功
} catch (CloudException $ex) {
    // 失败的话，请检查网络环境以及 SDK 配置是否正确
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


请阅读 [PHP 安装指南](sdk_setup-php.html)。






## 对象

`Object` 是 LeanStorage 对复杂对象的封装，每个 `Object` 包含若干属性值对，也称键值对（key-value）。属性的值是与 JSON 格式兼容的数据。通过 REST API 保存对象需要将对象的数据通过 JSON 来编码。这个数据是无模式化的（Schema Free），这意味着你不需要提前标注每个对象上有哪些 key，你只需要随意设置 key-value 对就可以，云端会保存它。

### 数据类型
`Object` 支持以下数据类型：


```php
$bool       = true;
$number     = 2015;
$string     = $number . " 年度音乐排行";
$date       = new \DateTime();
$bytesArray = Bytes::createFromBase64Data(base64_encode("Hello world!"));

$testObject = new Object("DataTypes");

$testObject->set("testBoolean", $bool);
$testObject->set("testInteger", $number);
$testObject->set("testString", $string);
$testObject->set("testData", $bytesArray);
$testObject->set("testDate", $date);
$testObject->set("testArray", array($string, $number));
$testObject->set("testAssociativeArray",
                 array("number" => $number,
                       "string" => $string));
$testObject->save();
```

此外，Array 和 Associative Array 支持嵌套，这样在一个 `Object` 中就可以使用它们来储存更多的结构化数据。



我们**不推荐**在 `Object` 中使用 `Bytes` 来储存大块的二进制数据，比如图片或整个文件。**每个 `Object` 的大小都不应超过 128 KB**。如果需要储存更多的数据，建议使用 [`File`](#文件)。


若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。

### 构建对象
构建一个 `Object` 可以使用如下方式：


```php
// "Todo" 对应的就是控制台中的 Class Name
$todo = new Object("Todo");

// 或者
$todo = Object::create("Todo");
```


每个 objectId 必须有一个 Class 类名称，这样云端才知道它的数据归属于哪张数据表。

### 保存对象
现在我们保存一个 `TodoFolder`，它可以包含多个 Todo，类似于给行程按文件夹的方式分组。我们并不需要提前去后台创建这个名为 **TodoFolder** 的 Class 类，而仅需要执行如下代码，云端就会自动创建这个类：



```php
$todoFolder = new Object("TodoFolder"); // 构建对象
$todoFolder->set("name", "工作");           // 设置名称
$todoFolder->set("priority", 1);            // 设置优先级

try {
    $todoFolder->save();
    // 保存到服务端
} catch (CloudException $ex) {
    // 失败
}
```



创建完成后，打开 [控制台 > 存储](/data.html?appid={{appid}}#/)，点开 `TodoFolder` 类，就可以看到刚才添加的数据。除了 name、priority（优先级）之外，其他字段都是数据表的内置属性。


内置属性|类型|描述
---|---|---
`objectId`|String|该对象唯一的 Id 标识
`ACL`|ACL|该对象的权限控制，实际上是一个 JSON 对象，控制台做了展现优化。
`createdAt`|DateTime|该对象被创建的 UTC 时间，控制台做了针对当地时间的展现优化。
`updatedAt` |DateTime|该对象最后一次被修改的时间

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



```php
// 执行 CQL 语句实现新增一个 TodoFolder 对象
try {
    $result = Query::doCloudQuery("INSERT INTO TodoFolder(name, priority) values('工作', 1)");
    // 保存成功
} catch (CloudException $ex) {
    // 保存失败
}
```





### 获取对象
每个被成功保存在云端的对象会有一个唯一的 Id 标识 `objectId`，因此获取对象的最基本的方法就是根据 `objectId` 来查询：



```php
$query = new Query("Todo");
$todo  = $query->get("558e20cbe4b060308e3eb36c");
// $todo 就是 ID 为 558e20cbe4b060308e3eb36c 的对象实例
```


如果不想使用查询，还可以通过从本地构建一个 `objectId`，然后调用接口从云端把这个 `objectId` 的数据拉取到本地，示例代码如下：


```php
// 假如已知了 objectId 可以用如下的方式构建一个 Object
$todo = Object::create("Todo", "5656e37660b2febec4b35ed7");
// 然后调用刷新的方法，将数据提取到对象
$todo->fetch();
```


#### 获取 objectId
每一次对象存储成功之后，云端都会返回 `objectId`，它是一个全局唯一的属性。



```php
$todo = new Object("Todo");
$todo->set("title", "工程师周会");
$todo->set("content", "每周工程师会议，周一下午2点");
$todo->set("location", "会议室"); // 只要添加这一行代码，服务端就会自动添加这个字段
try {
    $todo->save();
    // 保存成功之后，objectId 会自动加载到对象
    $todo->getObjectId();
} catch (CloudException $ex) {
    // 失败的话，请检查网络环境以及 SDK 配置是否正确
}
```



#### 访问对象的属性
访问 Todo 的属性的方式为：



```php
$query = new Query("Todo");
$todo  = $query->get("558e20cbe4b060308e3eb36c");
// $todo 就是 ID 为 558e20cbe4b060308e3eb36c 的对象实例

$todo->get("location");
$todo->get("title");
$todo->get("content");

// 获取三个特殊属性
$todo->getObjectId();
$todo->getUpdatedAt();
$todo->getCreatedAt();

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

假如 `objectId` 已知，则可以通过如下接口从本地构建一个 `Object` 来更新这个对象：



```php
// 参数依次为 className、objectId
$todo = Object::create("Todo", "558e20cbe4b060308e3eb36c");

// 修改 content
$todo->set("content","每周工程师会议，本周改为周三下午3点半。");
// 保存到云端
$todo->save();
```



更新操作是覆盖式的，云端会根据最后一次提交到服务器的有效请求来更新数据。更新是字段级别的操作，未更新的字段不会产生变动，这一点请不用担心。

#### 使用 CQL 语法更新对象
LeanStorage 提供了类似 SQL 语法中的 Update 方式更新一个对象，例如更新一个 TodoFolder 对象可以使用下面的代码：



```php
// 执行 CQL 语句实现更新一个 TodoFolder 对象
Query::doCloudquery("update TodoFolder set name='家庭' where objectId='558e20cbe4b060308e3eb36c'");
```


#### 更新计数器

这是原子操作（Atomic Operation）的一种。
为了存储一个整型的数据，LeanStorage 提供对任何数字字段进行原子增加（或者减少）的功能。比如一条微博，我们需要记录有多少人喜欢或者转发了它，但可能很多次喜欢都是同时发生的。如果在每个客户端都直接把它们读到的计数值增加之后再写回去，那么极容易引发冲突和覆盖，导致最终结果不准。此时就需要使用这类原子操作来实现计数器。

假如，现在增加一个记录查看 Todo 次数的功能，一些与他人共享的 Todo 如果不用原子操作的接口，很有可能会造成统计数据不准确，可以使用如下代码实现这个需求：



```php
$theTodo = Object::create("Todo", "564d7031e4b057f4f3006ad1");
$theTodo->set("views", 0); //初始值为 0

$theTodo->increment("views", 5); // 原子增加查看的次数
$theTodo->save();

$theTodo->increment("views"); // 默认加 1
$theTodo->save();
```




#### 更新数组

这也是原子操作的一种。使用以下方法可以方便地维护数组类型的数据：



* `addIn()`<br>
  将指定对象附加到数组末尾。
* `addUniqueIn()`<br>
  如果不确定某个对象是否已包含在数组字段中，可以使用此操作来添加。
* `removeIn()`<br>
  从数组字段中删除指定对象的所有实例。



例如，Todo 对象有一个提醒日期 reminders，它是一个数组，代表这个日程会在哪些时间点提醒用户。比如有些拖延症患者会把闹钟设为早上的 7:10、7:20、7:30：



```php
$reminder1 = new \DateTime("2015-11-11 07:10:00");
$reminder2 = new \DateTime("2015-11-11 07:20:00");
$reminder3 = new \DateTime("2015-11-11 07:30:00");

$todo = new Object("Todo");
$todo->addUniqueIn("reminders", $reminder1);
$todo->addUniqueIn("reminders", $reminder2);
$todo->addUniqueIn("reminders", $reminder3);
```





### 删除对象

假如某一个 Todo 完成了，用户想要删除这个 Todo 对象，可以如下操作：



```php
$todo->destroy();
```



<div class="callout callout-danger">删除对象是一个较为敏感的操作。在控制台创建对象的时候，默认开启了权限保护，关于这部分的内容请阅读《（PHP 文档待补充）》。</div>

#### 使用 CQL 语法删除对象
LeanStorage 提供了类似 SQL 语法中的 Delete 方式删除一个对象，例如删除一个 Todo 对象可以使用下面的代码：


```php
Query::doCloudQuery("delete from Todo where objectId='558e20cbe4b060308e3eb36c'");
```







### 批量操作

为了减少网络交互的次数太多带来的时间浪费，你可以在一个请求中对多个对象进行创建、更新、删除、获取。接口都在 `Object` 这个类下面：



```php
// 批量创建、更新
Object::saveAll()

// 批量删除
Object::destroyAll()

// 批量获取
Object::fetchAll()
```


批量设置 Todo 已经完成：



```php
$query = new Query("Todo");
$todos = $query->find();

forEach ($todos as $todo) {
    $todo->set("status", 1);
}
try {
    Object::saveAll($todos);
    // 保存成功
} catch (CloudException $ex) {
    // 保存失败
}
```



不同类型的批量操作所引发不同数量的 API 调用，具体请参考 [API 调用次数的计算](faq.html#API_调用次数的计算)。





### 关联数据

#### `Relation`
对象可以与其他对象相联系。如前面所述，我们可以把一个 `Object` 的实例 A，当成另一个 `Object` 实例 B 的属性值保存起来。这可以解决数据之间一对一或者一对多的关系映射，就像关系型数据库中的主外键关系一样。

例如，一个 TodoFolder 包含多个 Todo ，可以用如下代码实现：



```php
$todoFolder = new Object("TodoFolder"); // 构建对象
$todoFolder->set("name", "工作");
$todoFolder->set("priority", 1);

$todo1 = new Object("Todo");
$todo1->set("title", "工程师周会");
$todo1->set("content", "每周工程师会议，周一下午2点");
$todo1->set("location", "会议室");

$todo2 = new Object("Todo");
$todo2->set("title", "维护文档");
$todo2->set("content", "每天 16：00 到 18：00 定期维护文档");
$todo2->set("location", "当前工位");

$todo3 = new Object("Todo");
$todo3->set("title", "发布 SDK");
$todo3->set("content", "每周一下午 15：00");
$todo3->set("location", "SA 工位");

$relation = $todoFolder->getRelation("containedTodos"); // 新建一个 Relation
$relation->add($todo1);
$relation->add($todo2);
$relation->add($todo3);
// 上述 3 行代码表示 relation 关联了 3 个 Todo 对象

$todoFolder->save();
```


#### Pointer
Pointer 只是个描述并没有具象的类与之对应，它与 `Relation` 不一样的地方在于：`Relation` 是在**一对多**的「一」这一方（上述代码中的一指 TodoFolder）保存一个 `Relation` 属性，这个属性实际上保存的是对被关联数据**多**的这一方（上述代码中这个多指 Todo）的一个 Pointer 的集合。而反过来，LeanStorage 也支持在「多」的这一方保存一个指向「一」的这一方的 Pointer，这样也可以实现**一对多**的关系。

简单的说， Pointer 就是一个外键的指针，只是在 LeanCloud 控制台做了显示优化。

现在有一个新的需求：用户可以分享自己的 TodoFolder 到广场上，而其他用户看见可以给与评论，比如某玩家分享了自己想买的游戏列表（TodoFolder 包含多个游戏名字），而我们用 Comment 对象来保存其他用户的评论以及是否点赞等相关信息，代码如下：



```php
$comment = new Object("Comment"); // 构建 Comment 对象
$comment->set("like", 1); // 如果点了赞就是 1，而点了不喜欢则为 -1，没有做任何操作就是默认的 0
$comment->set("content", "这个太赞了！楼主，我也要这些游戏，咱们团购么？"); // 留言的内容

// 假设已知了被分享的该 TodoFolder 的 objectId 是 5590cdfde4b00f7adb5860c8
$comment->set("targetTodoFolder", Object::create("TodoFolder", "5590cdfde4b00f7adb5860c8"));
// 以上代码的执行结果就会在 comment 对象上有一个名为 targetTodoFolder 属性，它是一个 Pointer 类型，指向 objectId 为 5590cdfde4b00f7adb5860c8 的 TodoFolder
```



相关内容可参考 [关联数据查询](#Relation_查询)。

#### 地理位置
地理位置是一个特殊的数据类型，LeanStorage 封装了 `GeoPoint` 来实现存储以及相关的查询。

首先要创建一个 `GeoPoint` 对象。例如，创建一个北纬 39.9 度、东经 116.4 度的 `GeoPoint` 对象（LeanCloud 北京办公室所在地）：



```php
$geopoint = new GeoPoint(39.9, 116.4);
```


假如，添加一条 Todo 的时候为该 Todo 添加一个地理位置信息，以表示创建时所在的位置：



```php
$todo->set("whereCreated", $point);
```


同时请参考 [地理位置查询](#地理位置查询)。



### 序列化和反序列化
在实际的开发中，把 `Object` 当做参数传递的时候，会涉及到复杂对象的拷贝的问题，因此 `Object` 也提供了序列化和反序列化的方法：

序列化：


```php
// PHP 暂不支持
```


反序列化：


```php
// PHP 暂不支持
```











## 文件
文件存储也是数据存储的一种方式，图像、音频、视频、通用文件等等都是数据的载体，另外很多开发者习惯了把复杂对象序列化之后保存成文件（如 `.json` 或者 `.xml` )。文件存储在 LeanStorage 中被单独封装成一个 `File` 来实现文件的上传、下载等操作。

### 文件上传
文件的上传指的是开发者调用接口将文件存储在云端，并且返回文件最终的 URL 的操作。


#### 从数据流构建文件
`File` 支持图片、视频、音乐等常见的文件类型，以及其他任何二进制数据，在构建的时候，传入对应的数据流即可：



```php
$file = File::createWithData("resume.txt", "Working with LeanCloud is great!", "text/plain");
```



上例将文件命名为 `resume.txt`，这里需要注意两点：

- 不必担心文件名冲突。每一个上传的文件都有惟一的 ID，所以即使上传多个文件名为 `resume.txt` 的文件也不会有问题。
- 给文件添加扩展名非常重要。云端通过扩展名来判断文件类型，以便正确处理文件。所以要将一张 PNG 图片存到 `File` 中，要确保使用 `.png` 扩展名。



#### 从本地路径构建文件
大多数的客户端应用程序都会跟本地文件系统产生交互，常用的操作就是读取本地文件，如下代码可以实现使用本地文件路径构建一个 `File`：



```php
// 文件类型如果不提供，会按照结尾符自动识别
$file = File::createWithLocalFile("/tmp/LeanCloud.png");
```






#### 从网络路径构建文件
从一个已知的 URL 构建文件也是很多应用的需求。例如，从网页上拷贝了一个图像的链接，代码如下：



```php
$file = File::createWithUrl("test.gif", "http://ww3.sinaimg.cn/bmiddle/596b0666gw1ed70eavm5tg20bq06m7wi.gif");
```




我们需要做出说明的是，[从本地路径构建文件](#从本地路径构建文件) 会<u>产生实际上传的流量</u>，并且文件最后是存在云端，而 [从网络路径构建文件](#从网络路径构建文件) 的文件实体并不存储在云端，只是会把文件的物理地址作为一个字符串保存在云端。

#### 执行上传
上传的操作调用方法如下：



```php
$file->save();
$file->getUrl(); // 返回一个唯一的 Url 地址
```




#### 上传进度监听
一般来说，上传文件都会有一个上传进度条显示用以提高用户体验：



```php
// PHP 不支持
```





### 文件下载
客户端 SDK 接口可以下载文件并把它缓存起来，只要文件的 URL 不变，那么一次下载成功之后，就不会再重复下载，目的是为了减少客户端的流量。



```php 
// PHP 不支持
```


请注意代码中**下载进度**数据的读取。



### 图像缩略图

保存图像时，如果想在下载原图之前先得到缩略图，方法如下：



```php
$file = File::createWithUrl("test.jpg", "文件-url");
$file->getThumbnailUrl(100, 100);
```



<div class="callout callout-info">注意：<strong>图片最大不超过 20 M 才可以获取缩略图。</strong> </div>

### 文件元数据

`File` 的 `metaData` 属性，可以用来保存和获取该文件对象的元数据信息：


```php
$file = File::createWithLocalFile("/tmp/xxx.jpg");
$file->setMeta("width", 100);
$file->setMeta("height", 100);
$file->setMeta("author", "LeanCloud");
$file->save();
```




### 删除

当文件较多时，要把一些不需要的文件从云端删除：



```php
$file->destroy();
```







<div class="callout callout-info">注意：默认情况下，文件的删除权限是关闭的，需要进入控制台，在 [`_File` > 其他 > 权限设置 > delete](/data.html?appid={{appid}}#/_File)  中开启。</div>


## 查询
`Query` 是构建针对 `Object` 查询的基础类。


### 创建查询实例


```php
$query = new Query("Todo");
```



### 根据 id 查询
在 [获取对象](#获取对象) 中我们介绍过如何通过 objectId 来获取对象实例，从而简单的介绍了一下 `Query` 的用法，代码请参考对应的内容，不再赘述。

### 条件查询
在大多数情况下做列表展现的时候，都是根据不同条件来分类展现的，比如，我要查询所有优先级为 0 的 Todo，也就是做列表展现的时候，要展示优先级最高，最迫切需要完成的日程列表，此时基于 priority 构建一个查询就可以查询出符合需求的对象：



```php
$query = new Query("Todo");
$query->equalTo("priority", 0);
$todos = $query->find();
```


其实，拥有传统关系型数据库开发经验的开发者完全可以翻译成如下的 SQL：

```sql
  select * from Todo where priority = 0
```
LeanStorage 也支持使用这种传统的 SQL 语句查询。具体使用方法请移步至 [Cloud Query Language（CQL）查询](#CQL_查询)。

查询默认最多返回 100 条符合条件的结果，要更改这一数值，请参考 [限定结果返回数量](#限定返回数量)。

当多个查询条件并存时，它们之间默认为 AND 关系，即查询只返回满足了全部条件的结果。建立 OR 关系则需要使用 [组合查询](#组合查询)。

注意：在简单查询中，如果对一个对象的同一属性设置多个条件，那么先前的条件会被覆盖，查询只返回满足最后一个条件的结果。例如，我们要找出优先级为 0 和 1 的所有 Todo，错误写法是：



```php
$query = new Query("Todo");
$query->equalTo("priority", 0);
$query->equalTo("priority", 1);
// 如果这样写，第二个条件将覆盖第一个条件，查询只会返回 priority = 1 的结果
$todos = $query->find();
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



```php
$query->lessThan("priority", 2);
```


要查询优先级大于等于 2 的 Todo：



```php
$query->greaterThanOrEqualTo("priority", 2);
```


比较查询**只适用于可比较大小的数据类型**，如整型、浮点等。

#### 正则匹配查询

正则匹配查询是指在查询条件中使用正则表达式来匹配数据，查询指定的 key 对应的 value 符合正则表达式的所有对象。
例如，要查询标题包含中文的 Todo 对象可以使用如下代码：



```php
$query = new Query("Todo");
$query->matches("title","[\\u4e00-\\u9fa5]");
```


正则匹配查询**只适用于**字符串类型的数据。

#### 包含查询

包含查询类似于传统 SQL 语句里面的 `LIKE %keyword%` 的查询，比如查询标题包含「李总」的 Todo：



```php
$query = new Query("Todo");
$query->contains("title","李总");
```


翻译成 SQL 语句就是：

```sql
  select * from Todo where title LIKE '%李总%'
```
不包含查询与包含查询是对立的，不包含指定关键字的查询，可以使用 [正则匹配方法](#正则匹配查询) 来实现。例如，查询标题不包含「机票」的 Todo，正则表达式为 `^((?!机票).)*$`：



```php
$query = new Query("Todo");
$query->matches("title","^((?!机票).)*$");
```


但是基于正则的模糊查询有两个缺点：

- 当数据量逐步增大后，查询效率将越来越低。
- 没有文本相关性排序

因此，你还可以考虑使用 [应用内搜索](#应用内搜索) 功能。它基于搜索引擎技术构建，提供更强大的搜索功能。

还有一个接口可以精确匹配不等于，比如查询标题不等于「出差、休假」的 Todo 对象：



```php
$query = new Query("Todo");
$query->notContainedIn("title",array("出差", "休假"));
$query->find();
```


#### 数组查询

当一个对象有一个属性是数组的时候，针对数组的元数据查询可以有多种方式。例如，在 [数组](#更新数组) 一节中我们为 Todo 设置了 reminders 属性，它就是一个日期数组，现在我们需要查询所有在 8:30 会响起闹钟的 Todo 对象：



```php
$query = new Query("Todo");
$date = new \DateTime("2015-11-11 08:30:00");
// equalTo: 可以找出数组中包含单个值的对象
$query->equalTo("reminders", $date);
$query->find();

```


如果你要查询包含 8:30、9:30 这两个时间点响起闹钟的 Todo，可以使用如下代码：



```php
$query = new Query("Todo");
$date1 = new \DateTime("2015-11-11 08:30:00");
$date2 = new \DateTime("2015-11-11 09:30:00");
$query->containsAll("reminders", array($date1, $date2));
$query->find();
```


注意这里是包含关系，假如有一个 Todo 会在 8:30、9:30、10:30 响起闹钟，它仍然是会被查询出来的。

#### 字符串查询
使用 `startsWith()` 可以过滤出以特定字符串开头的结果，这有点像 SQL 的 LIKE 条件。因为支持索引，所以该操作对于大数据集也很高效。



```php
// 找出开头是「早餐」的 Todo
$query = new Query("Todo");
$query->startsWith("content", "早餐");
```


#### 空值查询
假设我们的 Todo 允许用户上传图片用来帮助用户记录某些特殊的事项，但是有时候用户可能就记得自己给一个 Todo 附加过图片，但是具体又不记得这个 Todo 的关键字是什么，因此我们需要一个接口可以找出那些有图片的 Todo，此时就可以使用到空值查询的接口：



```php
// 存储一个带有图片的 Todo 到 LeanCloud 云端
$aTodoAttachmentImage = File::createWithUrl("test.jpg", "http://www.zgjm.org/uploads/allimg/150812/1_150812103912_1.jpg");
$todo = new Object("Todo");
$todo->set("images", $aTodoAttachmentImage);
$todo->set("content", "记得买过年回家的火车票！！！");
$todo->save();

// 使用非空值查询获取有图片的 Todo
$query = new Query("Todo");
$query->exists("images");
// 返回有图片的 Todo 集合
$query->find();

// 使用空值查询获取没有图片的 Todo
$query->notExists("images");
```


### 组合查询
组合查询就是把诸多查询条件合并成一个查询，再交给 SDK 去云端查询。方式有两种：OR 和 AND。

#### OR 查询
OR 操作表示多个查询条件符合其中任意一个即可。 例如，查询优先级是大于等于 3 或者已经完成了的 Todo：



```php
$priorityQuery = new Query("Todo");
$priorityQuery->greaterThanOrEqualTo("priority", 3);

$statusQuery = new Query("Todo");
$statusQuery->equalTo("status", 1);

$query = Query::orQuery($priorityQuery, $statusQuery);

// 返回 priority 大于等于3 或 status 等于 1 的 Todo
$query->find();
```


**注意：OR 查询中，子查询中不能包含地理位置相关的查询。**

#### AND 查询
AND 操作是指只有满足了所有查询条件的对象才会被返回给客户端。例如，查询优先级小于 1 并且尚未完成的 Todo：



```php
$priorityQuery = new Query("Todo");
$priorityQuery->lessThan("priority", 3);

$statusQuery = new Query("Todo");
$statusQuery->equalTo("status", 0);

$query = Query::andQuery($priorityQuery, $statusQuery);

// 返回 priority 小于 3 并且 status 等于 0 的 Todo
$query->find();
```


可以对新创建的 `Query` 添加额外的约束，多个约束将以 AND 运算符来联接。

### 查询结果

#### 获取第一条结果
例如很多应用场景下，只要获取满足条件的一个结果即可，例如获取满足条件的第一条 Todo：



```php
$query = new Query("Todo");
$query->equalTo("priority",0);
// 返回符合条件的第一个对象
$query->first();
```


#### 限定返回数量
为了防止查询出来的结果过大，云端默认针对查询结果有一个数量限制，即 `limit`，它的默认值是 100。比如一个查询会得到 10000 个对象，那么一次查询只会返回符合条件的 100 个结果。`limit` 允许取值范围是 1 ~ 1000。例如设置返回 10 条结果：



```php
$query = new Query("Todo");
$query->lessThanOrEqualTo("createdAt", new \DateTime());
$query->limit(10); // 最多返回 10 条结果
```


#### 跳过数量
设置 skip 这个参数可以告知云端本次查询要跳过多少个结果。将 skip 与 limit 搭配使用可以实现翻页效果，这在客户端做列表展现时，尤其在数据量庞大的情况下就使用技术。例如，在翻页中，一页显示的数量是 10 个，要获取第 3 页的对象：



```php
$query = new Query("Todo");
$query->lessThanOrEqualTo("createdAt", new \DateTime());
$query->limit(10); // 最多返回 10 条结果
$query->skip(20);  // 跳过 20 条结果
```



尽管我们提供以上接口，但是我们不建议广泛使用，因为它的执行效率比较低。取而代之，我们建议使用 `createdAt` 或者 `updatedAt` 这类的时间戳进行分段查询。

#### 属性限定
通常列表展现的时候并不是需要展现某一个对象的所有属性，例如，Todo 这个对象列表展现的时候，我们一般展现的是 title 以及 content，我们在设置查询的时候，也可以告知云端需要返回的属性有哪些，这样既满足需求又节省了流量，也可以提高一部分的性能，代码如下：



```php
$query = new Query("Todo");
$query.select("title", "content");
$todos = $query->find();
forEach($todos as $todo) {
    $title   = $todo->get("title");
    $content = $todo->get("content");
    // 访问其它字段会返回 null
    $null = $todo->get("location");
}
```


#### 统计总数量
通常用户在执行完搜索后，结果页面总会显示出诸如「搜索到符合条件的结果有 1020 条」这样的信息。例如，查询一下今天一共完成了多少条 Todo：



```php
$query = new Query("Todo");
$query->equalTo("status", 0);
$query->count();
```



#### 排序

对于数字、字符串、日期类型的数据，可对其进行升序或降序排列。


```php
// 按时间，升序排列
$query->ascend("createdAt");

// 按时间，降序排列
$query->descend("createdAt");
```


一个查询可以附加多个排序条件，如按 priority 升序、createdAt 降序排列：



```php
$query->addAscend("priority");
$query->addDescend("createdAt");
```


<!-- #### 限定返回字段 -->

### 关系查询
关联数据查询也可以通俗地理解为关系查询，关系查询在传统型数据库的使用中是很常见的需求，因此我们也提供了相关的接口来满足开发者针对关联数据的查询。

首先，我们需要明确关系的存储方式，再来确定对应的查询方式。

#### Pointer 查询
基于在 [Pointer](#Pointer) 小节介绍的存储方式：每一个 Comment 都会有一个 TodoFolder 与之对应，用以表示 Comment 属于哪个 TodoFolder。现在我已知一个 TodoFolder，想查询所有的 Comnent 对象，可以使用如下代码：



```php
$query = new Query("Comment");
$query->equalTo("targetTodoFolder", Object::create("TodoFolder", "5590cdfde4b00f7adb5860c8"));
```


#### `Relation` 查询
假如用户可以给 TodoFolder 增加一个 Tag 选项，用以表示它的标签，而为了以后拓展 Tag 的属性，就新建了一个 Tag 对象，如下代码是创建 Tag 对象：



```php
$tag = new Object("Tag"); // 构建对象
$tag->set("name", "今日必做"); // 设置名称
$tag->save();
```


而 Tag 的意义在于一个 TodoFolder 可以拥有多个 Tag，比如「家庭」（TodoFolder） 拥有的 Tag 可以是：今日必做，老婆吩咐，十分重要。实现创建「家庭」这个 TodoFolder 的代码如下：



```php
$tag1 = new Object("Tag"); // 构建对象
$tag1->set("name", "今日必做"); // 设置 Tag 名称

$tag2 = new Object("Tag"); // 构建对象
$tag2->set("name", "老婆吩咐"); // 设置 Tag 名称

$tag3 = new Object("Tag"); // 构建对象
$tag3->set("name", "十分重要"); // 设置 Tag 名称

$todoFolder = new Object("TodoFolder"); // 构建对象
$todoFolder->set("name", "家庭"); // 设置 Todo 名称
$todoFolder->set("priority", 1); // 设置优先级

$relation = $todoFolder->getRelation("tags");
$relation->add($tag1);
$relation->add($tag2);
$relation->add($tag3);

$todoFolder->save(); // 保存到云端
```


查询一个 TodoFolder 的所有 Tag 的方式如下：



```php
$todoFolder = Object::create("TodoFolder", "5661047dddb299ad5f460166");
$relation   = $todoFolder->getRelation("tags");
$query      = $relation->getQuery();
// 结果将包含当前 todoFolder 的所有 Tag 对象
$query->find();
```


反过来，现在已知一个 Tag，要查询有多少个 TodoFolder 是拥有这个 Tag 的，可以使用如下代码查询：



```php
$tag = Object::create("Tag", "5661031a60b204d55d3b7b89");
$query = new Query("TodoFolder");
$query->equalTo("tags", $tag);
// 结果是所有包含当前 tag 的 TodoFolder 对象
$query->find();
```


关于关联数据的建模是一个复杂的过程，很多开发者因为在存储方式上的选择失误导致最后构建查询的时候难以下手，不但客户端代码冗余复杂，而且查询效率低，为了解决这个问题，我们专门针对关联数据的建模推出了一个详细的文档予以介绍，详情请阅读 (**PHP 文档待补充**)。

#### 关联属性查询
正如在 [Pointer](#Pointer) 中保存 Comment 的 targetTodoFolder 属性一样，假如查询到了一些 Comment 对象，想要一并查询出每一条 Comment 对应的 TodoFolder 对象的时候，可以加上 include 关键字查询条件。同理，假如 TodoFolder 表里还有 pointer 型字段 targetAVUser 时，再加上一个递进的查询条件，形如 include(b.c)，即可一并查询出每一条 TodoFolder 对应的 AVUser 对象。代码如下：



```php
$commentQuery = new Query("Comment");
$commentQuery->descend("createdAt");
$commentQuery->limit(10);
$commentQuery->_include("targetTodoFolder"); // 关键代码，用 _include 告知服务端需要返回的关联属性对应的对象的详细信息，而不仅仅是 objectId
$commentQuery->_include("targetTodoFolder.targetAVUser");// 关键代码，同上，会返回 targetAVUser 对应的对象的详细信息，而不仅仅是 objectId
$comments = $commentQuery->find();
// 最近的十条评论, 其 targetTodoFolder 字段也有相应数据
forEach($comments as $comment) {
    $folder = $comment->get("targetTodoFolder");
    $user = $folder->get("targetAVUser");
}
```


#### 内嵌查询
假如现在有一个需求是展现点赞超过 20 次的 TodoFolder 的评论（Comment）查询出来，注意这个查询是针对评论（Comment），要实现一次查询就满足需求可以使用内嵌查询的接口：



```php
// 构建内嵌查询
$innerQuery = new Query("TodoFolder");
$innerQuery->greaterThan("likes", 20);
// 将内嵌查询赋予目标查询
$query = new Query("Comment");
// 执行内嵌操作
$query->matchesInQuery("targetTodoFolder", $innerQuery);
// 返回符合 TodoFolder 超过 20 个赞这一条件的 Comment 对象集合
$comments = $query->find();

// 注意如果要做相反的查询可以使用
$query->notMatchInQuery("targetTodoFolder", $innerQuery);
// 如此做将查询出 likes 小于或者等于 20 的 TodoFolder 的 Comment 对象
$comments = $query->find();
```


### CQL 查询
Cloud Query Language（CQL）是 LeanStorage 独创的使用类似 SQL 语法来实现云端查询功能的语言，具有 SQL 开发经验的开发者可以方便地使用此接口实现查询。

分别找出 status = 1 的全部 Todo 结果，以及 priority = 0 的 Todo 的总数：



```php

$todos = Query::doCloudQuery("select * from Todo where status = 1");

$result = Query::doCloudQuery("select count(*) from Todo where priority = 0");
$result["count"];
```


通常查询语句会使用变量参数，为此我们提供了与 Java JDBC 所使用的 PreparedStatement 占位符查询相类似的语法结构。

查询 status = 0、priority = 1 的 Todo：



```php
$todos = Query::doCloudQuery("select * from Todo where status = ? and priority = ?", array(0, 1));
```


目前 CQL 已经支持数据的更新 update、插入 insert、删除 delete 等 SQL 语法，更多内容请参考 [Cloud Query Language 详细指南](cql_guide.html)。



### 地理位置查询
地理位置查询是较为特殊的查询，一般来说，常用的业务场景是查询距离 xx 米之内的某个位置或者是某个建筑物，甚至是以手机为圆心，查找方圆多少范围内餐厅等等。LeanStorage 提供了一系列的方法来实现针对地理位置的查询。

#### 查询位置附近的对象
Todo 的 `whereCreated`（创建 Todo 时的位置）是一个 `GeoPoint` 对象，现在已知了一个地理位置，现在要查询 `whereCreated` 靠近这个位置的 Todo 对象可以使用如下代码：



```php
$query = new Query("Todo");
$point = new GeoPoint(39.9, 116.4);
$query->limit(10);
$query->near("whereCreated", $point);
// 离这个位置最近的 10 个 Todo 对象
$nearbyTodos = $query->find();
```

在上面的代码中，`nearbyTodos` 返回的是与 `point` 这一点按距离排序（由近到远）的对象数组。注意：**如果在此之后又使用了 `ascend` 或 `descend` 方法，则按距离排序会被新排序覆盖。**


#### 查询指定范围内的对象
要查找指定距离范围内的数据，可使用 `whereWithinKilometers` 、 `whereWithinMiles` 或 `whereWithinRadians` 方法。
例如，我要查询距离指定位置，2 千米范围内的 Todo：



```php
$query->withinKilometers("whereCreated", $point, 2.0);
```


#### 注意事项

使用地理位置需要注意以下方面：

* 每个 `Object` 数据对象中只能有一个 `GeoPoint` 对象的属性。
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

`User` 是用来描述一个用户的特殊对象，与之相关的数据都保存在 `_User` 数据表中。

### 用户的属性

#### 默认属性
用户名、密码、邮箱是默认提供的三个属性，访问方式如下：



```php
$currentUser = User::getCurrentUser();
$currentUser->getUsername();
$currentUser->getEmail();
// 请注意，以下代码无法获取密码

$currentUser->getPassword(); // 无 getPassword() 方法
```


请注意代码中，密码是仅仅是在注册的时候可以设置的属性（这部分代码可参照 [用户名和密码注册](#用户名和密码注册)），它在注册完成之后并不会保存在本地（SDK 不会以明文保存密码这种敏感数据），所以在登录之后，再访问密码这个字段是为**空的**。

#### 自定义属性
用户对象和普通对象一样也支持添加自定义属性。例如，为当前用户添加年龄属性：



```php
$currentUser = User::getCurrentUser();
$currentUser->set("age", 25);
$currentUser->save();
```


#### 属性的修改

很多开发者都有这样的疑问：为什么我不能修改任意一个用户的属性？原因如下。

> 很多时候，就算是开发者也不要轻易修改用户的基本信息，例如用户的手机号、社交账号等个人信息都比较敏感，应该由用户在 App 中自行修改。所以为了保证用户的数据仅在用户自己已登录的状态下才能修改，云端对所有针对 `User` 对象的数据操作都要做验证。

假如，刚才我们为当前用户添加了一个 age 属性，现在我们来修改它：



```php
$currentUser->set("age", 27);
$currentUser->save();
```


细心的开发者应该已经发现 `User` 在自定义属性上的使用与一般的 `Object` 没本质区别。

### 注册





#### 手机号码登录

一些应用为了提高首次使用的友好度，一般会允许用户浏览一些内容，直到用户发起了一些操作才会要求用户输入一个手机号，而云端会自动发送一条验证码的短信给用户的手机号，最后验证一下，完成一个用户注册并且登录的操作，例如很多团购类应用都有这种用户场景。

首先调用发送验证码的接口：



```php
User::requestLoginSmsCode("13577778888");
```


然后在 UI 上给与用户输入验证码的输入框，用户点击登录的时候调用如下接口：



```php
User::logInWithSmsCode("13577778888", "123456");
```


#### 用户名和密码注册

采用「用户名 + 密码」注册时需要注意：密码是以明文方式通过 HTTPS 加密传输给云端，云端会以密文存储密码，并且我们的加密算法是无法通过所谓「彩虹表撞库」获取的，这一点请开发者放心。换言之，用户的密码只可能用户本人知道，开发者不论是通过控制台还是 API 都是无法获取。另外我们需要强调<u>在客户端，应用切勿再次对密码加密，这会导致重置密码等功能失效</u>。

例如，注册一个用户的示例代码如下（用户名 `Tom` 密码 `cat!@#123`）：



```php
$user = new User();              // 新建 User 对象实例
$user->setUsername("Tom");           // 设置用户名
$user->setPassword("cat!@#123");     // 设置密码
$user->setEmail("tom@leancloud.cn"); // 设置邮箱
$user->signUp();
```




如果注册不成功，请检查一下返回的错误对象。最有可能的情况是用户名已经被另一个用户注册，错误代码 [202](error_code.html#_202)，即 `_User` 表中的 `username` 字段已存在相同的值，此时需要提示用户尝试不同的用户名来注册。同样，邮件 `email` 和手机号码 `mobilePhoneNumber` 字段也要求在各自的列中不能有重复值出现，否则会出现 [203](error_code.html#_203)、[214](error_code.html#_214) 错误。

开发者也可以要求用户使用 Email 做为用户名注册，即在用户提交信息后将 `_User` 表中的 `username` 和 `email` 字段都设为相同的值，这样做的好处是用户在忘记密码的情况下可以直接使用「[邮箱重置密码](#重置密码)」功能，无需再额外绑定电子邮件。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。



#### 设置手机号码

微信、陌陌等流行应用都会建议用户将账号和一个手机号绑定，这样方便进行身份认证以及日后的密码找回等安全模块的使用。我们也提供了一整套发送短信验证码以及验证手机号的流程，这部分流程以及代码演示请参考 （PHP 文档待补充）。

#### 验证邮箱

许多应用会通过验证邮箱来确认用户注册的真实性。如果在 [应用控制台 > 应用设置 > 应用选项](https://leancloud.cn/app.html?appid={{appid}}#/permission) 中勾选了 **用户注册时，发送验证邮件**，那么当一个 `AVUser` 在注册时设置了邮箱，云端就会向该邮箱自动发送一封包含了激活链接的验证邮件，用户打开该邮件并点击激活链接后便视为通过了验证。有些用户可能在注册之后并没有点击激活链接，而在未来某一个时间又有验证邮箱的需求，这时需要调用如下接口让云端重新发送验证邮件：



```php
User::requestEmailVerify("abc@xyz.com");
```


### 登录

我们提供了多种登录方式，以满足不同场景的应用。



#### 用户名和密码登录



```php
User::logIn("Tom", "cat!@#123");
```


#### 手机号和密码登录

请确保已详细阅读了 （PHP 文档待补充） 这一小节的内容，才可以顺利理解手机号匹配密码登录的流程以及适用范围。

用户的手机号只要经过了验证，就可以使用手机号密码登录的功能，否则登录会失败。



```php
User::logInWithMobilePhoneNumber("13577778888", "cat!@#123");
```


#### 手机号和验证码登录

中国电信、中国联通、中国移动，这三大运营商的官网均支持「手机号 + 密码」和「手机号 + 随机验证码」的登录方式，我们也提供了这些方式。

首先，调用发送登录验证码的接口：



```php
User::requestLoginSmsCode("13577778888");
```


然后在界面上引导用户输入收到的 6 位短信验证码：



```php
User::logInWithSmsCode("13577778888", "238825");
```



#### 当前用户

打开微博或者微信，它不会每次都要求用户都登录，这是因为它将用户数据缓存在了客户端。
同样，只要是调用了登录相关的接口，LeanCloud SDK 都会自动缓存登录用户的数据。
例如，判断当前用户是否为空，为空就跳转到登录页面让用户登录，如果不为空就跳转到首页：



```php
$currentUser = User::getCurrentUser();

if ($currentUser != null) {
    // 跳转到首页
} else {
    //缓存用户对象为空时，可打开用户注册界面…
}
```



如果不调用 [登出](#登出) 方法，当前用户的缓存将永久保存在客户端。


#### SessionToken

所有登录接口调用成功之后，云端会返回一个 SessionToken 给客户端，客户端在发送 HTTP 请求的时候，PHP SDK 会在 HTTP 请求的 Header 里面自动添加上当前用户的 SessionToken 作为这次请求发起者 `User` 的身份认证信息。

如果在控制台的 [应用选项](/app.html?appid={{appid}}#/permission) 中勾选了 **密码修改后，强制客户端重新登录**，那么当用户密码再次被修改后，已登录的用户对象就会失效，开发者需要使用更改后的密码重新调用登录接口，使 SessionToken 得到更新，否则后续操作会遇到 [403 (Forbidden)](error_code.html#_403) 的错误。

#### 账户锁定

输入错误的密码或验证码会导致用户登录失败。如果在 15 分钟内，同一个用户登录失败的次数大于 6 次，该用户账户即被云端暂时锁定，此时云端会返回错误码 `{"code":1,"error":"登录失败次数超过限制，请稍候再试，或者通过忘记密码重设密码。"}`，开发者可在客户端进行必要提示。

锁定将在最后一次错误登录的 15 分钟之后由云端自动解除，开发者无法通过 SDK 或 REST API 进行干预。在锁定期间，即使用户输入了正确的验证信息也不允许登录。这个限制在 SDK 和云引擎中都有效。

### 重置密码

#### 邮箱重置密码

我们都知道，应用一旦加入账户密码系统，那么肯定会有用户忘记密码的情况发生。对于这种情况，我们为用户提供了一种安全重置密码的方法。

重置密码的过程很简单，用户只需要输入注册的电子邮件地址即可：



```php
User::requestPasswordReset("myemail@example.com");
```


密码重置流程如下：

1. 用户输入注册的电子邮件，请求重置密码；
2. LeanStorage 向该邮箱发送一封包含重置密码的特殊链接的电子邮件；
3. 用户点击重置密码链接后，一个特殊的页面会打开，让他们输入新密码；
4. 用户的密码已被重置为新输入的密码。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。

#### 手机号码重置密码



与使用 [邮箱重置密码](#邮箱重置密码) 类似，「手机号码重置密码」使用下面的方法来获取短信验证码：



```php
User::requestPasswordResetBySmsCode("18612340000");
```


注意！用户需要先绑定手机号码，然后使用短信验证码来重置密码：



```php
User::resetPasswordBySmsCode("123456", "password");
```


#### 登出

用户登出系统时，SDK 会自动清理缓存信息。



```php
User->logOut(); // 退出当前用户
$currentUser = User::getCurrentUser(); // 现在的 currentUser 是 null 了
```



### 用户的查询
请注意，**新创建的应用的用户表 `_User` 默认关闭了查询权限**。你可以通过 Class 权限设置打开查询权限，请参考 [数据与安全 · Class 级别的权限](data_security.html#Class_级别的_ACL)。我们推荐开发者在 [云引擎](leanengine_overview.html) 中封装用户查询，只查询特定条件的用户，避免开放用户表的全部查询权限。

查询用户代码如下：


```php
$userQuery = new Query("_User");
```


### 浏览器中查看用户表

用户表是一个特殊的表，专门存储用户对象。在浏览器端，你会看到一个 `_User` 表。

## 角色
关于用户与角色的关系，我们有一个更为详尽的文档介绍这部分的内容，并且针对权限管理有深入的讲解，详情请点击 （PHP 文档待补充）。


## 子类化
LeanCloud 希望设计成能让人尽快上手并使用。你可以通过 `Object#get` 方法访问所有的数据。但是在很多现有成熟的代码中，子类化能带来更多优点，诸如简洁、可扩展性以及 IDE 提供的代码自动完成的支持等等。子类化不是必须的，你可以将下列代码转化：

```
$student = new Object("Student");
$student->set("name", "小明");
$student->save();
```

可改写成:

```
$student = new Student();
$student->set("name", "小明");
$student->save();
```

这样代码看起来是不是更简洁呢？

### 子类化 AVObject

要实现子类化，需要下面几个步骤：

1. 首先声明一个子类继承自 `Object`；
2. 子类中声明静态字段 `protected static $className`，对应云端的数据表名；
3. 建议不要重载构造函数 `__construct()`，如果一定需要构造，请确保其接受 2 个参数 `$className` 和 `$objectId`；
4. 将子类注册到 `Object`，如 `Student::registerClass();`。

下面是实现 `Student` 子类化的例子:

```php
// Student.php
use LeanCloud\Object;

class Student extends Object {
    protected static $className = "Student";
}
Student::registerClass();
```

### 访问器、修改器和方法

添加方法到 Object 的子类有助于封装类的逻辑。你可以将所有跟子类有关的逻辑放到一个地方，而不是分成多个类来分别处理商业逻辑和存储/转换逻辑。

你可以很容易地添加访问器和修改器到你的 Object 子类。像平常那样声明字段的`getter` 和 `setter` 方法，但是通过 Object 的 `get` 和 `set` 方法来实现它们。下面是这个例子为 `Student` 类创建了一个 `content` 的字段：

```php
// Student.php
use LeanCloud\Object;

class Student extends Object {
    protected static $className = "Student";

    public function setContent($value) {
        $this->set("content", $value);
        return $this; // 方便链式调用
    }

    public function getContent() {
        return $this->get("content");
    }
}
Student::registerClass();
```

现在你就可以使用 `$student->getContent()` 方法来访问 `content` 字段，
并通过 `$student->setContent("blah blah blah")` 来修改它。

各种数据类型的访问器和修改器都可以这样被定义，使用各种 `get()` 方法的
变种，例如 `getInt()`，`getFile()` 或者 `getMap()`。

如果你不仅需要一个简单的访问器，而是有更复杂的逻辑，你也可以实现自己的方法，例如：

```php
public function takeAccusation() {
  // 处理用户举报，当达到某个条数的时候，自动打上屏蔽标志
  $this->increment("accusation", 1);
  if ($this->getAccusation() > 50) {
    $this->setSpam(true);
  }
}
```

### 初始化子类

你可以使用你自定义的构造函数来创建你的子类对象。`Object` 已定义了默认的构造函数，如果需要重载构造函数，请注意其需要接收 2 个参数：`$className` 和 `$objectId`。这个构造函数将会被 SDK 使用来创建子类的对象。

要创建一个到现有对象的引用，可以使用 `Object::create("Student", "abc123")`:

```php
$student = Object::create("Student", "573a8459df0eea005e6b711c");
```

### 查询子类

你可以通过 `Object#getQuery()` 方法获取特定的子类的查询对象。下面的例子就查询了用户发表的所有微博列表：

```php
$query = $post->getQuery();
$query->equalTo("pubUser", User::getCurrentUser()->getUsername());
$query->find();
```



## 应用内搜索
应用内搜索是一个针对应用数据进行全局搜索的接口，它基于搜索引擎构建，提供更强大的搜索功能。要深入了解其用法和阅读示例代码，请阅读 （**PHP 不支持**）。



## 应用内社交
应用内社交，又称「事件流」，在应用开发中出现的场景非常多，包括用户间关注（好友）、朋友圈（时间线）、状态、互动（点赞）、私信等常用功能，请参考 （**PHP 不支持**）。



## 第三方账户登录
社交账号的登录方便了应用开发者在提升用户体验，我们特地开发了一套支持第三方账号登录的组件，请参考 （**PHP 文档待补充**）。




## 用户反馈
用户反馈是一个非常轻量的模块，可以用最少两行的代码来实现一个支持文字和图片的用户反馈系统，并且能够方便的在我们的移动 App 中查看用户的反馈，请参考 （**PHP 不支持**）。





