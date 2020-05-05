package com.xap.voicetranslate.utils;

/**
 */
public class LanguageMap {
    public static String asrnames[] = new String[]{
            "南非荷兰语",
            "阿姆哈拉语",
            "亚美尼亚语",
            "阿塞拜疆语",
            "印度尼西亚语",
            "马来语",
            "孟加拉语-孟加拉",
            "孟加拉语-印度",
            "加泰罗尼亚语-西班牙",
            "捷克语",
            "丹麦语",
            "德语",
            "英语-澳大利亚",
            "英语-加拿大",
            "英语-加纳",
            "英语-英国",
            "英语-印度",
            "英语-爱尔兰",
            "英语-肯尼亚",
            "英语-新西兰",
            "英语-尼日利亚",
            "英语-菲律宾",
            "英语-新加坡",
            "英语-南非",
            "英语-坦桑尼亚",
            "英语-美国",
            "西班牙语-阿根廷",
            "西班牙语-玻利维亚",
            "西班牙语-智利",
            "西班牙语-哥伦比亚",
            "西班牙语-哥斯达黎加",
            "西班牙语-厄瓜多尔",
            "西班牙语-萨尔瓦多",
            "西班牙语-西班牙",
            "西班牙语-美国",
            "西班牙语-危地马拉",
            "西班牙语-洪都拉斯",
            "西班牙语-墨西哥",
            "西班牙语-尼加拉瓜",
            "西班牙语-巴拿马",
            "西班牙语-巴拉圭",
            "西班牙语-秘鲁",
            "西班牙语-波多黎各",
            "西班牙语-多米尼加",
            "西班牙语-乌拉圭",
            "西班牙语-委内瑞拉",
            "巴斯克语-西班牙",
            "菲律宾语",
            "法语-加拿大",
            "法语-法国",
            "加利西亚语-西班牙",
            "格鲁吉亚语",
            "古吉拉特语",
            "克罗地亚语",
            "祖鲁语",
            "冰岛语",
            "意大利语",
            "爪哇语",
            "卡纳达语",
            "柬埔寨语",
            "老挝语",
            "拉脱维亚语",
            "立陶宛语",
            "匈牙利语",
            "马拉雅拉姆语",
            "马拉地语",
            "荷兰语",
            "尼泊尔语",
            "博克马尔挪威语",
            "波兰语",
            "葡萄牙语-巴西",
            "葡萄牙语-葡萄牙",
            "罗马尼亚语",
            "僧伽罗语",
            "斯洛伐克语",
            "斯洛文尼亚语",
            "巽他语",
            "斯瓦希里语-坦桑尼亚",
            "斯瓦希里语-肯尼亚",
            "芬兰语",
            "瑞典语",
            "泰米尔语-印度",
            "泰米尔语-新加坡",
            "泰米尔语-斯里兰卡",
            "泰米尔语-马来西亚",
            "泰卢固语",
            "越南语",
            "土耳其语",
            "乌尔都语-巴基斯坦",
            "乌尔都语-印度",
            "希腊语",
            "保加利亚语",
            "俄语",
            "塞尔维亚语",
            "乌克兰语",
            "希伯来语",
            "阿拉伯语-以色列",
            "阿拉伯语-约旦",
            "阿拉伯语-阿联酋",
            "阿拉伯语-巴林",
            "阿拉伯语-阿尔及利亚",
            "阿拉伯语-沙特阿拉伯",
            "阿拉伯语-伊拉克",
            "阿拉伯语-科威特",
            "阿拉伯语-摩洛哥",
            "阿拉伯语-突尼斯",
            "阿拉伯语-阿曼",
            "阿拉伯语-巴勒斯坦",
            "阿拉伯语-卡塔尔",
            "阿拉伯语-黎巴嫩",
            "阿拉伯语-埃及",
            "波斯语",
            "印地语",
            "泰语",
            "韩语",
            "中文-台湾",
            "中文-粤语（香港）",
            "中文-普通话（香港）",
            "中文-普通话（大陆）",
            "日语",
    };
    private static String asrcode[] = new String[]{
            "af-ZA", "am-ET", "hy-AM", "az-AZ", "id-ID", "ms-MY", "bn-BD", "bn-IN",
            "ca-ES", "cs-CZ", "da-DK", "de-DE",
            "en-AU", "en-CA", "en-GH", "en-GB", "en-IN", "en-IE", "en-KE", "en-NZ",
            "en-NG", "en-PH", "en-SG", "en-ZA", "en-TZ", "en-US",
            "es-AR", "es-BO", "es-CL", "es-CO", "es-CR", "es-EC", "es-SV", "es-ES",
            "es-US", "es-GT", "es-HN", "es-MX", "es-NI", "es-PA", "es-PY", "es-PE",
            "es-PR", "es-DO", "es-UY", "es-VE", "eu-ES",
            "fil-PH","fr-CA", "fr-FR", "gl-ES", "ka-GE", "gu-IN", "hr-HR", "zu-ZA",
            "is-IS", "it-IT", "jv-ID", "kn-IN", "km-KH", "lo-LA", "lv-LV", "lt-LT",
            "hu-HU", "ml-IN", "mr-IN", "nl-NL", "ne-NP", "nb-NO", "pl-PL", "pt-BR",
            "pt-PT", "ro-RO", "si-LK", "sk-SK", "sl-SL", "su-ID", "sw-TZ", "sw-KE",
            "fi-FI", "sv-SE", "ta-IN", "ta-SG", "ta-LK", "ta-MY", "te-IN", "vi-VN",
            "tr-TR", "ur-PK", "ur-IN", "el-GR", "bg-BG", "ru-RU", "sr-RS", "uk-UA",
            "he-IL",
            "ar-IL", "ar-JO", "ar-AE", "ar-BH", "ar-DZ", "ar-SA", "ar-IQ", "ar-KW",
            "ar-MA", "ar-TN", "ar-OM", "ar-PS", "ar-QA", "ar-LB", "ar-EG",
            "fa-IR", "hi-IN", "th-TH", "ko-KR",
            "zh-TW", "yue-Hant-HK", "zh-HK", "zh",
            "ja-JP"};

    private static int nospeech[] = new int[]{
            48, 51, 55, 58, 60, 61, 77};

    public static int getASR(String name){
        for (int i = 0; i< asrnames.length; i++){
            if (asrnames[i].equals(name)){
                return i+1;
            }
        }
        return 0;
    }

    public static String getASRCode(String name){
        for (int i = 0; i< asrnames.length; i++){
            if (asrnames[i].equals(name)){
                return asrcode[i];
            }
        }
        return "";
    }

    public static boolean noSpeech(int index){
        for (int i = 0; i< nospeech.length; i++){
            if (nospeech[i] == index){
                return true;
            }
        }
        return false;
    }
}
