# XAP Sample Client for Node.js

## Introduction

This package is an implementation of XOrange Audio Project (XAP) client based on Node.js, which is also a example of customizing your own client for Web API.

##  Requirement

| Package | Version      |
| ------- | ------------ |
| Node.js | &gt;=10.11.0 |

## Configuration

You need to edit 'configuration.json' before running this program. Here is a configuration template (replace fields with your own configuration):

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
        "sample-rate": 16000,
        "from": "en-US",
        "to": "zh"
    }
}
```

| Key               | Type   | Optional | Description |
| ----------------- | ------ | -------- | ----------- |
| xap               | Object | N        | This XAP account. | 
| xap.appid         | String | N        | The APPID previously applied for. |
| xap.appsecret     | String | N        | The APP key previously applied for. |
| ws                | Object | N        | WebSocket connection. |
| ws.url            | String | N        | Connection URL. | 
| audio             | Object | N        | Audio parameters. |
| audio.input       | String | N        | Address of audio file as input. |
| audio.sample-rate | Number | N        | Sample rate of audio file. |
| audio.from        | String | N        | Language code of input audio. (based on BCP47) |
| <span>audio.to</span> | String | N    | Language code of output audio. (based on BCP47) |

## Running

Then, you can run this program in your terminal, like:

```
node main.js
```

##  Document

WebAPI document is [here](https://github.com/sinicloud/xap/blob/master/README.md)
