//
//  Scales.swift
//  ChordSwiper
//
//  Created by Jeroen Dunselman on 11/04/2019.
//  Copyright © 2019 Jeroen Dunselman. All rights reserved.
//

import Foundation

class NoteNumberService {
    
    //Present musical scales defined as note numbers
    let notes = IntervalTypes()
    var scales:[[[Int]]] = [[], [], []]
    
    //   Chords, determined from swipe position
    //Default chord layout for 4 swipe strips
    let numberOfRegions = 4
    /*'Minor', 'Root', 'Fourth' & 'Fifth' chords for regions:
     0: A minor -> notes (E, A, C) -> notenumbers 17;24;29;
     1: C (C, E, G),
     2: F (F, C, A) &
     3: G (G, B, D). */
    
    //    Scale variant, determined from number of touches
    enum row: Int {case basic = 0, variantVII, variantVI }
    //    VII'th: two finger swipe, intervalType: 'scale*7' &
    //    VI'th': three finger swipe, intervalType: 'scale*6'.
    //    (Four finger swipe uses .basic)
    
    //store notenumber data for each chord of region, to row for each scale variant
    init() {
        appendNotes(row.basic.rawValue,
                    [notes.scaleMinA, notes.scaleMajC, notes.scaleMajF, notes.scaleMajG     ])
        appendNotes(row.variantVII.rawValue,
                    [notes.scaleMinA7, notes.scaleMajC7, notes.scaleMajF7, notes.scaleMajG7 ])
        appendNotes(row.variantVI.rawValue,
                    [notes.scaleMinA6, notes.scaleMajC6, notes.scaleMajF6, notes.scaleMajG6 ])
    }
    
    func appendNotes(_ row: Int, _ regions: [String]) {
        for chord in regions {
            let scale:[Int] = chord.components(separatedBy: ";").map {return Int($0)!}
            scales[row].append(scale)
        }
    }
    
    struct IntervalTypes {
        //basic, one finger swipe
        let scaleMinA = "17;24;29;32;36;41;44;48;53;56;60;65;68;72"
        let scaleMajC = "20;24;27;32;36;39;44;48;51;56;60;63;68;72"
        let scaleMajF = "13;17;20;25;29;32;37;41;44;49;53;56;61;65"
        let scaleMajG = "15;19;22;27;31;34;39;43;46;51;55;58;63;67"
        //chord variant type 'VII', two finger swipe
        let scaleMinA7 = "17;24;27;32;36;39;41;44;48;51;56;60;63;65;68;72"
        let scaleMajC7 = "20;24;27;30;32;36;39;42;44;48;51;54;56;60;63;66;68;72"
        let scaleMajF7 = "13;17;20;23;29;32;35;37;41;44;47;53;56;59;61;65"
        let scaleMajG7 = "15;19;22;25;31;34;39;43;46;49;51;55;58;63;67"
        //chord variant type 'VI', three finger swipe
        let scaleMinA6 = "17;24;26;32;36;39;41;44;48;51;56;60;63;65;68;72"
        let scaleMajC6 = "20;24;27;29;32;36;39;41;44;48;51;53;56;60;63;65;68;72"
        let scaleMajF6 = "13;17;20;22;29;32;34;37;41;44;46;53;56;56;61;65"
        let scaleMajG6 = "15;19;22;24;31;34;36;39;43;46;48;51;55;57;63;67"
    }
}

