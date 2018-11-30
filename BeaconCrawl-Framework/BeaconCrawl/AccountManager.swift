//
//  AccountManager.swift
//  GKSessionTest
//
//  Created by WCA on 3/17/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

import UIKit
import CloudKit
import GameKit
import CoreData

public protocol AccountStatusChange: class {
	
	func setupDataSource()

}

public class AccountManager: NSObject {

    public typealias RequestType = String

    public struct Require {
        public static let none = "RequestNone"
        public static let account = "RequestAccount"
        public static let identity = "RequestIdentity"
    }
	
	static var serialQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	
	public static let shared = AccountManager()
    public var accountStatus: CKAccountStatus?
    public static var accountChangedOperationCompletionBlocks: [((_ accountStatus: CKAccountStatus) -> Swift.Void)] = [((CKAccountStatus) -> Void)]()

    override init() {
        super.init()
        self.setup()
    }
    
    deinit {
        removeObservers()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
    
    func setup() {
        setupObservers()
    }

    func setupObservers() {
        // listen for user login token changes so we can refresh and reflect our UI based on user login
        NotificationCenter.default.addObserver(forName:.CKAccountChanged, object: nil, queue: nil) { (notification:Notification) in
           DataManager.Container.accountStatus { accountStatus, accountError in
			Log.error(with: #line, functionName: #function, error: accountError)
                if accountStatus != self.accountStatus {
                    self.accountStatus = accountStatus
                    for completionBlock in AccountManager.accountChangedOperationCompletionBlocks {
                        completionBlock(accountStatus)
                    }
                }
            }
        }
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func accountAvailable(viewController: AccountStatusChange? = nil, request: RequestType, _ completionHandler:@escaping (_ accountStatus: CKAccountStatus) -> Void) {
        if let viewController = viewController {
            // Set up a block to catch accountAvailable when the User signs-in or out of iCloud. Generally, users should always be signed in, but it can happen.
            let completionBlock:((_ accountStatus: CKAccountStatus) -> Swift.Void) = { (accountStatus) in
				Log.message("View Controller updated Account: \(viewController)", enabled: false)

                self.accountStatus = accountStatus
				completionHandler(accountStatus)
            }
            AccountManager.accountChangedOperationCompletionBlocks.append(completionBlock)

			DataManager.Container.accountStatus { accountStatus, accountError in
				self.accountStatus = accountStatus
				switch (accountStatus == CKAccountStatus.available, request) {
				case (false, Require.account):
					AccountManager.alertPlayerNotSignedInToICloud()
					completionHandler(accountStatus)
				case (_, _):
					completionHandler(accountStatus)
				}
			}
		}
        else {
            DataManager.Container.accountStatus { accountStatus, accountError in
                self.accountStatus = accountStatus
                switch (accountStatus == CKAccountStatus.available, request) {
                case (false, Require.account):
                    AccountManager.alertPlayerNotSignedInToICloud()
                    completionHandler(accountStatus)
                case (_, _):
                    completionHandler(accountStatus)
                }
            }
        }
    }

    func presentViewController(_ viewController: UIViewController) {
        if let
            appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
            let window = appDelegate.window,
            let rootViewController = window!.rootViewController as? UITabBarController,
            let selectedViewController = rootViewController.selectedViewController {
            selectedViewController.modalPresentationStyle = UIModalPresentationStyle.currentContext
            selectedViewController.present(viewController, animated: true, completion: nil)
        }
    }

    func openICloudPreferences () {
        let type = "CASTLE"
        if let url = URL(string:"App-Prefs:root=" + type) {
            UIApplication.shared.open(url, options: [:], completionHandler:nil)
        }
    }

    public class func  alertPlayerNotSignedInToICloud () {
        let title = "Enable iCloud"
        let message = "To save your games and to play games with others, please open iCloud in Settings,  \"Sign In\" and enable \"iCloud Drive\"."
        let type = "CASTLE"
        AccountManager.alertPlayerNotSignedIn(title: title, message: message, type: type)
    }
    
   public class func alertPlayerNotSignedInToGameCenter () {
        let title = "Enable GameCenter"
        let message = "To save your games and to play games with others, please open GameCenter in Settings and \"Sign In\"."
        let type = "GAMECENTER"
        AccountManager.alertPlayerNotSignedIn(title: title, message: message, type: type)
    }
    
    public class func alertPlayerNotSignedIn (title: String, message: String, type: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert)
            
            let okay = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(okay)
            
            let openAction = UIAlertAction(title: title, style: .default) { (action) in
                if let url = URL(string:"App-Prefs:root=" + type) {
                    UIApplication.shared.open(url, options: [:], completionHandler:nil)
                }
            }
            alertController.addAction(openAction)
            if let
                appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
                let window = appDelegate.window,
                let rootViewController = window!.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }

    public class func warnPlayerNotSignedIn () {
        DispatchQueue.main.async {
            guard let viewController = self.createEnableICloudViewController() else { return
            }
            if let
                appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
                let window = appDelegate.window,
				let rootViewController = window!.rootViewController {
                rootViewController.present(viewController, animated: true, completion: nil)
            }

        }
    }


/// Obtain information on all users in our Address Book
//    func fetchAllUsers(_ completionHandler:@escaping (_ identities: [CKUserIdentity]?) -> Void) {
//        // Find all discoverable users in the device's address book
//        let operation: CKDiscoverAllUserIdentitiesOperation = CKDiscoverAllUserIdentitiesOperation()
//        operation.queuePriority = Operation.QueuePriority.normal
//
//        //This block is executed once for each identity that is discovered. Each time the block is executed, it is executed serially with respect to the other progress blocks of the operation.
//        //If you intend to use this block to process results, set it before executing the operation or submitting the operation object to a queue.
//        var identities: [CKUserIdentity]  = []
//        operation.userIdentityDiscoveredBlock = { (identity:CKUserIdentity) -> Void in
//            identities.append(identity)
//        }
//        
//        // This block is executed only once and represents your last chance to process the operation results. It is executed after all of the individual progress blocks but before the operation’s completion block. The block is executed serially with respect to the other progress blocks of the operation. If you intend to use this block to process results, update the value of this property before executing the operation or submitting the operation object to a queue.
//        operation.discoverAllUserIdentitiesCompletionBlock = { (error) -> Void in
//            Log.error(with: #line, functionName: #function, error: error)
//            DispatchQueue.main.async {
//                completionHandler(identities)
//            }
//        }
//        GameSessionsManager.container.add(operation)
//    }
	
	open class func currentUser() -> UserMO? {
		var user: UserMO?
		
		let group = DispatchGroup()
		group.enter()
		
		AccountManager.fetchUser { (fetchedUser) in
			user = fetchedUser
			group.leave()
		}
		group.wait()
		return user
	}
	
	public class func fetchUser(desiredKeys keys: [String]? = [], localThenRemote isLocalThenRemote: Bool = false, progress: Progress? = nil, completionHandler: @escaping (UserMO?) -> Swift.Void) {
		DataManager.Container.fetchUserRecordID { (recordID, error) in
			if let recordID = recordID {
				let fetchUserOperation = FetchUsersOperation(with: [recordID], localThenRemote: isLocalThenRemote, desiredKeys: keys, progress: progress)
				fetchUserOperation.fetchUsersCompletionBlock = { (users) in
					if let users = users, let user = users.first {
						completionHandler(user)
					}
					else {
						completionHandler(nil)
					}
				}
				fetchUserOperation.start()
			}
			else {
				completionHandler(nil)
			}
		}
	}
	
	public class func fetchUsers(forRecordIDs recordIDs: [CKRecordID], desiredKeys keys: [String]? = [], localThenRemote isLocalThenRemote: Bool = false, progress: Progress? = nil, completionHandler: @escaping ([UserMO]?) -> Swift.Void) {
		let fetchUsersOperation = FetchUsersOperation(with: recordIDs, localThenRemote: isLocalThenRemote, desiredKeys: keys, progress: progress)
		fetchUsersOperation.fetchUsersCompletionBlock = { (users) in
			if let users = users {
				completionHandler(users)
			}
			else {
				completionHandler(nil)
			}
		}
		fetchUsersOperation.start()
	}
}

extension AccountManager {

    public class func createEnableICloudViewController () -> UINavigationController? {
        let bundle = Bundle(identifier: "com.beaconcrawl.BeaconCrawl")
        let storyboard = UIStoryboard(name: "Account", bundle: bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EnableICloud") as? UINavigationController
        return viewController
    }
}
