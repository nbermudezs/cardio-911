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

class DiagnoseInterfaceController: WKInterfaceController, WorkoutSessionManagerDelegate, TropoGatewayDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var bpmLabel: WKInterfaceLabel!
    
    @IBOutlet var diagnosisLabel: WKInterfaceLabel!
    
    @IBOutlet var rmssdLabel: WKInterfaceLabel!
    
    @IBOutlet var heartIcon: WKInterfaceImage!
    
    // MARK: Properties
    let healthStore : HKHealthStore = HKHealthStore()
    let tropoGateway = TropoGateway()
    
    var sessionManager : WorkoutSessionManager
    var useFakeAfHeartRate = false
    var beatDuration = 0.0
    
    var animationSpeed:Double {
        get {
            return self.beatDuration / 2.0
        }
    }
    var notAlertedYet = true
    var playHapticFeedback = true
    
    // MARK: Overrides
    
    override init() {
        let context = WorkoutSessionContext(healthStore: healthStore, activityType: .Other, locationType: .Unknown)
        sessionManager = WorkoutSessionManager(context: context)
        
        super.init()
        
        sessionManager.delegate = self
        tropoGateway.delegate = self
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
            if notAlertedYet {
                alertUser()
            }
        } else {
            notAlertedYet = true
        }
    }
    
    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHeartRateSample heartRateSample: HKQuantitySample) {
        let bpm = heartRateSample.quantity.doubleValueForUnit(HKUnit(fromString: "count/min"))
        bpmLabel.setText("\(Int(bpm))")
        self.beatDuration = 60 / bpm;
    }
    
    // MARK: Emergency handling
    
    private func alertUser() {
        if playHapticFeedback {
            WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Failure)
        }
        self.showAlertControllerWithStyle(WKAlertControllerStyle.SideBySideButtonsAlert)
        self.notAlertedYet = false
    }
    
    private func showAlertControllerWithStyle(style: WKAlertControllerStyle!) {
        
        let cancelAction = WKAlertAction(
            title: "No",
            style: WKAlertActionStyle.Cancel) { () -> Void in
                // TODO: Add action to re-enable it, maybe a "I'm OK" button the user can click
                self.playHapticFeedback = false
                print("Haptic Feedback disabled")
        }
        
        let notifyAction = WKAlertAction(
            title: "Yes",
            style: WKAlertActionStyle.Destructive) { () -> Void in
                self.callContact()
        }
        
        self.presentAlertControllerWithTitle(
            "Everything OK?",
            message: "Your heart rate went crazy for a moment. Want to notify someone?",
            preferredStyle: style,
            actions: [notifyAction, cancelAction])
    }
    
    private func callContact() {
        tropoGateway.notifyUserInTroubles("+13122398676", name: NSFullUserName())
    }
    
    func callDidSucceed() {
        let okAction = WKAlertAction(
            title: "OK",
            style: WKAlertActionStyle.Default) { () -> Void in
                
        }
        
        self.presentAlertControllerWithTitle(
            "Help on its way",
            message: "Your contact has been notified",
            preferredStyle: WKAlertControllerStyle.Alert,
            actions: [okAction])
    }

}
