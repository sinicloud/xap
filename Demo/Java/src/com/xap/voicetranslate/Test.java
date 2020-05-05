package com.xap.voicetranslate;

import com.xap.voicetranslate.callback.STSCallback;
import com.xap.voicetranslate.utils.ComplexSpeech;


public class Test {
    static String recognize, translate;

	public static void main(String args[]) {
		recognize = "";
		translate = "";
		ComplexSpeech complexSpeech = new ComplexSpeech();
		String[] tempRecognize = new String[1], tempTranslate = new String[1];
		STSCallback stsCallback = new STSCallback() {//设置回调
            @Override
            public void onRecognizeSuccess(boolean isFinal, String recognizeResult) {
            	if (!isFinal) {
                    tempRecognize[0] = recognizeResult;//保存中间结果
                } else {
                    recognize += recognizeResult;
                    tempRecognize[0] = "";
                    System.out.println("识别结果：" + recognize + tempRecognize[0]);//打印最终结果
                }
            }

            @Override
            public void onTranslateSuccess(boolean isFinal, String translateResult) {
            	if (!isFinal) {
            		tempTranslate[0] = translateResult;
                } else {
                	translate += translateResult;
                    tempTranslate[0] = "";
                    System.out.println("翻译结果：" + translate + tempTranslate[0]);
                }
            }

            @Override
            public void onFinish(String path) {
                System.out.println("返回音频地址：" + path);
            }

            @Override
            public void onOpen() {
            }

            @Override
            public void onError(int errorCode, String error) {
                System.out.println("错误码:" + errorCode + "说明:" + error);
            }
        };
        
        complexSpeech.startSTS(Constant.FROM , Constant.TO, Constant.IN_FILE, Constant.OUT_FILE, stsCallback);
	}
}
