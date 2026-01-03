//
//  LidSensorManager.swift
//  LidSensorWatcher
//
//  Created by Pratyash Basel on 3/1/2026.
//

import Foundation
import IOKit.hid

class LidSensorManager: ObservableObject{
    @Published var angle: Double = 0.0;
    private var manager: IOHIDManager?;
    
    init(){
        setupHIDManager();
    }
    
    
    private func setupHIDManager(){
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone));
        
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: 0x20,
            kIOHIDDeviceUsageKey: 0x8A
        ];
        
        IOHIDManagerSetDeviceMatching(manager!, matchingDict as CFDictionary);
        
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque());
        
        IOHIDManagerRegisterInputValueCallback(manager!, {context, _, _, value in guard
            
            let context = context else{return}
            let sensorClass = Unmanaged<LidSensorManager>.fromOpaque(context).takeUnretainedValue()
            let rawValue = IOHIDValueGetIntegerValue(value)
            
            DispatchQueue.main.async{
                sensorClass.angle = Double(rawValue)
            }
            
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager! , CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(manager!, IOOptionBits(kIOHIDOptionsTypeNone))
        
    }
    
    
}
