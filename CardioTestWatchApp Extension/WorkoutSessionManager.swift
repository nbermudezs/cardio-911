//
//  WorkoutSessionManager.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/5/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import HealthKit
import Foundation

class WorkoutSessionContext {
    let healthStore : HKHealthStore
    var activityType : HKWorkoutActivityType
    var locationType : HKWorkoutSessionLocationType
    
    init(healthStore: HKHealthStore, activityType: HKWorkoutActivityType = .Other, locationType: HKWorkoutSessionLocationType = .Unknown) {
        self.healthStore = healthStore
        self.activityType = activityType
        self.locationType = locationType
    }
}

protocol WorkoutSessionManagerDelegate: class {
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate)
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStopWorkoutWithDate stopDate: Bool)
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample)
    func workoutSessionManager(WorkoutSessionManager: WorkoutSessionManager, didUpdateHrvAnalysis result: AtrialFibrilationDiagnosis)
}

public class WorkoutSessionManager : NSObject, HKWorkoutSessionDelegate {
    let healthStore : HKHealthStore
    let workoutSession : HKWorkoutSession
    
    var workoutStartDate: NSDate?
    var workoutStopDate: NSDate?
    
    var queries: [HKQuery] = []
    
    var heartRateSamples: [HKQuantitySample] = []
    
    let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    
    var currentHeartRateSample: HKQuantitySample?
    var currentAtrialFibrilationResult: String?
    var afAnalyzer : AtrialFibrilationAnalyzer = AtrialFibrilationAnalyzer()
    var useFakeAfHeartRate = false
    
    weak var delegate: WorkoutSessionManagerDelegate?
    
    init(context: WorkoutSessionContext) {
        self.healthStore = context.healthStore
        self.workoutSession = HKWorkoutSession(activityType: context.activityType, locationType: context.locationType)
        
        super.init()
        self.workoutSession.delegate = self
    }
    
    func startWorkout() {
        self.healthStore.startWorkoutSession(self.workoutSession)
    }
    
    func stopWorkoutAndSave() {
        self.healthStore.endWorkoutSession(self.workoutSession)
    }
    
    // MARK : HKWorkoutSessionDelegate
    
    public func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        dispatch_async(dispatch_get_main_queue()) {
            switch toState {
            case .Running:
                self.workoutDidStart(date)
            case .Ended:
                self.workoutDidEnd(date)
            default:
                print("Unexpected session state \(toState)")
            }
        }
    }
    
    public func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        //
    }
    
    // MARK: Internal
    
    func workoutDidStart(date: NSDate) {
        self.workoutStartDate = date
        
        queries.append(self.createStreamingHearRateQuery(date))
        
        for query in queries {
            self.healthStore.executeQuery(query)
        }
        
        self.delegate?.workoutSessionManager(self, didStartWorkoutWithDate: date)
    }
    
    func workoutDidEnd(date: NSDate) {
        self.workoutStopDate = date
        
        for query in queries {
            self.healthStore.stopQuery(query)
        }
        
        self.queries.removeAll()
        
        self.delegate?.workoutSessionManager(self, didStopWorkoutWithDate: true)
        
        self.saveWorkout()
    }
    
    func saveWorkout() {
        
    }
    
    func analyzeHeartRate(samples: [HKQuantitySample]) {
        let diagnosis = self.afAnalyzer.analyze(samples)
        self.delegate?.workoutSessionManager(self, didUpdateHrvAnalysis: diagnosis)
    }
    
    // MARK: Queries
    
    func createStreamingHearRateQuery(workoutStartDate: NSDate) -> HKQuery {
        let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: .None)
        let heartRateQuery = HKAnchoredObjectQuery(type: self.heartRateType!, predicate: predicate, anchor: nil, limit: 0) { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addHeartRateSamples(samples!)
        }
        
        heartRateQuery.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addHeartRateSamples(samples!)
        }
        
        return heartRateQuery
    }
    
    func addHeartRateSamples(samples: [HKSample]) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            let decide = arc4random_uniform(1) < 1 ? false : true
            let randomSamples: [HKQuantitySample] = [
                self.createRandomSample(decide),
                self.createRandomSample(!decide)
            ]
            let finalSamples = self.useFakeAfHeartRate ? randomSamples : heartRateSamples
            self.heartRateSamples += finalSamples
            
            self.analyzeHeartRate(self.heartRateSamples)
            
            if heartRateSamples.count > 0 {
                self.currentHeartRateSample = finalSamples[0]
                self.delegate?.workoutSessionManager(self, didUpdateHeartRateSample: self.currentHeartRateSample!)
            }
        }
    }
    
    func createRandomSample(min: Bool) -> HKQuantitySample {
        let minVal : Double = min ? 50 : 150
        let bpm = Double(arc4random_uniform(70)) + minVal
        let quantity = HKQuantity(unit: HKUnit(fromString: "count/min"), doubleValue: bpm)
        
        return HKQuantitySample(type: self.heartRateType!, quantity: quantity, startDate: NSDate(), endDate: NSDate())
    }
}