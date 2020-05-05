package com.xap.voicetranslate;

public class Constant {
    public static int AUDIO_RATE = 16000;
    public static final String APP_ID = "xapaccount-1385487646";
    public static final String APP_SECRET = "b1603e2fad947fc1a560e1f4bb7ffd589f2fbd785ca5176758ec0c9834ac4e3f";
    public static final String WSS_URL = "wss://api.xap.sinicloud.com:16443/v1/xap/?appID=%1s&salt=%2s" +
            "&timestamp=%3s&sign=%4s&from=%5s&to=%6s&rate=%7s";
    public static final String IN_FILE = "./xap-audio/en-US-female.pcm";
    public static final String OUT_FILE = "./xap-audio/output/";
    public static final String FROM = "en-US";
    public static final String TO = "zh";

}
