//
//  FetchServerChangesOperation.swift
//  Notifications
//
//  Created by WCA on 9/21/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import CloudKit
import CoreData

public struct Notifications {
	var toRead: [CKQueryNotification]
	var created: [CKQueryNotification]
	var updated: [CKQueryNotification]
	var deleted: [CKQueryNotification]
	
	init() {
		toRead = [CKQueryNotification]()
		created = [CKQueryNotification]()
		updated = [CKQueryNotification]()
		deleted = [CKQueryNotification]()
	}
}

// MARK: - Public Database Changes

open class FetchPublicServerChangesOperation: AsynchronousOperation {

	// Each item in the notification queue needs to be marked as "read" so next time we won't have to handle them
	private var notificationChanges = Notifications()
	private var notificationsToMarkRead = [CKNotificationID]()
	internal var progress: Progress = Progress(totalUnitCount:100)
	internal var progressStartedOperation: BlockOperation?
	var fetchPublicServerChangesCompletionBlock: ((_ changedNotifications: Notifications?) -> Swift.Void)?

	override open func main() {
		// Add a completion block to start progress reporting
		progressStartedOperation?.start()
		// This operation fetches notification changes from the server
		let fetchNotificationsChangedOperation = FetchNotificationsChangesOperation()
		// This operation fetches records from the server
		let fetchRecordswithNotificationOperation = FetchRecordWithNotificationsOperation()
		// This operation will Create and Update the records
		let updatePublicRecordsOperation = UpdatePublicRecordsOperation()
		// This operation will Delete unused records
		let deletePublicRecordsOperation = DeletePublicRecordsOperation()
		// This operation marks the notifications as read
		let markReadOperation = MarkReadOperation()

		self.progress.addChild(fetchNotificationsChangedOperation.progress, withPendingUnitCount: 10)

		// Finish fetching notification changes from the server
		fetchNotificationsChangedOperation.fetchNotificationsChangesCompletionBlock = { (serverChangedNotfications) in
			Log.message("Fetch Notification Changes Finished")
			if let serverChangedNotfications = serverChangedNotfications {
				if serverChangedNotfications.toRead.isEmpty {
					self.fetchPublicServerChangesCompletionBlock?(self.notificationChanges)
					self.state(.finished)
				}
				else {
					self.notificationChanges = serverChangedNotfications
					fetchRecordswithNotificationOperation.setup(with: self.notificationChanges)
					fetchRecordswithNotificationOperation.start()
				}
			}
		}

		// Finish fetching changed records from the server

		fetchRecordswithNotificationOperation.fetchRecordsWithNotificationCompletionBlock = { (recordsDictionary) in
			Log.message("Fetch Records Finished", enabled: false)

			guard let recordsDictionary = recordsDictionary else {
				deletePublicRecordsOperation.setup(with: self.notificationChanges)
				deletePublicRecordsOperation.start()
				return
			}
			updatePublicRecordsOperation.setup(with: self.notificationChanges, recordsDictionary: recordsDictionary)
			updatePublicRecordsOperation.start()
		}

		// Finish creating and Updating the records

		updatePublicRecordsOperation.updatePublicRecordsCompletionBlock = { (notificationsToMarkRead) in
			Log.message("Update Records Finished", enabled: false)

			guard let notificationsToMarkRead = notificationsToMarkRead else {
				self.fetchPublicServerChangesCompletionBlock?(self.notificationChanges)
				self.state(.finished)
				return
			}
			Log.message("Update Notifications To Mark Read: " + "\(String(describing: notificationsToMarkRead.count))", enabled: false)
			self.notificationsToMarkRead.append(contentsOf: notificationsToMarkRead)
			deletePublicRecordsOperation.setup(with: self.notificationChanges)
			deletePublicRecordsOperation.start()
		}

		// Finish deleting unused records

		deletePublicRecordsOperation.deletePublicRecordsCompletionBlock = { (notificationsToMarkRead) in

			guard let notificationsToMarkRead = notificationsToMarkRead else {
				self.fetchPublicServerChangesCompletionBlock?(self.notificationChanges)
				self.state(.finished)
				return
			}

			Log.message("Delete Notifications To Mark Read: " + "\(String(describing: notificationsToMarkRead.count))", enabled: false)
			self.notificationsToMarkRead.append(contentsOf: notificationsToMarkRead)
			markReadOperation.setup(with: self.notificationsToMarkRead)
			markReadOperation.start()
		}

		// Finish marking the notifications as read
		markReadOperation.markReadCompletionBlock = { (wasChanged) in
			Log.message("Mark Records Finished", enabled: false)

			self.fetchPublicServerChangesCompletionBlock?(self.notificationChanges)
			self.state(.finished)
		}

		// Add operations to queue
		fetchNotificationsChangedOperation.start()
	}
}

class FetchNotificationsChangesOperation: AsynchronousOperation, ProgressReporting {

	// Each item in the notification queue needs to be marked as "read" so next time we won't have to handle them
	private var notifications = Notifications()
	private var fetchChangesOperation: CKFetchNotificationChangesOperation!
	var fetchNotificationsChangesCompletionBlock: ((Notifications?) -> Swift.Void)?
	internal let progress = Progress.discreteProgress(totalUnitCount: 1)

	override func main() {
		Log.message("FetchNotificationsChangesOperation Start")
		self.progress.completedUnitCount = 0
		// Read change token from disk
		let publicChangeToken: CKServerChangeToken? = UserDefaults.value(forKey:ServerDatabaseDefaults.databaseChangeToken, withName: String(DataManager.Container.publicCloudDatabase.databaseScope.rawValue)) as? CKServerChangeToken
		if let publicChangeToken = publicChangeToken {
			Log.message("Get Public Database Change Token: \(publicChangeToken)")
		}
		else {
			Log.message("Public Database Change Token = nil")
		}

		fetchChangesOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: publicChangeToken)
		fetchChangesOperation.qualityOfService = QualityOfService.utility

		let configurataion = CKOperation.Configuration()
		configurataion.container = DataManager.Container
		fetchChangesOperation.configuration = configurataion
		DataManager.Container.add(fetchChangesOperation)

		// this block processes a single push notification
		self.fetchChangesOperation.notificationChangedBlock = { (cloudKitNotification: CKNotification) -> Void in
			if cloudKitNotification.notificationType != CKNotificationType.readNotification {
				if let cloudKitNotification: CKQueryNotification = cloudKitNotification as? CKQueryNotification {
					Log.message(cloudKitNotification.subscriptionID!)
					self.notifications.toRead.append(cloudKitNotification)
				}
			}
		}

		self.fetchChangesOperation.fetchNotificationChangesCompletionBlock = { (newerServerChangeToken: CKServerChangeToken?, error: Error?) -> Void in
			guard error == nil else {
				// Handle the error here
				Log.error(with: #line, functionName: #function, error: error)
				self.finish()
				return
			}

			/** If "moreComing" is set then the server wasn't able to return all the changes in this response, another CKFetchNotificationChangesOperation operation should be run with the updated serverChangeToken token from this operation.
			*/
			if self.fetchChangesOperation.moreComing {
				if let newerServerChangeToken = newerServerChangeToken {
					Log.message("Set Public Database Change Token: \(newerServerChangeToken)")
					// Write this new database change token to memory
					UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : newerServerChangeToken], forName: String(DataManager.Container.publicCloudDatabase.databaseScope.rawValue))
					let moreOperation = FetchNotificationsChangesOperation()
					moreOperation.start()
				}
			}
			else {
				if let newerServerChangeToken = newerServerChangeToken {
					Log.message("Set Public Database Change Token: \(newerServerChangeToken)")
					// Write this new database change token to memory
					UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : newerServerChangeToken], forName: String(DataManager.Container.publicCloudDatabase.databaseScope.rawValue))
				}
			}
		}

		// this block is executed after all requested notifications are fetched
		self.fetchChangesOperation.completionBlock = {
			Log.message("found \(self.notifications.toRead.count) items in the change notifcation queue")
			Log.message("FetchNotificationsChangesOperation End")
			for cloudKitNotification:CKNotification in self.notifications.toRead {
				switch cloudKitNotification.notificationType {
				case CKNotificationType.readNotification, CKNotificationType.recordZone, CKNotificationType.database:
					Log.message("Other notification type called: \(cloudKitNotification.notificationType.hashValue)")
					break
				case CKNotificationType.query:
					if let
						queryNotification: CKQueryNotification = cloudKitNotification as? CKQueryNotification {
						// Do your process here depending on the reason of the change
						let reason: CKQueryNotificationReason = queryNotification.queryNotificationReason
						switch reason {
						case .recordDeleted:
							self.notifications.deleted.append(queryNotification)
						case .recordUpdated:
							self.notifications.updated.append(queryNotification)
						case .recordCreated:
							self.notifications.created.append(queryNotification)
						}
					}
				}
			}
			Log.message("FetchNotificationsChangesOperation Before\nCreated: \(self.notifications.created.count) Updated: \(self.notifications.updated.count) Deleted: \(self.notifications.deleted.count)", enabled: false, alert: false)

			// When creating an object is cancelled, we can get both a save and a delete request. Just honer the delete request.
			for notificationCreated in self.notifications.created {
				for notificationDeleted in self.notifications.deleted {
					if notificationDeleted.recordID == notificationCreated.recordID {
						if let index = self.notifications.created.index(of: notificationCreated) {
							self.notifications.created.remove(at: index)
							self.notifications.deleted.append(notificationCreated)
						}
					}
				}
			}

			Log.message("FetchNotificationsChangesOperation After\nCreated: \(self.notifications.created.count) Updated: \(self.notifications.updated.count) Deleted: \(self.notifications.deleted.count)")
			self.finish()
		}
	}

	private func finish() {
		self.fetchNotificationsChangesCompletionBlock?(self.notifications)
		self.state(.finished)
		self.progress.completedUnitCount = self.progress.totalUnitCount
	}
}

class FetchRecordWithNotificationsOperation: AsynchronousOperation, ProgressReporting {

	// Each item in the notification queue needs to be marked as "read" so next time we won't have to handle them
	private var notifications: Notifications?
	var fetchRecordsWithNotificationCompletionBlock: (([CKRecordID : CKRecord]?) -> Swift.Void)?
	internal let progress = Progress.discreteProgress(totalUnitCount: 1)

	convenience init(_ notifications: Notifications/*, progress: Progress? = nil*/) {
		self.init()
		self.notifications = notifications
	}

	func setup(with notifications: Notifications) {
		self.notifications = notifications
	}

	override func main() {
		Log.message("FetchRecordWithNotificationsOperation Start", enabled: false)
		guard let notifications = self.notifications, !((notifications.created + notifications.updated).isEmpty) else {
			fetchRecordsWithNotificationCompletionBlock?(nil)
			state(.finished)
			return
		}
		let queryNotifications = notifications.created + notifications.updated
		progress.totalUnitCount = Int64(queryNotifications.count)
		// This block processes and fetches all Records
		let remoteRecordIDs:[CKRecordID] = queryNotifications.map(){$0.recordID!}
		let truncatedRecordIDs = Array(remoteRecordIDs.prefix(400))
		let fetchRecordsDictionaryOperation = FetchRecordsDictionaryOperation(with: truncatedRecordIDs, database: DataManager.Container.publicCloudDatabase)
		fetchRecordsDictionaryOperation.qualityOfService = QualityOfService.userInitiated
		progress.addChild(fetchRecordsDictionaryOperation.progress, withPendingUnitCount: 1)
		fetchRecordsDictionaryOperation.fetchRecordsDictionaryCompletionBlock = { (recordsDictionary) in
			self.fetchRecordsWithNotificationCompletionBlock?(recordsDictionary)
			self.progress.completedUnitCount = 1
			Log.message("FetchRecordWithNotificationsOperation Completed", enabled: false)
			self.state(.finished)
		}
		fetchRecordsDictionaryOperation.start()
	}
}

class UpdatePublicRecordsOperation: AsynchronousOperation {

	private var notifications: Notifications?
	private var recordsDictionary: [CKRecordID : CKRecord]?
	private var notificationsToMarkRead = [CKNotificationID]()
	var updatePublicRecordsCompletionBlock: ((_ notificationsToMarkRead: [CKNotificationID]?) -> Swift.Void)?

	convenience init(notifications: Notifications, recordsDictionary: [CKRecordID : CKRecord]) {
		self.init()
		self.notifications = notifications
		self.recordsDictionary = recordsDictionary
	}

	public func setup(with notifications:Notifications, recordsDictionary: [CKRecordID : CKRecord]) {
		self.notifications = notifications
		self.recordsDictionary = recordsDictionary
	}

	override func main() {
		guard let notifications = self.notifications, let recordsDictionary = self.recordsDictionary else {
			self.finish()
			return
		}

		for (recordID, record) in recordsDictionary {
			// We are fetching this for the first time. Update the locally created record.
			let objects = DataManager.fetchLocalEntities(withType: record.recordType, predicate: NSPredicate(format: "recordName = %@", recordID.recordName))
			if let fetchedObject:NSManagedObject = objects?.first {
				fetchedObject.addAttributes(from:record)
			}
			else {
				var recordIDs = notifications.created.map{$0.recordID!}
				recordIDs.append(contentsOf:notifications.updated.map{$0.recordID!})
				if recordIDs.contains(recordID), let createdObject = DataManager.createManagedObject(forRecord: record) {
					createdObject.addAttributes(from:record)
				}
			}
			
			let queryNotifications: [CKQueryNotification] = notifications.toRead.filter({$0.recordID == recordID})
			let notificationIDs:[CKNotificationID] = queryNotifications.map{$0.notificationID!}
			self.notificationsToMarkRead.append(contentsOf: notificationIDs)
		}
		self.finish()
	}

	private func finish() {
		self.updatePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
		self.state(.finished)
	}
}


class DeletePublicRecordsOperation: AsynchronousOperation {

	private var notificationsToMarkRead = [CKNotificationID]()
	private var notifications: Notifications?
	public var deletePublicRecordsCompletionBlock: (([CKNotificationID]?) -> Swift.Void)?

	convenience init(notifications: Notifications, notificationsToMarkRead: [CKNotificationID]) {
		self.init()
		self.notifications = notifications
	}

	public func setup(with notifications: Notifications) {
		self.notifications = notifications
	}

	override func main() {
		Log.message("DeletePublicRecordsOperation Start", enabled: false)
		guard let notifications = self.notifications,
			!notifications.deleted.isEmpty else {
				self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
				self.state(.finished)
				return
		}
		var index = 0
		for notification in notifications.deleted  {
			guard
				let recordID: CKRecordID = notification.recordID,
				let subscriptionID: String = notification.subscriptionID
				else {
					index += 1
					if index == notifications.deleted.count {
						self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
						self.state(.finished)
					}
					return
			}
			let queryNotifications: [CKQueryNotification] = notifications.toRead.filter({$0.recordID == recordID})
			let notificationIDs:[CKNotificationID] = queryNotifications.map{$0.notificationID!}
			self.notificationsToMarkRead.append(contentsOf: notificationIDs)

			let recordType = subscriptionID
			let objects = DataManager.fetchLocalEntities(withType: recordType, predicate: NSPredicate(format: "recordName = %@", recordID.recordName))
			if let fetchedObject = objects?.first {
				DataManager.backgroundContext.delete(fetchedObject)
				index += 1
				if index == notifications.deleted.count {
					self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
					self.state(.finished)
					Log.message("DeletePublicRecordsOperation End", enabled: false)
				}
			}
			else {
				index += 1
				if index == notifications.deleted.count {
					self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
					self.state(.finished)
				}
			}
		}
	}
}

class DeletePublicRecordsOperation2: AsynchronousOperation {

	private var notificationsToMarkRead = [CKNotificationID]()
	private var notifications: Notifications?
	public var deletePublicRecordsCompletionBlock: (([CKNotificationID]?) -> Swift.Void)?

	convenience init(notifications: Notifications, notificationsToMarkRead: [CKNotificationID]) {
		self.init()
		self.notifications = notifications
	}

	public func setup(with notifications: Notifications) {
		self.notifications = notifications
	}

	override func main() {
		DispatchQueue.main.async {
			Log.message("DeletePublicRecordsOperation Start", enabled: false)

			guard let notifications = self.notifications,
				!notifications.deleted.isEmpty else {
					self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
					self.state(.finished)
					return
			}
			var index = 0
			for notification in notifications.deleted  {
				guard
					let recordID: CKRecordID = notification.recordID,
					let subscriptionID: String = notification.subscriptionID
					else {
						index += 1
						if index == notifications.deleted.count {
							self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
							self.state(.finished)
						}
						return
				}
				let queryNotifications: [CKQueryNotification] = notifications.toRead.filter({$0.recordID == recordID})
				let notificationIDs:[CKNotificationID] = queryNotifications.map{$0.notificationID!}
				self.notificationsToMarkRead.append(contentsOf: notificationIDs)

				let recordType = subscriptionID
				let objects = DataManager.fetchLocalEntities(withType: recordType, predicate: NSPredicate(format: "recordName = %@", recordID.recordName))
				if let fetchedObject = objects?.first {
					DataManager.backgroundContext.delete(fetchedObject)
					index += 1
					if index == notifications.deleted.count {
						self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
						self.state(.finished)
						Log.message("DeletePublicRecordsOperation End", enabled: false)
					}
				}
				else {
					index += 1
					if index == notifications.deleted.count {
						self.deletePublicRecordsCompletionBlock?(self.notificationsToMarkRead)
						self.state(.finished)
					}
				}
			}
		}
	}
}

class MarkReadOperation: AsynchronousOperation, ProgressReporting {

	private var notificationsToMarkRead: [CKNotificationID]!
	public let progress = Progress.discreteProgress(totalUnitCount: 1)
	var markReadCompletionBlock: ((_ wasChanged: Bool?) -> Swift.Void)?

	convenience init(notificationIDS: [CKNotificationID]) {
		self.init()
		self.notificationsToMarkRead = notificationIDS
	}

	public func setup(with notificationsToMarkRead: [CKNotificationID]) {
		self.notificationsToMarkRead = notificationsToMarkRead
	}

	override func main() {
		Log.message("MarkReadOperation Start with Count \(self.notificationsToMarkRead.count)", enabled: false)

		guard !notificationsToMarkRead.isEmpty else {
			markReadCompletionBlock?(false)
			self.state(.finished)
			self.progress.completedUnitCount = 1
			return
		}
		let truncatedNotificationsIDsToMarkRead = Array(notificationsToMarkRead.prefix(400))
		// Mark the notifications as read
		let markReadOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: truncatedNotificationsIDsToMarkRead)
		markReadOperation.qualityOfService = QualityOfService.utility
		let configurataion = CKOperation.Configuration()
		configurataion.container = DataManager.Container
		markReadOperation.configuration = configurataion

		markReadOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotificationID]?, operationError: Error?) -> Void in
			if let notificationIDsMarkedRead = notificationIDsMarkedRead {
				self.markReadCompletionBlock?(!notificationIDsMarkedRead.isEmpty)
			}
			guard operationError == nil else {
				// Handle the error here
				Log.message("Unable to mark notifications \(String(describing: notificationIDsMarkedRead)) as read. Error: \(String(describing: operationError))", enabled: false)
				self.markReadCompletionBlock?(false)
				self.state(.finished)
				self.progress.completedUnitCount = 1
				return
			}
			Log.message("Mark notifications \(String(describing: notificationIDsMarkedRead)) as read. Error: \(String(describing: operationError))", enabled: false)
			if DataManager.backgroundContext.hasChanges {
				DataManager.backgroundContext.performAndWait {
					do {
						Log.message("Save Background Context")
						try DataManager.backgroundContext.save()
					} catch {
						Log.message((error as NSError).debugDescription)
					}
				}
			}
			self.markReadCompletionBlock?(true)
			self.state(.finished)
			self.progress.completedUnitCount = 1
			Log.message("MarkReadOperation End", enabled: false)
		}
		DataManager.Container.add(markReadOperation)
	}
}

// MARK: - Private Database Changes

class FetchDatabaseChangesOperation: AsynchronousOperation, ProgressReporting {
	
	private var database: CKDatabase!
	var fetchDatabaseChangesCompletionBlock: ((_ changedRecords: [CKRecord]?, _ deletedRecords: [(CKRecordID, String)]?) -> Swift.Void)?
	
	public let progress = Progress.discreteProgress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	
	convenience init(for database: CKDatabase) {
		self.init()
		self.database = database
	}
	
	override func main() {
		guard database != nil else {
			self.state(.finished)
			self.fetchDatabaseChangesCompletionBlock?(nil, nil)
			return
		}

		self.progress.completedUnitCount = 0
		// Add a completion block to start progress reporting
		progressStartedOperation?.start()
		let zoneChangesOperation = FetchZoneChangesOperation(for: database)
		
		let fetchRecordChangesInZonesOperation = FetchRecordChangesInZonesOperation()
		let updatePrivateRecordsOperation = UpdatePrivateRecordsOperation()
		let deletePrivateRecordsOperation = DeletePrivateRecordsOperation()
		
		zoneChangesOperation.fetchZoneChangesCompletionBlock = { (zoneIDsChanged, zoneIDsDeleted) in
			if let zoneIDsChanged = zoneIDsChanged, let zoneIDsDeleted = zoneIDsDeleted {
				for zoneIDDeleted in zoneIDsDeleted {
					let recordType = "GameZone"
					let predicate = NSPredicate(format: "recordZoneID == %@", zoneIDDeleted)
					if let object = DataManager.fetchLocalEntities(withType: recordType, predicate: predicate)?.first {
						DataManager.backgroundContext.performAndWait {
							DataManager.backgroundContext.delete(object)
						}
					}
				}
				fetchRecordChangesInZonesOperation.setup(recordZoneIDs:zoneIDsChanged + zoneIDsDeleted, for:self.database)
			}
			fetchRecordChangesInZonesOperation.start()
		}
		
		fetchRecordChangesInZonesOperation.fetchRecordChangesInZoneCompletionBlock = { (changedRecords, deletedRecords) in
			
			if let changedRecords = changedRecords {
				updatePrivateRecordsOperation.setup(records: changedRecords)
			}
			updatePrivateRecordsOperation.updatePrivateRecordsOperationCompletionBlock = { (recordIDs) in
				deletePrivateRecordsOperation.setup(deletedRecords: deletedRecords)
				deletePrivateRecordsOperation.start()
			}
			deletePrivateRecordsOperation.deletePrivateRecordsOperationCompletionBlock = { (deletedRecords) in
				if DataManager.backgroundContext.hasChanges {
					DataManager.backgroundContext.performAndWait {
						try? DataManager.backgroundContext.save()
					}
				}
				self.state(.finished)
				self.fetchDatabaseChangesCompletionBlock?(changedRecords, deletedRecords)
			}
			updatePrivateRecordsOperation.start()
		}
		zoneChangesOperation.start()
	}
}

class FetchZoneChangesOperation: AsynchronousOperation, ProgressReporting {
	
	var database: CKDatabase!
	
	// Store these to disk so that they persist across launches
	private lazy var serverChangeToken: CKServerChangeToken? = {
		// Read change token from disk
		return UserDefaults.value(forKey:ServerDatabaseDefaults.databaseChangeToken, withName: String(self.database.databaseScope.rawValue)) as? CKServerChangeToken
	}()
	
	private var zoneIDsChanged = [CKRecordZoneID]()
	private var zoneIDsDeleted = [CKRecordZoneID]()
	
	fileprivate var fetchZoneChangesCompletionBlock: ((_ zoneIDsChanged: [CKRecordZoneID]?, _ zoneIDsDeleted:[CKRecordZoneID]?) -> Swift.Void)?
	
	public let progress = Progress.discreteProgress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	
	convenience init(for database: CKDatabase) {
		self.init()
		self.database = database
	}
	
	override func main() {
		guard database != nil else {
			self.state(.finished)
			return
		}
		
		self.progress.completedUnitCount = 0
		// Add a completion block to start progress reporting
		progressStartedOperation?.start()
		let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: serverChangeToken)
		// previously cached
		changesOperation.fetchAllChanges = true
		changesOperation.recordZoneWithIDChangedBlock = { (zoneID) in
			self.zoneIDsChanged.append(zoneID)
		}
		// collect zone IDs
		changesOperation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
			self.zoneIDsDeleted.append(zoneID)
		}
		// delete local cache
		changesOperation.changeTokenUpdatedBlock = { (newToken) in
			// Write this new database change token to memory
			UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : newToken], forName: String(self.database.databaseScope.rawValue))
		}
		
		changesOperation.fetchDatabaseChangesCompletionBlock = {
			(newToken, more, error) in
			// error handling here
			Log.error(with: #line, functionName: #function, error: error)
			if let newToken = newToken {
				// Write this new database change token to memory
				UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : newToken], forName: String(self.database.databaseScope.rawValue))
			}
			self.fetchZoneChangesCompletionBlock?(self.zoneIDsChanged, self.zoneIDsDeleted)
			self.state(.finished)
		}
		self.database.add(changesOperation)
	}
}

class FetchRecordChangesInZonesOperation: AsynchronousOperation, ProgressReporting {
	
	private var recordZoneIDs = [CKRecordZoneID]()
	private var records = [CKRecord]()
	private var deletedRecords = [(CKRecordID, String)]()
	private var database: CKDatabase!

	fileprivate var fetchRecordChangesInZoneCompletionBlock: ((_ changedRecords: [CKRecord]?, _ deletedRecords: [(CKRecordID, String)]) -> Swift.Void)?
	
	public let progress = Progress.discreteProgress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	
	convenience init(recordZoneIDs: [CKRecordZoneID], for database: CKDatabase) {
		self.init()
		self.recordZoneIDs = recordZoneIDs
		self.database = database
	}
	
	func setup(recordZoneIDs: [CKRecordZoneID], for database: CKDatabase) {
		self.recordZoneIDs = recordZoneIDs
		self.database = database
	}
	
	override func main() {
		self.progress.completedUnitCount = 0
		// Add a completion block to start progress reporting
		progressStartedOperation?.start()
		
		var optionsByRecordZoneID = [CKRecordZoneID : CKFetchRecordZoneChangesOptions]()
		
		for recordZoneID in recordZoneIDs {
			let options = CKFetchRecordZoneChangesOptions()
			let zoneName = recordZoneID.zoneName
			let changeToken = UserDefaults.value(forKey:ServerDatabaseDefaults.databaseChangeToken, withName: zoneName) as? CKServerChangeToken
			options.previousServerChangeToken = changeToken
			optionsByRecordZoneID[recordZoneID] = options
		}
		
		let fetchRecordZoneChangesOperation = CKFetchRecordZoneChangesOperation()
		
		fetchRecordZoneChangesOperation.recordZoneIDs = self.recordZoneIDs
		fetchRecordZoneChangesOperation.optionsByRecordZoneID = optionsByRecordZoneID
		fetchRecordZoneChangesOperation.fetchAllChanges = true
		
		fetchRecordZoneChangesOperation.recordChangedBlock =  {(record) in
			self.records.append(record)
			Log.message("Append Records Count: \(self.records.count)")
		}
		
		fetchRecordZoneChangesOperation.recordWithIDWasDeletedBlock = {(recordID, recordType) in
			self.deletedRecords.append((recordID, recordType))
			Log.message("Delete Records Count: \(self.deletedRecords.count)")
		}
		
		fetchRecordZoneChangesOperation.recordZoneFetchCompletionBlock = { (recordZoneID, zoneChangeToken, data, moreComing, error) in
			Log.message("More Coming \(moreComing)")
			// Write this new database change token to memory
			if let zoneChangeToken = zoneChangeToken {
				UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : zoneChangeToken], forName: recordZoneID.zoneName)
			}
		}
		
		fetchRecordZoneChangesOperation.recordZoneChangeTokensUpdatedBlock = {(recordZoneID, zoneChangeToken, data) in
			// Write this new database change token to memory
			if let zoneChangeToken = zoneChangeToken {
				Log.message("Zone Change Token: \(zoneChangeToken)")
				UserDefaults.update(withDictionary: [ServerDatabaseDefaults.databaseChangeToken : zoneChangeToken], forName: recordZoneID.zoneName)
			}
		}
		
		fetchRecordZoneChangesOperation.fetchRecordZoneChangesCompletionBlock = { error in
			Log.error(with: #line, functionName: #function, error: error)
			self.fetchRecordChangesInZoneCompletionBlock?(self.records, self.deletedRecords)
			self.state(.finished)
		}
		database.add(fetchRecordZoneChangesOperation)
	}
}

class UpdatePrivateRecordsOperation: AsynchronousOperation {
	
	private var records: [CKRecord]!
	var updatePrivateRecordsOperationCompletionBlock: (([CKRecord]?) -> Swift.Void)?
	convenience init(records: [CKRecord]) {
		self.init()
		self.records = records
	}
	
	func setup(records: [CKRecord]) {
		self.records = records
	}
	
	override func main() {
		Log.message("Update PrivateRecordsOperation Start")

		guard let records = self.records, !records.isEmpty else {
			if let updatePrivateRecordsOperationCompletionBlock = updatePrivateRecordsOperationCompletionBlock {
				updatePrivateRecordsOperationCompletionBlock(self.records)
			}
			Log.message("Update PrivateRecordsOperation End")

			self.state(.finished)
			return
		}
		for record in records {

			var recordType: String
			switch record.recordType {
			case "cloudkit.share":
				recordType = "Share"
			default:
				recordType = record.recordType
				break
			}
			
			let fetchedObjects = DataManager.fetchLocalEntities(withType: recordType, predicate: NSPredicate(format: "recordName == %@", record.recordID.recordName))
			if let fetchedObject:NSManagedObject = fetchedObjects?.first {
				fetchedObject.addAttributes(from:record)
			}
			else {
				Log.message("\(record.recordType)")
				_ = DataManager.createManagedObject(forRecord: record)
			}
		}

		self.updatePrivateRecordsOperationCompletionBlock?(self.records)
		Log.message("Update PrivateRecordsOperation End")

		self.state(.finished)
	}
}

class DeletePrivateRecordsOperation: AsynchronousOperation {
	
	var deletedRecords:[(CKRecordID, String)]?
	var deletePrivateRecordsOperationCompletionBlock: (([(CKRecordID, String)]?) -> Swift.Void)?

	convenience init(deletedRecords: [(CKRecordID, String)]) {
		self.init()
		self.deletedRecords = deletedRecords
	}
	
	func setup(deletedRecords: [(CKRecordID, String)]) {
		self.deletedRecords = deletedRecords
	}
	
	override func main() {
		Log.message("DeletePrivateRecordsOperation Start")
		guard let deletedRecords = self.deletedRecords , !deletedRecords.isEmpty  else {
			if let deletePrivateRecordsOperationCompletionBlock = self.deletePrivateRecordsOperationCompletionBlock {
				deletePrivateRecordsOperationCompletionBlock(self.deletedRecords)
			}
			Log.message("DeletePrivateRecordsOperation End")
			self.state(.finished)
			return
		}
		
		for deletedRecord in deletedRecords  {
			let recordType = deletedRecord.1
			if let objects = DataManager.fetchLocalEntities(withType: recordType, predicate: NSPredicate(format: "recordName = %@", deletedRecord.0.recordName)) {
				for managedObject in objects {
					DataManager.backgroundContext.delete(managedObject)
				}
			}
		}
		
		if let deletePrivateRecordsOperationCompletionBlock = self.deletePrivateRecordsOperationCompletionBlock {
			deletePrivateRecordsOperationCompletionBlock(self.deletedRecords)
		}
		Log.message("DeletePrivateRecordsOperation End")
		self.state(.finished)
	}
}
