
//
//  HarmoniumEngine.swift
//  LidSensorWatcher
//
//  Created by Pratyash Basel on 14/1/2026.
//

import Foundation
import AVFoundation

class HarmoniumEngine: ObservableObject {
    private var buffer: AVAudioPCMBuffer?
    
    private var sampleRate: Double = 44100.0
    
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private var speedControl = AVAudioUnitVarispeed() 

    init(){
        setupAudio()
    }
    
    func setupAudio() {
        engine.attach(player)
        engine.attach(speedControl) 
        
        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        

        self.buffer = generateSineWave(freaquency: 440.0, format: format)
        
       
        engine.connect(player, to: speedControl, format: format)
        engine.connect(speedControl, to: mixer, format: format)
        
        do {
            try engine.start()
            if let b = buffer {
                // Loop forever
                player.scheduleBuffer(b, at: nil, options: .loops, completionHandler: nil)
                player.play()
            }
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }
    
    func updateSound(freaquency: Double, volume: Double){

        let rate = freaquency / 440.0
        
        speedControl.rate = Float(rate)
        
        
        player.volume = Float(volume)
        
        print("Set Rate: \(rate) Vol: \(volume)")
    }
    
    func generateSineWave(freaquency: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate / 10.0) 
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        
        buffer.frameLength = frameCount
        let channels = Int(format.channelCount)
        
        for ch in 0..<channels {
            guard let channelData = buffer.floatChannelData?[ch] else { continue }
            for i in 0..<Int(frameCount) {
                let theta = Double(i) * 2.0 * Double.pi * freaquency / format.sampleRate
                channelData[i] = Float(sin(theta))
            }
        }
        return buffer
    }

}
