//
//  CloudKitManager.swift
//  Notifications
//
//  Created by WCA on 6/14/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import GameKit
import UserNotifications

@objc(CloudKitManager)
open class CloudKitManager: NSObject {
	
	public static var isUploadingToNewDatabase: Bool {
		return false
	}
	
	let publicCloudDatabase = DataManager.Container.publicCloudDatabase
	let privateCloudDatabase = DataManager.Container.privateCloudDatabase
	let sharedCloudDatabase = DataManager.Container.sharedCloudDatabase
	
	// MARK: - Subscribe
	
	public func subscribe(forRecordTypes recordTypes: [String], to database: CKDatabase = DataManager.Container.publicCloudDatabase, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE")) {
		// First check if we have already subscribed by checking our UserDefaults
		var toSubscribeRecordTypes = [String]()
		for recordType in recordTypes {
			// Subscription doesn't' match our current request. Add to list of Records to be Subscribed to
			if !UserDefaults.contains(recordType, for: Defaults.subscriptions) {
				toSubscribeRecordTypes.append(recordType)
				Log.message("Needs subscription to Record: \(recordType)", enabled: false)
			}
			else {
				Log.message("Is subscribed to Record: \(recordType)", enabled: false)
			}
		}
		// If we have any RecordTypes that our UserDefaults doesn't know about check if we already have our subscription registered on the server, and adjust our NSUserDefaults
		if !toSubscribeRecordTypes.isEmpty {
			let fetchSubscriptionsOperation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
			fetchSubscriptionsOperation.fetchSubscriptionCompletionBlock = { (subscriptionsBySubscriptionID, error) -> Void in
				guard error == nil else {
					let ckerror = CKError(_nsError: error! as NSError)
					Log.error(with: #line, functionName: #function, error: error, alert: false)
					if ckerror.code == .notAuthenticated {
						// Try again after 3 seconds if we don't have a retry hint
						if let retryAfterValue = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
							DataManager.runAfterDelay(retryAfterValue, completionHandler: {
								self.subscribe(forRecordTypes: recordTypes)
							})
						}
					}
					return
				}
				var subscriptions = [CKSubscription]()
				if let subscriptionsBySubscriptionID = subscriptionsBySubscriptionID {
					let allSubscriptionIDValues = Array(subscriptionsBySubscriptionID.values)
					let notSubscribedRecordTypes = Set(recordTypes).subtracting(Set(allSubscriptionIDValues.compactMap{$0.subscriptionID}))
					let subscribedRecordTypes = Set(recordTypes).subtracting(notSubscribedRecordTypes)
					// Remember our subscription for next time
					for recordType in subscribedRecordTypes {
						UserDefaults.updateUserDefaults(with: recordType, forKey: Defaults.subscriptions)
					}
					for recordType in notSubscribedRecordTypes {
						let subscription = self.createSubscription(for: recordType, to: database, predicate: predicate)
						subscriptions.append(subscription)
					}
					// save our subscription, note: that if saving multiple subscriptions, they should be saved in succession, and not independently
					self.modify(subscriptionsToSave: subscriptions, to: database) { (savedSubscriptions, deletedSubscriptionIDs, error: Error?) in
						if error != nil {
							Log.error(with: #line, functionName: #function, error: error, enabled: true)
						}
						else {
							if let savedSubscriptions = savedSubscriptions {
								for subscription in savedSubscriptions {
									UserDefaults.updateUserDefaults(with: subscription.subscriptionID, forKey: Defaults.subscriptions)
								}
							}
							
						}
					}
					
				}
			}
			database.add(fetchSubscriptionsOperation)
		}
	}
	
	open func createSubscription(for subscriptionName: String, to database: CKDatabase, predicate: NSPredicate = NSPredicate(format: "TRUEPREDICATE"), desiredKeys: [String]? = nil) -> CKSubscription {
		// subscribe to deletion, update and creation of our record type
		var itemSubscription: CKSubscription
		switch database.databaseScope {
		case .public:
			let options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
			itemSubscription = CKQuerySubscription(recordType: subscriptionName, predicate: predicate, subscriptionID: subscriptionName, options:options)
		case .private, .shared:
			itemSubscription = CKDatabaseSubscription(subscriptionID: subscriptionName)
		}
		// Set the notification content: Note: if you don't set "alertBody", "soundName" or "shouldBadge", it will make the notification a priority, sent at an opportune time
		let notificationInfo = CKNotificationInfo()
		
		// Allows the action to launch the app if it’s not running. Once launched, the notifications will be delivered, and the app will be given some background time to process them. Indicates that the notification should be sent with the "content-available" flag to allow for background downloads in the application. Default value is NO.
		notificationInfo.shouldSendContentAvailable = true
		
		// Optional. a list of keys from the matching record to include in the notification payload,
		if desiredKeys != nil {
			notificationInfo.desiredKeys = desiredKeys
		}
		// set our CKNotificationInfo to our CKSubscription
		itemSubscription.notificationInfo = notificationInfo
		
		return itemSubscription
	}
	
	public func subscribe(forDatabase database: CKDatabase) {
		// First check if we have already subscribed by checking our UserDefaults
		var needsSubscription: Bool = false
		var databaseScope: String = ""
		switch database.databaseScope {
		case .public:
			databaseScope = "Public"
		case .private:
			databaseScope = "Private"
		case .shared:
			databaseScope = "Shared"
		}
		// Subscription doesn't' match our current request. Add to list of Records to be Subscribed to
		if !UserDefaults.contains(databaseScope, for: Defaults.subscriptions) {
			needsSubscription = true
			Log.message("Needs subscription to Database: \(databaseScope)", enabled: true)
		}
		else {
			Log.message("Is subscribed to Database: \(databaseScope)", enabled: false)
		}
		// If we have any Databases that our UserDefaults doesn't know about check if we already have our subscription registered on the server, and adjust our NSUserDefaults
		if needsSubscription {
			let fetchSubscriptionsOperation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
			fetchSubscriptionsOperation.fetchSubscriptionCompletionBlock = { (subscriptionsBySubscriptionID, error) -> Void in
				guard error == nil else {
					let ckerror = CKError(_nsError: error! as NSError)
					Log.error(with: #line, functionName: #function, error: error, alert: false)
					if ckerror.code == .notAuthenticated {
						// Try again after 3 seconds if we don't have a retry hint
						if let retryAfterValue = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
							DataManager.runAfterDelay(retryAfterValue, completionHandler: {
								self.subscribe(forDatabase: database)
							})
						}
					}
					return
				}
				if let subscriptionsBySubscriptionID = subscriptionsBySubscriptionID {
					let allSubscriptionIDValues = Array(subscriptionsBySubscriptionID.values)
					let allSubscriptionIDs = allSubscriptionIDValues.map{$0.subscriptionID}
					let scope = databaseScope
					if !allSubscriptionIDs.contains(scope) {
						let subscription = self.createSubscription(for: databaseScope, to: database)
						// save our subscription, note: that if saving multiple subscriptions, they should be saved in succession, and not independently
						self.modify(subscriptionsToSave: [subscription], to: database) { (savedSubscriptions, deletedSubscriptionIDs, error: Error?) in
							if error != nil {
								Log.error(with: #line, functionName: #function, error: error, alert: false)
							}
							else {
								UserDefaults.updateUserDefaults(with: databaseScope, forKey: Defaults.subscriptions)
							}
						}
					}
					else {
						UserDefaults.updateUserDefaults(with: databaseScope, forKey: Defaults.subscriptions)
					}
				}
			}
			database.add(fetchSubscriptionsOperation)
		}
	}
	
	open func modify(subscriptionsToSave toSave: [CKSubscription] = [], subscriptionsToDelete toDelete: [String] = [], to database: CKDatabase, completionHandler:@escaping ([CKSubscription]?, [String]?, Error?) -> Void) {
		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: toSave, subscriptionIDsToDelete: toDelete)
		operation.modifySubscriptionsCompletionBlock = { (savedSubscriptions, deletedSubscriptionIDs, error) in
			guard error == nil else {
				// Handle the error here
				if let error:NSError = error as NSError? {
					if error.userInfo[CKPartialErrorsByItemIDKey] != nil {
						let ckerror: CKError = CKError(_nsError: error as NSError)
						switch ckerror.code {
						case .serverRejectedRequest:
							Log.error(with: #line, functionName: #function, error: error, enabled: false, alert: false)
							// save subscription request rejected! Trying to save a subscribution (subscribe) failed (probably because we already have a subscription saved) This is likely due to the fact that the app was deleted and reinstalled to the device, so assume we have a subscription already registed with the server
							break
						case .notAuthenticated:
							Log.error(with: #line, functionName: #function, error: error, alert: false)
							// Could not subscribe (not authenticated)
							Log.message("User not authenticated (could not subscribe to record changes)")
							break
						default:
							Log.error(with: #line, functionName: #function, error: error, alert: false)
							break
						}
					}
				}
				DispatchQueue.main.async {
					completionHandler(toSave, toDelete, error)  // we are done with an error
				}
				return
			}
			// Back on the main queue call our completion handler
			DispatchQueue.main.async {
				completionHandler(savedSubscriptions, deletedSubscriptionIDs, error)  // we are done
			}
		}
		database.add(operation)
	}
	
	public func unsubscribe(forRecordTypes recordTypes: [String], in key: String) {
		guard var array = UserDefaults.standard.array(forKey: key) as? [String] else { return }
		
		// Remove previous subscribed types from our UserDefaults
		for recordType in recordTypes {
			// Subscription matches our current request
			if UserDefaults.contains(recordType, for: key) {
				array.remove(at: array.index(of: recordType)!)
				UserDefaults.standard.removeObject(forKey: key)
				UserDefaults.standard.set(array, forKey: key)
			}
		}
	}
}

extension CloudKitManager {
	
	func userDidAcceptCloudKitShare(with cloudKitShareMetadata: CKShareMetadata) {
		
		let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
		
		var recordIDs = [CKRecordID]()
		acceptSharesOperation.perShareCompletionBlock = { metadata, share, error in
			if error != nil {
				print(error?.localizedDescription ?? "")
			}
			recordIDs.append(metadata.share.recordID)
			recordIDs.append(metadata.rootRecordID)
		}
		
		acceptSharesOperation.acceptSharesCompletionBlock = { error in
			Log.error(with: #line, functionName: #function , error: error)
			let operation = FetchRecordsDictionaryOperation(with: recordIDs, database: DataManager.Container.sharedCloudDatabase)
			
			operation.fetchRecordsDictionaryCompletionBlock = { (recordsDictionary) in
				if let recordsDictionary = recordsDictionary {
					let records: [CKRecord] = Array(recordsDictionary.values)
					for record in records {
						var gameShare: GameShareMO? = nil
						if let object = DataManager.fetchLocalEntities(withType: record.recordType,
																	   in: DataManager.viewContext,
																	   predicate: NSPredicate(format: "recordID = %@", record.recordID))?.first {
							if let object = object as? GameShareMO {
								gameShare = object
							}
						}
						else if let object = DataManager.createManagedObject(forRecord: record) {
							if let object = object as? GameShareMO {
								gameShare = object
							}
						}
						if let gameShare = gameShare,
							let adventureRecordName = gameShare.adventureRecordName {
							let request: NSFetchRequest<AdventureMO> = AdventureMO.fetchRequest()
							request.predicate = NSPredicate(format: "recordName == %@", adventureRecordName)
							if let adventure = DataManager.fetchLocalEntities(withFetchRequest: request as! NSFetchRequest<NSManagedObject>, in: DataManager.backgroundContext)?.first as? AdventureMO {
								if let name = adventure.name {
									let operation = GameZoneOperation(withName: name, database: DataManager.Container.privateCloudDatabase)
									operation.fetchZoneOperationCompletionBlock = { (zoneObject) in
										zoneObject?.adventure = adventure
										if let zoneObject = zoneObject {
											
											var game: GameMO? = nil
											if let recordID = adventure.recordID {
												let request: NSFetchRequest<GameMO> = GameMO.fetchRequest()
												request.predicate = NSPredicate(format: "gameZone.adventure.recordID = %@", recordID)
												request.returnsObjectsAsFaults = false
												let fetchedGame = DataManager.fetchLocalEntities(withFetchRequest: request as! NSFetchRequest<NSManagedObject>)?.first as? GameMO
												if let fetchedGame = fetchedGame {
													game = fetchedGame
												}
												else if let createdGame = DataManager.createManagedObject(forRecordType: GameMO.recordType(), zone: zoneObject) as? GameMO {
													game = createdGame
												}
												if let game = game {
													zoneObject.game = game
													game.isFavorite = true
													game.name = adventure.name
													gameShare.game = game
													gameShare.name = game.name
													game.path = gameShare.share?.path
													DataManager.save([game],
																	 to: DataManager.Container.privateCloudDatabase, completionHandler: {
																		NotificationCenter.default.post(name: .GameShareAcceptedNotification, object: adventure)
													})
												}
											}
										}
									}
									operation.start()
								}
								else {
									if let game = adventure.gameZone?.game {
										game.isFavorite = true
										gameShare.game = game
										DataManager.save([game],
														 to:DataManager.Container.privateCloudDatabase,
														 completionHandler: {
															NotificationCenter.default.post(name: .GameShareAcceptedNotification, object: adventure)
										})
									}
								}
							}
						}
					}
				}
			}
			operation.start()
		}
		CKContainer(identifier: cloudKitShareMetadata.containerIdentifier).add(acceptSharesOperation)
	}
}

extension CKContainer {
	
	public func prepareSharingController(forGameShare gameShare: GameShareMO, database: CKDatabase? = DataManager.Container.privateCloudDatabase,
										 completionHandler:@escaping (UICloudSharingController?) -> Void) {
		
		// Share setup: fetch the share if the root record has been shared, or create a new one.
		//
		var cloudSharingController: UICloudSharingController? = nil
		
		if let share = gameShare.share {
			if let shareRecord = DataManager.shareFromObject(share) {
				cloudSharingController = UICloudSharingController(share: shareRecord, container: self)
			}
		}
		else {
			cloudSharingController = UICloudSharingController(){(controller, prepareCompletionHandler) in
				if let gameShareRecord = DataManager.recordFromObject(gameShare) {
					gameShare.addAttributes(to: gameShareRecord, for: gameShare.allKeys())
					let shareRecord = CKShare(rootRecord: gameShareRecord)
					if let cloudSharingController = cloudSharingController, let delegate = cloudSharingController.delegate {
						shareRecord[CKShareThumbnailImageDataKey] = delegate.itemThumbnailData?(for: cloudSharingController) as CKRecordValue?
						shareRecord[CKShareTitleKey] = delegate.itemTitle(for: cloudSharingController)! as CKRecordValue
						shareRecord[CKShareTypeKey] = "com.districtapp.District-1" as CKRecordValue
					}
					shareRecord.publicPermission = .readWrite
					
					let shareObject = DataManager.createManagedObject(forShare: shareRecord)
					shareObject.gameShare = gameShare
					shareObject.name = gameShare.name
					shareObject.addAttributes(to: shareRecord, for: shareObject.allKeys())
					gameShare.addAttributes(to: gameShareRecord, for: gameShare.allKeys())
					
					// Clear the parent property because root record is now sharing independently.
					// Restore it when the sharing is stoped if necessary (cloudSharingControllerDidStopSharing).
					gameShareRecord.parent = nil
					
					let modifyRecordsOperation = ModifyRecordsOperation(recordsToSave: [shareRecord, gameShareRecord], recordIDsToDelete: [], database: database!)
					modifyRecordsOperation.qualityOfService = .userInteractive
					modifyRecordsOperation.modifyRecordsCompletionBlock = { (updatedRecords, deletedRecordIDs) in
						if let updatedRecords = updatedRecords {
							for record in updatedRecords {
								if let share = record as? CKShare {
									shareObject.addAttributes(from:share)
								}
								else {
									gameShare.addAttributes(from: record)
								}
							}
						}
						if DataManager.backgroundContext.hasChanges {
							DataManager.backgroundContext.performAndWait {
								do {
									try gameShare.managedObjectContext!.save()
								}
								catch {
									Log.message(error.localizedDescription)
								}
							}
						}
						prepareCompletionHandler(shareRecord, self, nil)
					}
					modifyRecordsOperation.start()
				}
			}
		}
		completionHandler(cloudSharingController)
	}
	
	
	/// Fetch participants from container and add them if the share is private. If a participant with a matching userIdentity already exists in this share that existing participant’s properties are updated; no new participant is added. Note that private users cannot be added to a public share.
	fileprivate func addParticipants(to share: CKShare,
									 lookupInfos: [CKUserIdentityLookupInfo],
									 operationQueue: OperationQueue) {
		
		if lookupInfos.count > 0 && share.publicPermission == .none {
			
			let fetchParticipantsOperation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: lookupInfos)
			fetchParticipantsOperation.shareParticipantFetchedBlock = { participant in
				share.addParticipant(participant)
			}
			fetchParticipantsOperation.fetchShareParticipantsCompletionBlock = { error in
				Log.error(with: #line, functionName: #function , error: error)
				guard error == nil else {
					if let error:NSError = error as NSError? {
						if let errors = error.userInfo[CKPartialErrorsByItemIDKey] {
							for (_, ckerror) in (errors as? [CKRecordID: NSError])! {
								fetchParticipantsOperation.checkFetchError(ckerror, completionHandler: nil)
							}
						}
						else {
							fetchParticipantsOperation.checkFetchError(error, completionHandler: nil)
						}
					}
					return
				}
			}
			let configurataion = CKOperation.Configuration()
			configurataion.container = self
			fetchParticipantsOperation.configuration = configurataion
			operationQueue.addOperation(fetchParticipantsOperation)
		}
	}
}

// MARK -  Error Handling
extension CKFetchRecordsOperation {
	
	open override func copy() -> Any {
		let operation:CKFetchRecordsOperation = CKFetchRecordsOperation()
		operation.database = database
		operation.perRecordProgressBlock = self.perRecordProgressBlock
		operation.perRecordCompletionBlock = self.perRecordCompletionBlock
		return operation
	}
	
	func checkFetchError(_ error: Error, completionHandler:@escaping (_: [CKRecordID : CKRecord]?, _: Error?) -> Void) {
		let ckerror: CKError = CKError(_nsError: error as NSError)
		switch ckerror.code {
		case .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
			if let retryAfterValue = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
				let delayTime = DispatchTime.now() + retryAfterValue
				DispatchQueue.main.asyncAfter(deadline: delayTime) {
					if let newOperation: CKFetchRecordsOperation = self.copy() as? CKFetchRecordsOperation {
						newOperation.start()
						newOperation.fetchRecordsCompletionBlock = { (recordsDictionary: [CKRecordID : CKRecord]?, error: Error?) in
							DispatchQueue.main.async {
								completionHandler(recordsDictionary, error)
							}
						}
					}
				}
			}
		case .networkUnavailable:
			var observer: NSObjectProtocol?
			observer = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: nil, queue: nil) { (notification: Notification) in
				if let reachability: Reachability = notification.object as? Reachability {
					Log.message("Reachbility Changed \(reachability.currentReachabilityStatus)")
					if reachability.currentReachabilityStatus == .notReachable {
						if observer != nil {
							NotificationCenter.default.removeObserver(observer!)
							observer = nil
						}
						if let newOperation: CKFetchRecordsOperation = self.copy() as? CKFetchRecordsOperation {
							newOperation.start()
							newOperation.fetchRecordsCompletionBlock = { (recordsDictionary: [CKRecordID : CKRecord]?, error: Error?)  -> Void in
								DispatchQueue.main.async {
									completionHandler(recordsDictionary, error)
								}
							}
						}
					}
				}
			}
		case .serverRecordChanged:
			if let
				// CKRecordChangedErrorAncestorRecordKey: Key to the original CKRecord that you used as the basis for making your changes.
				_: CKRecord = ckerror.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
				
				//CKRecordChangedErrorServerRecordKey: Key to the CKRecord that was found on the server. Use this record as the basis for merging your changes.
				let serverRecord: CKRecord = ckerror.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
				
				// CKRecordChangedErrorClientRecordKey: Key to the CKRecord that you tried to save. This record is based on the record in the CKRecordChangedErrorAncestorRecordKey key but contains the additional changes you made.
				let clientRecord: CKRecord = ckerror.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord {
				
				let keys = clientRecord.allKeys()
				// Important to use the server's record as a basis for our changes, apply our current record to the server's version
				for key in keys {
					serverRecord[key] = clientRecord[key]
				}
				let newOperation: CKFetchRecordsOperation = self.copy() as! CKFetchRecordsOperation
				newOperation.start()
				newOperation.fetchRecordsCompletionBlock = { (recordsDictionary: [CKRecordID : CKRecord]?, error: Error?)  -> Void in
					DispatchQueue.main.async {
						completionHandler(recordsDictionary, error)
					}
				}
			}
		case .unknownItem:
			Log.error(with: #line, functionName: #function, error: ckerror)
			DispatchQueue.main.async {
				completionHandler(nil, ckerror)
			}
		default:
			Log.error(with: #line, functionName: #function, error: ckerror)
			DispatchQueue.main.async {
				completionHandler(nil, ckerror)
			}
		}
	}
}

extension CKModifyRecordsOperation {
	
	open override func copy() -> Any {
		let operation:CKModifyRecordsOperation = CKModifyRecordsOperation()
		operation.savePolicy = CKRecordSavePolicy.ifServerRecordUnchanged
		operation.perRecordProgressBlock = self.perRecordProgressBlock
		operation.perRecordCompletionBlock = self.perRecordCompletionBlock
		operation.database = self.database
		return operation
	}
	
	func checkModifyError(_ nserror: NSError, forRecord record: CKRecord? = nil, completionHandler:@escaping (_: [CKRecord]?,_: [CKRecordID]?, _: Error?) -> Void) {
		let error: CKError = CKError(_nsError: nserror)
		switch error.code {
		case .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
			if let retryAfterValue = nserror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
				let delayTime = DispatchTime.now() + retryAfterValue
				DispatchQueue.main.asyncAfter(deadline: delayTime) {
					let newOperation: CKModifyRecordsOperation = self.copy() as! CKModifyRecordsOperation
					newOperation.start()
					newOperation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
						DispatchQueue.main.async {
							completionHandler(savedRecords, deletedRecordIDs, error)
						}
					}
				}
			}
		case .networkUnavailable:
			Log.error(with: #line, functionName: #function, error: nserror)
			var observer: NSObjectProtocol?
			observer = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: nil, queue: nil) { (notification: Notification) in
				if let reachability: Reachability = notification.object as? Reachability {
					Log.message("Reachbility Changed \(reachability.currentReachabilityStatus)")
					if reachability.currentReachabilityStatus == .notReachable {
						if observer != nil {
							NotificationCenter.default.removeObserver(observer!)
							observer = nil
						}
						let newOperation: CKModifyRecordsOperation = self.copy() as! CKModifyRecordsOperation
						newOperation.start()
						newOperation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
							DispatchQueue.main.async {
								completionHandler(savedRecords, deletedRecordIDs, error)
							}
						}
					}
				}
			}
			
		case .serverRecordChanged:
			if let
				// CKRecordChangedErrorAncestorRecordKey: Key to the original CKRecord that you used as the basis for making your changes.
				_: CKRecord = nserror.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
				
				//CKRecordChangedErrorServerRecordKey: Key to the CKRecord that was found on the server. Use this record as the basis for merging your changes.
				let serverRecord: CKRecord = nserror.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
				
				// CKRecordChangedErrorClientRecordKey: Key to the CKRecord that you tried to save. This record is based on the record in the CKRecordChangedErrorAncestorRecordKey key but contains the additional changes you made.
				let clientRecord: CKRecord = nserror.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord {
				
				let keys = clientRecord.allKeys()
				// Important to use the server's record as a basis for our changes, apply our current record to the server's version
				for key in keys {
					serverRecord[key] = clientRecord[key]
				}
				let newOperation: CKModifyRecordsOperation = self.copy() as! CKModifyRecordsOperation
				
				newOperation.recordsToSave = [serverRecord]
				newOperation.start()
				newOperation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
					DispatchQueue.main.async {
						completionHandler(savedRecords, deletedRecordIDs, error)
					}
				}
			}
		case .unknownItem:
			if let record = record {
				let recordType = record.recordType
				let recordID = record.recordID
				let recordName = record.recordID.recordName
				let predicate = NSPredicate(format: "recordName == %@", recordName)
				if let object = DataManager.fetchLocalEntities(withType: recordType, predicate: predicate)?.first {
					if let managedObjectContext = object.managedObjectContext {
						managedObjectContext.delete(object)
					}
					completionHandler([record], [recordID], nserror)
				}
			}
			completionHandler(nil, nil, nserror)
		case .zoneNotFound:
			break;
		case .userDeletedZone:
			//Log.error(with: #line, functionName: #function, error: nserror)
			// create a new zone
			if let zoneID = record?.recordID.zoneID {
				UserDefaults.standard.removeObject(forKey: zoneID.zoneName)
			}
			if let record = record {
				let recordType = record.recordType
				let recordName = record.recordID.recordName
				let predicate = NSPredicate(format: "recordName == %@", recordName)
				if let object = DataManager.fetchLocalEntities(withType: recordType, predicate: predicate)?.first {
					if let managedObjectContext = object.managedObjectContext {
						managedObjectContext.delete(object)
					}
					completionHandler([record], nil, nserror)
				}
			}
			completionHandler(nil, nil, nserror)
		default:
			Log.error(with: #line, functionName: #function, error: nserror)
			completionHandler(nil, nil, nserror)
		}
	}
}

extension CKModifyRecordZonesOperation {
	
	open override func copy() -> Any {
		let operation:CKModifyRecordZonesOperation = CKModifyRecordZonesOperation()
		operation.recordZonesToSave = self.recordZonesToSave
		operation.recordZoneIDsToDelete = self.recordZoneIDsToDelete
		operation.database = self.database
		return operation
	}
	
	func checkModifyError(_ nserror: NSError, completionHandler:@escaping (_: [CKRecordZone]?,_: [CKRecordZoneID]?, _: Error?) -> Void) {
		let error: CKError = CKError(_nsError: nserror)
		switch error.code {
		case .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
			if let retryAfterValue = nserror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
				let delayTime = DispatchTime.now() + retryAfterValue
				DispatchQueue.main.asyncAfter(deadline: delayTime) {
					let newOperation: CKModifyRecordZonesOperation = self.copy() as! CKModifyRecordZonesOperation
					newOperation.start()
					newOperation.modifyRecordZonesCompletionBlock = { (savedRecordZones, deletedRecordZoneIDs, error) in
						DispatchQueue.main.async {
							completionHandler(savedRecordZones, deletedRecordZoneIDs, error)
						}
					}
				}
			}
		case .networkUnavailable:
			Log.error(with: #line, functionName: #function, error: nserror)
			var observer: NSObjectProtocol?
			observer = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: nil, queue: nil) { (notification: Notification) in
				if let reachability: Reachability = notification.object as? Reachability {
					Log.message("Reachbility Changed \(reachability.currentReachabilityStatus)")
					if reachability.currentReachabilityStatus == .notReachable {
						if observer != nil {
							NotificationCenter.default.removeObserver(observer!)
							observer = nil
						}
						let newOperation: CKModifyRecordZonesOperation = self.copy() as! CKModifyRecordZonesOperation
						newOperation.start()
						newOperation.modifyRecordZonesCompletionBlock = { (savedRecordZones, deletedRecordZoneIDs, error) in
							DispatchQueue.main.async {
								completionHandler(savedRecordZones, deletedRecordZoneIDs, error)
							}
						}
					}
				}
			}
		default:
			Log.error(with: #line, functionName: #function, error: nserror)
			DispatchQueue.main.async {
				let alertController: UIAlertController = UIAlertController(title: "iCloud Error", message: nserror.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
				alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
				if let
					appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
					let window = appDelegate.window,
					let rootViewController = window!.rootViewController {
					rootViewController.present(alertController, animated: true, completion: nil)
				}
				completionHandler(nil, nil, nserror)
			}
		}
	}
}

extension CKQueryOperation {
	
	open override func copy() -> Any {
		let operation:CKQueryOperation = CKQueryOperation()
		operation.query = self.query
		operation.cursor = self.cursor
		operation.zoneID = self.zoneID
		operation.resultsLimit = self.resultsLimit
		operation.desiredKeys = self.desiredKeys
		operation.recordFetchedBlock = self.recordFetchedBlock
		operation.queryCompletionBlock = self.queryCompletionBlock
		operation.database = self.database
		return operation
	}
	
	func checkFetchError(_ error: Error, completionHandler:@escaping (_: CKQueryCursor?, _: Error?) -> Void) {
		let ckerror: CKError = CKError(_nsError: error as NSError)
		Log.error(with: #line, functionName: #function, error: ckerror)
		
		switch ckerror.code {
		case .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
			if let retryAfterValue = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
				let delayTime = DispatchTime.now() + retryAfterValue
				DispatchQueue.main.asyncAfter(deadline: delayTime) {
					if let newOperation: CKQueryOperation = self.copy() as? CKQueryOperation {
						newOperation.start()
						newOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) in
							DispatchQueue.main.async {
								completionHandler(cursor, error)
							}
						}
					}
				}
			}
		case .networkUnavailable:
			var observer: NSObjectProtocol?
			observer = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: nil, queue: nil) { (notification: Notification) in
				if let reachability: Reachability = notification.object as? Reachability {
					Log.message("Reachbility Changed \(reachability.currentReachabilityStatus)")
					if reachability.currentReachabilityStatus == .notReachable {
						if observer != nil {
							NotificationCenter.default.removeObserver(observer!)
							observer = nil
						}
						if let newOperation: CKQueryOperation = self.copy() as? CKQueryOperation {
							newOperation.start()
							newOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) in
								DispatchQueue.main.async {
									completionHandler(cursor, error)
								}
							}
						}
					}
				}
			}
		case .serverRecordChanged:
			if let
				// CKRecordChangedErrorAncestorRecordKey: Key to the original CKRecord that you used as the basis for making your changes.
				_: CKRecord = ckerror.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord,
				
				//CKRecordChangedErrorServerRecordKey: Key to the CKRecord that was found on the server. Use this record as the basis for merging your changes.
				let serverRecord: CKRecord = ckerror.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord,
				
				// CKRecordChangedErrorClientRecordKey: Key to the CKRecord that you tried to save. This record is based on the record in the CKRecordChangedErrorAncestorRecordKey key but contains the additional changes you made.
				let clientRecord: CKRecord = ckerror.userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord {
				
				let keys = clientRecord.allKeys()
				// Important to use the server's record as a basis for our changes, apply our current record to the server's version
				for key in keys {
					serverRecord[key] = clientRecord[key]
				}
				if let newOperation: CKQueryOperation = self.copy() as? CKQueryOperation {
					newOperation.start()
					newOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) in
						DispatchQueue.main.async {
							completionHandler(cursor, error)
						}
					}
				}
			}
		case .unknownItem:
			Log.error(with: #line, functionName: #function, error: ckerror)
			DispatchQueue.main.async {
				completionHandler(nil, ckerror)
			}
		default:
			Log.error(with: #line, functionName: #function, error: ckerror)
			DispatchQueue.main.async {
				completionHandler(nil, ckerror)
			}
		}
	}
}

extension CKFetchShareParticipantsOperation {
	
	open override func copy() -> Any {
		let operation:CKFetchShareParticipantsOperation = CKFetchShareParticipantsOperation()
		operation.userIdentityLookupInfos = self.userIdentityLookupInfos
		return operation
	}
	
	func checkFetchError(_ error: Error, completionHandler: ((_: Error?) -> Swift.Void)? = nil) {
		let ckerror: CKError = CKError(_nsError: error as NSError)
		Log.error(with: #line, functionName: #function, error: ckerror)
		completionHandler?(error)
	}
}

