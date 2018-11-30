//
//  ErrorHandling.swift
//  Notifications
//
//  Created by WCA on 7/17/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation

public struct Log {
	
	static var operationQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	
	public static func error(with lineNumber: Int, functionName: String, error: Error?, enabled: Bool = true, alert: Bool = true) {
		#if !RELEASE
		if enabled == true {
			if let error: NSError = error as NSError? {
				var messageString: String = "ERROR [\(error.domain): \(error.code) \(error.localizedDescription)]"
				if error.localizedFailureReason != nil {
					messageString.append(" \(String(describing: error.localizedFailureReason))")
				}
				if error.userInfo[NSUnderlyingErrorKey] != nil {
					messageString.append(" \(String(describing: error.userInfo[NSUnderlyingErrorKey]))")
				}
				if error.localizedRecoverySuggestion != nil {
					messageString.append(" \(String(describing: error.localizedRecoverySuggestion))")
				}
				messageString.append(" \(functionName) — \(lineNumber)]\n")
				message(messageString, alert:alert)
			}
		}
		#endif
	}
	
	public static func message(_ string:String, enabled: Bool = true, alert: Bool = false) {
		#if !RELEASE
		if enabled == true || operationQueue.operationCount > 0 {
			let dateFormatter: DateFormatter = DateFormatter()
			dateFormatter.dateFormat = "h:mm:ss.SSS"
			let dateString = dateFormatter.string(from: Date())
			print("\n\(dateString) — \(string)")
		}
		
		if alert == true {
			operationQueue.addOperation {
				let group = DispatchGroup()
				group.enter()
				DispatchQueue.main.async {
					
					let message = string
					let alertController = UIAlertController(
						title: "Warning",
						message: message,
						preferredStyle: .alert)
					
					alertController.addAction(UIAlertAction(title: "Okay", style: .default) {_ in
						group.leave()
					})
					if let
						appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
						let window = appDelegate.window,
						let rootViewController = window!.rootViewController {
						rootViewController.present(alertController, animated: true, completion: nil)
					}
				}
				// Wait until the alert is dismissed by the user tapping on the OK button.
				group.wait()
			}
		}
		#endif
	}
}


