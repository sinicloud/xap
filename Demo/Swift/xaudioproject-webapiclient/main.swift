//
//  Copyright 2019-2020 SiniCloud. All rights reserved.
//  Use of this source code is governed by a BSD-style license that can be
//  found in the LICENSE.md file.
//

//
//  MARK: Imports.
//
import CommonCrypto
import Foundation
import Starscream
import SwiftyJSON

//
//  MARK: Struct.
//

///
///  XAP Error object.
///
struct XAPError: Error {
    //  The message binded to localized description.
    let message: String
}
extension XAPError: LocalizedError {
    var errorDescription: String? {
        get {
            return message
        }
    }
}

//
//  MARK: Classes.
//

///
///  WebSocket event handler.
///
class WebSocketHandler: WebSocketDelegate {

    //
    //  MARK: WebSocketHandler members.
    //
    private let m_HandlerDispatcher = DispatchQueue.init(label: "com.xorange")
    private var m_ConnectedHandlers = [() -> Void]()
    private var m_DisconnectedHandlers = [(UInt16, String) -> Void]()
    private var m_MessageHandlers = [(String) -> Void]()
    private var m_ErrorHandlers = [(Error) -> Void]()
    
    //
    //  MARK: WebSocketHandler private methods.
    //

    ///
    ///  Emit WebSocket 'connected' event handlers.
    ///
    private func emitConnectedHandlers() {
        m_HandlerDispatcher.async {
            for handler in self.m_ConnectedHandlers {
                handler()
            }
        }
    }
    
    ///
    ///  Emit WebSocket 'disconnected' handlers.
    ///
    ///  - Parameters:
    ///    - code: The error code.
    ///    - reason: The reason.
    ///
    private func emitDisconnectedHandlers(code: UInt16, reason: String) {
        m_HandlerDispatcher.async {
            for handler in self.m_DisconnectedHandlers {
                handler(code, reason)
            }
        }
    }
    
    ///
    ///  Emit WebSocket 'message' handlers.
    ///
    ///  - Parameter message: The message.
    ///
    private func emitMessageHandlers(message: String) {
        m_HandlerDispatcher.async {
            for handler in self.m_MessageHandlers {
                handler(message)
            }
        }
    }
    
    ///
    ///  Emit WebSocket 'error' handlers.
    ///
    ///  - Parameter error: The error object.
    ///
    private func emitErrorHandlers(error: Error) {
        m_HandlerDispatcher.async {
            for handler in self.m_ErrorHandlers {
                handler(error)
            }
        }
    }
    
    //
    //  MARK: WebSocketHandler WebSocketDelegate.
    //
    
    ///  WebSocketDelegate protocol. Handle WebSocket events.
    ///
    ///   - Parameters:
    ///     - event: The event.
    ///     - client: The context.
    ///
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            emitConnectedHandlers()
            break
        case .disconnected(let reason, let code):
            emitDisconnectedHandlers(code: code, reason: reason)
            break
        case .cancelled:
            emitErrorHandlers(error:
                XAPError(message: "Unexpected cancelled."));
            break
        case .binary(let data):
            guard let msg = String(data: data, encoding: .utf8) else {
                emitErrorHandlers(error:
                    XAPError(message: "Binary data cannot be parsed."))
                break
            }
            emitMessageHandlers(message: msg)
            break
        case .text(let msg):
            emitMessageHandlers(message: msg)
            break
        case .error(let error):
            guard let error = error else {
                break
            }
            emitErrorHandlers(error: error)
            break
        default:
            break
        }
    }
    
    ///
    ///  (Event) Handle WebSocket 'connected' event.
    ///
    ///  - Parameter handler: The handler.
    ///
    func onConnected(handler: @escaping () -> Void) {
        m_HandlerDispatcher.async {
            self.m_ConnectedHandlers.append(handler)
        }
    }
    
    ///
    ///  (Event) Handle WebSocket 'disconnected' event.
    ///
    ///  - Parameter handler: The handler.
    ///
    func onDisconnected(handler: @escaping (UInt16, String) -> Void) {
        m_HandlerDispatcher.async {
            self.m_DisconnectedHandlers.append(handler)
        }
    }
    
    ///
    ///  (Event) Handle WebSocket 'message' event.
    ///
    ///  - Parameter handler: The handler.
    ///
    func onMesssage(handler: @escaping (String) -> Void) {
        m_HandlerDispatcher.async {
            self.m_MessageHandlers.append(handler)
        }
    }
    
    ///
    ///  (Event) Handle WebSocket 'error' event.
    ///
    ///  - Parameter handler: The handler.
    ///
    func onError(handler: @escaping (Error) -> Void) {
        m_HandlerDispatcher.async {
            self.m_ErrorHandlers.append(handler)
        }
    }
}

//
//  MARK: Functions.
//

///
///  Sign.
///
///  - Parameters:
///    - appID: The APP ID.
///    - salt: The salt of signature.
///    - current: Current timestamp.
///    - appSecret: The APP secret key.
///
///  - Returns: The signature.
///
func XAPSignature(
    appID: String,
    salt: String,
    current: String,
    appSecret: String
) -> String? {
    //  Append string.
    let raw = appID + salt + current + appSecret
    return raw.data(using: .utf8)?.withUnsafeBytes({ (ptr) -> String? in
        guard let baseaddr = ptr.baseAddress else {
            return nil
        }
        
        //  Sha256 hash.
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(baseaddr, UInt32(ptr.count), &hash)
        
        //  Convert hash bytes to hex string.
        return hash.map { String(format: "%02hhx", $0) }.joined()
    })
}

///
///  Build audio data to JSON packets.
///
///  - Parameter data: The audio data.
///
///  - Returns: The packets.
///
func GenerateAudioJSONPkts(_ data: Data) throws -> [Data] {
    var pkts = [Data]()
    var cursor = 0
    while cursor < data.count {
        var pktLen = data.count - cursor
        if pktLen > 0x8FFE {
            pktLen = 0x8FFE
        }
        
        //  Split audio data.
        let subJSON = JSON.init([
            "type": "audio",
            "data": [
                "audio": data[cursor..<(cursor + pktLen)].base64EncodedString()
            ]
        ])
        guard let subData = try? subJSON.rawData() else {
            throw XAPError(message: "Generating audio JSON packet was failed")
        }
        pkts.append(subData)
        cursor += pktLen
    }
    return pkts
}


//
//  MARK: Main.
//

//  Configuration.
guard let path = Bundle.main.path(
        forResource: "configuration", ofType: ".json") else {
    
    print("[ERROR] Cannot find configuration file.")
    exit(1)
}

//  Read configuration file.
guard let cfgRaw = try? String.init(contentsOfFile: path) else {
    print("[ERROR] Cannot read configuration file.")
    exit(1)
}

//  Parse configuration file.
let cfg = JSON.init(parseJSON: cfgRaw)

//  Audio file.
let auFile = URL(fileURLWithPath: cfg["audio"]["input"].stringValue)

//  Read audio file.
let auData: Data
do {
    auData = try Data.init(contentsOf: auFile)
} catch let error {
    print("Read audio file failedly. " +
        "(error = \"\(error.localizedDescription)\")");
    exit(1)
}

//  Generate audio chunks.
let auChunks: [Data]
let endChunk: Data
do {
    auChunks = try GenerateAudioJSONPkts(auData)
    endChunk = try JSON.init([
        "type": "audio/end"
    ]).rawData()
} catch let error {
    print("[] \(error.localizedDescription)")
    exit(1)
}

//  Query params.
let appID = cfg["xap"]["appid"].stringValue
let appSecret = cfg["xap"]["appsecret"].stringValue
let salt = String((0..<16).map{ _ in "qwertyuiop1234567890".randomElement()! })
let current = String(format: "%.0f", floor(Date().timeIntervalSince1970 * 1000))

//  Sign.
guard let sign = XAPSignature(
    appID: appID,
    salt: salt,
    current: current,
    appSecret: appSecret
) else {
    print("[] Cannot get signature.")
    exit(1)
}

//  Build query param.
let qparams = [
    URLQueryItem(name: "appID", value: appID),
    URLQueryItem(name: "salt", value: salt),
    URLQueryItem(name: "timestamp", value: current),
    URLQueryItem(name: "sign", value: sign),
    URLQueryItem(name: "from", value: cfg["audio"]["from"].stringValue),
    URLQueryItem(name: "to", value: cfg["audio"]["to"].stringValue),
    URLQueryItem(name: "rate", value: "\(cfg["audio"]["sample-rate"].intValue)")
]

//  Build URL.
guard var urlComps = URLComponents(string: cfg["ws"]["url"].stringValue) else {
    print("[] Create URL components object failedly.")
    exit(1)
}
urlComps.queryItems = qparams
guard let url = urlComps.url else {
    print("[] Cannot get URL object.")
    exit(1)
}

//  Build request.
var request = URLRequest(url: url)
request.timeoutInterval = 16

//  Bulid socket.
let socket = WebSocket(request: request)

//  Build handler.
let handler = WebSocketHandler()


//
//  MARK: TX.
//
handler.onConnected {
    //  Write audio data.
    for pkt in auChunks {
        socket.write(data: pkt)
    }
    
    //  Write end chunk.
    socket.write(data: endChunk)
}

//
//  MARK: RX.
//
handler.onMesssage { (msg) in
    //  Read.
    let pkt = JSON.init(parseJSON: msg)
    
    if pkt["type"].stringValue == "origin" {
        if pkt["data"]["is-final"].boolValue {
            print("[RX][ORI][FINAL] Sentence: " +
                  "\(pkt["data"]["sentence"].stringValue)")
        } else {
            print("[RX][ORI][PARTIAL] Sentence: " +
                  "\(pkt["data"]["sentence"].stringValue)")
        }
    } else if pkt["type"] == "origin/end" {
        print("[RX][ORI] Finished!")
    } else if pkt["type"].stringValue == "translation" {
        if pkt["data"]["is-final"].boolValue {
            print("[RX][TRAN][FINAL] Sentence: " +
                  "\(pkt["data"]["sentence"].stringValue)")
        } else {
            print("[RX][TRAN][PARTIAL] Sentence: " +
                  "\(pkt["data"]["sentence"].stringValue)")
        }
    } else if pkt["type"] == "translation/end" {
        print("[RX][TRAN] Finished!")
    } else if pkt["type"].stringValue == "audio" {
        let bytes = String(describing:
            Data.init(base64Encoded:
                pkt["data"]["audio"].stringValue)?.count)
        print("[RX][AU] \(bytes) bytes.")
    } else if pkt["type"].stringValue == "audio/flush" {
        print("[RX][AU] Flush!!")
    } else if pkt["type"].stringValue == "audio/end" {
        print("[RX][AU] Finished!")
    }
    
}

//  Bind 'error' event.
handler.onError { (error) in
    print("[ERROR] Unexpected error occurred. " +
          "(error = \"\(error.localizedDescription)\")")
    exit(1)
}

//  Bind 'close' event.
handler.onDisconnected { (code, reason) in
    print("[] Connection closed. (code = \"\(code)\", " +
          "reason = \"\(reason)\")")
    exit((code == 1000) ? 0 : 1)
}

//  Regist delegate.
socket.delegate = handler

//  Connect.
socket.connect()

//  Run event loop.
RunLoop.main.run()
