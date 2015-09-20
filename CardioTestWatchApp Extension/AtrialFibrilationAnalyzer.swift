//
//  AtrialFibrilationAnalyzer.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/6/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import HealthKit
import Foundation

class AtrialFibrilationDiagnosis {
    var result : String
    var rMSSD : Double
    var shannonEntropy : Double?
    var positive = false
    
    init(result: String) {
        self.result = result
        self.rMSSD = 0
    }
    
    init(result: String, rMSSD: Double, positive: Bool) {
        self.result = result
        self.rMSSD = rMSSD
        self.positive = positive
    }
}

class AtrialFibrilationAnalyzer {
    let minimumSampleCount : Int = 16
    let requiredSamples : Int = 16
    let sampleUnit = HKUnit(fromString: "count/min")
    let THrmssd = 0.115
    let THshe = 0.55
    
    func analyze(samples: [HKQuantitySample]) -> AtrialFibrilationDiagnosis {
        var result = "Not enough info"
        var positive = false
        
        let reducedSamples = self.reduceSamples(samples)
        
        if reducedSamples.count >= minimumSampleCount {
            let rrIntervals = self.calculateRRIntervals(reducedSamples)
            let rMSSD = self.calculateNormalizedRMSSD(rrIntervals)
            let she = self.calculateShE(rrIntervals)
            print("ShE", she)
            
            if rMSSD > THrmssd && she > THshe {
                result = "Irregular"
                positive = true
            } else {
                result = "Regular"
            }
            
            return AtrialFibrilationDiagnosis(result: result, rMSSD: rMSSD, positive: positive)
        }
        
        return AtrialFibrilationDiagnosis(result: result)
    }
    
    func calculateRRIntervals(samples: [HKQuantitySample]) -> [Double] {
        // See https://courses.kcumb.edu/physio/ecg%20primer/normecgcalcs.htm#The R-R interval
        // on how RR and BPM are related.
        var result : [Double] = []
        
        for sample in samples {
            let bpm = sample.quantity.doubleValueForUnit(sampleUnit)
            result.append(60.0 / bpm)
        }
        
        return result
    }
    
    func reduceSamples(samples: [HKQuantitySample]) -> [HKQuantitySample] {
        let count = samples.count
        let downLimit = [0, count - requiredSamples].maxElement()!
        return Array(samples[downLimit..<count])
    }
    
    func calculateNormalizedRMSSD(rrIntervals: [Double]) -> Double {
        /* Turns out the original formula in the paper was wrong
         http://www.heartrhythmjournal.com/article/S1547-5271%2812%2901435-X/fulltext
         To calculate RMSSD I followed: https://www.biopac.com/researchApplications.asp?Aid=32&AF=450&Level=3
         Then the flow in the paper indicates that we need RMSSD/mean but the formula showed sum instead of mean
        */
        let j = rrIntervals.count
        let sum = rrIntervals.reduce(0.0, combine: +)
        let mean = sum / Double(j)
        
        var squaresSum : Double = 0
        for i in 0..<(j - 1) {
            squaresSum += pow(rrIntervals[i + 1] - rrIntervals[i], 2)
        }
        
        let squareRoot = sqrt(squaresSum / (Double(j) - 1))
        print("normalized RSMMD", squareRoot / mean)
        
        return squareRoot / mean
    }
    
    func calculateShE(rrIntervals: [Double]) -> Double {
        // Ref: http://www.heartrhythmjournal.com/article/S1547-5271%2812%2901435-X/fulltext
        let j = rrIntervals.count
        
        let min = rrIntervals.minElement()!
        let max = rrIntervals.maxElement()!
        
        let N = 16
        let delta = (max - min) / Double(N)
        var bins : [Int: Int] = [:]
        
        // Calculate N(i)
        for rrInterval in rrIntervals {
            let binIndex = Int((rrInterval - min) / delta - 0.05)
            if bins.indexForKey(binIndex) == nil {
                bins[binIndex] = 1
            } else {
                bins[binIndex] = bins[binIndex]! + 1
            }
        }
        
        var sum = 0.0
        
        for (_, ni) in bins {
            let pi = Double(ni) / Double(j)
            sum += pi * log(pi)
        }
        
        return -sum
    }
}