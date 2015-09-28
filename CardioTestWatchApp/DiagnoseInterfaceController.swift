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

class DiagnoseInterfaceController: WKInterfaceController, WorkoutSessionManagerDelegate, GatewayDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var bpmLabel: WKInterfaceLabel!

    @IBOutlet var rmssdLabel: WKInterfaceLabel!
    
    @IBOutlet var heartIcon: WKInterfaceImage!
    
    // MARK: Properties
    let healthStore : HKHealthStore = HKHealthStore()
    let gateway: Gateway
    let alertWaitTime: Int = 30 // seconds
    var timer: NSTimer? = nil
    
    var sessionManager : WorkoutSessionManager? = nil
    var useFakeAfHeartRate = false
    var beatDuration = 0.0
    
    var animationSpeed:Double {
        get {
            return self.beatDuration / 2.0
        }
    }

    // MARK: Flags
    var notAlertedYet = true
    var playHapticFeedback = true
    var alertResponded = false
    
    // MARK: Overrides
    
    override init() {
        gateway = TropoGateway()

        super.init()

        self.initWorkoutSessionManager()
        gateway.delegate = self
    }
    
    override func willActivate() {
        self.tryStartAnalysis()
        self.startAnimation()
    }
    
    override func didDeactivate() {
        
    }

    private func initWorkoutSessionManager() {
        let context = WorkoutSessionContext(healthStore: healthStore, activityType: .Other, locationType: .Unknown)
        self.sessionManager = WorkoutSessionManager(context: context)
        self.sessionManager?.delegate = self
    }

    private func tryStartAnalysis() {
        let typesToShare = Set([HKObjectType.workoutType()])
        let typesToRead = Set([
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            ])
        self.healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { success, error in
            if success {
                self.healthAccessAuthorized()
            } else {
                self.healthAccessDenied()
            }
        }
    }

    private func startAnimation() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1,
            target: self,
            selector: Selector("animateHeart"),
            userInfo: nil,
            repeats: true)
    }
    
    // MARK: Animation
    
    func animateHeart() {
        if self.animationSpeed > 0 {
            self.animateWithDuration(self.animationSpeed) { () -> Void in
                self.heartIcon.setWidth(70)
                self.heartIcon.setHeight(90)
            }
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.animationSpeed * double_t(NSEC_PER_SEC)))
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            dispatch_after(when, queue) { () -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    self.animateWithDuration(self.animationSpeed, animations: { () -> Void in
                        self.heartIcon.setWidth(60)
                        self.heartIcon.setHeight(80)
                    })
                })
            }
        }
    }

    // MARK: Authorization handling
    private func healthAccessAuthorized() {
        self.sessionManager?.startWorkout()
    }

    private func healthAccessDenied() {

    }

    // MARK: View Actions
    
    @IBAction func finishDiagnostic() {
        self.sessionManager?.stopWorkoutAndSave()
    }
    
    @IBAction func toggleFakeAf(value: Bool) {
        self.useFakeAfHeartRate = value
        sessionManager?.useFakeAfHeartRate = value
    }
    
    @IBAction func restartAnalysis() {
        self.finishDiagnostic()
        self.initWorkoutSessionManager()
        self.tryStartAnalysis()
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
        self.alertResponded = false

        let cancelAction = WKAlertAction(
            title: "No",
            style: WKAlertActionStyle.Cancel) { () -> Void in
                // TODO: Add action to re-enable it, maybe a "I'm OK" button the user can click
                self.playHapticFeedback = false
                print("Haptic Feedback disabled")
                self.unscheduleAutoNotify()
        }
        
        let notifyAction = WKAlertAction(
            title: "Yes",
            style: WKAlertActionStyle.Destructive) { () -> Void in
                self.unscheduleAutoNotify()
                self.callContact()
        }
        
        self.presentAlertControllerWithTitle(
            "Everything OK?",
            message: "Your heart rate went crazy for a moment. Want to notify someone?",
            preferredStyle: style,
            actions: [notifyAction, cancelAction])

        self.scheduleAutoNotify()
    }

    private func scheduleAutoNotify() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(self.alertWaitTime) * double_t(NSEC_PER_SEC)))
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_after(when, queue) { () -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if !self.alertResponded {
                    self.dismissController()
                    self.callContact()
                }
            })
        }

    }

    private func unscheduleAutoNotify() {
        self.alertResponded = true
    }
    
    private func callContact() {
        let name = "Nestor Bermudez" // NSFullUserName()
        let location = self.getCurrentLocation() // get location using location API
        gateway.sendVoiceCall("+13122011010", to: "+13122398676", data: ["name": name, "location": location])
    }

    // MARK: Implement WorkoutSessionManagerDelegate

    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStartWorkoutWithDate startDate: NSDate) {
        print("workout started!")
    }

    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didStopWorkoutWithDate stopDate: Bool) {
        print("workout ended")
        self.beatDuration = 0.0
    }

    func workoutSessionManager(workoutSessionManager: WorkoutSessionManager, didUpdateHrvAnalysis result: AtrialFibrilationDiagnosis) {
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

    // MARK: Implement GatewayDelegate
    func callDidSucceed() {
        notificationWasSuccessful()
    }

    func smsWasSent() {
        notificationWasSuccessful()
    }

    private func notificationWasSuccessful() {
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

    // MARK: Geo location

    private func getCurrentLocation() -> String {
        return "Burger King, Central Park"
    }
}
