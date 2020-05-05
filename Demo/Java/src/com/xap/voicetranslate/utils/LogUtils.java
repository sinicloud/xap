package com.xap.voicetranslate.utils;

public class LogUtils {
    private static final String TAG = "xap";
    public static boolean logOn = false;
    public static void d(String detail){
        if (logOn){
            System.out.println(TAG+detail);
        }
    }
}
