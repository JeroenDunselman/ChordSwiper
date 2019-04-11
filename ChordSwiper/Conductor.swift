//
//  Conductor.swift
//  ChordSwiper
//
//  Created by Jeroen Dunselman on 11/04/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import Foundation
import UIKit
import AudioKit

typealias SwipeEvent = (at: Int64, data: SenderData)
typealias SenderData = (velocity: CGPoint, position: CGPoint, fingerCount: Int)

@objc protocol Conductable: NSObjectProtocol {
    @objc optional func phraseEnded()
    func chordChanged()
    func visualizePlaying(position: CGPoint, velocity: CGFloat) //, chordVariant: Int)
}

extension Date {
    //            _ = Date().millisecondsSince1970 // 1476889390939
    //            _ = Date(milliseconds: 0) // "Dec 31, 1969, 4:00 PM" (PDT variant of 1970 UTC)
    var millisecondsSince1970:Int64 {return Int64((self.timeIntervalSince1970 * 1000.0).rounded())}
    init(milliseconds:Int) {self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))}
}

extension Double {
    func asMaxRandom() -> Double {
        let maximum = self
        return Double(Int({Int(arc4random_uniform(UInt32(maximum)))}()))
    }}

class Conductor {
    let client: ViewController
    let orchestra = AudioService()
    
    var currentVelocity: CGPoint = CGPoint(x: 0, y: 0)
    var triggerEnabled = true
    var timerNoteOff: Timer?
    let releaseTime: Double = 0.5
    
    let chords = NoteNumberService()
    var chordIndex = 0
    var chordVariant = 0
    var octaveZonesCount = 3 //limited notes in scale
    var octaveIndex = 1
    var fourFingerTranspose = 0 //transposes - 1
    
    let sequence:[Int] = [0, 1, 2, 1, 3, 2, 0, 1]
    var sequenceIndex = 0
    
    var autoPlaytimer: Timer?
    var autoPlayInterval = 0.25
    var autoPlayCancelled = false
    
    var recording: Bool = false
    var recordedEvents: [SwipeEvent] = []
    var recordStarted: Date?
    
    let replayEnabled = false
    var replaySequenceIndex = 0
    var replayTimer: Timer?
    
    init(_ swipeVC: ViewController) {
        client = swipeVC
        orchestra.conductor = self
        playRecursive()
    }
    
    @objc func gestureAction(_ sender:UIPanGestureRecognizer) {
        handleEventWith(SenderData(
            velocity: sender.velocity(in: client.view),
            position: sender.location(in: client.view),
            fingerCount: sender.numberOfTouches))
    }
}

extension Conductor {
    
    func handleEventWith(_ data: SenderData) {
        
        let position = data.position
        //            sender.location(in: client.view)
        let velocity = data.velocity
        //            sender.velocity(in: client.view)
        
        handleNumberOfTouches(data.fingerCount)
        handlePan(position)
        
        //next phrase
        if triggerEnabled {
            if recording { recordStarted = Date()}
            playNextNote(data)
            triggerEnabled = false
            client.chordChanged()
        }
        
        let directionChanged = (velocity.y > 0 && currentVelocity.y < 0) || (velocity.y < 0 && currentVelocity.y > 0)
        if (directionChanged) {
            //transport sequence to next note and play it
            sequenceIndex += 1
            self.playNextNote(data)
        }
        currentVelocity.y = velocity.y
        
        //prepare note release
        //accomplish continuous postponement of NoteOff event while still panning
        if let _ = timerNoteOff {
            //cancel previous noteOff
            timerNoteOff?.invalidate()
            timerNoteOff = nil
        }
        //accomplish continuous reset of timer to invoke noteOff after releaseTime after pan ends
        self.timerNoteOff = Timer.scheduledTimer(timeInterval: releaseTime, target:self, selector: #selector(self.triggerNoteOffEvent), userInfo: nil, repeats: false)
    }
    
    func handleNumberOfTouches(_ fingerCount: Int) {
        fourFingerTranspose = fingerCount == 4 ? -1 : 0
        self.chordVariant = fingerCount == 4 ? 0 : max(fingerCount - 1, 0)
    }
    
    func handlePan(_ pos: CGPoint) {
        
        let chordFromLocation = min(
            Int((pos.x/client.view.bounds.size.width) * CGFloat(chords.numberOfRegions)),
            chords.numberOfRegions - 1)
        
        //chord changes
        if chordIndex != chordFromLocation {
            chordIndex = chordFromLocation
            client.chordChanged()
        }
        
        //oct changes
        let octaveFromLocation = Int((pos.y / client.view.bounds.size.height) * CGFloat(octaveZonesCount))
        if (octaveIndex != octaveFromLocation) {
            octaveIndex = octaveFromLocation
        }
        
        //animate
        let limiter = 16
        let velocity: CGFloat = currentVelocity.y / CGFloat(limiter)
        client.visualizePlaying(position: pos, velocity: velocity)
    }
}

extension Conductor {
    
    func playNextNote(_ data: SenderData) {
        
        noteOn(note: MIDINoteNumber(determineCurrentNote()))
        
        //record it
        if recording, let start = recordStarted {
            recordedEvents.append(SwipeEvent(
                at: Int64(Date().millisecondsSince1970 - start.millisecondsSince1970),
                data: data))
        }
    }
    
    func determineCurrentNote() -> Int {
        let octave = octaveIndex == 0 ? -12 : ( octaveIndex == 2 ? 12 : 0)
        
        return octave + 40 + chords.scales[self.chordVariant][self.chordIndex % self.chords.scales[0].count][sequence[sequenceIndex % sequence.count]] + fourFingerTranspose
    }
    
    func noteOn(note: MIDINoteNumber) {
        orchestra.play(noteNumber: note)
    }
    
    @objc func triggerNoteOffEvent() {
        timerNoteOff?.invalidate()
        timerNoteOff = nil
        
        sequenceIndex = 0
        triggerEnabled = true
        client.phraseEnded()
        orchestra.allNotesOff()
        
        print("recordedEvents.count: \(recordedEvents.count)")
        recordStarted = nil
        recording = false
        
        if replayEnabled {replayEvents()}
        if !autoPlayCancelled {autoPlayCancelled = true}
    }
    
}

extension Conductor {
    
    @objc func playRecursive() {
        let initialEvent = SenderData(velocity: CGPoint(x: 0, y: 0),
                                      position: CGPoint(x: 0, y: 0),
                                      fingerCount: 0)
        playNextNote(initialEvent)
        sequenceIndex += 1
        
        if sequenceIndex > 100 || autoPlayCancelled {
            orchestra.allNotesOff()
            return
        }

        chordIndex += 1
        client.chordChanged()

        //schedule next trigger
        self.autoPlaytimer = Timer.scheduledTimer(timeInterval: autoPlayInterval, target:self, selector: #selector(self.playRecursive), userInfo: nil, repeats: false)
    }
    
    @objc func replayEvents() {
        
        guard recordedEvents.count > replaySequenceIndex else {
            
            replaySequenceIndex = 0
            recordedEvents = []
            replayTimer?.invalidate()
            self.replayTimer = nil
            recording = replayEnabled
            print("replay ended")
            return
        }
        
        handleEventWith(recordedEvents[replaySequenceIndex].data)
        
        //schedule next trigger
        var interval = recordedEvents[replaySequenceIndex].at
        replaySequenceIndex += 1
        if replaySequenceIndex < recordedEvents.count {
            interval = recordedEvents[replaySequenceIndex].at - interval
            let intervalResult = Double(interval) / 1000
            
            self.replayTimer = Timer.scheduledTimer(timeInterval: intervalResult, target:self, selector: #selector(self.replayEvents), userInfo: nil, repeats: false)
        }
    }
}
