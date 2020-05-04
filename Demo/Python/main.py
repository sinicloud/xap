#!/usr/bin/env python3
#
#  Copyright 2019-2020 SiniCloud. All rights reserved.
#  Use of this source code is governed by a BSD-style license that can be
#  found in the LICENSE.md file.
#

#
#  Imports.
#
import base64
from hashlib import sha256
import math
import json
import os
import sys
import time
import _thread as thread
from urllib.parse import urlencode
import websocket

#
#  Functions.
#

def sign(app_id: str, salt: str, current: str, app_secret: str):
    """Sign.

    :param app_id: The APP ID.
    :param salt: The salt of signature.
    :param current: Current timestamp.
    :param app_secret: The APP secret key.
    :return: The signature.
    """

    raw = (app_id + salt + current + app_secret).encode("utf-8")
    return sha256(raw).hexdigest()

def generate_audio_json_pkts(audio: bytes) -> [bytes]:
    """Sign.

    :param audio: The audio data.
    :return: The audio packets.
    """
    pkts = []
    while len(audio) != 0:
        pktlen = len(audio)
        if pktlen > 0x8FFE:
            pktlen = 0x8FFE
        
        #  Split audio data.
        sub_data = audio[0:pktlen]
        pkts.append(json.dumps({
            "type": "audio",
            "data": {
                "audio": base64.b64encode(sub_data).decode("utf-8")
            }
        }).encode("utf-8"))
        audio = audio[pktlen:]
    return pkts

def on_websocket_message_event(ws, msg):
    """Handle WebSocket client 'message' event..

    :param ws: WebSocket context.
    :param msg: The message.
    """
    try:
        pkt = json.loads(msg, encoding="utf-8")
    except Exception as error:
        print("[RX][ERROR] Decode JSON failedly. (error = {0})".format(
            repr(error)
        ))
        return
    
    if pkt["type"] == "origin":
        if pkt["data"]["is-final"]:
            print("RX][ORI][FINAL] Sentence: {0}".format(
                pkt["data"]["sentence"]
            ))
        else:
            print("[RX][ORI][PARTIAL] Sentence: {0}".format(
                pkt["data"]["sentence"]
            ))
    elif pkt["type"] == "origin/end":
        print("[RX][ORI] Finished!")
    elif pkt["type"] == "translation":
        if pkt["data"]["is-final"]:
            print("RX][TRAN][FINAL] Sentence: {0}".format(
                pkt["data"]["sentence"]
            ))
        else:
            print("[RX][TRAN][PARTIAL] Sentence: {0}".format(
                pkt["data"]["sentence"]
            ))
    elif pkt["type"] == "translation/end":
        print("[RX][TRAN] Finished!")
    elif pkt["type"] == "audio":
        print("[RX][AU] {0} bytes.".format(
            len(base64.b64decode(pkt["data"]["audio"]))
        ))
    elif pkt["type"] == "audio/flush":
        print("[RX][AU] Flush!")
    elif pkt["type"] == "audio/end":
        print("[RX][AU] Finished!")
    else:
        print("[RX][ERROR] Unknown chunk.")

def on_websocket_error_event(ws, error):
    """Handle WebSocket client 'error' event..

    :param ws: WebSocket context.
    :param error: Error object.
    """

    print("[][ERROR] Unexpected error. (error = {0})".format(
        repr(error)
    ))

    # Exit.
    sys.exit(1)

def on_websocket_close_event(ws, code, reason):
    """Handle WebSocket client 'close' event..

    :param ws: WebSocket context.
    """

    print("[] WebSocket close. (code = \"{0}\", reason = \"{1}\")".format(
        code,
        reason
    ))
    ws.close()

#
#  Main.
#
if __name__ == "__main__":
    #  Configuration file.
    cfg_file = os.path.join(
        os.path.dirname(__file__),
        "configuration.json"
    )

    #  Read and parse configuration.
    with open(cfg_file, "r") as f:
        cfg = json.loads(f.read())

    #  Audio file path.
    au_file = cfg["audio"]["input"]

    #  Read audio file.
    with open(au_file, "rb") as f:
        audio = f.read()

    #  Query parameters.
    app_id = cfg["xap"]["appid"]
    app_secret = cfg["xap"]["appsecret"]
    current = str(math.floor(time.time() * 1000))
    salt = os.urandom(8).hex()

    #  Sign.
    sign = sign(app_id, salt, current, app_secret)

    #  Build query param.
    qparam = urlencode({
        "appID": app_id,
        "salt": salt,
        "timestamp": current,
        "sign": sign,
        "from": cfg["audio"]["from"],
        "to": cfg["audio"]["to"],
        "rate": cfg["audio"]["sample-rate"]
    })

    #  Build URL.
    url = "{0}?{1}".format(cfg["ws"]["url"], qparam)
 
    #  Connect.
    client = websocket.WebSocketApp(
        url, 
        on_message=on_websocket_message_event,
        on_close=on_websocket_close_event,
        on_error=on_websocket_error_event
    )

    def on_websocket_open_event(ws):
        """Handle WebSocket client 'open' event.
        """

        def run_transmitter_thread(**kwargs):
            """Run transmitter thread to send audio data.
            """
            
            pkts = generate_audio_json_pkts(audio)

            for i in range(len(pkts)):
                client.send(pkts[i])

            client.send(json.dumps({
                "type": "audio/end"
            }).encode("utf-8"))

        #  Start new thread to send message.
        thread.start_new_thread(run_transmitter_thread, ())

    #  Bind 'open' event.
    client.on_open = on_websocket_open_event

    #  Hang.
    client.run_forever()
