# 声云实时语音翻译 Web API 文档

## 一、接口简介
声云实时语音翻译 Web API 接口，可实现对音频流进行实时多语言语音转语音翻译。


## 二、接口要求

集成声云实时语音翻译 Web API 时，需按照以下要求：


| 内容        | 说明                                 |
| --------- | ---------------------------------- |
| 请求协议      | wss                             |
| 字符编码      | UTF-8                              |
| 请求/响应数据格式 | JSON                               |
| 音频属性      | 采样率为 8K 到 55K（推荐 8K、16K、44100）、采样精度 16 bit、单声道 |
| 音频格式| pcm|
| 音频长度|最长 3 分钟|
| 超时        | 当 16s 内没有数据互相传输时，服务端将断开连接        |

## 三、接口调用
### 3.1 接口调用流程简介

接口调用分为以下 2 阶段：
1. 认证阶段：使用 WebSocket 协议向服务端发起认证请求，在请求参数中添加签名和其他查询参数。
2. 实时音频流数据传输阶段：
    - 将音频流数据以 JSON 格式上传至服务端，并接收服务端推送的实时文本和音频结果。
    - 音频流数据上传完毕后，上传一次结束标志，等待服务端推送的全部结果返回后断开 WebSocket 连接。

### 3.2 认证
使用 WebSocket 协议向服务端发起认证请求，在请求参数中添加签名和其他参数。

#### 请求地址
```
wss://api.xap.sinicloud.com:16808/v1/xap/?{请求参数}
```

#### 请求参数格式
```
key1=value1&key2=value2&key3=value3&key4=value4
```

#### 请求示例
```
wss://api.xap.sinicloud.com:16808/v1/xap/?appID=anfwxxx01&salt=5fQUr0z4jOMt&timestamp=1588347032185&sign=267a098e2c69ced7f8e27fd2c64bc4c176c64386dc325c90528ca3f58fbe1ec7&from=zh&to=en-US
```


#### 请求参数说明


| 参数          | 类型     | 必须  | 说明                                    |
| ----------- | ------ | --- | ------------------------------------- |
| appID       | String | 是   | 已申请的应用 ID                        |
| salt        | String | 是   | 随机字符串，用于签名验证，长度在 4 到 64 之间           |
| timestamp   | String | 是   | 当前时间戳，单位毫秒。必须为标准协调世界时（UTC），服务端会对 timestamp 进行时钟偏移检查，最大允许 3 分钟的偏差，超出偏差的请求都将被拒绝                        |
| sign        | String | 是   | 签名，用于验证连接的合法性。sign 的生成见[签名生成](####签名生成)                     |
| from        | String | 是   | 源语言选择，BCP47 编码，支持语言见[附录一](#附录一：支持的语言)  |
| to          | String | 是   | 目标语言选择，BCP47 编码，支持语言见[附录一](#附录一：支持的语言) |
| rate | String | 是   | 上传音频和合成音频的采样率。如 16000               |


#### 签名生成

签名 sign 的原始字段由 appID、salt、timestamp、appSecret（已申请的应用密钥）按照顺序拼接而成，将拼接成的原始字段通过 Sha256 哈希计算可得签名 sign 的值。

示例如下（Node.js 代码）：
```
let appID = "xxx";
let salt = "xxx";
let timestamp = Date.now().toString();
let appSecret = "";

let sign = Crypto.createHash("sha256")
                 .update(appID + salt + timestamp + appSecret)
                 .digest("hex");

```

假设：

```
appID = anfwxxx015
salt = fQUr0z4jOMt
timestamp = 1588347032185
appSecret = TorbvHDGFmUmoGCOzE6GwyJOsSHytzBRlxWpi5gaD+0PbJQFewWMpr1p4BrlCTHo

```

则 sign 为：

```
sign = 267a098e2c69ced7f8e27fd2c64bc4c176c64386dc325c90528ca3f58fbe1ec7

```


### 3.3 实时音频流数据传输

认证成功后，客户端与服务端会建立 WebSocket 连接，客户端通过 WebSocket 连接可以同时上传和接收数据。当服务端有识别结果时，会通过 WebSocket 连接推送识别出的文字和音频结果到客户端。


#### 3.3.1 音频数据上传

音频数据通过 JSON 格式上传到服务端，客户端需要将音频数据通过 Base64 编码成可打印字符，并构建成合法的 JSON 格式上传。

注意：单个 JSON 的大小应小于 65535 字节。


业务数据流示例：

```
{
    "type": "audio",
    "data": {
        "audio": ""xjt+pq7bDxlo9XrQ+vI7XApFAyeTorbvHDGi..."
    }
}

```

业务数据流参数说明：

| 参数名  | 类型     | 必须  | 描述                 |
| ---- | ------ | --- | ------------------ |
| type | String | 是   | 类型描述，值为“audio”   |
| data | Object | 是   | 音频数据信息 |
| data.audio | String | 是 | 音频数据，采用 Base64 编码 |

<b>音频数据上传结束</b>

当最后一帧音频数据发送完毕后，客户端需要通知服务端所有音频上传完毕，此时应构建如下 JSON 并发送给服务器。

```
{
    "type": "audio/end"
}

```

业务数据流参数说明：

| 参数名  | 类型     | 必须  | 描述                  |
| ---- | ------ | --- | ------------------- |
| type | String | 是   | 类型描述，值为 "audio/end"。 |

#### 3.3.2 源语言文本结果返回

当服务端有源语言文本结果传回客户端时，将构建如下格式 JSON 并发送给客户端：

```
{
    "type": "origin",
    "data": {
        "is-final": false,
        "sentence": "你好" 
    }
}

```

返回参数说明：

| 参数名         | 类型     | 必须 | 描述                 |
| ------------- | ------- | --- | ------------------ |
| type          | String  | 是   | 类型描述，值为 "origin"|
| data          | Object  | 是   | 源语言文本结果信息           |
| data.is-final | Boolean | 是   | 是否为完整单句         |
| data.sentence | String  | 是   | 源语言文本结果，采用 UTF-8 编码 |



><span id="jump1">在用户界面上实时显示源语言文本结果的小提示。</span>
>
>当客户端与服务器建立连接后，可以在连接上下文内存储两个字符串：
>```
> S1 = ""
> S2 = ""
>```
>
>
>当客户端收到该 JSON 后，可以按如下逻辑生成实时文本结果：
>
>```
>IF  是完整单句  THEN
>    S1 += 文本数据
>    S2 = ""
>ELSE
>    S2 = 文本数据
>END IF
>实时结果为 S1 + S2
>```
>
>下面是一个客户端收到该 JSON 时构建当前实时结果逻辑的样例：
>
>| 收到的文本数据    | 是否为完整单句 | 当前实时结果  |
>| --------------- | ----------- | ----------- |
>| 你              | 否          | 你           |
>| 你好            | 否          | 你好        |
>| 你好            | 是          | 你好        |
>| 今天            | 否          | 你好今天 |
>| 今天天气         | 否          | 你好今天天气 |
>| 今天天气怎么样   | 是          | 你好今天天气怎么样 |

<b>源语言文本结果返回结束</b>

当服务端已发送完所有源语言文本数据，服务端会向客户端发送如下 JSON：

```
{
    "type": "origin/end"
}

```

返回参数说明：

| 参数名  | 类型     | 必须  | 描述                   |
| ---- | ------ | --- | -------------------- |
| type | String | 是   | 类型描述，值为 "origin/end"|

#### 3.3.3 目标语言文本结果返回

当服务端有目标语言文本结果需要传回客户端时，将向客户端发送如下格式的 JSON：

```
{
    "type": "translation",
    "data": {
        "is-final": false,
        "sentence": "Hello"
    }
}

```

返回参数说明：

| 参数名         | 类型      | 必须  | 描述                    |
| ------------- | ------- | --- | --------------------- |
| type          | String  | 是   | 类型描述，值为 "translation" |
| data          | Object  | 是   | 目标语言文本结果信息            |
| data.is-final | Boolean | 是   | 是否为完整单句               |
| data.sentence | String  | 是   | 目标语言文本结果，采用 UTF-8 编码   |

>就像[在用户界面上实时显示源语言的文本结果](#jump1)一样，我们也可以在用户界面上按照相同的逻辑实时显示目标语言的文本结果。
>
>下面是一个客户端收到该 JSON 时构建当前实时结果逻辑的样例：
>
>| 收到的文本数据                  | 是否为完整单句 | 当前实时结果  |
>| ----------------------------- | ----------- | ----------- |
>| Ha                            | 否          | Ha           |
>| Hello                         | 否          | Hello        |
>| Hello                         | 是          | Hello        |
>| Today                         | 否          | Hello Toady |
>| Today's weather               | 否          | Hello Toady's weather |
>| What's the weather like today | 是          | Hello What's the weather like today |


<b>目标语言文本结果返回结束</b>

当服务端发送完所有目标语言文本结果，服务端会向客户端发送如下 JSON：

```
{
    "type": "translation/end"
}

```

返回参数说明：

| 参数名  | 类型     | 必须  | 描述                        |
| ---- | ------ | --- | ------------------------- |
| type | String | 是   | 类型描述，值为 "translation/end"|

#### 3.3.4 合成音频结果返回

当服务端有目标语言的合成音频数据待传回时，服务端会将该音频数据通过 Base64 进行编码，并构建如下格式 JSON 发送给客户端：

```
{
    "type": "audio",
    "data": {
        "audio": "yZNUKi3zLdIIMEeEyrZ0LprlCTHoet+DIA6BJk3Ab6svj..."
    }
}

```

返回参数说明：

| 参数名      | 类型    | 必须  | 描述                   |
| ---------- | ------ | --- | -------------------- |
| type       | String | 是   | 类型描述，值为 "audio"     |
| data       | Object | 是   | 音频数据信息        |
| data.audio | String | 是   | 目标语言的音频合成数据，Base64 编码|

<b>一条完整的目标语言单句的音频数据返回结束</b>

当服务端已传回一条完整的目标语言单句的音频数据时，服务端会向客户端发送如下 JSON：

```
{
    "type": "audio/flush"
}
```

返回参数说明：

| 参数名  | 类型     | 必须  | 描述                  |
| ---- | ------ | --- | ------------------- |
| type | String | 是   | 类型描述，值为 "audio/flush" |

<b>目标语言的合成音频结果返回结束</b>

当服务端已经发送完所有目标语言的合成音频数据，服务端会向客户端发送如下 JSON：

```
{
    "type": "audio/end"
}

```

返回参数说明：

| 参数名  | 类型     | 必须  | 描述                  |
| ---- | ------ | --- | ------------------- |
| type | String | 是   | 类型描述，值为 "audio/end" |

### 3.4 错误处理

本协议的错误码通过 WebSocket 的状态码返回，错误码的描述请见[附录二](#附录二：错误码)。

## 附录一：支持的语言

| \#  | 语言名称           | 对应的 BCP47 编码 |
| --- | -------------- | ------------ |
| 1   | 南非荷兰语（南非）      | af-ZA        |
| 2   | 阿姆哈拉语（埃塞俄比亚）   | am-ET        |
| 3   | 亚美尼亚语（亚美尼亚）    | hy-AM        |
| 4   | 阿塞拜疆语（阿塞拜疆）    | az-AZ        |
| 5   | 印度尼西亚语（印度尼西亚）  | id-ID        |
| 6   | 马来语（马来西亚）      | ms-MY        |
| 7   | 孟加拉语（孟加拉）      | bn-BD        |
| 8   | 孟加拉语（印度）       | bn-IN        |
| 9   | 加泰罗尼亚语（西班牙）    | ca-ES        |
| 10  | 捷克语（捷克共和国）     | cs-CZ        |
| 11  | 丹麦语（丹麦）        | da-DK        |
| 12  | 德语（德国）         | de-DE        |
| 13  | 英语（澳大利亚）       | en-AU        |
| 14  | 英语（加拿大）        | en-CA        |
| 15  | 英语（加纳）         | en-GH        |
| 16  | 英语（英国）         | en-GB        |
| 17  | 英语（印度）         | en-IN        |
| 18  | 英语（爱尔兰）        | en-IE        |
| 19  | 英语（肯尼亚）        | en-KE        |
| 20  | 英语（新西兰）        | en-NZ        |
| 21  | 英语（尼日利亚）       | en-NG        |
| 22  | 英语（菲律宾）        | en-PH        |
| 23  | 英语（新加坡）        | en-SG        |
| 24  | 英语（南非）         | en-ZA        |
| 25  | 英语（坦桑尼亚）       | en-TZ        |
| 26  | 英语（美国）         | en-US        |
| 27  | 西班牙语（阿根廷）      | es-AR        |
| 28  | 西班牙语（玻利维亚）     | es-BO        |
| 29  | 西班牙语（智利）       | es-CL        |
| 30  | 西班牙语（哥伦比亚）     | es-CO        |
| 31  | 西班牙语（哥斯达黎加）    | es-CR        |
| 32  | 西班牙语（厄瓜多尔）     | es-EC        |
| 33  | 西班牙语（萨尔瓦多）     | es-SV        |
| 34  | 西班牙语（西班牙）      | es-ES        |
| 35  | 西班牙语（美国）       | es-US        |
| 36  | 西班牙语（危地马拉）     | es-GT        |
| 37  | 西班牙语（洪都拉斯）     | es-HN        |
| 38  | 西班牙语（墨西哥）      | es-MX        |
| 39  | 西班牙语（尼加拉瓜）     | es-NI        |
| 40  | 西班牙语（巴拿马）      | es-PA        |
| 41  | 西班牙语（巴拉圭）      | es-PY        |
| 42  | 西班牙语（秘鲁）       | es-PE        |
| 43  | 西班牙语（波多黎各）     | es-PR        |
| 44  | 西班牙语（多米尼加共和国）  | es-DO        |
| 45  | 西班牙语（乌拉圭）      | es-UY        |
| 46  | 西班牙语（委内瑞拉）     | es-VE        |
| 47  | 巴斯克语（西班牙）      | eu-ES        |
| 48  | 菲律宾语（菲律宾）      | fil-PH       |
| 49  | 法语（加拿大）        | fr-CA        |
| 50  | 法语（法国）         | fr-FR        |
| 51  | 加利西亚语（西班牙）     | gl-ES        |
| 52  | 格鲁吉亚语（格鲁吉亚）    | ka-GE        |
| 53  | 古吉拉特语（印度）      | gu-IN        |
| 54  | 克罗地亚语（克罗地亚）    | hr-HR        |
| 55  | 祖鲁语（南非）        | zu-ZA        |
| 56  | 冰岛语（冰岛）        | is-IS        |
| 57  | 意大利语（意大利）      | it-IT        |
| 58  | 爪哇语（印度尼西亚）     | jv-ID        |
| 59  | 卡纳达语（印度）       | kn-IN        |
| 60  | 高棉语（柬埔寨）       | km-KH        |
| 61  | 老挝语（老挝）        | lo-LA        |
| 62  | 拉脱维亚语（拉脱维亚）    | lv-LV        |
| 63  | 立陶宛语（立陶宛）      | lt-LT        |
| 64  | 匈牙利语（匈牙利）      | hu-HU        |
| 65  | 马拉雅拉姆语（印度）     | ml-IN        |
| 66  | 马拉地语（印度）       | mr-IN        |
| 67  | 荷兰语（荷兰）        | nl-NL        |
| 68  | 尼泊尔语（尼泊尔）      | ne-NP        |
| 69  | 博克马尔挪威语（挪威）    | nb-NO        |
| 70  | 波兰语（波兰）        | pl-PL        |
| 71  | 葡萄牙语（巴西）       | pt-BR        |
| 72  | 葡萄牙语（葡萄牙）      | pt-PT        |
| 73  | 罗马尼亚语（罗马尼亚）    | ro-RO        |
| 74  | 僧伽罗语（斯里兰卡）     | si-LK        |
| 75  | 斯洛伐克语（斯洛伐克）    | sk-SK        |
| 76  | 斯洛文尼亚语（斯洛文尼亚）  | sl-SI        |
| 77  | 巽他语（印度尼西亚）     | su-ID        |
| 78  | 斯瓦希里语（坦桑尼亚）    | sw-TZ        |
| 79  | 斯瓦希里语（肯尼亚）     | sw-KE        |
| 80  | 芬兰语（芬兰）        | fi-FI        |
| 81  | 瑞典语（瑞典）        | sv-SE        |
| 82  | 泰米尔语（印度）       | ta-IN        |
| 83  | 泰米尔语（新加坡）      | ta-SG        |
| 84  | 泰米尔语（斯里兰卡）     | ta-LK        |
| 85  | 泰米尔语（马来西亚）     | ta-MY        |
| 86  | 泰卢固语（印度）       | te-IN        |
| 87  | 越南语（越南）        | vi-VN        |
| 88  | 土耳其语（土耳其）      | tr-TR        |
| 89  | 乌尔都语（巴基斯坦）     | ur-PK        |
| 90  | 乌尔都语（印度）       | ur-IN        |
| 91  | 希腊语（希腊）        | el-GR        |
| 92  | 保加利亚语（保加利亚）    | bg-BG        |
| 93  | 俄语（俄罗斯）        | ru-RU        |
| 94  | 塞尔维亚语（塞尔维亚）    | sr-RS        |
| 95  | 乌克兰语（乌克兰）      | uk-UA        |
| 96  | 希伯来语（以色列）      | he-IL        |
| 97  | 阿拉伯语（以色列）      | ar-IL        |
| 98  | 阿拉伯语（约旦）       | ar-JO        |
| 99  | 阿拉伯语（阿拉伯联合酋长国） | ar-AE        |
| 100 | 阿拉伯语（巴林）       | ar-BH        |
| 101 | 阿拉伯语（阿尔及利亚）    | ar-DZ        |
| 102 | 阿拉伯语（沙特阿拉伯）    | ar-SA        |
| 103 | 阿拉伯语（伊拉克）      | ar-IQ        |
| 104 | 阿拉伯语（科威特）      | ar-KW        |
| 105 | 阿拉伯语（摩洛哥）      | ar-MA        |
| 106 | 阿拉伯语（突尼斯）      | ar-TN        |
| 107 | 阿拉伯语（阿曼）       | ar-OM        |
| 108 | 阿拉伯语（巴勒斯坦）     | ar-PS        |
| 109 | 阿拉伯语（卡塔尔）      | ar-QA        |
| 110 | 阿拉伯语（黎巴嫩）      | ar-LB        |
| 111 | 阿拉伯语（埃及）       | ar-EG        |
| 112 | 波斯语（伊朗）        | fa-IR        |
| 113 | 印地语（印度）        | hi-IN        |
| 114 | 泰语（泰国）         | th-TH        |
| 115 | 韩语（韩国）         | ko-KR        |
| 116 | 中文（台湾）         | zh-TW        |
| 117 | 中文（香港/粤语）      | yue-Hant-HK  |
| 118 | 中文（香港/普通话）     | zh-HK        |
| 119 | 中文（大陆/普通话）     | zh           |
| 120 | 日语（日本）         | ja-JP        |

## 附录二：错误码

| 错误码  | 描述   | 解决方法 |
| ---- | ---- | ---- |
| 1000 | 正常关闭 |     |
| 1006 | 异常关闭，请检查您的网络连接。 |
| 4001 | 请求不合法  | 请检查请求参数是否正确  |
| 4002 | 时间戳不合法  | 请检查时间戳是否正确|
| 4003 | 签名不合法  | 请检查 appID 和 appSecret是否正确、签名算法是否正确 |
| 4004 | 语言码不合法 | 请检查语言码是否合法 |
| 4005 | 采样率不合法 | 请检查请求参数中的采样率设置 |
| 4008 | JSON 数据不合法 | 请检查发送至服务端的 JSON 是否合法|
| 4012 | 语音识别失败 | 请重新尝试或者联系系统管理员/提交工单 |
| 4013 | 文本翻译失败 | 请重新尝试或者联系系统管理员/提交工单 |
| 4014 | 语音合成失败 | 请重新尝试或者联系系统管理员/提交工单 |
| 4015 | 未知错误 | 请联系系统管理员/提交工单 |
| 4016 | 音频超过最大时长 | 请检查是否上传音频超过 3 分钟 |

**范围在 1000-2999 的错误码为 WebSocket 标准（RFC 6455）规定状态码**

## 附录三：示例代码

- [基于 Node.js 的实时语音翻译 Web API Demo](https://github.com/sinicloud/xap/tree/master/Demo/Node.js)

- [基于 Python 的实时语音翻译 Web API Demo](https://github.com/sinicloud/xap/tree/master/Demo/Python)