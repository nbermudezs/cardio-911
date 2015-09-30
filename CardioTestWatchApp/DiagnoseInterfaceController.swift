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
import CoreLocation

class DiagnoseInterfaceController: WKInterfaceController, WorkoutSessionManagerDelegate, GatewayDelegate, CLLocationManagerDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var bpmLabel: WKInterfaceLabel!

    @IBOutlet var rmssdLabel: WKInterfaceLabel!

    @IBOutlet var locationLabel: WKInterfaceLabel!

    @IBOutlet var heartIcon: WKInterfaceImage!

    // MARK: Properties
    let healthStore : HKHealthStore = HKHealthStore()
    let gateway: Gateway
    let locationManager: CLLocationManager = CLLocationManager()
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
    var isRequestingLocation = false
    
    // MARK: Overrides
    
    override init() {
        gateway = TropoGateway()

        super.init()

        self.initWorkoutSessionManager()
        gateway.delegate = self

        self.locationManager.delegate = self
    }
    
    override func willActivate() {
        self.locationManager.requestAlwaysAuthorization()

        self.checkHealthKitAuthorization(self.hkAuthorizationCallback)
        self.startAnimation()
    }
    
    override func didDeactivate() {
        
    }

    private func initWorkoutSessionManager() {
        let context = WorkoutSessionContext(healthStore: healthStore, activityType: .Other, locationType: .Unknown)
        self.sessionManager = WorkoutSessionManager(context: context)
        self.sessionManager?.delegate = self
    }

    private func checkHealthKitAuthorization(callback: (Bool, NSError?) -> Void) {
        let typesToShare = Set([HKObjectType.workoutType()])
        let typesToRead = Set([
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            ])
        self.healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead, completion: callback)
    }

    private func hkAuthorizationCallback(success: Bool, error: NSError?) {
        if success {
            self.checkCoreLocationAuthorization()
            self.healthAccessAuthorized()
        } else {
            self.healthAccessDenied()
        }
    }

    private func checkCoreLocationAuthorization() {
        guard !isRequestingLocation else {
            locationManager.stopUpdatingLocation()
            isRequestingLocation = false

            return
        }

        let authorizationStatus = CLLocationManager.authorizationStatus()

        if authorizationStatus == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
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
        self.checkHealthKitAuthorization(self.hkAuthorizationCallback)
    }

    @IBAction func requestLocation() {
        self.locationManager.requestLocation()
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
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.requestLocation()
        } else {
            self.callContactWithLocation("Unknown location")
        }
    }

    private func callContactWithLocation(location: String) {
        let name = "Nestor Bermudez"
        print(location, name)
        self.gateway.sendVoiceCall("+13122011010", to: "+13122398676", data: ["name": name, "location": location])
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

    // MARK: Implement CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count == 0 { return }
        let coordinate = locations[0].coordinate
        let location = String(format: "%f latitude, %f longitude", coordinate.latitude, coordinate.longitude)
        self.locationLabel.setText(location)
        //self.callContactWithLocation(location)
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("didChangeAuthorizationStatus")
        print(status)
    }

    // MARK: Geo location

    private func getCurrentLocation(callback: (String) -> Void) {
        callback("Burger King, Central Park")
    }
}
