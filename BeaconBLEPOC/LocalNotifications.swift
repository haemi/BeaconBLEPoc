//
//  LocalNotifications.swift
//  BeaconBLEPOC
//
//  Created by Stefan Walkner on 14.09.16.
//  Copyright © 2016 Stefan Walkner. All rights reserved.
//

import Foundation

import UIKit

struct LocalNotifications {
    static func sendLocalNotification(text: String, shouldRepeat: Bool) {
        let notification = UILocalNotification()
        notification.alertBody = text
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = NSDate(timeIntervalSinceNow: 0)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        
        if shouldRepeat {
            notification.repeatInterval = .Minute
        }
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
}
