//
//  ViewController.swift
//  ChordSwiper
//
//  Created by Jeroen Dunselman on 11/04/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import UIKit

class GestureViewController: UIViewController {
    public var panGesture = UIPanGestureRecognizer()
    //visual response to swipe
    let emitterLayer = CAEmitterLayer()
    let colors = [UIColor.blue, UIColor.red, UIColor.green, UIColor.yellow]
    var guides: [UIView] = []
    override func viewDidLoad() {
        
    }
    
}

class SwipeOPhoneConductor: Conductor {
    let sclient: ViewController
    override init(_ swipeVC: ViewController) {
        sclient = swipeVC
        super.init(sclient)
    }
    @objc override func gestureAction(_ sender:UIPanGestureRecognizer) {
        //        let pos = sender.location(in: client.view)
        //        let velocity = sender.velocity(in: client.view)
        //
        //        handleNumberOfTouches(sender)
    }
}

class ViewController: GestureViewController {
    
    var zoneCount = 0
    //audio response to swipe
    var conductor: Conductor?
    //    var sconductor: SwipeOPhoneConductor?
    
    override func viewDidLoad() {
        
        
        conductor = Conductor(self)
        //        sconductor = SwipeOPhoneConductor(self)
        
        if conductor != nil {
            zoneCount = (conductor?.chords.numberOfRegions)!
        }
        super.viewDidLoad()
        
        self.panGesture = UIPanGestureRecognizer(target: self.conductor!, action: #selector(conductor?.gestureAction(_:)))
        
        //        self.panGesture = UIPanGestureRecognizer(target: sconductor, action: #selector(sconductor?.gestureAction(_:)))
        
        self.panGesture.maximumNumberOfTouches = 4
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(panGesture)
        
        prepareChordGuide()
        prepareEmitterLayer()
        
        //        conductor?.playContinuous()
    }
    
}

extension ViewController: Conductable {
    
    func visualizePlaying(position: CGPoint, velocity: CGFloat){
        emitterLayer.emitterPosition = position
        emitterLayer.birthRate = Float(velocity < 0 ? velocity * -1 : velocity)
    }
    
    func chordChanged() {
        
        //  show/hide chord colors for current
        for i in 0..<zoneCount {
            let alphaValue:CGFloat = i == ((conductor?.chordIndex)! % zoneCount) ? 0.7 : 0.0
            UIView.animate(withDuration: 0.0) {
                self.guides[i].alpha = alphaValue
            }
        }
        
        emitterLayer.setValue(colors[colors.count.asMaxRandom()].cgColor, forKey: "emitterCells.fire.color")
    }
    
    func phraseEnded() {
        //  hide chord colors
        for g in guides {UIView.animate(withDuration: 0.2) {g.alpha = 0.0} }
        emitterLayer.birthRate = 0
        
        //            //    vwBtnShowHideSetting.alpha = 0.7
        //            //    isVisibleVwBtnShowHideSetting = true
    }
}

extension Int {
    
    func asMaxRandom() -> Int {
        let maximum = self
        return Int({Int(arc4random_uniform(UInt32(maximum)))}())
    }
}

extension ViewController {
    
    func prepareChordGuide() {
        
        for i in 0..<zoneCount { //chordZonesCount {
            let g = UIView()
            g.alpha = 0.0
            
            let xPos = CGFloat(i) * (self.view.bounds.width / CGFloat(zoneCount ))
            g.frame = CGRect(origin: CGPoint(x: xPos, y: 0),
                             size: CGSize(width: self.view.bounds.width / CGFloat(zoneCount),
                                          height: self.view.bounds.height ))
            let h = UIImageView()
            h.frame = CGRect(origin: CGPoint(x: 10, y: 10),
                             size: CGSize(width: g.bounds.width - 10,
                                          height: g.bounds.height - 10))
            h.backgroundColor = colors[(i % colors.count)]
            g.addSubview(h)
            
            //            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            //            g.addSubview(blur)
            
            guides.append(g)
            self.view.addSubview(g)
        }
    }
    
    func prepareEmitterLayer() {
        let fire = Fire() //CAEmitterCell()
        
        self.emitterLayer.emitterCells = [fire.cell]
        self.emitterLayer.emitterMode = CAEmitterLayerEmitterMode.outline
        self.emitterLayer.emitterShape = CAEmitterLayerEmitterShape.circle
        self.emitterLayer.emitterSize = CGSize(width: 5, height: 5)
        
        self.view.layer.addSublayer(self.emitterLayer)
    }
}

