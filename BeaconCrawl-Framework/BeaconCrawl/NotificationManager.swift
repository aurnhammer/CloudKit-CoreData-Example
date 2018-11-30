//
//  NotificationManager.swift
//  District-1 Admin
//
//  Created by WCA on 10/12/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import UserNotifications
import CloudKit

open class NotificationManager: NSObject {

	public static let shared = NotificationManager()

    override fileprivate init() {
        super.init()
        self.setup()
    }
    
	func setup() {
			swizzleAppDelegateNotifications()
		// We only register for remote notifactions to recieve silent Pushes
		// Use "NotificationManager.checkNotificationServices()" to ask for permisions when it is appropriate.
		#if !targetEnvironment(simulator)
		UIApplication.shared.registerForRemoteNotifications()
		#endif
	}
    
	@objc func emptyMethod() {
        Log.message("Application Delegate does not implement method")
    }
    
	// MARK: - Swizzle AppDelegate Notifications
	func swizzleAppDelegateNotifications() {
		
			swizzle(from:#selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)), to:#selector(NotificationManager.swizzle_application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
			
			swizzle(from:#selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)), to:#selector(NotificationManager.swizzle_application(_:didRegisterForRemoteNotificationsWithDeviceToken:)))
			
			swizzle(from:#selector(UIApplicationDelegate.application(_:userDidAcceptCloudKitShareWith:)), to:#selector(NotificationManager.swizzle_application(_:userDidAcceptCloudKitShareWith:)))
		
	}

    // Call me to swizzle

    func swizzle(from originalSelector:Selector, to swizzledSelector:Selector) {
		
		let applicationDelegateClass = type(of: UIApplication.shared.delegate!)
		let thisClass = NotificationManager.self
		
		var originalMethod = class_getInstanceMethod(applicationDelegateClass, originalSelector)
		
		if originalMethod == nil {
			originalMethod = class_getInstanceMethod(thisClass, #selector(emptyMethod))
		}
		
		if let swizzledMethod = class_getInstanceMethod(thisClass, swizzledSelector) {
			
			let didAddMethod: Bool = class_addMethod(applicationDelegateClass, originalSelector, method_getImplementation(swizzledMethod),  method_getTypeEncoding(swizzledMethod))
			
			if didAddMethod {
				class_replaceMethod(thisClass, swizzledSelector, method_getImplementation(originalMethod!),  method_getTypeEncoding(originalMethod!));
			}
			else {
				method_exchangeImplementations(originalMethod!, swizzledMethod)
			}
		}
	}
    
	@objc dynamic func swizzle_application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error){
        Log.error(with: #line, functionName: #function, error: error)
        NotificationManager.shared.swizzle_application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
	@objc dynamic func swizzle_application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        NotificationManager.shared.swizzle_application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
	@objc dynamic func swizzle_application(_ application: UIApplication,
                                     handleActionWithIdentifier identifier: String?,
                                     forRemoteNotification userInfo: [AnyHashable : Any],
                                     completionHandler: @escaping () -> Void){

        NotificationManager.shared.swizzle_application(application, handleActionWithIdentifier: identifier, forRemoteNotification: userInfo) {
            guard let identifier = identifier else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                return
            }
            switch identifier {
            case "declineAction":
                break
            case "answerAction":
                break
            default:
                break
            }
        }
    }

	@objc dynamic func swizzle_application(_ application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return NotificationManager.shared.swizzle_application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
	@objc dynamic func swizzle_application(_ application: UIApplication,
                              didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DataManager.shared.handleRemoteNotification(userInfo)
        
        NotificationManager.shared.swizzle_application(application, didReceiveRemoteNotification: userInfo) { (result) in
            completionHandler(result)
        }
    }
	
	@objc dynamic func swizzle_application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShareMetadata){
		DataManager.cloudKitManager.userDidAcceptCloudKitShare(with: cloudKitShareMetadata)
		NotificationManager.shared.swizzle_application(application, userDidAcceptCloudKitShareWith: cloudKitShareMetadata)
	}

 }

//  MARK: - Class Methods
extension NotificationManager {

	class public func notificationRequest(with notificationInfo: NSDictionary) -> UNNotificationRequest {
		let content = UNMutableNotificationContent()
		content.sound = UNNotificationSound(named: "beacon.caf")
		let recordName: String = notificationInfo.object(forKey: "recordName") as! String
		if let value = notificationInfo.value(forKey: "isCurrentWindow")  {
			content.userInfo["isCurrentWindow"] = value
		}
		if let value = notificationInfo.value(forKey: "showInApp")  {
			content.userInfo["showInApp"] = value
		}
		if let value = notificationInfo.value(forKey: "recordName") {
			content.userInfo["recordName"] =  value
		}
		if let title = notificationInfo.object(forKey: "title") as? String {
			content.title = title
		}
		if let subtitle = notificationInfo.object(forKey: "subtitle") as? String {
			content.subtitle = subtitle
		}
		if let body = notificationInfo.object(forKey: "body") as? String {
			content.body = body
		}
		var trigger: UNNotificationTrigger
		if let timeInterval: TimeInterval = notificationInfo.object(forKey: "timeInterval") as? TimeInterval {
			trigger = UNTimeIntervalNotificationTrigger(timeInterval:timeInterval, repeats: false)
		}
		else {
			let center = CLLocationCoordinate2D(latitude: 37.335400, longitude: -122.009201)
			let region = CLCircularRegion(center: center, radius: 2000.0, identifier: "Headquarters")
			region.notifyOnEntry = true
			region.notifyOnExit = false
			trigger = UNLocationNotificationTrigger(region: region, repeats: false)
		}
		// Create the request object.
		return UNNotificationRequest(identifier: "DistrictNotification" + "." + recordName, content: content, trigger: trigger)
	}
	

    class func wakeupRequest() -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
		content.sound = UNNotificationSound(named: "beacon.caf")
        content.title = NSString.localizedUserNotificationString(forKey: "Wake up!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Rise and shine! It's morning time!",
                                                                arguments: nil)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        // Create the request object.
        return UNNotificationRequest(identifier: "DistrictAlarm", content: content, trigger: trigger)
    }

    class public func add(request: UNNotificationRequest) {
        // Schedule the request.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            Log.error(with: #line, functionName: #function, error: error)
        }
    }

    class public func add(requests: [UNNotificationRequest]) {
        for request in requests {
            add(request: request)
        }
    }
}


// MARK: - Registering

extension NotificationManager {
    
	public class func checkNotificationServices(_ completionHandler:( (_ granted: Bool?) -> Void)? = nil) {
        
        let center = UNUserNotificationCenter.current()

		center.getNotificationSettings { (settings) in
			
			switch settings.authorizationStatus {
			case UNAuthorizationStatus.notDetermined:
				let userNotificationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
				center.requestAuthorization(options: userNotificationOptions) { (granted, error)
					in
					Log.error(with: #line, functionName: #function, error: error)
					
					// Enable or disable features based on authorization.
					let generalCategory = UNNotificationCategory(identifier: "GENERAL",
																 actions: [],
																 intentIdentifiers: [],
																 options: .customDismissAction)
					
					// Create the custom actions for the TIMER_EXPIRED category.
					let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION",
															title: "Snooze",
															options: UNNotificationActionOptions(rawValue: 0))
					let stopAction = UNNotificationAction(identifier: "STOP_ACTION",
														  title: "Stop",
														  options: .foreground)
					
					let expiredCategory = UNNotificationCategory(identifier: "TIMER_EXPIRED",
																 actions: [snoozeAction, stopAction],
																 intentIdentifiers: [],
																 options: UNNotificationCategoryOptions(rawValue: 0))
					
					// Register the category.
					center.setNotificationCategories([generalCategory, expiredCategory])
					completionHandler?(granted)
				}
			case UNAuthorizationStatus.authorized:
				completionHandler?(true)
			case UNAuthorizationStatus.denied:
				completionHandler?(false)
			default:
				completionHandler?(false)
			}
		}
	}
}

extension NotificationManager {
	
	public func registerForNotifications(_  geofenceTrigger: UNNotificationTrigger) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
			if granted {
				self.setupAndGenerateLocalNotification(geofenceTrigger)
			}
			if error != nil {
				print(error!)
			}
		}
	}
	
	func setupAndGenerateLocalNotification(_  geofenceTrigger: UNNotificationTrigger) {
		let content = UNMutableNotificationContent()
		content.title = "Geofence Notification"
		content.subtitle = "Core Location Region Monitoring"
		content.body = "You just entered/exited a geofence!"
		content.badge = 1
		content.sound = UNNotificationSound.default()
		
		let center = UNUserNotificationCenter.current()
		let request = UNNotificationRequest(identifier: "LocalNotification", content: content, trigger: geofenceTrigger)
		center.add(request) { error in
			if let error = error {
				print(error)
			}
		}
	}
	//UNNotificationRequest
	func removeNotifications() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}

}

