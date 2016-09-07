





#  JavaScript 数据存储开发指南

数据存储（LeanStorage）是 LeanCloud 提供的核心功能之一，它的使用方法与传统的关系型数据库有诸多不同。下面我们将其与传统数据库的使用方法进行对比，让大家有一个初步了解。

下面这条 SQL 语句在绝大数的关系型数据库都可以执行，其结果是在 Todo 表里增加一条新数据：

```sql
  INSERT INTO Todo (title, content) VALUES ('工程师周会', '每周工程师会议，周一下午2点')
```

使用传统的关系型数据库作为应用的数据源几乎无法避免以下步骤：

- 插入数据之前一定要先创建一个表结构，并且随着之后需求的变化，开发者需要不停地修改数据库的表结构，维护表数据。
- 每次插入数据的时候，客户端都需要连接数据库来执行数据的增删改查（CRUD）操作。

使用 LeanStorage，实现代码如下：



```js
  // 声明一个 Todo 类型
  var Todo = AV.Object.extend('Todo');
  // 新建一个 Todo 对象
  var todo = new Todo();
  todo.set('title', '工程师周会');
  todo.set('content', '每周工程师会议，周一下午2点');
  todo.save().then(function (todo) {
    // 成功保存之后，执行其他逻辑.
    console.log('New object created with objectId: ' + todo.id);
  }, function (error) {
    // 失败之后执行其他逻辑
    console.log('Failed to create new object, with error message: ' + error.message);
  });
```


使用 LeanStorage 的特点在于：

- 不需要单独维护表结构。例如，为上面的 Todo 表新增一个 `location` 字段，用来表示日程安排的地点，那么刚才的代码只需做如下变动：

  

```js
  var Todo = AV.Object.extend('Todo');
  var todo = new Todo();
  todo.set('title', '工程师周会');
  todo.set('content', '每周工程师会议，周一下午2点');
  // 只要添加这一行代码，服务端就会自动添加这个字段
  todo.set('location','会议室');
  todo.save().then(function (todo) {
    // 成功保存之后，执行其他逻辑.
  }, function (error) {
    // 失败之后执行其他逻辑
  });
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


请阅读 [JavaScript 安装指南](sdk_setup-js.html)。





## Web 安全

如果在前端使用 JavaScript SDK，当你打算正式发布的时候，请务必配置 **Web 安全域名**。配置方式为：进入 [控制台 / 设置 / 安全中心 / **Web 安全域名**](/app.html?appid={{appid}}#/security)。这样就可以防止其他人，通过外网其他地址盗用你的服务器资源。

具体安全相关内容可以仔细阅读文档 [数据和安全](data_security.html) 。


## 对象

`AV.Object` 是 LeanStorage 对复杂对象的封装，每个 `AV.Object` 包含若干属性值对，也称键值对（key-value）。属性的值是与 JSON 格式兼容的数据。通过 REST API 保存对象需要将对象的数据通过 JSON 来编码。这个数据是无模式化的（Schema Free），这意味着你不需要提前标注每个对象上有哪些 key，你只需要随意设置 key-value 对就可以，云端会保存它。

### 数据类型
`AV.Object` 支持以下数据类型：



```js
  // 该语句应该只声明一次
  var TestObject = AV.Object.extend('DataTypeTest');

  var number = 2014;
  var string = 'famous film name is ' + number;
  var date = new Date();
  var array = [string, number];
  var object = { number: number, string: string };

  var testObject = new TestObject();
  testObject.set('testNumber', number);
  testObject.set('testString', string);
  testObject.set('testDate', date);
  testObject.set('testArray', array);
  testObject.set('testObject', object);
  testObject.set('testNull', null);
  testObject.save().then(function(testObject) {
    // 成功
  }, function(error) {
    // 失败
  });
```

我们**不推荐**在 `AV.Object` 中储存大块的二进制数据，比如图片或整个文件。**每个 `AV.Object` 的大小都不应超过 128 KB**。如果需要储存更多的数据，建议使用 [`AV.File`](#文件)。




若想了解更多有关 LeanStorage 如何解析处理数据的信息，请查看专题文档《[数据与安全](./data_security.html)》。

### 构建对象
构建一个 `AV.Object` 可以使用如下方式：



```js
  // AV.Object.extend('className') 所需的参数 className 则表示对应的表名
  // 声明一个类型
  var Todo = AV.Object.extend('Todo');
```

**注意**：如果你的应用时不时出现 `Maximum call stack size exceeded` 异常，可能是因为在循环或回调中调用了 `AV.Object.extend`。有两种方法可以避免这种异常：

- 升级 SDK 到 v1.4.0 或以上版本
- 在循环或回调外声明 Class，确保不会对一个 Class 执行多次 `AV.Object.extend`

从 v1.4.0 开始，SDK 支持使用 ES6 中的 extends 语法来声明一个继承自 `AV.Object` 的类，上述的 Todo 声明也可以写作：

```js
class Todo extends AV.Object {}
// 需要向 SDK 注册这个 Class
AV.Object.register(Todo);
```


每个 id 必须有一个 Class 类名称，这样云端才知道它的数据归属于哪张数据表。

### 保存对象
现在我们保存一个 `TodoFolder`，它可以包含多个 Todo，类似于给行程按文件夹的方式分组。我们并不需要提前去后台创建这个名为 **TodoFolder** 的 Class 类，而仅需要执行如下代码，云端就会自动创建这个类：



```js
  // 声明类型
  var TodoFolder = AV.Object.extend('TodoFolder');
  // 新建对象
  var todoFolder = new TodoFolder();
  // 设置名称
  todoFolder.set('name','工作');
  // 设置优先级
  todoFolder.set('priority',1);
  todoFolder.save().then(function (todo) {
    console.log('objectId is ' + todo.id);
  }, function (error) {
    console.log(error);
  });
```



创建完成后，打开 [控制台 > 存储](/data.html?appid={{appid}}#/)，点开 `TodoFolder` 类，就可以看到刚才添加的数据。除了 name、priority（优先级）之外，其他字段都是数据表的内置属性。


内置属性|类型|描述
---|---|---
`id`|String|该对象唯一的 Id 标识
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



```js
  // 执行 CQL 语句实现新增一个 TodoFolder 对象
  AV.Query.doCloudQuery('insert into TodoFolder(name, priority) values("工作", 1)').then(function (data) {
    // data 中的 results 是本次查询返回的结果，AV.Object 实例列表
    var results = data.results;
  }, function (error) {
    //查询失败，查看 error
    console.log(error);
  });
```



#### 保存选项

`AV.Object` 对象在保存时可以设置选项来快捷完成关联操作，可用的选项属性有：

选项 | 类型 | 说明
--- | --- | ---
<code class="text-nowrap">fetchWhenSave</code> | BOOL | 对象成功保存后，自动返回该对象在云端的最新数据。用途请参考 [更新计数器](#更新计数器)。
`query` | `AV.Query`  | 当 query 中的条件满足后对象才能成功保存，否则放弃保存，并返回错误码 305。<br/><br/>开发者原本可以通过 `AV.Query` 和 `AV.Object` 分两步来实现这样的逻辑，但如此一来无法保证操作的原子性从而导致并发问题。该选项可以用来判断多用户更新同一对象数据时可能引发的冲突。

<a id="saveoption_query_example" name="saveoption_query_example"></a>【示例】一篇 wiki 文章允许任何人来修改，它的数据表字段有：**content**（wiki 内容）、**version**（版本号）。每当 wiki 内容被更新后，其 version 也需要更新（+1）。用户 A 要修改这篇 wiki，从数据表中取出时其 version 值为 3，当用户 A 完成编辑要保存新内容时，如果数据表中的 version 仍为 3，表明这段时间没有其他用户更新过这篇 wiki，可以放心保存；如果不是 3，开发者可以拒绝掉用户 A 的修改，或执行其他自定义的业务逻辑。



```js
  new AV.Query('Wiki').first().then(function (data) {
    var wiki = data;
    var currentVersion = wiki.get('version');
    wiki.set('version', currentVersion + 1);
    wiki.save(null, {
      query: new AV.Query('Wiki').equalTo('version', currentVersion)
    }).then(function (data) {
    }, function (error) {
      if (error) {
        throw error;
      }
    });
  }, function (error) {
    if (error) {
      throw error;
    }
  });
```



### 获取对象
每个被成功保存在云端的对象会有一个唯一的 Id 标识 `id`，因此获取对象的最基本的方法就是根据 `id` 来查询：



```js
  var query = new AV.Query('Todo');
  query.get('57328ca079bc44005c2472d0').then(function (data) {
    // 成功获得实例
    // data 就是 id 为 57328ca079bc44005c2472d0 的 Todo 对象实例
  }, function (error) {
    // 失败了
  });
```


如果不想使用查询，还可以通过从本地构建一个 `id`，然后调用接口从云端把这个 `id` 的数据拉取到本地，示例代码如下：



```js
  // 第一个参数是 className，第二个参数是 objectId
  var todo = AV.Object.createWithoutData('Todo', '5745557f71cfe40068c6abe0');
  todo.fetch().then(function () {
    var title = todo.get('title');// 读取 title
    var content = todo.get('content');// 读取 content
  }, function (error) {

  });
```


#### 获取 objectId
每一次对象存储成功之后，云端都会返回 `id`，它是一个全局唯一的属性。



```js
  var todo = new Todo();
  todo.set('title', '工程师周会');
  todo.set('content', '每周工程师会议，周一下午2点');
  todo.save().then(function (todo) {
    // 成功保存之后，执行其他逻辑
    // 获取 objectId
    var objectId = todo.id;
  }, function (error) {
    // 失败之后执行其他逻辑
    console.log(error);
  });
```



#### 访问对象的属性
访问 Todo 的属性的方式为：



```js
  var query = new AV.Query('Todo');
  query.get('558e20cbe4b060308e3eb36c').then(function (todo) {
    // 成功获得实例
    // todo 就是 id 为 558e20cbe4b060308e3eb36c 的 Todo 对象实例
    var priority = todo.get('priority');
    var location = todo.get('location');
    var title = todo.get('title');
    var content = todo.get('content');

    // 获取三个特殊属性
    var objectId = todo.id;
    var updatedAt = todo.updatedAt;
    var createdAt = todo.createdAt;

    //Wed May 11 2016 09:36:32 GMT+0800 (CST)
    console.log(createdAt);
  }, function (error) {
    // 失败了
    console.log(error);
  });
```


请注意以上代码中访问三个特殊属性 `id`、`createdAt`、`updatedAt` 的方式。

如果访问了并不存在的属性，SDK 并不会抛出异常，而是会返回空值。

#### 默认属性
默认属性是所有对象都会拥有的属性，它包括 `id`、`createdAt`、`updatedAt`。

<dl>
  <dt>`createdAt`</dt>
  <dd>对象第一次保存到云端的时间戳。该时间一旦被云端创建，在之后的操作中就不会被修改。它采用国际标准时区 UTC，开发者可能需要根据客户端当前的时区做转化。</dd>
  <dt>`updatedAt`</dt>
  <dd>对象最后一次被修改（或最近一次被更新）的时间。</dd>
</dl>



#### 同步对象
多终端共享一个数据时，为了确保当前客户端拿到的对象数据是最新的，可以调用刷新接口来确保本地数据与云端的同步：



```js
  // 使用已知 objectId 构建一个 AV.Object
  var todo = new Todo();
  todo.id = '5590cdfde4b00f7adb5860c8';
  todo.fetch().then(function (todo) {
    // // todo 是从服务器加载到本地的 Todo 对象
    var priority = todo.get('priority');
  }, function (error) {

  });
```


在更新对象操作后，对象本地的 `updatedAt` 字段（最后更新时间）会被刷新，直到下一次 save 或 fetch 操作，`updatedAt` 的最新值才会被同步到云端，这样做是为了减少网络流量传输。

如果需要在保存或更新之后让本地数据自动与云端保持一致，可以使用 [保存选项 `fetchWhenSave`](#保存选项)：



```js
  //设置 fetchWhenSave 为 true
  todo.fetchWhenSave(true);
  todo.save().then(function () {
    // 保存成功
  }, function (error) {
    // 失败了
    console.log(error);
  });
```


#### 同步指定属性

目前 Todo 这个类已有四个自定义属性：`priority`、`content`、`location` 和 `title`。为了节省流量，现在只想刷新 `priority` 和 `location` 可以使用如下方式：



```js
  // 使用已知 objectId 构建一个 AV.Object
  var todo = new Todo();
  todo.id = '5590cdfde4b00f7adb5860c8';
  todo.fetch({include:'priority,location'},{}).then(function (todo) {
    // 获取到本地
  }, function (error) {
    // 失败了
    console.log(error);
  });
```


**刷新操作会强行使用云端的属性值覆盖本地的属性**。因此如果本地有属性修改，请慎用这类接口。



### 更新对象

LeanStorage 上的更新对象都是针对单个对象，云端会根据<u>有没有 objectId</u> 来决定是新增还是更新一个对象。

假如 `id` 已知，则可以通过如下接口从本地构建一个 `AV.Object` 来更新这个对象：



```js
  // 第一个参数是 className，第二个参数是 objectId
  var todo = AV.Object.createWithoutData('Todo', '5745557f71cfe40068c6abe0');
  // 修改属性
  todo.set('content', '每周工程师会议，本周改为周三下午3点半。');
  // 保存到云端
  todo.save();
```



更新操作是覆盖式的，云端会根据最后一次提交到服务器的有效请求来更新数据。更新是字段级别的操作，未更新的字段不会产生变动，这一点请不用担心。

#### 使用 CQL 语法更新对象
LeanStorage 提供了类似 SQL 语法中的 Update 方式更新一个对象，例如更新一个 TodoFolder 对象可以使用下面的代码：



```js
  // 执行 CQL 语句实现更新一个 TodoFolder 对象
  AV.Query.doCloudQuery('update TodoFolder set name="家庭" where objectId="558e20cbe4b060308e3eb36c"')
  .then(function (data) {
    // data 中的 results 是本次查询返回的结果，AV.Object 实例列表
    var results = data.results;
  }, function (error) {
    //查询失败，查看 error
    console.log(error);
  });
```


#### 更新计数器

这是原子操作（Atomic Operation）的一种。
为了存储一个整型的数据，LeanStorage 提供对任何数字字段进行原子增加（或者减少）的功能。比如一条微博，我们需要记录有多少人喜欢或者转发了它，但可能很多次喜欢都是同时发生的。如果在每个客户端都直接把它们读到的计数值增加之后再写回去，那么极容易引发冲突和覆盖，导致最终结果不准。此时就需要使用这类原子操作来实现计数器。

假如，现在增加一个记录查看 Todo 次数的功能，一些与他人共享的 Todo 如果不用原子操作的接口，很有可能会造成统计数据不准确，可以使用如下代码实现这个需求：



```js
  var todo = AV.Object.createWithoutData('Todo', '57328ca079bc44005c2472d0');
  todo.set('views', 0);
  todo.save().then(function (todo) {
    todo.increment('views', 1);
    todo.fetchWhenSave(true);
    // 也可以指定增加一个特定的值
    // 例如一次性加 5
    todo.increment('views', 5);
    todo.save().then(function (data) {
      // 因为使用了 fetchWhenSave 选项，save 调用之后，如果成功的话，对象的计数器字段是当前系统最新值。
    }, function (error) {
      if (error) {
        throw error;
      }
    });
  }, function (error) {
    if (error) {
      throw error;
    }
  });
```



#### 更新数组

这也是原子操作的一种。使用以下方法可以方便地维护数组类型的数据：



* `AV.Object.add('arrayKey',arrayValue)`<br>
  将指定对象附加到数组末尾。
* `AV.Object.addUnique('arrayKey',arrayValue);`<br>
  如果不确定某个对象是否已包含在数组字段中，可以使用此操作来添加。对象的插入位置是随机的。
* `AV.Object.remove('arrayKey',arrayValue);`<br>
  从数组字段中删除指定对象的所有实例。



例如，Todo 对象有一个提醒日期 reminders，它是一个数组，代表这个日程会在哪些时间点提醒用户。比如有些拖延症患者会把闹钟设为早上的 7:10、7:20、7:30：



```js
  var reminder1 = new Date('2015-11-11 07:10:00');
  var reminder2 = new Date('2015-11-11 07:20:00');
  var reminder3 = new Date('2015-11-11 07:30:00');

  var reminders = [reminder1, reminder2, reminder3];

  var todo = new AV.Object('Todo');
  // 指定 reminders 是做一个 Date 对象数组
  todo.addUnique('reminders', reminders);
  todo.save().then(function (todo) {
   console.log(todo.id);
  }, function (error) {
    // 失败了
    console.log(error);
  });
```




### 删除对象

假如某一个 Todo 完成了，用户想要删除这个 Todo 对象，可以如下操作：



```js
  var todo = AV.Object.createWithoutData('Todo', '57328ca079bc44005c2472d0');
  todo.destroy().then(function (success) {
    // 删除成功
  }, function (error) {
    // 删除失败
  });
```


<div class="callout callout-danger">删除对象是一个较为敏感的操作。在控制台创建对象的时候，默认开启了权限保护，关于这部分的内容请阅读《[JavaScript 权限管理使用指南](acl_guide-js.html)》。</div>

#### 使用 CQL 语法删除对象
LeanStorage 提供了类似 SQL 语法中的 Delete 方式删除一个对象，例如删除一个 Todo 对象可以使用下面的代码：


```js
  // 执行 CQL 语句实现删除一个 Todo 对象
  AV.Query.doCloudQuery('delete from Todo where objectId="558e20cbe4b060308e3eb36c"').then(function (data) {
  }, function (error) {
  });
```







### 批量操作

为了减少网络交互的次数太多带来的时间浪费，你可以在一个请求中对多个对象进行创建、更新、删除、获取。接口都在 `AV.Object` 这个类下面：



```js
  var avObjectArray = [];// 构建一个本地的 AV.Object 对象数组

   // 批量创建、更新
  AV.Object.saveAll(avObjectArray).then(function (avobjs) {
  }, function (error) {
  });
  // 批量删除
  AV.Object.destroyAll(avObjectArray).then(function (avobjs) {
  }, function (error) {
  });
  // 批量获取
  AV.Object.fetchAll(avObjectArray).then(function (avobjs) {
  }, function (error) {
  });
```


批量设置 Todo 已经完成：



```js
  var query = new AV.Query('Todo');
  query.find().then(function (todos) {
      for (var i = 0; i < todos.length; i++) {
          var todo = todos[i];
          todo['status'] = 1;
      }
      AV.Object.saveAll(todos).then(function (success) {
      }, function (error) {
      });
  }, function (error) {
  });
```


不同类型的批量操作所引发不同数量的 API 调用，具体请参考 [API 调用次数的计算](faq.html#API_调用次数的计算)。





### 关联数据

#### `AV.Relation`
对象可以与其他对象相联系。如前面所述，我们可以把一个 `AV.Object` 的实例 A，当成另一个 `AV.Object` 实例 B 的属性值保存起来。这可以解决数据之间一对一或者一对多的关系映射，就像关系型数据库中的主外键关系一样。

例如，一个 TodoFolder 包含多个 Todo ，可以用如下代码实现：



```js
  var todoFolder = new AV.Object('TodoFolder');
  todoFolder.set('name', '工作');
  todoFolder.set('priority', 1);

  var todo1 = new AV.Object('Todo');
  todo1.set('title', '工程师周会');
  todo1.set('content', '每周工程师会议，周一下午2点');
  todo1.set('location', '会议室');

  var todo2 = new AV.Object('Todo');
  todo2.set('title', '维护文档');
  todo2.set('content', '每天 16：00 到 18：00 定期维护文档');
  todo2.set('location', '当前工位');

  var todo3 = new AV.Object('Todo');
  todo3.set('title', '发布 SDK');
  todo3.set('content', '每周一下午 15：00');
  todo3.set('location', 'SA 工位');

  var localTodos = [todo1, todo2, todo3];
  AV.Object.saveAll(localTodos).then(function (cloudTodos) {
      var relation = todoFolder.relation('containedTodos'); // 创建 AV.Relation
      for (var i = 0; i < cloudTodos.length; i++) {
          var todo = cloudTodos[i];
          relation.add(todo);// 建立针对每一个 Todo 的 Relation
      }
      todoFolder.save();// 保存到云端
  }, function (error) {
  });
```


#### Pointer
Pointer 只是个描述并没有具象的类与之对应，它与 `AV.Relation` 不一样的地方在于：`AV.Relation` 是在**一对多**的「一」这一方（上述代码中的一指 TodoFolder）保存一个 `AV.Relation` 属性，这个属性实际上保存的是对被关联数据**多**的这一方（上述代码中这个多指 Todo）的一个 Pointer 的集合。而反过来，LeanStorage 也支持在「多」的这一方保存一个指向「一」的这一方的 Pointer，这样也可以实现**一对多**的关系。

简单的说， Pointer 就是一个外键的指针，只是在 LeanCloud 控制台做了显示优化。

现在有一个新的需求：用户可以分享自己的 TodoFolder 到广场上，而其他用户看见可以给与评论，比如某玩家分享了自己想买的游戏列表（TodoFolder 包含多个游戏名字），而我们用 Comment 对象来保存其他用户的评论以及是否点赞等相关信息，代码如下：



```js
  var comment = new AV.Object('Comment');// 构建 Comment 对象
  comment.set('like', 1);// 如果点了赞就是 1，而点了不喜欢则为 -1，没有做任何操作就是默认的 0
  comment.set('content', '这个太赞了！楼主，我也要这些游戏，咱们团购么？');
  // 假设已知被分享的该 TodoFolder 的 objectId 是 5735aae7c4c9710060fbe8b0
  var targetTodoFolder = AV.Object.createWithoutData('TodoFolder', '5735aae7c4c9710060fbe8b0');
  comment.set('targetTodoFolder', targetTodoFolder);
  comment.save();//保存到云端
```


相关内容可参考 [关联数据查询](#AV.Relation_查询)。

#### 地理位置
地理位置是一个特殊的数据类型，LeanStorage 封装了 `AV.GeoPoint` 来实现存储以及相关的查询。

首先要创建一个 `AV.GeoPoint` 对象。例如，创建一个北纬 39.9 度、东经 116.4 度的 `AV.GeoPoint` 对象（LeanCloud 北京办公室所在地）：


``` js
  // 第一个参数是： latitude ，纬度
  // 第二个参数是： longitude，经度
  var point1 = new AV.GeoPoint(39.9, 116.4);

  // 以下是创建 AV.GeoPoint 对象不同的方法
  var point2 = new AV.GeoPoint([12.7, 72.2]);
  var point3 = new AV.GeoPoint({ latitude: 30, longitude: 30 });
```


假如，添加一条 Todo 的时候为该 Todo 添加一个地理位置信息，以表示创建时所在的位置：


``` objc
[todo setObject:point forKey:@"whereCreated"];
```


同时请参考 [地理位置查询](#地理位置查询)。


<!-- js 以及 ts 没有序列化和反序列化的需求 -->






### 数据协议
很多开发者在使用 LeanStorage 初期都会产生疑惑：客户端的数据类型是如何被云端识别的？
因此，我们有必要重点介绍一下 LeanStorage 的数据协议。

先从一个简单的日期类型入手，比如在 JavaScript 中，默认的日期类型是 `Date`，下面会详细讲解一个
 `Date` 是如何被云端正确的按照日期格式存储的。

为一个普通的 `AV.Object` 的设置一个 `Date` 的属性，然后调用保存的接口：


```js
  var testDate = new Date('2016-06-04');
  var testAVObject = new AV.Object('TestClass');
  testAVObject.set('testDate', testDate);
  testAVObject.save();
```


JavaScript SDK 在真正调用保存接口之前，会自动的调用一次序列化的方法，将 `Date` 类型的数据，转化为如下格式的数据：

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
`Buffer` |  `{"__type": "Bytes","base64":"utf-8-encoded-string}"`
`Pointer` |`{"__type":"Pointer","className":"Todo","objectId":"55a39634e4b0ed48f0c1845c"}`
`AV.Relation`| `{"__type": "Relation","className": "Todo"}`







## 文件
文件存储也是数据存储的一种方式，图像、音频、视频、通用文件等等都是数据的载体，另外很多开发者习惯了把复杂对象序列化之后保存成文件（如 `.json` 或者 `.xml` )。文件存储在 LeanStorage 中被单独封装成一个 `AV.File` 来实现文件的上传、下载等操作。

### 文件上传
文件的上传指的是开发者调用接口将文件存储在云端，并且返回文件最终的 URL 的操作。


#### 从数据流构建文件
`AV.File` 支持图片、视频、音乐等常见的文件类型，以及其他任何二进制数据，在构建的时候，传入对应的数据流即可：



```js
  var data = { base64: '6K+077yM5L2g5Li65LuA5LmI6KaB56C06Kej5oiR77yf' };
  var file = new AV.File('resume.txt', data);
  file.save().then(function (savedFile) {
  }, function (error) {
  });

  var bytes = [0xBE, 0xEF, 0xCA, 0xFE];
  var byteArrayFile = new AV.File('myfile.txt', bytes);
  byteArrayFile.save();
```


上例将文件命名为 `resume.txt`，这里需要注意两点：

- 不必担心文件名冲突。每一个上传的文件都有惟一的 ID，所以即使上传多个文件名为 `resume.txt` 的文件也不会有问题。
- 给文件添加扩展名非常重要。云端通过扩展名来判断文件类型，以便正确处理文件。所以要将一张 PNG 图片存到 `AV.File` 中，要确保使用 `.png` 扩展名。



#### 从本地路径构建文件
大多数的客户端应用程序都会跟本地文件系统产生交互，常用的操作就是读取本地文件，如下代码可以实现使用本地文件路径构建一个 `AV.File`：


假设在页面上有如下文件选择框：

```html
<input type="file" id="photoFileUpload"/>
```
上传文件对应的代码如下：
```js
    var fileUploadControl = $('#photoFileUpload')[0];
    if (fileUploadControl.files.length > 0) {
      var file = fileUploadControl.files[0];
      var name = 'avatar.jpg';

      var avFile = new AV.File(name, file);
      avFile.save().then(function(obj) {
        // 数据保存成功
        console.log(obj.url());
      }, function(error) {
        // 数据保存失败
        console.log(error);
      });
    }
```





#### 从网络路径构建文件
从一个已知的 URL 构建文件也是很多应用的需求。例如，从网页上拷贝了一个图像的链接，代码如下：



```js
  var file = AV.File.withURL('Satomi_Ishihara.gif', 'http://ww3.sinaimg.cn/bmiddle/596b0666gw1ed70eavm5tg20bq06m7wi.gif');
  file.save().then(function (savedFile) {
  }, function (error) {
  });
```




我们需要做出说明的是，[从本地路径构建文件](#从本地路径构建文件) 会<u>产生实际上传的流量</u>，并且文件最后是存在云端，而 [从网络路径构建文件](#从网络路径构建文件) 的文件实体并不存储在云端，只是会把文件的物理地址作为一个字符串保存在云端。

#### 执行上传
上传的操作调用方法如下：


如果仅是想简单的上传，可以直接在 Web 前端使用 AV.File 上面的相关方法。但真实使用场景中，还有很多开发者需要自行实现一个上传接口，对数据做更多的处理。

以下是一个在 Web 中完整上传一张图片的 Demo，包括前端与 Node.js 服务端代码。服务端推荐使用 LeanCloud 推出的「[云引擎](leanengine_overview.html)」，非常出色的 Node.js 环境。

前端页面（比如:fileUpload.html）：
```html
// 页面元素（限制上传为图片类型，使用时可自行修改 accept 属性）
<form id="upload-file-form" class="upload" enctype="multipart/form-data">
  <input name="attachment" type="file" accept="image/gif, image/jpeg, image/png">
</form>
```
纯前端调用方式：

```javascript
// 前端代码，基于 jQuery
function uploadPhoto() {
  var uploadFormDom = $('#upload-file-form');
  var uploadInputDom = uploadFormDom.find('input[type=file]');
  // 获取浏览器 file 对象
  var files = uploadInputDom[0].files;
  // 创建 formData 对象
  var formData = new window.FormData(uploadFormDom[0]);
  if (files.length) {
    $.ajax({
      // 注意，这个 url 地址是一个例子，真实使用时需替换为自己的上传接口 url
      url: 'https://leancloud.cn/xxx/xxx/upload',
      method: 'post',
      data: formData,
      processData: false,
      contentType: false
    }).then((data) => {
      // 上传成功，服务端设置返回
      console.log(data);
    });
  }
};
```

在服务端可以编写如下代码：

```javascript
// 服务端代码，基于 Node.js、Express
var AV = require('leanengine');
// 服务端需要使用 connect-busboy（通过 npm install 安装）
var busboy = require('connect-busboy');
// 使用这个中间件
app.use(busboy());

// 上传接口方法（使用时自行配置到 router 中）
function uploadFile (req, res) {
  if (req.busboy) {
    var base64data = [];
    var pubFileName = '';
    var pubMimeType = '';
    req.busboy.on('file', (fieldname, file, fileName, encoding, mimeType) => {
      var buffer = '';
      pubFileName = fileName;
      pubMimeType = mimeType;
      file.setEncoding('base64');
      file.on('data', function(data) {
        buffer += data;
      }).on('end', function() {
        base64data.push(buffer);
      });
    }).on('finish', function() {
      var f = new AV.File(pubFileName, {
        // 仅上传第一个文件（多个文件循环创建）
        base64: base64data[0]
      });
      try {
        f.save().then(function(fileObj) {
          // 向客户端返回数据
          res.send({
            fileId: fileObj.id,
            fileName: fileObj.name(),
            mimeType: fileObj.metaData().mime_type,
            fileUrl: fileObj.url()
          });
        });
      } catch (error) {
        console.log('uploadFile - ' + error);
        res.status(502);
      }
    })
    req.pipe(req.busboy);
  } else {
    console.log('uploadFile - busboy undefined.');
    res.status(502);
  }
};
```






### 图像缩略图

保存图像时，如果想在下载原图之前先得到缩略图，方法如下：



```js
  //获得宽度为100像素，高度200像素的缩略图
  var url = file.thumbnailURL(100, 200);
```


<div class="callout callout-info">注意：<strong>图片最大不超过 20 M 才可以获取缩略图。</strong> </div>

### 文件元数据

`AV.File` 的 `metaData` 属性，可以用来保存和获取该文件对象的元数据信息：



```js
    // 获取文件大小
    var size = file.size();
    // 上传者(AV.User) 的 objectId，如果未登录，默认为空
    var ownerId = file.ownerId();

    // 获取文件的全部元信息
    var metadata = file.metaData();
    // 设置文件的作者
    file.metaData('author', 'LeanCloud');
    // 获取文件的格式
    var format = file.metaData('format');
```




### 文件查询
文件的查询依赖于文件在系统中的关系模型，例如，用户的头像，有一些用户习惯直接在 `_User` 表中直接使用一个 `avatar` 列，然后里面存放着一个 url 指向一个文件的地址，但是，我们更推荐用户使用 Pointer 来关联一个 AV.User 和 AV.File，代码如下：



```js
    var data = { base64: '文件的 base64 编码' };
    var avatar = new AV.File('avatar.png', data);

    var user = new AV.User();
    var randomUsername = 'Tom';
    user.setUsername(randomUsername)
    user.setPassword('leancloud');
    user.set('avatar',avatar);
    user.signUp().then(function (u){
    });
```




### 删除

当文件较多时，要把一些不需要的文件从云端删除：



```js
  var file = AV.File.createWithoutData('552e0a27e4b0643b709e891e');
  file.destroy().then(function (success) {
  }, function (error) {
  });
```






<div class="callout callout-info">注意：默认情况下，文件的删除权限是关闭的，需要进入控制台，在 [`_File` > 其他 > 权限设置 > delete](/data.html?appid={{appid}}#/_File)  中开启。</div>


## 查询
`AV.Query` 是构建针对 `AV.Object` 查询的基础类。


### 创建查询实例


```js
  var query = new AV.Query('Todo');
```



### 根据 id 查询
在 [获取对象](#获取对象) 中我们介绍过如何通过 objectId 来获取对象实例，从而简单的介绍了一下 `AV.Query` 的用法，代码请参考对应的内容，不再赘述。

### 条件查询
在大多数情况下做列表展现的时候，都是根据不同条件来分类展现的，比如，我要查询所有优先级为 0 的 Todo，也就是做列表展现的时候，要展示优先级最高，最迫切需要完成的日程列表，此时基于 priority 构建一个查询就可以查询出符合需求的对象：



```js
  var query = new AV.Query('Todo');
  // 查询 priority 是 0 的 Todo
  query.equalTo('priority', 0);
  query.find().then(function (results) {
      var priorityEqualsZeroTodos = results;
  }, function (error) {
  });
```


其实，拥有传统关系型数据库开发经验的开发者完全可以翻译成如下的 SQL：

```sql
  select * from Todo where priority = 0
```
LeanStorage 也支持使用这种传统的 SQL 语句查询。具体使用方法请移步至 [Cloud Query Language（CQL）查询](#CQL_查询)。

查询默认最多返回 100 条符合条件的结果，要更改这一数值，请参考 [限定结果返回数量](#限定返回数量)。

当多个查询条件并存时，它们之间默认为 AND 关系，即查询只返回满足了全部条件的结果。建立 OR 关系则需要使用 [组合查询](#组合查询)。

注意：在简单查询中，如果对一个对象的同一属性设置多个条件，那么先前的条件会被覆盖，查询只返回满足最后一个条件的结果。例如，我们要找出优先级为 0 和 1 的所有 Todo，错误写法是：



```js
  var query = new AV.Query('Todo');
  query.equalTo('priority', 0);
  query.equalTo('priority', 1);
  query.find().then(function (results) {
  // 如果这样写，第二个条件将覆盖第一个条件，查询只会返回 priority = 1 的结果
  }, function (error) {
  });
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



```js
  var query = new AV.Query('Todo');
  query.lessThan('priority', 2);
```


要查询优先级大于等于 2 的 Todo：



```js
  query.greaterThanOrEqualTo('priority',2);
```


比较查询**只适用于可比较大小的数据类型**，如整型、浮点等。

#### 正则匹配查询

正则匹配查询是指在查询条件中使用正则表达式来匹配数据，查询指定的 key 对应的 value 符合正则表达式的所有对象。
例如，要查询标题包含中文的 Todo 对象可以使用如下代码：



```js
  var query = new AV.Query('Todo');
  var regExp = new RegExp('[\u4e00-\u9fa5]', 'i');
  query.matches('title', regExp);
  query.find().then(function (results) {
  }, function (error) {
  });
```


正则匹配查询**只适用于**字符串类型的数据。

#### 包含查询

包含查询类似于传统 SQL 语句里面的 `LIKE %keyword%` 的查询，比如查询标题包含「李总」的 Todo：



```js
  query.contains('title','李总');
```


翻译成 SQL 语句就是：

```sql
  select * from Todo where title LIKE '%李总%'
```
不包含查询与包含查询是对立的，不包含指定关键字的查询，可以使用 [正则匹配方法](#正则匹配查询) 来实现。例如，查询标题不包含「机票」的 Todo，正则表达式为 `^((?!机票).)*$`：


```js
  var query = new AV.Query('Todo');
  var regExp = new RegExp('^((?!机票).)*$', 'i');
  query.matches('title', regExp);
```


但是基于正则的模糊查询有两个缺点：

- 当数据量逐步增大后，查询效率将越来越低。
- 没有文本相关性排序

因此，你还可以考虑使用 [应用内搜索](#应用内搜索) 功能。它基于搜索引擎技术构建，提供更强大的搜索功能。

还有一个接口可以精确匹配不等于，比如查询标题不等于「出差、休假」的 Todo 对象：



```js
  var query = new AV.Query('Todo');
  var filterArray = ['出差', '休假'];
  query.notContainedIn('title', filterArray);
```


#### 数组查询

当一个对象有一个属性是数组的时候，针对数组的元数据查询可以有多种方式。例如，在 [数组](#更新数组) 一节中我们为 Todo 设置了 reminders 属性，它就是一个日期数组，现在我们需要查询所有在 8:30 会响起闹钟的 Todo 对象：



```js
  var query = new AV.Query('Todo');
  var reminderFilter = [new Date('2015-11-11 08:30:00')];
  query.containsAll('reminders', reminderFilter);

  // 也可以使用 equals 接口实现这一需求
  var targetDateTime = new Date('2015-11-11 08:30:00');
  query.equalTo('reminders', targetDateTime);
```


如果你要查询包含 8:30、9:30 这两个时间点响起闹钟的 Todo，可以使用如下代码：



```js
  var query = new AV.Query('Todo');
  var reminderFilter = [new Date('2015-11-11 08:30:00'), new Date('2015-11-11 09:30:00')];
  query.containsAll('reminders', reminderFilter);
```


注意这里是包含关系，假如有一个 Todo 会在 8:30、9:30、10:30 响起闹钟，它仍然是会被查询出来的。

#### 字符串查询
使用 `startsWith` 可以过滤出以特定字符串开头的结果，这有点像 SQL 的 LIKE 条件。因为支持索引，所以该操作对于大数据集也很高效。



```js
  // 找出开头是「早餐」的 Todo
  var query = new AV.Query('Todo');
  query.startsWith('content', '早餐');

  // 找出包含 「bug」 的 Todo
  var query = new AV.Query('Todo');
  query.contains('content', 'bug');
```


#### 空值查询
假设我们的 Todo 允许用户上传图片用来帮助用户记录某些特殊的事项，但是有时候用户可能就记得自己给一个 Todo 附加过图片，但是具体又不记得这个 Todo 的关键字是什么，因此我们需要一个接口可以找出那些有图片的 Todo，此时就可以使用到空值查询的接口：



```js
  var aTodoAttachmentImage = AV.File.withURL('attachment.jpg', 'http://www.zgjm.org/uploads/allimg/150812/1_150812103912_1.jpg');
  var todo = new AV.Object('Todo');
  todo.set('images', aTodoAttachmentImage);
  todo.set('content', '记得买过年回家的火车票！！！');
  todo.save();

  var query = new AV.Query('Todo');
  query.exists('images');
  query.find().then(function (results) {
    // results 返回的就是有图片的 Todo 集合
  }, function (error) {
  });

  // 使用空值查询获取没有图片的 Todo
  query.doesNotExist('images');
```


### 组合查询
组合查询就是把诸多查询条件合并成一个查询，再交给 SDK 去云端查询。方式有两种：OR 和 AND。

#### OR 查询
OR 操作表示多个查询条件符合其中任意一个即可。 例如，查询优先级是大于等于 3 或者已经完成了的 Todo：



```js
  var priorityQuery = new AV.Query('Todo');
  priorityQuery.greaterThanOrEqualTo('priority', 3);

  var statusQuery = new AV.Query('Todo');
  statusQuery.equalTo('status', 1);

  var query = AV.Query.or(priorityQuery, statusQuery);
  // 返回 priority 大于等于 3 或 status 等于 1 的 Todo
```


**注意：OR 查询中，子查询中不能包含地理位置相关的查询。**

#### AND 查询
AND 操作是指只有满足了所有查询条件的对象才会被返回给客户端。例如，查询优先级小于 1 并且尚未完成的 Todo：



```js
  var priorityQuery = new AV.Query('Todo');
  priorityQuery.lessThan('priority', 3);

  var statusQuery = new AV.Query('Todo');
  statusQuery.equalTo('status', 0);

  var query = AV.Query.and(priorityQuery, statusQuery);
  // 返回 priority 小于 3 并且 status 等于 0 的 Todo
```


可以对新创建的 `AV.Query` 添加额外的约束，多个约束将以 AND 运算符来联接。

### 查询结果

#### 获取第一条结果
例如很多应用场景下，只要获取满足条件的一个结果即可，例如获取满足条件的第一条 Todo：



```js
  var query = new AV.Query('Comment');
  query.equalTo('priority', 0);
  query.first().then(function (data) {
    // data 就是符合条件的第一个 AV.Object
  }, function (error) {
  });
```


#### 限定返回数量
为了防止查询出来的结果过大，云端默认针对查询结果有一个数量限制，即 `limit`，它的默认值是 100。比如一个查询会得到 10000 个对象，那么一次查询只会返回符合条件的 100 个结果。`limit` 允许取值范围是 1 ~ 1000。例如设置返回 10 条结果：



```js
  var query = new AV.Query('Todo');
  var now = new Date();
  query.lessThanOrEqualTo('createdAt', now);//查询今天之前创建的 Todo
  query.limit(10);// 最多返回 10 条结果
```


#### 跳过数量
设置 skip 这个参数可以告知云端本次查询要跳过多少个结果。将 skip 与 limit 搭配使用可以实现翻页效果，这在客户端做列表展现时，尤其在数据量庞大的情况下就使用技术。例如，在翻页中，一页显示的数量是 10 个，要获取第 3 页的对象：



```js
  var query = new AV.Query('Todo');
  var now = new Date();
  query.lessThanOrEqualTo('createdAt', now);//查询今天之前创建的 Todo
  query.limit(10);// 最多返回 10 条结果
  query.skip(20);// 跳过 20 条结果
```


尽管我们提供以上接口，但是我们不建议广泛使用，因为它的执行效率比较低。取而代之，我们建议使用 `createdAt` 或者 `updatedAt` 这类的时间戳进行分段查询。

#### 属性限定
通常列表展现的时候并不是需要展现某一个对象的所有属性，例如，Todo 这个对象列表展现的时候，我们一般展现的是 title 以及 content，我们在设置查询的时候，也可以告知云端需要返回的属性有哪些，这样既满足需求又节省了流量，也可以提高一部分的性能，代码如下：



```js
  var query = new AV.Query('Todo');
  query.select('title', 'content');
  query.find().then(function (results) {
      for (var i = 0; i < results.length; i++) {
          var todo = results[i];
          var title = todo.get('title');
          var content = todo.get('content');
          var location_1 = todo.get('location');
      }
  }, function (error) {
  });
```


#### 统计总数量
通常用户在执行完搜索后，结果页面总会显示出诸如「搜索到符合条件的结果有 1020 条」这样的信息。例如，查询一下今天一共完成了多少条 Todo：



```js
  var query = new AV.Query('Todo');
  query.equalTo('status', 1);
  query.count().then(function (count) {
      console.log(count);
  }, function (error) {
  });
```


#### 排序

对于数字、字符串、日期类型的数据，可对其进行升序或降序排列。



```js
  // 按时间，升序排列
  query.ascending('createdAt');

  // 按时间，降序排列
  query.descending('createdAt');
```


一个查询可以附加多个排序条件，如按 priority 升序、createdAt 降序排列：



```js
  var query = new AV.Query('Todo');
  query.ascending('priority');
  query.descending('createdAt');
```


<!-- #### 限定返回字段 -->

### 关系查询
关联数据查询也可以通俗地理解为关系查询，关系查询在传统型数据库的使用中是很常见的需求，因此我们也提供了相关的接口来满足开发者针对关联数据的查询。

首先，我们需要明确关系的存储方式，再来确定对应的查询方式。

#### Pointer 查询
基于在 [Pointer](#Pointer) 小节介绍的存储方式：每一个 Comment 都会有一个 TodoFolder 与之对应，用以表示 Comment 属于哪个 TodoFolder。现在我已知一个 TodoFolder，想查询所有的 Comnent 对象，可以使用如下代码：



```js
  var query = new AV.Query('Comment');
  var todoFolder = AV.Object.createWithoutData('TodoFolder', '5735aae7c4c9710060fbe8b0');
  query.equalTo('targetTodoFolder', todoFolder);

  // 想在查询的同时获取关联对象的属性则一定要使用 `include` 接口用来指定返回的 `key`
  query.include('targetTodoFolder');
```


#### `AV.Relation` 查询
假如用户可以给 TodoFolder 增加一个 Tag 选项，用以表示它的标签，而为了以后拓展 Tag 的属性，就新建了一个 Tag 对象，如下代码是创建 Tag 对象：



```js
  var tag = new AV.Object('Todo');
  tag.set('name', '今日必做');
  tag.save();
```


而 Tag 的意义在于一个 TodoFolder 可以拥有多个 Tag，比如「家庭」（TodoFolder） 拥有的 Tag 可以是：今日必做，老婆吩咐，十分重要。实现创建「家庭」这个 TodoFolder 的代码如下：



```js
  var tag1 = new AV.Object('Todo');
  tag1.set('name', '今日必做');

  var tag2 = new AV.Object('Todo');
  tag2.set('name', '老婆吩咐');

  var tag3 = new AV.Object('Todo');
  tag3.set('name', '十分重要');

  var tags = [tag1, tag2, tag3];
  AV.Object.saveAll(tags).then(function (savedTags) {

      var todoFolder = new AV.Object('TodoFolder');
      todoFolder.set('name', '家庭');
      todoFolder.set('priority', 1);

      var relation = todoFolder.relation('tags');
      relation.add(tag1);
      relation.add(tag2);
      relation.add(tag3);

      todoFolder.save();
  }, function (error) {
  });
```


查询一个 TodoFolder 的所有 Tag 的方式如下：



```js
  var todoFolder = AV.Object.createWithoutData('Todo', '5735aae7c4c9710060fbe8b0');
  var relation = todoFolder.relation('tags');
  var query = relation.query();
  query.find().then(function (results) {
    // results 是一个 AV.Object 的数组，它包含所有当前 todoFolder 的 tags
  }, function (error) {
  });
```


反过来，现在已知一个 Tag，要查询有多少个 TodoFolder 是拥有这个 Tag 的，可以使用如下代码查询：



```js
  var targetTag = AV.Object.createWithoutData('Tag', '5655729900b0bf3785ca8192');
  var query = new AV.Query('TodoFolder');
  query.equalTo('tags', targetTag);
  query.find().then(function (results) {
  // results 是一个 AV.Object 的数组
  // results 指的就是所有包含当前 tag 的 TodoFolder
  }, function (error) {
  });
```


关于关联数据的建模是一个复杂的过程，很多开发者因为在存储方式上的选择失误导致最后构建查询的时候难以下手，不但客户端代码冗余复杂，而且查询效率低，为了解决这个问题，我们专门针对关联数据的建模推出了一个详细的文档予以介绍，详情请阅读 [JavaScript 数据模型设计指南](relation_guide-js.html)。

#### 关联属性查询
正如在 [Pointer](#Pointer) 中保存 Comment 的 targetTodoFolder 属性一样，假如查询到了一些 Comment 对象，想要一并查询出每一条 Comment 对应的 TodoFolder 对象的时候，可以加上 include 关键字查询条件。同理，假如 TodoFolder 表里还有 pointer 型字段 targetAVUser 时，再加上一个递进的查询条件，形如 include(b.c)，即可一并查询出每一条 TodoFolder 对应的 AVUser 对象。代码如下：



```js
  var commentQuery = new AV.Query('Comment');
  commentQuery.descending('createdAt');
  commentQuery.limit(10);
  commentQuery.include('targetTodoFolder');// 关键代码，用 include 告知服务端需要返回的关联属性对应的对象的详细信息，而不仅仅是 objectId
  commentQuery.include('targetTodoFolder.targetAVUser');// 关键代码，同上，会返回 targetAVUser 对应的对象的详细信息，而不仅仅是 objectId
  commentQuery.find().then(function (comments) {
      // comments 是最近的十条评论, 其 targetTodoFolder 字段也有相应数据
      for (var i = 0; i < comments.length; i++) {
          var comment = comments[i];
          // 并不需要网络访问
          var todoFolder = comment.get('targetTodoFolder');
          var avUser = todoFolder.get('targetAVUser');
      }
  }, function (error) {
  });
```


#### 内嵌查询
假如现在有一个需求是展现点赞超过 20 次的 TodoFolder 的评论（Comment）查询出来，注意这个查询是针对评论（Comment），要实现一次查询就满足需求可以使用内嵌查询的接口：



```js
  // 构建内嵌查询
  var innerQuery = new AV.Query('TodoFolder');
  innerQuery.greaterThan('likes', 20);

  // 将内嵌查询赋予目标查询
  var query = new AV.Query('Comment');

  // 执行内嵌操作
  query.matchesQuery('targetTodoFolder', innerQuery);
  query.find().then(function (results) {
     // results 就是符合超过 20 个赞的 TodoFolder 这一条件的 Comment 对象集合
  }, function (error) {
  });

  query.doesNotMatchQuery('targetTodoFolder', innerQuery);
  // 如此做将查询出 likes 小于或者等于 20 的 TodoFolder 的 Comment 对象
```


### CQL 查询
Cloud Query Language（CQL）是 LeanStorage 独创的使用类似 SQL 语法来实现云端查询功能的语言，具有 SQL 开发经验的开发者可以方便地使用此接口实现查询。

分别找出 status = 1 的全部 Todo 结果，以及 priority = 0 的 Todo 的总数：



```js
  var cql = 'select * from Todo where status = 1';
  AV.Query.doCloudQuery(cql).then(function (data) {
      // results 即为查询结果，它是一个 AV.Object 数组
      var results = data.results;
  }, function (error) {
  });
  cql = 'select * from %@ where status = 1';
  AV.Query.doCloudQuery(cql).then(function (data) {
      // 获取符合查询的数量
      var count = data.count;
  }, function (error) {
  });
```


通常查询语句会使用变量参数，为此我们提供了与 Java JDBC 所使用的 PreparedStatement 占位符查询相类似的语法结构。

查询 status = 0、priority = 1 的 Todo：



```js
  // 带有占位符的 cql 语句
  var cql = 'select * from Todo where status = ? and priority = ?';
  var pvalues = [0, 1];
  AV.Query.doCloudQuery(cql, pvalues).then(function (data) {
      // results 即为查询结果，它是一个 AV.Object 数组
      var results = data.results;
  }, function (error) {
  });
```


目前 CQL 已经支持数据的更新 update、插入 insert、删除 delete 等 SQL 语法，更多内容请参考 [Cloud Query Language 详细指南](cql_guide.html)。



### 地理位置查询
地理位置查询是较为特殊的查询，一般来说，常用的业务场景是查询距离 xx 米之内的某个位置或者是某个建筑物，甚至是以手机为圆心，查找方圆多少范围内餐厅等等。LeanStorage 提供了一系列的方法来实现针对地理位置的查询。

#### 查询位置附近的对象
Todo 的 `whereCreated`（创建 Todo 时的位置）是一个 `AV.GeoPoint` 对象，现在已知了一个地理位置，现在要查询 `whereCreated` 靠近这个位置的 Todo 对象可以使用如下代码：



```js
  var query = new AV.Query('Todo');
  var point = new AV.GeoPoint('39.9', '116.4');
  query.withinKilometers('whereCreated', point, 2.0);
  query.find().then(function (results) {
      var nearbyTodos = results;
  }, function (error) {
  });
```


在上面的代码中，`nearbyTodos` 返回的是与 `point` 这一点按距离排序（由近到远）的对象数组。注意：**如果在此之后又使用了 `ascending` 或 `descending` 方法，则按距离排序会被新排序覆盖。**


#### 查询指定范围内的对象
要查找指定距离范围内的数据，可使用 `whereWithinKilometers` 、 `whereWithinMiles` 或 `whereWithinRadians` 方法。
例如，我要查询距离指定位置，2 千米范围内的 Todo：



```js
  var query = new AV.Query('Todo');
  var point = new AV.GeoPoint('39.9', '116.4');
  query.withinKilometers('whereCreated', point, 2.0);
```



#### 注意事项

使用地理位置需要注意以下方面：

* 每个 `AV.Object` 数据对象中只能有一个 `AV.GeoPoint` 对象的属性。
* 地理位置的点不能超过规定的范围。纬度的范围应该是在 `-90.0` 到 `90.0` 之间，经度的范围应该是在 `-180.0` 到 `180.0` 之间。如果添加的经纬度超出了以上范围，将导致程序错误。



## Promise

除了回调函数之外，每一个在 LeanCloud JavaScript SDK 中的异步方法都会返回一个
 `Promise`。使用 `Promise`，你的代码可以比原来的嵌套 callback 的方法看起来优雅得多。

```javascript
// 这是一个比较完整的例子，具体方法可以看下面的文档
// 查询某个 AV.Object 实例，之后进行修改
var query = new AV.Query('TestObject');
query.equalTo('name', 'hjiang');
// find 方法是一个异步方法，会返回一个 Promise，之后可以使用 then 方法
query.find().then(function(results) {
  // 返回一个符合条件的 list
  var obj = results[0];
  obj.set('phone', '182xxxx5548');
  // save 方法也是一个异步方法，会返回一个 Promise，所以在此处，你可以直接 return 出去，后续操作就可以支持链式 Promise 调用
  return obj.save();
}).then(function() {
  // 这里是 save 方法返回的 Promise
  console.log('设置手机号码成功');
}).catch(function(error) {
  // catch 方法写在 Promise 链式的最后，可以捕捉到全部 error
  console.log(error);
});
```

### then 方法

每一个 Promise 都有一个叫 `then` 的方法，这个方法接受一对 callback。第一个 callback 在 promise 被解决（`resolved`，也就是正常运行）的时候调用，第二个会在 promise 被拒绝（`rejected`，也就是遇到错误）的时候调用。

```javascript
obj.save().then(function(obj) {
  //对象保存成功
}, function(error) {
  //对象保存失败，处理 error
});
```

其中第二个参数是可选的。

### try、catch 和 finally 方法

你还可以使用 `try,catch,finally` 三个方法，将逻辑写成：

```javascript
obj.save().try(function(obj) {
  //对象保存成功
}).catch(function(error) {
  //对象保存失败，处理 error
}).finally(function(){
  //无论成功还是失败，都调用到这里
});
```

类似语言里的 `try ... catch ... finally` 的调用方式来简化代码。

为了兼容其他 Promise 库，我们提供了下列别名：

* `AV.Promise#done` 等价于 `try` 方法
* `AV.Promise#fail` 等价于 `catch` 方法
* `AV.Promise#always` 等价于 `finally` 方法

因此上面例子也可以写成：

```javascript
obj.save().done(function(obj) {
  //对象保存成功
}).fail(function(error) {
  //对象保存失败，处理 error
}).always(function(){
  //无论成功还是失败，都调用到这里
});
```

### 将 Promise 组织在一起

Promise 比较神奇，可以代替多层嵌套方式来解决发送异步请求代码的调用顺序问题。如果一个 Promise 的回调会返回一个 Promise，那么第二个 then 里的 callback 在第一个 then
的 callback 没有解决前是不会解决的，也就是所谓 **Promise Chain**。

```javascript
var query = new AV.Query('Student');
query.addDescending('gpa');
query.find().then(function(students) {
  students[0].set('valedictorian', true);
  return students[0].save();

}).then(function(valedictorian) {
  return query.find();

}).then(function(students) {
  students[1].set('salutatorian', true);
  return students[1].save();

}).then(function(salutatorian) {
  // Everything is done!

});
```

### 错误处理

如果任意一个在链中的 Promise 返回一个错误的话，所有的成功的 callback 在接下
来都会被跳过直到遇到一个处理错误的 callback。

处理 error 的 callback 可以转换 error 或者可以通过返回一个新的 Promise 的方式来处理它。你可以想象成拒绝的 promise 有点像抛出异常，而 error callback 函数则像是一个 catch 来处理这个异常或者重新抛出异常。

```javascript
var query = new AV.Query('Student');
query.addDescending('gpa');
query.find().then(function(students) {
  students[0].set('valedictorian', true);
  // 强制失败
  return AV.Promise.error('There was an error.');

}).then(function(valedictorian) {
  // 这里的代码将被忽略
  return query.find();

}).then(function(students) {
  // 这里的代码也将被忽略
  students[1].set('salutatorian', true);
  return students[1].save();
}, function(error) {
  // 这个错误处理函数将被调用，并且错误信息是 'There was an error.'.
  // 让我们处理这个错误，并返回一个“正确”的新 Promise
  return AV.Promise.as('Hello!');

}).then(function(hello) {
  // 最终处理结果
}, function(error) {
  // 这里不会调用，因为前面已经处理了错误
});
```

通常来说，在正常情况的回调函数链的末尾，加一个错误处理的回调函数，是一种很
常见的做法。

利用 `try,catch` 方法可以将上述代码改写为：

```javascript
var query = new AV.Query('Student');
query.addDescending('gpa');
query.find().try(function(students) {
  students[0].set('valedictorian', true);
  // 强制失败
  return AV.Promise.error('There was an error.');

}).try(function(valedictorian) {
  // 这里的代码将被忽略
  return query.find();

}).try(function(students) {
  // 这里的代码也将被忽略
  students[1].set('salutatorian', true);
  return students[1].save();

}).catch(function(error) {
  // 这个错误处理函数将被调用，并且错误信息是 'There was an error.'.
  // 让我们处理这个错误，并返回一个“正确”的新 Promise
  return AV.Promise.as('Hello!');
}).try(function(hello) {
  // 最终处理结果
}).catch(function(error) {
  // 这里不会调用，因为前面已经处理了错误
});
```

### 创建 Promise

在开始阶段,你可以只用系统（譬如 find 和 save 方法等）返回的 promise。但是，在更高级
的场景下，你可能需要创建自己的 promise。在创建了 Promise 之后，你需要调用 `resolve` 或者 `reject` 来触发它的 callback.

```javascript
var successful = new AV.Promise();
successful.resolve('The good result.');

var failed = new AV.Promise();
failed.reject('An error message.');
```

如果你在创建 promise 的时候就知道它的结果，下面有两个很方便的方法可以使用：

```javascript
var successful = AV.Promise.as('The good result.');

var failed = AV.Promise.error('An error message.');
```

除此之外，你还可以为 `AV.Promise` 提供一个函数，这个函数接收 `resolve` 和 `reject` 方法，运行实际的业务逻辑。例如：

```javascript
var promise = new AV.Promise(function(resolve, reject){
  resolve(42);
});

promise.then(functon(ret){
  //print 42.
  console.log(ret);
});
```

尝试下两个一起用：

```javascript
var promise = new AV.Promise(function(resolve, reject) {
  setTimeout(function() {
    if (Date.now() % 2) {
     resolve('奇数时间');
    } else {
     reject('偶数时间');
    }
  }, 2000);
});

promise.then(function(value) {
  // 奇数时间
  console.log(value);
}, function(value) {
  // 偶数时间
  console.log(value);
});
```

### 顺序的 Promise

在你想要某一行数据做一系列的任务的时候，Promise 链是很方便的，每一个任务都等着前
一个任务结束。比如，假设你想要删除你的博客上的所有评论：

<div class="callout callout-info">下文中在代码里出现的 `_.???` 表示引用了 [underscore.js](http://underscorejs.org/) 这个类库的方法。underscore.js 是一个非常方便的 JS 类库，提供了很多工具方法。</div>

```javascript
var query = new AV.Query('Comment');
query.equalTo('post', post); // 假设 post 是一个已经存在的实例

query.find().then(function(results) {
  // Create a trivial resolved promise as a base case.
  var promise = AV.Promise.as();
  _.each(results, function(result) {
    // For each item, extend the promise with a function to delete it.
    promise = promise.then(function() {
      // Return a promise that will be resolved when the delete is finished.
      return result.destroy();
    });
  });
  return promise;

}).then(function() {
  // Every comment was deleted.
});
```

### 并行的 Promise

你也可以用 Promise 来并行的进行多个任务，这时需要使用 when 方法，你可以一次同时开始几个操作。使用 `AV.Promise.when` 来创建一个新的 promise，它会在所有输入的 `Promise` 被 resolve 之后才被 resolve。即便一些输入的 promise 失败了，其他的 Promise 也会被成功执行。你可以在 callback 的参数部分检查每一个 promise 的结果。并行地进行操作会比顺序进行更快，但是也会消耗更多的系统资源和带宽。

简单例子：

```javascript
function timerPromisefy(delay) {
  return new AV.Promise(function (resolve) {
    //延迟 delay 毫秒，然后调用 resolve
    setTimeout(function () {
      resolve(delay);
    }, delay);
   });
}

var startDate = Date.now();

AV.Promise.when(
  timerPromisefy(1),
  timerPromisefy(32),
  timerPromisefy(64),
  timerPromisefy(128)
).then(function (r1, r2, r3, r4) {
  //r1,r2,r3,r4 分别为1,32,64,128
  //大概耗时在 128 毫秒
  console.log(new Date() - startDate);
});

//尝试下其中一个失败的例子
var startDate = Date.now();
AV.Promise.when(
  timerPromisefy(1),
  timerPromisefy(32),
  AV.Promise.error('test error'),
  timerPromisefy(128)
).then(function () {
  //不会执行
}, function(errors){
  //大概耗时在 128 毫秒
  console.log(new Date() - startDate);
  console.dir(errors);  //print [ , , 'test error',  ]
});
```

下面例子执行一次批量删除某个 Post 的评论：

```javascript
var query = new AV.Query('Comment');
query.equalTo('post', post);  // 假设 post 是一个已经存在的实例

query.find().then(function(results) {
  // Collect one promise for each delete into an array.
  var promises = [];
  _.each(results, function(result) {
    // Start this delete immediately and add its promise to the list.
    promises.push(result.destroy());
  });
  // Return a new promise that is resolved when all of the deletes are finished.
  return AV.Promise.when(promises);

}).then(function() {
  // Every comment was deleted.
});
```

`when` 会在错误处理器中返回所有遇到的错误信息，以数组的形式提供。

除了 `when` 之外，还有一个类似的方法是 `AV.Promise.all`，这个方法和 `when` 的区别在于：

它只接受数组形式的 promise 输入，并且如果有任何一个 promise 失败，它就会直接调用错误处理器，而不是等待所有 promise 完成，其次是它的 resolve 结果返回的是数组。例如：

```javascript
AV.Promise.all([
  timerPromisefy(1),
  timerPromisefy(32),
  timerPromisefy(64),
  timerPromisefy(128)
]).then(function (values) {
  //values 数组为 [1, 32, 64, 128]
});
//测试下失败的例子
AV.Promise.all([
  timerPromisefy(1),
  timerPromisefy(32),
  AV.Promise.error('test error'),
  timerPromisefy(128)
]).then(function () {
  //不会执行
}, function(error){
  console.dir(error);  //print 'test error'
});

//http://jsplay.avosapps.com/zuy/embed?js,console
```

### race 方法

`AV.Promise.race` 方法接收一个 promise 数组输入，当这组 promise 中的任何一个 promise 对象如果变为 resolve 或者 reject 的话， 该函数就会返回，并使用这个 promise 对象的值进行 resolve 或者 reject。`race`，顾名思义就是在这些 promise 赛跑，谁先执行完成，谁就先 resolve。

```javascript
var p1 = AV.Promise.as(1);
var p2 = AV.Promise.as(2);
var p3 = AV.Promise.as(3);
Promise.race([p1, p2, p3]).then(function (value) {
  // 打印 1
  console.log(value);
});
```

### 创建异步方法

有了上面这些工具以后，就很容易创建你自己的异步方法来返回 promise 了。譬如，你可以创建一个有 promise 版本的 setTimeout：

```javascript
var delay = function(millis) {
  var promise = new AV.Promise();
  setTimeout(function() {
    promise.resolve();
  }, millis);
  return promise;
};

delay(100).then(function() {
  // This ran after 100ms!
});
```

### 兼容性

在非 node.js 环境（例如浏览器环境）下，`AV.Promise` 并不兼容 [Promises/A+](https://promisesaplus.com/) 规范，特别是错误处理这块。
如果你想兼容，可以手工启用：

```javascript
AV.Promise.setPromisesAPlusCompliant(true);
```

在 node.js 环境下如果启用兼容 Promises/A+， 可能在一些情况下 promise 抛出的错误无法通过 `process.on('uncaughtException')` 捕捉，你可以启用额外的 debug 日志：

```javascript
AV.Promise.setDebugError(true);
```

默认日志是关闭的。

### JavaScript Promise 迷你书

如果你想更深入地了解和学习 Promise，我们推荐[《JavaScript Promise迷你书（中文版）》](http://liubin.github.io/promises-book/)这本书。


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

`AV.User` 是用来描述一个用户的特殊对象，与之相关的数据都保存在 `_User` 数据表中。

### 用户的属性

#### 默认属性
用户名、密码、邮箱是默认提供的三个属性，访问方式如下：



```js
  AV.User.logIn('Tom', 'cat!@#123').then(function (loginedUser) {
    console.log(loginedUser);
    var username = loginedUser.getUsername();
    var email = loginedUser.getEmail();
    // 请注意，密码不会明文存储在云端，因此密码只能重置，不能查看
  }, function (error) {
  });
```


请注意代码中，密码是仅仅是在注册的时候可以设置的属性（这部分代码可参照 [用户名和密码注册](#用户名和密码注册)），它在注册完成之后并不会保存在本地（SDK 不会以明文保存密码这种敏感数据），所以在登录之后，再访问密码这个字段是为**空的**。

#### 自定义属性
用户对象和普通对象一样也支持添加自定义属性。例如，为当前用户添加年龄属性：



```js
  AV.User.logIn('Tom', 'cat!@#123').then(function (loginedUser) {
    loginedUser.set('age', 25);
    loginedUser.save();
  }, function (error) {
    // 失败了
    console.log(error);
  });
```


#### 属性的修改

很多开发者都有这样的疑问：为什么我不能修改任意一个用户的属性？原因如下。

> 很多时候，就算是开发者也不要轻易修改用户的基本信息，例如用户的手机号、社交账号等个人信息都比较敏感，应该由用户在 App 中自行修改。所以为了保证用户的数据仅在用户自己已登录的状态下才能修改，云端对所有针对 `AV.User` 对象的数据操作都要做验证。

假如，刚才我们为当前用户添加了一个 age 属性，现在我们来修改它：



```js
  AV.User.logIn('Tom', 'cat!@#123').then(function (loginedUser) {
    // 25
    console.log(loginedUser.get('age'));
    loginedUser.set('age', 18);
    return loginedUser.save();
  }).then(function(loginedUser) {
    // 18
    console.log(loginedUser.get('age'));
  }).catch(function(error) {
    // 失败了
    console.log(error);
  });
```


细心的开发者应该已经发现 `AV.User` 在自定义属性上的使用与一般的 `AV.Object` 没本质区别。

### 注册





#### 手机号码登录

一些应用为了提高首次使用的友好度，一般会允许用户浏览一些内容，直到用户发起了一些操作才会要求用户输入一个手机号，而云端会自动发送一条验证码的短信给用户的手机号，最后验证一下，完成一个用户注册并且登录的操作，例如很多团购类应用都有这种用户场景。

首先调用发送验证码的接口：



```js
  AV.Cloud.requestSmsCode('13577778888').then(function (success) {
  }, function (error) {
  });
```


然后在 UI 上给与用户输入验证码的输入框，用户点击登录的时候调用如下接口：



```js
  AV.User.signUpOrlogInWithMobilePhone('13577778888', '123456').then(function (success) {
    // 成功
  }, function (error) {
    // 失败
  });
```


#### 用户名和密码注册

采用「用户名 + 密码」注册时需要注意：密码是以明文方式通过 HTTPS 加密传输给云端，云端会以密文存储密码，并且我们的加密算法是无法通过所谓「彩虹表撞库」获取的，这一点请开发者放心。换言之，用户的密码只可能用户本人知道，开发者不论是通过控制台还是 API 都是无法获取。另外我们需要强调<u>在客户端，应用切勿再次对密码加密，这会导致重置密码等功能失效</u>。

例如，注册一个用户的示例代码如下（用户名 `Tom` 密码 `cat!@#123`）：



```js
  // 新建 AVUser 对象实例
  var user = new AV.User();
  // 设置用户名
  user.setUsername('Tom');
  // 设置密码
  user.setPassword('cat!@#123');
  // 设置邮箱
  user.setEmail('tom@leancloud.cn');
  user.signUp().then(function (loginedUser) {
      console.log(loginedUser);
  }, (function (error) {
  }));
```



我们建议在可能的情况下尽量使用异步版本的方法，这样就不会影响到应用程序主 UI 线程的响应。


如果注册不成功，请检查一下返回的错误对象。最有可能的情况是用户名已经被另一个用户注册，错误代码 [202](error_code.html#_202)，即 `_User` 表中的 `username` 字段已存在相同的值，此时需要提示用户尝试不同的用户名来注册。同样，邮件 `email` 和手机号码 `mobilePhoneNumber` 字段也要求在各自的列中不能有重复值出现，否则会出现 [203](error_code.html#_203)、[214](error_code.html#_214) 错误。

开发者也可以要求用户使用 Email 做为用户名注册，即在用户提交信息后将 `_User` 表中的 `username` 和 `email` 字段都设为相同的值，这样做的好处是用户在忘记密码的情况下可以直接使用「[邮箱重置密码](#重置密码)」功能，无需再额外绑定电子邮件。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。


#### 第三方账号登录

为了简化用户注册的繁琐流程，许多应用都在登录界面提供了第三方社交账号登录的按钮选项，例如微信、QQ、微博、豆瓣、Twitter、FaceBook 等，以此来提高用户体验。LeanCloud 封装的 AV.User 对象也支持通过第三方账号的 accessToken 信息来创建一个用户。例如，使用微信授权信息创建 AV.User 的代码如下：

```js
  AV.User.signUpOrlogInWithAuthData({
      "openid": "oPrJ7uM5Y5oeypd0fyqQcKCaRv3o",
      "access_token": "OezXcEiiBSKSxW0eoylIeNFI3H7HsmxM7dUj1dGRl2dXJOeIIwD4RTW7Iy2IfJePh6jj7OIs1GwzG1zPn7XY_xYdFYvISeusn4zfU06NiA1_yhzhjc408edspwRpuFSqtYk0rrfJAcZgGBWGRp7wmA",
      "expires_at": "2016-01-06T11:43:11.904Z"
  }, 'weixin').then(function (s) {
  }, function (e) {

  });
```

其他的平台可以参考如上代码。



#### 设置手机号码

微信、陌陌等流行应用都会建议用户将账号和一个手机号绑定，这样方便进行身份认证以及日后的密码找回等安全模块的使用。我们也提供了一整套发送短信验证码以及验证手机号的流程，这部分流程以及代码演示请参考 [JavaScript 短信服务使用指南](sms_guide-js.html#注册验证)。

#### 验证邮箱

许多应用会通过验证邮箱来确认用户注册的真实性。如果在 [应用控制台 > 应用设置 > 应用选项](https://leancloud.cn/app.html?appid={{appid}}#/permission) 中勾选了 **用户注册时，发送验证邮件**，那么当一个 `AVUser` 在注册时设置了邮箱，云端就会向该邮箱自动发送一封包含了激活链接的验证邮件，用户打开该邮件并点击激活链接后便视为通过了验证。有些用户可能在注册之后并没有点击激活链接，而在未来某一个时间又有验证邮箱的需求，这时需要调用如下接口让云端重新发送验证邮件：



```js
  AV.User.requestEmailVerfiy('abc@xyz.com').then(function (result) {
      console.log(JSON.stringify(result));
  }, function (error) {
      console.log(JSON.stringify(error));
  });
```


### 登录

我们提供了多种登录方式，以满足不同场景的应用。



#### 用户名和密码登录



```js
  AV.User.logIn('Tom', 'cat!@#123').then(function (loginedUser) {
    console.log(loginedUser);
  }, function (error) {
  });
```


#### 手机号和密码登录

请确保已详细阅读了 [JavaScript 短信服务使用指南](sms_guide-js.html#注册验证) 这一小节的内容，才可以顺利理解手机号匹配密码登录的流程以及适用范围。

用户的手机号只要经过了验证，就可以使用手机号密码登录的功能，否则登录会失败。



```js
  AV.User.logInWithMobilePhone('13577778888', 'cat!@#123').then(function (loginedUser) {
      console.log(loginedUser);
  }, (function (error) {
  }));
```


#### 手机号和验证码登录

中国电信、中国联通、中国移动，这三大运营商的官网均支持「手机号 + 密码」和「手机号 + 随机验证码」的登录方式，我们也提供了这些方式。

首先，调用发送登录验证码的接口：



```js
AV.User.requestLoginSmsCode('13577778888').then(function (success) {
  }, function (error) {
  });
```


然后在界面上引导用户输入收到的 6 位短信验证码：



```js
  AV.User.logInWithMobilePhoneSmsCode('13577778888', '238825').then(function (success) {
  }, function (error) {
  });
```



#### 当前用户

打开微博或者微信，它不会每次都要求用户都登录，这是因为它将用户数据缓存在了客户端。
同样，只要是调用了登录相关的接口，LeanCloud SDK 都会自动缓存登录用户的数据。
例如，判断当前用户是否为空，为空就跳转到登录页面让用户登录，如果不为空就跳转到首页：



```js
  var currentUser = AV.User.current();
  if (currentUser) {
     // 跳转到首页
  }
  else {
     //currentUser 为空时，可打开用户注册界面…
  }
```



如果不调用 [登出](#登出) 方法，当前用户的缓存将永久保存在客户端。


#### SessionToken

所有登录接口调用成功之后，云端会返回一个 SessionToken 给客户端，客户端在发送 HTTP 请求的时候，JavaScript SDK 会在 HTTP 请求的 Header 里面自动添加上当前用户的 SessionToken 作为这次请求发起者 `AV.User` 的身份认证信息。

如果在控制台的 [应用选项](/app.html?appid={{appid}}#/permission) 中勾选了 **密码修改后，强制客户端重新登录**，那么当用户密码再次被修改后，已登录的用户对象就会失效，开发者需要使用更改后的密码重新调用登录接口，使 SessionToken 得到更新，否则后续操作会遇到 [403 (Forbidden)](error_code.html#_403) 的错误。

#### 账户锁定

输入错误的密码或验证码会导致用户登录失败。如果在 15 分钟内，同一个用户登录失败的次数大于 6 次，该用户账户即被云端暂时锁定，此时云端会返回错误码 `{"code":1,"error":"登录失败次数超过限制，请稍候再试，或者通过忘记密码重设密码。"}`，开发者可在客户端进行必要提示。

锁定将在最后一次错误登录的 15 分钟之后由云端自动解除，开发者无法通过 SDK 或 REST API 进行干预。在锁定期间，即使用户输入了正确的验证信息也不允许登录。这个限制在 SDK 和云引擎中都有效。

### 重置密码

#### 邮箱重置密码

我们都知道，应用一旦加入账户密码系统，那么肯定会有用户忘记密码的情况发生。对于这种情况，我们为用户提供了一种安全重置密码的方法。

重置密码的过程很简单，用户只需要输入注册的电子邮件地址即可：



```js
  AV.User.requestPasswordReset('myemail@example.com').then(function (success) {
  }, function (error) {
  });
```


密码重置流程如下：

1. 用户输入注册的电子邮件，请求重置密码；
2. LeanStorage 向该邮箱发送一封包含重置密码的特殊链接的电子邮件；
3. 用户点击重置密码链接后，一个特殊的页面会打开，让他们输入新密码；
4. 用户的密码已被重置为新输入的密码。

关于自定义邮件模板和验证链接，请参考《[自定义应用内用户重设密码和邮箱验证页面](https://blog.leancloud.cn/607/)》。

#### 手机号码重置密码



与使用 [邮箱重置密码](#邮箱重置密码) 类似，「手机号码重置密码」使用下面的方法来获取短信验证码：



```js
  AV.User.requestPasswordResetBySmsCode('18612340000').then(function (success) {
  }, function (error) {
  });
```


注意！用户需要先绑定手机号码，然后使用短信验证码来重置密码：



```js
  AV.User.resetPasswordBySmsCode('123456', 'thenewpassword').then(function (success) {
  }, function (error) {
  });
```


#### 登出

用户登出系统时，SDK 会自动清理缓存信息。



```js
  AV.User.logOut();
  // 现在的 currentUser 是 null 了
  var currentUser = AV.User.current();
```



### 用户的查询
请注意，**新创建的应用的用户表 `_User` 默认关闭了查询权限**。你可以通过 Class 权限设置打开查询权限，请参考 [数据与安全 · Class 级别的权限](data_security.html#Class_级别的_ACL)。我们推荐开发者在 [云引擎](leanengine_overview.html) 中封装用户查询，只查询特定条件的用户，避免开放用户表的全部查询权限。

查询用户代码如下：


```js
  var query = new AV.Query('_User');
```


### 浏览器中查看用户表

用户表是一个特殊的表，专门存储用户对象。在浏览器端，你会看到一个 `_User` 表。

## 角色
关于用户与角色的关系，我们有一个更为详尽的文档介绍这部分的内容，并且针对权限管理有深入的讲解，详情请点击 [JavaScript 权限管理使用指南](acl_guide-js.html)。




## 应用内搜索
应用内搜索是一个针对应用数据进行全局搜索的接口，它基于搜索引擎构建，提供更强大的搜索功能。要深入了解其用法和阅读示例代码，请阅读 [JavaScript 应用内搜索指南](app_search_guide.html)。



## 应用内社交
应用内社交，又称「事件流」，在应用开发中出现的场景非常多，包括用户间关注（好友）、朋友圈（时间线）、状态、互动（点赞）、私信等常用功能，请参考 [JavaScript 应用内社交模块](status_system.html#JavaScript_SDK)。







## Push 通知

通过 JavaScript SDK 也可以向移动设备推送消息，使用也非常简单。

如果想在 Web 端独立使用推送模块，包括通过 Web 端推送消息到各个设备、以及通过 Web 端也可以接收其他端的推送，可以了解下我们的 [JavaScript 推送 SDK 使用指南](./js_push.html) 来获取更详细的信息。

一个简单例子推送给所有订阅了 `public` 频道的设备：

```javascript
AV.Push.send({
  channels: [ 'Public' ],
  data: {
    alert: 'Public message'
  }
});
```

这就向订阅了 `public` 频道的设备发送了一条内容为 `public message` 的消息。

如果希望按照某个 `_Installation` 表的查询条件来推送，例如推送给某个 `installationId` 的 Android 设备，可以传入一个 `AV.Query` 对象作为 `where` 条件：

```javascript
var query = new AV.Query('_Installation');
query.equalTo('installationId', installationId);
AV.Push.send({
  where: query,
  data: {
    alert: 'Public message'
  }
});
```

此外，如果你觉得 AV.Query 太繁琐，也可以写一句 [CQL](./cql_guide.html) 来搞定：

```javascript
AV.Push.send({
  cql: 'select * from _Installation where installationId="设备id"',
  data: {
    alert: 'Public message'
  }
});
```

`AV.Push` 的更多使用信息参考 API 文档 [AV.Push](/api-docs/javascript/symbols/AV.Push.html)。更多推送的查询条件和格式，请查阅 [消息推送指南](./push_guide.html)。

iOS 设备可以通过 `prod` 属性指定使用测试环境还是生产环境证书：

```javascript
AV.Push.send({
  prod: 'dev',
  data: {
    alert: 'Public message'
  }
});
```

`dev` 表示开发证书，`prod` 表示生产证书，默认生产证书。



## WebView 中使用

JS SDK 支持在各种 WebView 中使用（包括 PhoneGap/Cordova、微信 WebView 等）。

### Android WebView 中使用

如果是 Android WebView，在 Native 代码创建 WebView 的时候你需要打开几个选项，
这些选项生成 WebView 的时候默认并不会被打开，需要配置：

1. 因为我们 JS SDK 目前使用了 window.localStorage，所以你需要开启 WebView 的 localStorage：

  ```java
  yourWebView.getSettings().setDomStorageEnabled(true);
  ```
2. 如果你希望直接调试手机中的 WebView，也同样需要在生成 WebView 的时候设置远程调试，具体使用方式请参考 [Google 官方文档](https://developer.chrome.com/devtools/docs/remote-debugging)。

  ```java
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      yourWebView.setWebContentsDebuggingEnabled(true);
  }
  ```

  注意：这种调试方式仅支持 Android 4.4 已上版本（含 4.4）
3. 如果你是通过 WebView 来开发界面，Native 调用本地特性的 Hybrid 方式开发你的 App。比较推荐的开发方式是：通过 Chrome 的开发者工具开发界面部分，当界面部分完成，与 Native 再来做数据连调，这种时候才需要用 Remote debugger 方式在手机上直接调试 WebView。这样做会大大节省你开发调试的时间，不然如果界面都通过 Remote debugger 方式开发，可能效率较低。
4. 为了防止通过 JavaScript 反射调用 Java 代码访问 Android 文件系统的安全漏洞，在 Android 4.2 以后的系统中间，WebView 中间只能访问通过 [@JavascriptInterface](http://developer.android.com/reference/android/webkit/JavascriptInterface.html) 标记过的方法。如果你的目标用户覆盖 4.2 以上的机型，请注意加上这个标记，以避免出现 **Uncaught TypeError**。

