# 基于 Swift 的 XAP 客户端 Demo

基于 Swft 的声云实时语音翻译 Web API 的客户端 Demo 实现。

## 支持平台

- MacOS 10.15+

## 依赖

| 依赖包     | 版本        |
| --------- | ---------- |
| Swift    | &gt;=5.2 |
| Xcode | &gt;=11.4 |

**其他 Swift 依赖包由 Xcode 自动下载配置。**

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
        "input": "en-US-female.pcm",
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
| audio.sample-rate      | Number | 是  | 音频采样率 |
| audio.from             | String | 是  | 源语言（遵循 [BCP47](https://github.com/sinicloud/xap#%E9%99%84%E5%BD%95%E4%B8%80%E6%94%AF%E6%8C%81%E7%9A%84%E8%AF%AD%E8%A8%80)） |
| <span>audio.to</span>  | String | 是  | 目标语言（遵循 [BCP47](https://github.com/sinicloud/xap#%E9%99%84%E5%BD%95%E4%B8%80%E6%94%AF%E6%8C%81%E7%9A%84%E8%AF%AD%E8%A8%80)） |

## 运行

在 Xcode 中，打开项目、下载依赖库并运行程序。

## 文档

[Web API 文档](https://github.com/sinicloud/xap/blob/master/README.md)
