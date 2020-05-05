# 基于 Java 的 XAP 客户端 Demo

基于 Java 的声云实时语音翻译 Web API 的客户端 Demo 实现。

## 运行环境

Java&gt;=8

## 第三方依赖

| 依赖包     | 版本        |
| --------- | ---------- |
| okhttp    | &gt;=3.12.0 |
| okio | &gt;=2.6.0 |
| fastjson | &gt;=1.2.68 |

**依赖包通过maven配置，案例（pom.xml）如下：**
````xml
  <dependencies>
   <dependency>
     <groupId>com.squareup.okio</groupId>
     <artifactId>okio</artifactId>
     <version>2.6.0</version>
   </dependency>
   <dependency>
    <groupId>com.squareup.okhttp3</groupId>
    <artifactId>okhttp</artifactId>
    <version>3.12.0</version>
    <exclusions>
      <exclusion>
        <groupId>com.google.android</groupId>
        <artifactId>android</artifactId>
      </exclusion>
    </exclusions>
   </dependency>
   <dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.68</version>
   </dependency>
  </dependencies>
````

## 配置

在运行该程序之前，需要先编辑 'Constant.java' 文件，以下是一个配置的样例（用您自己的配置替换对应变量）：

```java
    public static final int AUDIO_RATE = 16000;
    public static final String APP_ID = "xapaccount-1385487646";
    public static final String APP_SECRET = "b1603e2fad947fc1a560e1f4bb7ffd589f2fbd785ca5176758ec0c9834ac4e3f";
    public static final String WSS_URL = "wss://api.xap.sinicloud.com:16443/v1/xap/?appID=%1s&salt=%2s" +
            "&timestamp=%3s&sign=%4s&from=%5s&to=%6s&rate=%7s";
    public static final String IN_FILE = "./xap-audio/en-US-female.pcm";
    public static final String OUT_FILE = "./xap-audio/output/";
    public static final String FROM = "en-US";
    public static final String TO = "zh";
```

| 键                      | 类型   | 必须 | 描述 |
| ---------------------- | ------ | --- | ---- |
| APP_ID              | String | 是  | 已申请的 APPID |
| APP_SECRET          | String | 是  | 已申请的 APP 密钥 |
| WSS_URL                 | String | 是  | 目的 URL|
| IN_FILE            | String | 是  | 作为输入的音频文件的路径 |
| OUT_FILE            | String | 是  | 作为输出的音频文件的路径 |
| AUDIO_RATE      | int | 是  | 音频采样率 |
| FROM             | String | 是  | 源语言（遵循 BCP46） |
| TO  | String | 是  | 目标语言（遵循 BCP46） |

## 运行

将项目导入支持maven project的IDE如Eclipse/IDEA/VSCode中，编译后运行Test.java文件即可。

## 文档

[Web API 文档](https://github.com/sinicloud/xap/blob/master/README.md)
