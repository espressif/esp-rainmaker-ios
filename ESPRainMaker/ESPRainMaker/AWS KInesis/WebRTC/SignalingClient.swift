// Copyright 2025 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  SignalingClient.swift
//  ESPRainMaker
//

import Foundation
import Starscream
import WebKit
import WebRTC

// interface for remote connectivity events
protocol SignalClientDelegate: class {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription)
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate)
}

final class SignalingClient {
    private let socket: Starscream.WebSocket
    private let encoder = JSONEncoder()
    weak var delegate: SignalClientDelegate?
    
    let appName = "aws-kvs-webrtc-ios-client"
    let appVersion = "1.0.0"
    let userAgentHeader = "User-Agent"

    init(serverUrl: URL) {
        var request: URLRequest = URLRequest(url: serverUrl)

        let webView = WKWebView()
        webView.configuration.preferences.javaScriptEnabled = false

        let UA = webView.value(forKey: "userAgent") as? String?
        if let agent = UA {
            request.setValue(appName + "/" + appVersion + " " + agent!, forHTTPHeaderField: userAgentHeader)
        } else {
            request.setValue(appName + "/" + appVersion, forHTTPHeaderField: userAgentHeader)
        }
        
        socket = WebSocket(request: request)
    }

    func connect() {
        socket.delegate = self
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func sendOffer(rtcSdp: RTCSessionDescription, senderClientid: String) {
        do {
            let message: Message = Message.createOfferMessage(sdp: rtcSdp.sdp, senderClientId: senderClientid)
            let data = try encoder.encode(message)
            let msg = String(data: data, encoding: .utf8)!
            socket.write(string: msg)

        } catch {
            print(error)
        }
    }

    func sendAnswer(rtcSdp: RTCSessionDescription, recipientClientId: String) {
        do {
            let message: Message = Message.createAnswerMessage(sdp: rtcSdp.sdp, recipientClientId)
            let data = try encoder.encode(message)
            let msg = String(data: data, encoding: .utf8)!
            socket.write(string: msg)
        } catch {
            print(error)
        }
    }

    func sendIceCandidate(rtcIceCandidate: RTCIceCandidate, master: Bool,
                          recipientClientId: String,
                          senderClientId: String) {
        do {
            let message: Message = Message.createIceCandidateMessage(candidate: rtcIceCandidate,
                                                                     master,
                                                                     recipientClientId: recipientClientId,
                                                                     senderClientId: senderClientId)
            let data = try encoder.encode(message)
            let msg = String(data: data, encoding: .utf8)!
            socket.write(string: msg)
        } catch {
            print(error)
        }
    }
}

// MARK: Websocket
extension SignalingClient: WebSocketDelegate {
    func websocketDidConnect(socket _: WebSocketClient) {
        delegate?.signalClientDidConnect(self)
    }

    func websocketDidDisconnect(socket _: WebSocketClient, error: Error?) {
        delegate?.signalClientDidDisconnect(self)
    }

    func websocketDidReceiveData(socket _: WebSocketClient, data: Data) {
    }

    func websocketDidReceiveMessage(socket _: WebSocketClient, text: String) {
        var parsedMessage: Message?

        parsedMessage = Event.parseEvent(event: text)

        if parsedMessage != nil {
            let messagePayload = parsedMessage?.getMessagePayload()

            let messageType = parsedMessage?.getAction()
            let senderClientId = parsedMessage?.getSenderClientId()
            // todo: add a guard here because some of java base64 encode options might break ios base64 decode unless extended
            let message: String = String(messagePayload!.base64Decoded()!)

            do {
                let jsonObject = try message.trim().convertToDictionary()
                if jsonObject.count != 0 {
                    if messageType == "SDP_OFFER" {
                        guard let sdp = jsonObject["sdp"] as? String else {
                            return
                        }
                        let rcSessionDescription: RTCSessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
                        delegate?.signalClient(self, senderClientId: senderClientId!, didReceiveRemoteSdp: rcSessionDescription)
                    } else if messageType == "SDP_ANSWER" {
                        guard let sdp = jsonObject["sdp"] as? String else {
                            return
                        }
                        let rcSessionDescription: RTCSessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
                        delegate?.signalClient(self, senderClientId: "", didReceiveRemoteSdp: rcSessionDescription)
                    } else if messageType == "ICE_CANDIDATE" {
                        guard let iceCandidate = jsonObject["candidate"] as? String else {
                            return
                        }
                        guard let sdpMid = jsonObject["sdpMid"] as? String else {
                            return
                        }
                        guard let sdpMLineIndex = jsonObject["sdpMLineIndex"] as? Int32 else {
                            return
                        }
                        let rtcIceCandidate: RTCIceCandidate = RTCIceCandidate(sdp: iceCandidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                        delegate?.signalClient(self, senderClientId: senderClientId!, didReceiveCandidate: rtcIceCandidate)
                    }
                } else {
                }
            } catch {
                print("payLoad parsing Error \(error)")
            }
        }
    }
}
