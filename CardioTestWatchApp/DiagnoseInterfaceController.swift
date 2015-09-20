//
//  DiagnoseInterfaceController.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/6/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation
import HealthKit
import WatchKit

class DiagnoseInterfaceController: WKInterfaceController, WorkoutSessionManagerDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var bpmLabel: WKInterfaceLabel!
    
    @IBOutlet var diagnosisLabel: WKInterfaceLabel!
    
    @IBOutlet var rmssdLabel: WKInterfaceLabel!
    
    @IBOutlet var heartIcon: WKInterfaceImage!
    
    // MARK: Properties
    let healthStore : HKHealthStore = HKHealthStore()
    let shrinkFactor = CGFloat(2.0 / 3)
    
    var sessionManager : WorkoutSessionManager
    var useFakeAfHeartRate = false
    var beatDuration = 0.0
    
    var expandFactor: CGFloat {
        return 1.0 / shrinkFactor
    }
    var animationSpeed:Double {
        get {
            return self.beatDuration / 2.0
        }
    }
    
    // MARK: Overrides
    
    override init() {
        let context = WorkoutSessionContext(healthStore: healthStore, activityType: .Other, locationType: .Unknown)
        sessionManager = WorkoutSessionManager(context: context)
        
        super.init()
        
        sessionManager.delegate = self
    }
    
    override func willActivate() {
        self.sessionManager.startWorkout()
        
        NSTimer.scheduledTimerWithTimeInterval(1,
            target: self,
            selector: Selector("animateHeart"),
            userInfo: nil,
            repeats: true)
    }
    
    override func didDeactivate() {
        
    }
    
    // MARK: Animation
    
    func animateHeart() {
        self.animateWithDuration(self.animationSpeed) { () -> Void in
            self.heartIcon.setWidth(50)
            self.heartIcon.setHeight(50)
        }
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.animationSpeed * double_t(NSEC_PER_SEC)))
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(when, queue) { () -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.animateWithDuration(self.animationSpeed, animations: { () -> Void in
                    self.heartIcon.setWidth(40)
                    self.heartIcon.setHeight(40)
                })
            })
        }

    }
    
    // MARK: View Actions
    
    @IBAction func finishDiagnostic() {
        self.sessionManager.stopWorkoutAndSave()
    }
    
    @IBAction func toggleFakeAf(value: Bool) {
        self.useFakeAfHeartRate = value
        sessionManager.useFakeAfHeartRate = value
    }
    // MARK: workoutSession callbacks
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate) {
        print("workout started!")
    }
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStopWorkoutWithDate stopDate: Bool) {
        print("workout ended")
    }
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHrvAnalysis result: AtrialFibrilationDiagnosis) {
        diagnosisLabel.setText(result.result)
        // print("rMSSD \(result.rMSSD)")
        rmssdLabel.setText(String(format: "%f", result.rMSSD))
        if result.positive {
            WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Failure)
            alertUser()
        }
    }
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample) {
        let bpm = heartRateSample.quantity.doubleValueForUnit(HKUnit(fromString: "count/min"))
        // print("BPM: \(bpm)")
        bpmLabel.setText("\(bpm)")
        self.beatDuration = 60 / bpm;
    }
    
    // MARK: Emergency handling
    
    func alertUser() {
        
    }
}
