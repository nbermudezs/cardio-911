//
//  InterfaceController.swift
//  CardioTestWatchApp Extension
//
//  Created by Nestor Bermudez Sarmiento on 9/5/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import WatchKit
import HealthKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    let healthStore : HKHealthStore = HKHealthStore()
    
    @IBOutlet var timer: WKInterfaceTimer!
    
    @IBOutlet var slider: WKInterfaceSlider!
    
    @IBOutlet var startButton: WKInterfaceButton!
    
    var realTimer : NSTimer = NSTimer()
    var sliderValue : Double = 11.0
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let typesToShare = Set([HKObjectType.workoutType()])
        let typesToRead = Set([
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            ])
        self.healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { success, error in
            
        }
        
        self.sliderDidChange(Float(sliderValue))
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func sliderDidChange(value: Float) {
        let targetDate = NSDate(timeIntervalSinceNow: NSTimeInterval(value * 60.0 + 1.0))
        if realTimer.valid { realTimer.invalidate() }
        timer.setDate(targetDate)
        timer.stop()
        self.sliderValue = Double(value)
    }

    @IBAction func startDiagnosis() {
//        realTimer = NSTimer(timeInterval: NSTimeInterval(sliderValue * 60.0 + 1.0), target: self, selector: "timerFinished", userInfo: nil, repeats: false)
//        
//        let targetDate = NSDate(timeIntervalSinceNow: NSTimeInterval(sliderValue * 60.0 + 1.0))
//        timer.setDate(targetDate)
//        timer.start()
        
        self.presentControllerWithName("diagnoseController", context: nil)
    }
    
    func timerFinished()
    {
        // Any custom code to be executed after the timer finishes can be put here
        self.sliderDidChange(Float(sliderValue))
    }
}
