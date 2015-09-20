//
//  BeatPattern.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/13/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

struct BeatPattern {
    var icon = ""
    var description = "Mid-range"
    var bpm = 80
    
    var duration: Double {
        return 60.0 / Double(bpm)
    }
}