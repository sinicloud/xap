package com.xap.voicetranslate.callback;

public interface STSCallback {
    void onRecognizeSuccess(boolean isFinal, String recognizeResult);
    void onTranslateSuccess(boolean isFinal, String translateResult);
    void onFinish(String voicePath);
    void onOpen();
    void onError(int errorCode, String error);
}
