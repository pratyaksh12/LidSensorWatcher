//
//  WebSocketClient.swift
//  LidSensorWatcher
//
//  Created by Pratyash Basel on 4/1/2026.
//

import Foundation

class WebSocketClient: NSObject, URLSessionWebSocketDelegate{
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlString = "ws://localhost:5000/ws/sensor";
    var onReceive: ((String) -> Void)?

    func connect(){
        guard let url = URL(string: urlString) else {return}
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue());
        webSocketTask = session.webSocketTask(with: url);
        
        webSocketTask?.resume()
        print("Websocket: connecting to \(urlString)");
        
        receiveMessage();
    }
    
    func send(message: String){
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message){
            error in if let error = error{
                print("Websocket Send Error \(error)");
            }
        }
    }
    
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
                case .failure(let error):
                    print("WebSocket Receive Error: \(error)")
                case .success(let message):
                switch message{
                    case .string(let text):
                        self?.onReceive?(text)
                    
                    case .data(let data):
                        print("data received: \(data)");
                    @unknown default:
                        break;
                }
                
                self?.receiveMessage();
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket: Connected!")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?){
        print("Websocket: Disconnected")
    }
    
}
