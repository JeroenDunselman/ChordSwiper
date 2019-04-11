//
//  AudioService.swift
//  ChordSwiper
//
//  Created by Jeroen Dunselman on 11/04/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import Foundation
import AudioKit

class AudioService {
    var time = 0.0
    let timeStep = 0.05
    
    let oscillator = AKOscillatorBank(waveform: AKTable(.sawtooth, count: 256))
    let filter: AKRolandTB303Filter?
    let mandolin = AKMandolin()
    //    let bar = AKMetalBar()
    var mixer = AKMixer()
    
    let pluckPosition = 0.2
    let delay: AKDelay?
    var conductor: Conductor?
    let freqMax: Double = 1_350
    init() { //_ conductor: Conductor) {
        filter = AKRolandTB303Filter(oscillator)
        filter!.cutoffFrequency = freqMax
        filter!.resonance = 0.6
        
        mandolin.detune = 1
        mandolin.bodySize = 1
        [filter!, mandolin,] >>> mixer //
        delay = AKDelay(mixer) //mandolin)
        setupDelay()
        
        let reverb = AKReverb(delay)
        
        //set chordIndex, autoplay
        let timer = AKPeriodicFunction(every: timeStep) {
            //    moet ook .output zijn?        panner.pan = sin(time)
            self.conductor!.chordIndex = Int(sin(self.time))
            print("self.conductor!.chordIndex: \(self.conductor!.chordIndex)")
            self.time += self.timeStep
        }
        
        AudioKit.output = reverb
        do {
            try AudioKit.start(withPeriodicFunctions: timer)
            AKLog("AudioKit started")
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    func setupDelay() {
        delay?.time = 0.6108
        delay?.dryWetMix = 0.05
        delay?.feedback = 0.05
    }
    
    var currentNote: MIDINoteNumber = 0
    func play(noteNumber: MIDINoteNumber) {
        mandolin.fret(noteNumber: noteNumber, course: 1)
        mandolin.pluck(course: 1, position: pluckPosition, velocity: 127)
        
        oscillator.stop(noteNumber: currentNote)
        currentNote = noteNumber
        oscillator.play(noteNumber: noteNumber, velocity: 64)
    }
    
    //not in use for plucked instrument
    func noteOff(note: MIDINoteNumber) {
        oscillator.stop(noteNumber: note)
    }
    
    func allNotesOff() {
        _ = (0..<128).map { noteOff(note: MIDINoteNumber($0)) }
    }
}
