# 基于 Node.js 的 XAP 示例客户端

基于 Node.js 的声云实时语音翻译 Web API 的客户端 Demo 实现。

##  依赖

| 依赖     | 版本         |
| ------- | ------------ |
| Node.js | &gt;=10.11.0 |

下载该项目后，在项目目录中运行以下命令安装依赖包：

```
npm install
```

或者 

```
npm ci
```

## 配置

在运行该程序之前，需要先编辑 'configuration.json' 文件，以下是一个配置的样例（用您自己的配置替换对应字段）：

```json
{
    "xap": {
        "appid": "xxx",
        "appsecret": "xxx"
    },
    "ws": {
        "url": "wss://api.xap.sinicloud.com:16443/v1/xap/"
    },
    "audio": {
        "input": "./en-US-female.pcm",
        "output": "./output.wav",
        "sample-rate": 16000,
        "from": "en-US",
        "to": "zh"
    }
}
```

| 键                      | 类型   | 必须 | 描述 |
| ---------------------- | ------ | --- | ---- |
| xap                    | Objecg | 是  | XAP 账户配置 |
| xap.appid              | String | 是  | 已申请的 APPID |
| xap.appsecret          | String | 是  | 已申请的 APP 密钥 |
| ws                     | Object | 是  | WebSocket 配置 |
| ws.url                 | String | 是  | 目的 URL |
| audio                  | Object | 是  | 音频配置 |
| audio.input            | String | 是  | 作为输入的音频文件的路径 |
| audio.output           | String | 否  | 作为输出的音频文件的路径 |
| audio.sample-rate      | Number | 是  | 音频采样率 |
| audio.from             | String | 是  | 源语言（遵循 BCP46） |
| <span>audio.to</span>  | String | 是  | 目标语言（遵循 BCP46） |

**注：输入音频格式为 Web API 文档所规定的 PCM 原始数据，输出音频格式则为可播放的 WAV。**

## 运行

在终端使用以下命令运行程序：

```
node main.js
```

## 文档

[Web API 文档](https://github.com/sinicloud/xap/blob/master/README.md)
