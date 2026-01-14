//
//  HarmoniumEngine.swift
//  LidSensorWatcher
//
//  Created by Pratyash Basel on 14/1/2026.
//

import Foundation
import AVFoundation

class HarmoniumEngine: ObservableObject{
    private var buffer: AVAudioPCMBuffer?
    
    private var sampleRate: Double = 44100.0;
    
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()

    init(){
        setupAudio();
    }
    
    func setupAudio() {
        engine.attach(player)
        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        
        self.buffer = generateSineWave(frequency: 440.0, format: format)
        

        engine.connect(player, to: mixer, format: format)
        
        do {
            try engine.start()
            if let b = buffer {
                player.scheduleBuffer(b, at: nil, options: .loops, completionHandler: nil)
                player.play()
            }
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }

}
