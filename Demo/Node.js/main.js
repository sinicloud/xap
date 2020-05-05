//
//  Copyright 2019-2020 SiniCloud. All rights reserved.
//  Use of this source code is governed by a BSD-style license that can be
//  found in the LICENSE.md file.
//

//
//  Imports.
//

//  Imported modules
const Crypto = require("crypto");
const FS = require("fs");
const Path = require("path");
const Process = require("process");
const QueryString = require("querystring");
const WebSocket = require("ws");
const Util = require("util");
const WaveFile = require("wavefile")

//
//  Functions.
//

/**
 *  Sign.
 * 
 *  @param {String} appID - The APP ID.
 *  @param {String} salt - The salt of signature.
 *  @param {String} current - Current timestamp.
 *  @param {String} appSecret - The APP secret key.
 *  @return - The signature.
 */
function XAPSignature(appID, salt, current, appSecret) {
    return Crypto.createHash("sha256")
                 .update(appID)
                 .update(salt)
                 .update(current)
                 .update(appSecret)
                 .digest("hex");
}

/**
 *  Build audio data to JSON packets.
 * 
 *  @param {Buffer} auData - The audio data.
 *  @return {Buffer[]} - The packets.
 */
function GenerateAudioJSONPkts(
    auData
) {
    let pkts = [];
    while (auData.length != 0) {
        let pktLen = auData.length;
        if (pktLen > 0x8FFE) {
            pktLen = 0x8FFE
        }

        //  Split audio data.
        let subData = auData.slice(0, pktLen);
        let subJSON = JSON.stringify({
            "type": "audio",
            "data": {
                "audio": subData.toString("base64")
            }
        });
        pkts.push(Buffer.from(subJSON));
        auData = auData.slice(pktLen);
    }
    return pkts;
}

/**
 *  Read PCM data (signed, little-endian, 16-bits) to audio sample data.
 * 
 *  @param {Buffer} data
 *      - The PCM data.
 *  @return {Number[]}
 *      - The audio sample data.
 */
function ReadDataS16LE(data) {
    let output = [];
    for (let i = 0; i < data.length; i += 2) {
        output.push(data.readInt16LE(i));
    }
    return output;
}

//
//  Main.
//
(function() {
    //  Configuration file.
    let cfgFile = Path.join(
        __dirname,
        "configuration.json"
    );

    //  Read and parse.
    let cfg;
    try {
        let cfgData = FS.readFileSync(cfgFile);
        cfg = JSON.parse(cfgData);
    } catch (error) {
        console.error(Util.format(
            "Read configuration file failedly. (error = \"%s\")",
            error.message || "Unknown error."
        ));
        Process.exit(1);
    }

    //  Audio file path.
    let auFile = cfg["audio"]["input"];

    //  Audio file path.
    let outputFile = cfg["audio"]["output"];
    let outputAudio = [];

    //  Query params.
    let appID = cfg["xap"]["appid"];
    let appSecret = cfg["xap"]["appsecret"];
    let salt = Crypto.randomBytes(8).toString("hex");
    let current = Date.now().toString();

    //  Sign.
    let sign = XAPSignature(
        appID,
        salt,
        current,
        appSecret
    );

    //  Sample rate.
    let auSampleRate = cfg["audio"]["sample-rate"];

    //  Build query param.
    let qparam = QueryString.stringify({
        "appID": appID,
        "salt": salt,
        "timestamp": current,
        "sign": sign,
        "from": cfg["audio"]["from"],
        "to": cfg["audio"]["to"],
        "rate": auSampleRate
    });

    //  Build URL.
    let url = Util.format(
        "%s?%s",
        cfg["ws"]["url"],
        qparam
    );

    //  Connect to server.
    let client = new WebSocket(url);

    //  Attach events.
    client.on("close", function(code, reason) {
        console.log(Util.format(
            "[] Connection was closed. (code = \"%d\", reason = \"%s\")",
            code,
            reason || "Unknown"
        ));

        //  Exit.
        Process.exit(0);
    });
    client.on("error", function(error) {
        console.error(Util.format(
            "[] Error occurred. (error = \"%s\")",
            error.message || "Unknown error."
        ));

        //  Exit.
        Process.exit(0);
    });

    //
    //  Transmit event.
    //
    client.on("open", async function() {
        //  Send audio packet if opened.
        let auData = FS.readFileSync(auFile);
        let pkts = GenerateAudioJSONPkts(auData);

        for (let i = 0; i < pkts.length; ++i) {
            client.send(pkts[i]);
        }

        //  Send end packet.
        client.send(Buffer.from(JSON.stringify({
            "type": "audio/end"
        })))
    });

    //
    //  Receive event.
    //
    client.on("message", function(msg) {
        //  Parse JSON.
        let pkt;
        try {
            pkt = JSON.parse(msg);
        } catch (error) {
            console.error(Util.format(
                "[RX][ERROR] Received invalid JSON packet. (error = \"%s\")",
                error.message || "Unkonwn error."
            ));
            return;
        }

        if (pkt["type"] == "origin") {
            if (pkt["data"]["is-final"]) {
                console.log(Util.format(
                    "[RX][ORI][FINAL] Sentence: %s",
                    pkt["data"]["sentence"]
                ));
            } else {
                console.log(Util.format(
                    "[RX][ORI][PARTIAL] Sentence: %s",
                    pkt["data"]["sentence"]
                ));
            }
        } else if (pkt["type"] == "origin/end") {
            console.log("[RX][ORI] Finished!");
        } else if (pkt["type"] == "translation") {
            if (pkt["data"]["is-final"]) {
                console.log(Util.format(
                    "[RX][TRAN][FINAL] Sentence: %s",
                    pkt["data"]["sentence"]
                ));
            } else {
                console.log(Util.format(
                    "[RX][TRAN][PARTIAL] Sentence: %s",
                    pkt["data"]["sentence"]
                ));
            }
        } else if (pkt["type"] == "translation/end") {
            console.log("[RX][TRAN] Finished!");
        } else if (pkt["type"] == "audio") {
            let data = Buffer.from(pkt["data"]["audio"], "base64");
            console.log(Util.format(
                "[RX][AU] %d bytes.",
                data.length
            ));
            outputAudio.push(data);
        } else if (pkt["type"] == "audio/flush") {
            console.log("[RX][AU] Flush!");
        } else if (pkt["type"] == "audio/end") {
            console.log("[RX][AU] Finished!");

            //  Write to output file.
            if (outputFile) {
                let output = Buffer.concat(outputAudio);
                let wav = new WaveFile.WaveFile();
                wav.fromScratch(1, auSampleRate, "16", ReadDataS16LE(output));
                FS.writeFileSync(outputFile, wav.toBuffer())
            }
        } else {
            console.error("[RX][ERROR] Unknown chunk.");
        }
    });

})();