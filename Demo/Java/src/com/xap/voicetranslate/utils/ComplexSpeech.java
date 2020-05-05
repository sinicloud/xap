package com.xap.voicetranslate.utils;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.xap.voicetranslate.Constant;
import com.xap.voicetranslate.callback.STSCallback;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.util.Base64;
import java.util.Random;
import java.util.concurrent.locks.ReentrantLock;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.ByteString;

public class ComplexSpeech {

    //static
    private static volatile int currentConversation;

    //sts
    private String fromLanguage = "";
    private String toLanguage = "";
    private String recordFile, voiceFile;

    //callbacks
    private STSCallback stsCallback;

    //lock
    private final ReentrantLock conversationLock = new ReentrantLock(true);

    //common
    private Random random;

    public ComplexSpeech() {
        random = new Random(40);
    }

    public void startSTS(String sourceLan, String targetLan, String voicePath, String outputPath, STSCallback stsCallback) {
        int conversation = random.nextInt(10000);
        conversationLock.lock();
        currentConversation = conversation;//多线程处理
        conversationLock.unlock();
        LogUtils.d("startSTS"+conversation);
        if (stsCallback == null){
            return;
        } else if ((TextUtils.isEmpty(targetLan) || TextUtils.isEmpty(sourceLan)) || TextUtils.isEmpty(voicePath)) {
            stsCallback.onError(30002, "Arguments are null!");
            return;
        }
        recordFile = voicePath;
        voiceFile = outputPath;
        File path = new File(voiceFile);
        if (!path.exists())
        	path.mkdirs();
        fromLanguage = sourceLan;
        toLanguage = targetLan;
        StsThread stsThread;
        StsRunnable stsRunnable;
        this.stsCallback = stsCallback;
        stsRunnable = new StsRunnable(conversation);
        stsThread = new StsThread(conversation, stsRunnable);
        stsThread.start();//开始请求
    }

    private String jsonPrepare(byte[] data) {//封装音频发送的json数据
    	String encodedData = Base64.getEncoder()
                .encodeToString(data);
        JSONObject object = new JSONObject();
        JSONObject object1 = new JSONObject();
        object.put("audio", encodedData);
        object1.put("data", object);
        object1.put("type", "audio");
        return object1.toString();
    }

    private String jsonEndPrepare() {//音频发送结束的json数据
        JSONObject object1 = new JSONObject();
        object1.put("type", "audio/end");
        return object1.toString();
    }

    private static String generateWsUrl(String from, String to) throws Exception {//整合请求链接
        String salt = EncryptUtil.getRandomString(10);
        String time = ""+System.currentTimeMillis();
        String sign = EncryptUtil.SHA256(Constant.APP_ID+salt+time+Constant.APP_SECRET);
        return String.format(Constant.WSS_URL, Constant.APP_ID, salt, time, sign, from, to, Constant.AUDIO_RATE);
    }

    class StsThread extends Thread {
        int conversation;

        StsThread(int id, StsRunnable sendRunnable){
            super(sendRunnable);
            conversation = id;
        }
    }

    class StsRunnable implements Runnable{
        private int conversation;

        StsRunnable(int id){
            conversation = id;
        }

        @Override
        public void run() {
            LogUtils.d("startsend"+ conversation);
            //LogUtils.d("startsend"+ s.hashCode()+socketUtils.isSocketOn(s));
            if (conversation != currentConversation){//判断是否是最新会话（下同）
                return;
            }
            String voiceName = System.currentTimeMillis()+".pcm";//新建音频输出文件
            LogUtils.d(voiceName+"存储"+voiceFile);
            File file = new File(voiceFile+voiceName);
            LogUtils.d(conversation+"存储"+file.getAbsolutePath());
            FileOutputStream voiceOut = null;
            try {
                voiceOut = new FileOutputStream(file);
                FileOutputStream finalVoiceOut = voiceOut;
                WebSocketListener listener = new WebSocketListener() {//websocket新建监听
                    @Override
                    public void onOpen(WebSocket webSocket, Response response) {
                        if (conversation != currentConversation){
                            return;
                        }
                        LogUtils.d("onOpen ");
                        if (stsCallback != null) {
                            stsCallback.onOpen();
                        }           
                        byte[] bytes = new byte[0x8FFE];
                        InputStream inputStream = null;
                        try {
                            inputStream = new FileInputStream(recordFile);
                            int len = -1;
                            while ((len = inputStream.read(bytes)) != -1 && conversation == currentConversation) {
                                String data = jsonPrepare(bytes);
                                LogUtils.d("to send"+data);
                                boolean isOk = webSocket.send(data);//发送读取的音频数据
                                if (!isOk) {
                                    LogUtils.d("send error");
                                } else {
                                    LogUtils.d("send ok");
                                }
                            }
                            String data = jsonEndPrepare();//发送音频结束
                            LogUtils.d("to send"+data);
                            boolean isOk = webSocket.send(data);
                            if (!isOk) {
                                LogUtils.d("send error");
                            } else {
                                LogUtils.d("send ok");
                            }
                        } catch (Exception e) {
                            LogUtils.d(String.valueOf(e));
                            if (stsCallback != null && conversation == currentConversation){
                                stsCallback.onError(30002, e.getMessage());
                            }
                        }finally {
                            try {
                                if (inputStream != null){
                                    inputStream.close();
                                }
                            } catch (IOException e) {
                                if (stsCallback != null && conversation == currentConversation){
                                    stsCallback.onError(30002, e.getMessage());
                                }                       
                            }
                        }                     
                    }

                    @Override
                    public void onMessage(WebSocket webSocket, ByteString bytes) {
                        String text = bytes.string(Charset.defaultCharset());
                        if (conversation != currentConversation){
                            return;
                        }
                        LogUtils.d(text);
                        try {
                            JSONObject j = JSON.parseObject(text);
                            final String type = j.getString("type");
                            JSONObject data;
                            boolean isEnd;
                            switch (type){
                                case "audio":    //收到音频数据
                                    data = j.getJSONObject("data");
                                    String audio = data.getString("audio");
                                    byte[] voice = Base64.getDecoder().decode(audio);//解码音频数据
                                    if (voice == null || voice.length <= 0){
                                        if (stsCallback != null) {
                                            stsCallback.onError(30003, "Audio data invalid!");
                                        }
                                        break;
                                    }
                                    finalVoiceOut.write(voice);//写入音频数据
                                    break;
                                case "audio/flush": //音频接收完成
                                    if (stsCallback != null && conversation == currentConversation) {
                                        finalVoiceOut.close();
                                        String path = AudioUtil.convertWaveFile(voiceFile+voiceName);//转码音频为wav格式
                                        file.delete();
                                        stsCallback.onFinish(path);
                                    }
                                    break;
                                case "origin":  //收到识别结果
                                    data = j.getJSONObject("data");
                                    String rec = data.getString("sentence");
                                    isEnd = data.getBoolean("is-final");
                                    if (stsCallback != null && conversation == currentConversation) {
                                        stsCallback.onRecognizeSuccess(isEnd, rec);//传递识别文字
                                    }
                                    break;
                                case "origin/end": //识别结束
                                    break;
                                case "translation": //收到翻译结果
                                    data = j.getJSONObject("data");
                                    String trans = data.getString("sentence");
                                    isEnd = data.getBoolean("is-final");
                                    if (stsCallback != null && conversation == currentConversation) {
                                        stsCallback.onTranslateSuccess(isEnd, trans);//传递翻译文字
                                    }
                                    break;
                                case "translation/end": //翻译结束
                                    break;
                            }
                        } catch (Exception e) {
                            LogUtils.d(e.getMessage());
                            if (stsCallback != null && conversation == currentConversation){
                                file.delete();
                                stsCallback.onError(30003, e.getMessage());
                            }
                        }
                        LogUtils.d("onMessage " + text);
                    }

                    @Override
                    public void onClosed(WebSocket webSocket, int code, String reason) {
                        if (conversation != currentConversation){
                            return;
                        }
                        LogUtils.d("onClosed " + reason);
                    }

                    @Override
                    public void onClosing(WebSocket webSocket, int code, String reason) {
                        if (conversation != currentConversation){
                            return;
                        }
                        LogUtils.d("onClosing " + reason);
                    }

                    @Override
                    public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                        if (conversation != currentConversation){
                            return;
                        }
                        if (stsCallback != null){
                            file.delete();
                            stsCallback.onError(30001, String.valueOf(t));//websocket报错
                        }
                        LogUtils.d("onError " + String.valueOf(t) + response.toString());
                    }
                };
                Request request = null;
                LogUtils.d(generateWsUrl(fromLanguage, toLanguage).replace(" ", ""));
                request = new Request.Builder()
                        .url(generateWsUrl(fromLanguage, toLanguage).replace(" ", ""))
                        .build();
                OkHttpClient client = new OkHttpClient();
                client.newWebSocket(request, listener);//建立websocket
            } catch (Exception e) {
                if (stsCallback != null && conversation == currentConversation){
                    stsCallback.onError(30001, e.getMessage());
                }
            }
        }
    }
}
