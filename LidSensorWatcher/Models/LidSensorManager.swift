//
//  LidSensorManager.swift
//  LidSensorWatcher
//
//  Created by Pratyash Basel on 3/1/2026.
//

import Foundation;
import IOKit.hid;

struct soundData: Decodable {
    let freaquency: Double;
    let volume: Double;
}

class LidSensorManager: ObservableObject{
    @Published var angle: Double =  0.0;
    var lastUpdateTime: TimeInterval = 0;
    private var manager: IOHIDManager?
    
    private let socketClient = WebSocketClient();
    private let harmonium = HarmoniumEngine();
    
    init(){
        setupHIDManager();
        setupConnection();
    }
    
    private func setupConnection(){
        socketClient.onReceive = { [weak self] jsonString in
            guard let data = jsonString.data(using: .utf8) else { return }
            
            do{
                let sound = try JSONDecoder().decode(soundData.self, from: data)
                
                DispatchQueue.main.async{
                    self?.harmonium.updateSound(freaquency: sound.freaquency, volume: sound.volume)
                }
            } catch{
                print("Error paring: \(error)")
            }
        }
        socketClient.connect();
    }
    
    
    private func setupHIDManager(){
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone));
        
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: 0x20,
            kIOHIDDeviceUsageKey: 0x8A
        ]
        
        IOHIDManagerSetDeviceMatching(manager!, matchingDict as CFDictionary);
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque());
        
        IOHIDManagerRegisterInputValueCallback(manager!, {context, _, _, value in
            
            let rawValue = IOHIDValueGetIntegerValue(value)
            print("HID Event: \(rawValue)")
            
            guard let context = context else {return}
            let sensorClass = Unmanaged<LidSensorManager>.fromOpaque(context).takeUnretainedValue()
            
            
            let currentTime = Date().timeIntervalSince1970
            if currentTime - sensorClass.lastUpdateTime > 0.016 {
                sensorClass.lastUpdateTime = currentTime
                
                DispatchQueue.main.async{
                    sensorClass.angle = Double(rawValue)
                    let json = "{\"angle\": \(Double(rawValue))}"
                    sensorClass.socketClient.send(message: json)
                }
            }
            
            
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager!, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(manager!, IOOptionBits(kIOHIDOptionsTypeNone));
        
    }
    
    
    
    
    func sendKey(key: String, isDown: Bool) {
        let json = "{\"key\": \"\(key)\", \"isDown\": \(isDown)}"
        socketClient.send(message: json)
    }
}
