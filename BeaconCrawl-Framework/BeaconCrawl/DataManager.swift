//
//  DataManager.swift
//  Notifications
//
//  Created by WCA on 6/20/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MapKit
import GameKit

extension Notification.Name {
	public static let RemoteNotification: Notification.Name = Notification.Name("RemoteNotification")
	public static let MessageUpdatedNotification: Notification.Name = Notification.Name("MessageUpdatedNotification")
	public static let PlaceUpdatedNotification: Notification.Name = Notification.Name("PlaceUpdatedNotification")
	public static let BeaconUpdatedNotification: Notification.Name = Notification.Name("BeaconUpdatedNotification")
	public static let BeaconsUpdatedNotification: Notification.Name = Notification.Name("BeaconsUpdatedNotification")
	public static let PlayerUpdatedNotification: Notification.Name = Notification.Name("PlayerUpdatedNotification")
	public static let GameShareAcceptedNotification: Notification.Name = Notification.Name("GameShareAcceptedNotification")
	public static let GameShareUpdatedNotification: Notification.Name = Notification.Name("GameShareUpdatedNotification")
}


public struct District {
	public static let user = "Users"
	public static let place = "Place"
	public static let beacon = "Beacon"
	public static let adventure = "Adventure"
	public static let adventureDescription = "AdventureDescription"
	public static let webArchive = "WebArchive"
	public static let photo = "Photo"
	public static let photoShared = "PhotoShared"
	public static let game = "Game"
	public static let gameShare = "GameShare"
	public static let gameMessage = "GameMessage"
}


// Store these to disk so that they persist across launches
public struct ServerDatabaseDefaults {
	public static let databaseExists = "databaseExists"
	public static let databaseChangeToken = "databaseChangeToken"
}

@objc(DataManager)
open class DataManager: NSObject {
	
	public static let viewContext = CoreDataManager.shared.persistentContainer.viewContext
	public static let backgroundContext = CoreDataManager.shared.persistentContainer.newBackgroundContext()
	
	// used for marking subscriptions as "read", this token tells the server what portions of the records to fetch and return to your app
	let internetReachability: Reachability = Reachability()!
	fileprivate var serialQueue: OperationQueue!
	fileprivate var identifier = UIBackgroundTaskInvalid
	fileprivate var isInBackground = false
	
	public static var Container: CKContainer {
		get {
			if let string = UserDefaults.standard.object(forKey: "container") as? String, string == "iCloud.com.districtapp.CloudKit-CoreData"  {
				return CKContainer(identifier: "iCloud.com.districtapp.CloudKit-CoreData")
			}
			else {
				#if BETA
				return CKContainer(identifier: "iCloud.com.districtapp.CloudKit-CoreData")
				#elseif DEBUG
				return CKContainer(identifier: "iCloud.com.districtapp.CloudKit-CoreData")
				#else
				return CKContainer(identifier: "iCloud.com.districtapp.CloudKit-CoreData")
				#endif
			}
		}
	}
	
	public static let shared = DataManager()
	
	public static let cloudKitManager = CloudKitManager()
	
	override fileprivate init() {
		super.init()
		DataManager.viewContext.undoManager = nil
		DataManager.viewContext.automaticallyMergesChangesFromParent = true
		setupQueue()
		setupSubscriptions()
		setupObservers()
		setupReachability()
	}
	
	deinit {
		// perform the deinitialization
		self.removeObservers()
	}
	
	// MARK: - Setup
	
	func setupSubscriptions() {
		AccountManager.shared.accountAvailable(request: AccountManager.Require.none) { (accountStatus) in
			if CKAccountStatus.available == accountStatus {
				self.subscribe()
			}
			else {
				self.unsubscribe()
			}
		}
		// Set up a block to catch accountAvailable when the User signs-in or out
		let completionBlock:((_ accountStatus: CKAccountStatus) -> Swift.Void) = { (accountStatus) in
			if CKAccountStatus.available == accountStatus {
				self.subscribe()
			}
			else {
				self.unsubscribe()
			}
		}
		AccountManager.accountChangedOperationCompletionBlocks.append(completionBlock)
	}
	
	func subscribe() {
		DataManager.cloudKitManager.subscribe(forRecordTypes: [District.beacon])
		
		DataManager.cloudKitManager.subscribe(forDatabase: DataManager.Container.privateCloudDatabase)
		DataManager.cloudKitManager.subscribe(forDatabase: DataManager.Container.sharedCloudDatabase)
		
		DataManager.Container.fetchUserRecordID { (recordID, error) in
		}
	}
	
	func unsubscribe() {
		Log.message("Unsubscribe")
		DataManager.cloudKitManager.unsubscribe(forRecordTypes: [District.beacon], in: Defaults.subscriptions)
	}
	
	func setupQueue() {
		self.serialQueue = OperationQueue()
		serialQueue.maxConcurrentOperationCount = 1
	}
	
	
	func setupObservers() {
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { (notification:Notification) in
			if self.isInBackground {
				self.isInBackground = false
				self.endBackgroundTask()
			}
			//			let operation = CKModifyBadgeOperation(badgeValue: 0)
			//			operation.modifyBadgeCompletionBlock = { (error) in
			//				Log.error(with: #line, functionName: #function, error: error)
			//			}
			//			operation.start()
			
			UIApplication.shared.applicationIconBadgeNumber = 0
		}
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: nil) { (notification:Notification) in
			if !self.isInBackground {
				self.isInBackground = true
				self.startBackgroundTask()
			}
		}
	}
	
	func removeObservers() {
		NotificationCenter.default.removeObserver(self)
	}
	
	func setupReachability() {
		do {
			try internetReachability.startNotifier()
		}
		catch {
			Log.message("Failed to setup Reachability")
		}
	}
	
	func teardownReachability() {
		internetReachability.stopNotifier()
	}
	
	fileprivate func startBackgroundTask() {
		if identifier == UIBackgroundTaskInvalid {
			identifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundObserver", expirationHandler: {
				self.endBackgroundTask()
			})
		}
	}
	
	fileprivate func endBackgroundTask() {
		if identifier != UIBackgroundTaskInvalid {
			UIApplication.shared.endBackgroundTask(identifier)
			identifier = UIBackgroundTaskInvalid
		}
	}
	
	// MARK: - Creating
	
	
	open class func createManagedObject(forRecordType name: String, recordID: CKRecordID) -> NSManagedObject? {
		var managedObject: NSManagedObject? = nil
		backgroundContext.performAndWait {
			if let entityDescription =  NSEntityDescription.entity(forEntityName: name, in:backgroundContext) {
				let record = CKRecord(recordType: name, recordID:recordID)
				entityDescription.userInfo = ["record" : record]
				managedObject = NSManagedObject(entity: entityDescription, insertInto:backgroundContext)
			}
		}
		return managedObject
	}
	
	open class func createManagedObject(forRecordType name: String, in context: NSManagedObjectContext = backgroundContext, zone: GameZoneMO? = nil) -> NSManagedObject? {
		var managedObject: NSManagedObject? = nil
		let recordZoneID = zone?.recordZoneID != nil ? zone?.recordZoneID : CKRecordZone.default().zoneID
		if let entityDescription =  NSEntityDescription.entity(forEntityName: name, in:context) {
			let record = CKRecord(recordType: name, zoneID:recordZoneID!)
			entityDescription.userInfo = ["record" : record]
			managedObject = NSManagedObject(entity: entityDescription, insertInto:context)
		}
		return managedObject
	}
	
	open class func createManagedObject(forRecord record:CKRecord) -> NSManagedObject? {
		var managedObject: NSManagedObject? = nil
		backgroundContext.performAndWait {
			switch record.recordType {
			case "cloudkit.share":
				if let entityDescription = NSEntityDescription.entity(forEntityName: "Share", in:backgroundContext) {
					entityDescription.userInfo = ["record" : record]
					managedObject = NSManagedObject(entity:entityDescription, insertInto:backgroundContext)
				}
			default:
				if let entityDescription = NSEntityDescription.entity(forEntityName: record.recordType, in:backgroundContext) {
					entityDescription.userInfo = ["record" : record]
					managedObject = NSManagedObject(entity:entityDescription, insertInto:backgroundContext)
				}
			}
		}
		return managedObject
	}
	
	open class func createManagedObject(forShare share: CKShare) -> ShareMO {
		let entity = ShareMO.entity()
		entity.userInfo = ["record" : share]
		return ShareMO(entity: entity, insertInto: DataManager.backgroundContext)
	}
	
	open class func createManagedObject(forShareParticipant shareParticipant: CKShareParticipant) -> ShareParticipantMO {
		let entity = ShareParticipantMO.entity()
		entity.userInfo = ["shareParticipant" : shareParticipant]
		return ShareParticipantMO(entity: entity, insertInto: DataManager.backgroundContext)
	}
	
	// MARK: - Fetching
	
	open class func fetchLocalEntities(withType type: String, in context: NSManagedObjectContext = DataManager.backgroundContext, predicate: NSPredicate) -> [NSManagedObject]? {
		var type = type
		guard type != "AdventureImage", type != "Favorite" else {
			return nil
		}
		if type == "cloudkit.share" {
			type = "Share"
		}
		
		let fetchRequest:NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName:type)
		fetchRequest.predicate = predicate
		return fetchLocalEntities(withFetchRequest: fetchRequest, in: context)
	}
	
	open class func fetchLocalEntities(withFetchRequest fetchRequest: NSFetchRequest<NSManagedObject>, in context: NSManagedObjectContext = DataManager.backgroundContext) -> [NSManagedObject]? {
		do {
			return try context.fetch(fetchRequest)
		}
		catch {
			Log.error(with: #line, functionName: #function, error: error)
			return nil
		}
	}
	
	// MARK: - Saving
	
	/// Convience method to save to iCloud and CoreData
	open class func save(_ objects: [NSManagedObject],
						 to database: CKDatabase = DataManager.Container.publicCloudDatabase,
						 with zone: CKRecordZone? = nil,
						 withProgress progress:Progress? = nil,
						 completionHandler: (()->())? = nil) {
		
		var objects = objects
		
		var updatedRecords = [CKRecord]()
		for object in objects {
			
			// We can't make "currentDistance" transient or it will not work with sorting or NSFetchedResults Controller
			// Filter out changes that are only "currentDistance"
			var changedValues = object.changedValues()
			changedValues.removeValue(forKey: "currentDistance")
			if changedValues.isEmpty {
				objects.remove(at: objects.index(of: object)!)
			}
			
			if let managedObjectData = object.data,
				let record = recordFromData(managedObjectData as Data) {
				object.addAttributes(to:record, for: Array(object.changedValues().keys))
				updatedRecords.append(record)
			}
			else {
				if let entityName = object.entity.name {
					var record: CKRecord
					if let zone = zone {
						record = CKRecord(recordType: entityName, zoneID: zone.zoneID)
					}
					else {
						record = CKRecord(recordType: entityName)
					}
					object.addAttributes(to:record, for: Array(object.changedValues().keys))
					updatedRecords.append(record)
				}
			}
		}
		
		if viewContext.hasChanges {
			
			viewContext.performAndWait {
				do {
					try viewContext.save()
				} catch {
					fatalError("Failure to save context: \(error)")
				}
			}
		}
		
		
		let modifyRecordsOperation = ModifyRecordsOperation(recordsToSave: updatedRecords, recordIDsToDelete: [], database: database)
		
		progress?.addChild(modifyRecordsOperation.progress, withPendingUnitCount: 1)
		
		
		modifyRecordsOperation.modifyRecordsCompletionBlock = { (updatedRecords, deletedRecordIDs) in
			
			let group = DispatchGroup()
			group.enter()
			guard let updatedRecords = updatedRecords, let recordType = updatedRecords.map ({$0.recordType}).first else {
					return
			}
			let recordNames = updatedRecords.map {$0.recordID.recordName}
			let fetchRequest:NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName:recordType)
			fetchRequest.predicate = NSPredicate(format: "recordName IN %@", recordNames)
			
			let localObjectsOperation = FetchLocalObjectsOperation(with: fetchRequest)
			localObjectsOperation.fetchLocalObjectsCompletionBlock = { (fetchedObjects) in
				guard let fetchedObjects = fetchedObjects else {
					return
				}
				backgroundContext.performAndWait {
					for (index, object) in fetchedObjects.enumerated() {
						object.addAttributes(from: updatedRecords[index])
					}
				}
				group.leave()
			}
			localObjectsOperation.start()
			
			group.wait()
			// Save the context again because the local object has been updated with the new CKRecordID
			backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.overwriteMergePolicyType)
			if backgroundContext.hasChanges {
				backgroundContext.performAndWait {
					do {
						try backgroundContext.save()
					} catch {
						Log.message((error as NSError).localizedDescription)
					}
				}
			}
			completionHandler?()
		}
		let queue = OperationQueue()
		queue.addOperation(modifyRecordsOperation)
	}
	/// Convience method to save to iCloud and CoreData
	open class func save2(_ objects: [NSManagedObject],
						 to database: CKDatabase = DataManager.Container.publicCloudDatabase,
						 with zone: CKRecordZone? = nil,
						 withProgress progress:Progress? = nil,
						 completionHandler: (()->())? = nil) {
		
		var objects = objects

		var updatedRecords = [CKRecord]()
		for object in objects {
			
			// We can't make "currentDistance" transient or it will not work with sorting or NSFetchedResults Controller
			// Filter out changes that are only "currentDistance"
			var changedValues = object.changedValues()
			changedValues.removeValue(forKey: "currentDistance")
			if changedValues.isEmpty {
				objects.remove(at: objects.index(of: object)!)
			}
			
			if let managedObjectData = object.data,
				let record = DataManager.recordFromData(managedObjectData as Data) {
				object.addAttributes(to:record, for: Array(object.changedValues().keys))
				updatedRecords.append(record)
			}
			else {
				if let entityName = object.entity.name {
					var record: CKRecord
					if let zone = zone {
						record = CKRecord(recordType: entityName, zoneID: zone.zoneID)
					}
					else {
						record = CKRecord(recordType: entityName)
					}
					object.addAttributes(to:record, for: Array(object.changedValues().keys))
					updatedRecords.append(record)
				}
			}
		}

//		objects.forEach { object in
//			guard let context = object.managedObjectContext else { return }
			do {
				try viewContext.save()
			} catch {
				fatalError("Failure to save context: \(error)")
			}
//		}

		let modifyRecordsOperation = ModifyRecordsOperation(recordsToSave: updatedRecords, recordIDsToDelete: [], database: database)
		
		progress?.addChild(modifyRecordsOperation.progress, withPendingUnitCount: 1)
		
		
		modifyRecordsOperation.modifyRecordsCompletionBlock = { (updatedRecords, deletedRecordIDs) in
			if let records = updatedRecords  {
				for record in records {
					
//					CoreDataManager.shared.persistentContainer.performBackgroundTask({ (context) in
//						// ... do some task on the context
//
//						// save the context
//						do {
//							try context.save()
//						} catch {
//							// handle error
//						}
//					})
//
					// Update the locally object's CKRecordID to reflect the changes.
					let objects = DataManager.fetchLocalEntities(withType: record.recordType,
																 in: backgroundContext,
																 predicate: NSPredicate(format: "recordName = %@",
																						record.recordID.recordName))
					
//					DataManager.backgroundContext.performAndWait {
					if let object = objects?.first {
//						backgroundContext.performAndWait {
//						let fetchedObject = DataManager.viewContext.object(with: object.objectID)
							
							object.addAttributes(from: record)
//						}
					}
//					}
				}
			}
			
			// Save the context again because the local object has been updated with the new CKRecordID
//			objects.forEach{ object in
//				guard let context = object.managedObjectContext else { return }
			if viewContext.hasChanges {
				do {
					try viewContext.save()
				} catch {
					fatalError("Failure to save context: \(error)")
				}
			}
			completionHandler?()
		}
		let queue = OperationQueue()
		queue.addOperation(modifyRecordsOperation)
	}

	
	open class func forceSave(objects: [NSManagedObject], with recordType: String, to database: CKDatabase, withProgress progress:Progress? = nil) {
		let savedObjects: [NSManagedObject] = objects
		
		// Save the records to core data now, in case there is a new save request.
		DispatchQueue.main.async {
			var updatedRecords = [CKRecord]()
			for object in savedObjects {
				Log.message("Fire Fault: \(String(describing: object.name))")
				var record: CKRecord
				if let recordID = object.recordID {
					record = CKRecord.init(recordType: recordType, recordID: recordID)
				}
				else {
					record = CKRecord.init(recordType: recordType)
				}
				if CloudKitManager.isUploadingToNewDatabase {
					object.addAttributes(to:record, for: Array(object.entity.propertiesByName.keys))
				}
				else {
					object.addAttributes(to:record, for: Array(object.changedValues().keys))
				}
				updatedRecords.append(record)
			}
			
			let modifyRecordsOperation = ModifyRecordsOperation(recordsToSave: updatedRecords, recordIDsToDelete: nil, database: database)
			
			progress?.addChild(modifyRecordsOperation.progress, withPendingUnitCount: 1)
			
			
			modifyRecordsOperation.completionBlock = {
				Log.message("Finished: \(recordType)")
				
			}
			let queue = OperationQueue()
			queue.addOperation(modifyRecordsOperation)
		}
	}
	
	
	class func runAfterDelay(_ delay: TimeInterval, completionHandler: @escaping ()->()) {
		let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: time, execute: completionHandler)
	}
	
	/// Deletes the object from both CloudKit and Core Data if database is specified
	
	open class func deleteObjects(_ managedObjects: [NSManagedObject], from database: CKDatabase? = nil) {
		for managedObject in managedObjects {
			if let managedObjectContext = managedObject.managedObjectContext {
				managedObjectContext.delete(managedObject)
			}
		}
		if let database = database {
			let deletedRecordIDs : [CKRecordID] = managedObjects.map({$0.recordID})
			let modifyRecordsOperation = ModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: deletedRecordIDs, database: database)
			modifyRecordsOperation.modifyRecordsCompletionBlock = { (_, deletedRecordIDs) in
				Log.message("Deleted \(String(describing: deletedRecordIDs))")
			}
			let queue = OperationQueue()
			queue.addOperation(modifyRecordsOperation)
		}
	}
	
	// MARK: - Remote Notifications
	open func handleRemoteNotification(_ userInfo:[AnyHashable : Any]) {
		let dictionary = userInfo as! [String: NSObject]
		let queryNotification = CKQueryNotification(fromRemoteNotificationDictionary: dictionary)
		guard let subscriptionID = queryNotification.subscriptionID else { return }
		switch queryNotification.databaseScope {
		case .public:
//			guard let recordID = queryNotification.recordID else {
//				return
//			}
//			let predicate = NSPredicate(format: "recordID = %@", recordID)
//			let query = CKQuery(recordType: subscriptionID, predicate: predicate)
//			let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: subscriptionID)
//			fetchRequest.predicate = predicate
//			let queryOperation = CKQueryOperation(query: query)
//			let fetchRecordsOperation = FetchObjectsOperation(with: fetchRequest,  queryOperation:queryOperation, DataManager.Container.publicCloudDatabase, localThenRemote: true)
//			fetchRecordsOperation.start()
//
//
//
//
//			switch queryNotification.queryNotificationReason {
//			case .recordUpdated:
//				break
//			case .recordDeleted:
//				break
//			case .recordCreated:
//				break
//			}
			let queryNotification = CKQueryNotification(fromRemoteNotificationDictionary: dictionary)
			Log.message("Query Notification: \(queryNotification),\n\n")
			let fetchPublicServerChangesOperation = FetchPublicServerChangesOperation()
			fetchPublicServerChangesOperation.completionBlock = {
				Log.message("Finished updating \(subscriptionID)", enabled: true)
			}
			fetchPublicServerChangesOperation.fetchPublicServerChangesCompletionBlock = { (notifications) in
				if let notifications = notifications {
					Log.message("Was Changed = \(notifications)", enabled: true)
				}
			}
			serialQueue.addOperation(fetchPublicServerChangesOperation)
		case .private:
			let fetchPrivateChangesOperation = FetchDatabaseChangesOperation(for: DataManager.Container.privateCloudDatabase)
			fetchPrivateChangesOperation.fetchDatabaseChangesCompletionBlock = { (changedRecords, deletedRecord) in
				NotificationCenter.default.post(name: .GameShareUpdatedNotification, object: changedRecords)
				Log.message("Finished updating \(subscriptionID)")
			}
			serialQueue.addOperation(fetchPrivateChangesOperation)
		case .shared:
			Log.message("Share Message Recieved \(userInfo)")
			let fetchSharedChangesOperation = FetchDatabaseChangesOperation(for: DataManager.Container.sharedCloudDatabase)
			fetchSharedChangesOperation.fetchDatabaseChangesCompletionBlock = { (changedRecords, deletedRecord) in
				NotificationCenter.default.post(name: .GameShareUpdatedNotification, object: changedRecords)
				Log.message("Finished updating \(subscriptionID)")
			}
			serialQueue.addOperation(fetchSharedChangesOperation)
		}
	}
	
//	open func fetchChanges(_ completionHandler:( (_ changedNotifications: Notifications?) -> Void)? = nil)  {
//		let fetchPublicServerChangesOperation = FetchPublicServerChangesOperation()
//		fetchPublicServerChangesOperation.fetchPublicServerChangesCompletionBlock = { (changedNotifications) in
//			completionHandler?(changedNotifications)
//		}
//		Log.message("Serial Queue Operation count: \(serialQueue.operationCount)", enabled: false)
//		serialQueue.addOperation(fetchPublicServerChangesOperation)
//	}
	
	// MARK: - Updating in Background
	
	func startBackgroundOperation(_ operation: CKOperation, queue: OperationQueue) -> UIBackgroundTaskIdentifier {
		var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
		
		backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundTask") {
			// Clean up any unfinished task business by marking where you stopped or ending the task outright.
			Log.message("Cleanup Task Started: \(String(describing: backgroundTaskIdentifier)) Time: \(UIApplication.shared.backgroundTimeRemaining)", enabled: true)
			UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
			backgroundTaskIdentifier = UIBackgroundTaskInvalid
		}
		
		// Start the long-running task and return immediately.
		DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
			Log.message("Background Task for queue Started: \(String(describing: backgroundTaskIdentifier)) Time: \(UIApplication.shared.backgroundTimeRemaining)", enabled: false, alert: false)
			queue.addOperation(operation)
		}
		return backgroundTaskIdentifier
	}
	
	func endBackgroundOperation (_ backgroundTaskIdentifier: UIBackgroundTaskIdentifier) {
		var backgroundTaskIdentifier = backgroundTaskIdentifier
		Log.message("Background Task Ended: \(backgroundTaskIdentifier) Time: \(UIApplication.shared.backgroundTimeRemaining)", enabled: false, alert: false)
		
		UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
		backgroundTaskIdentifier = UIBackgroundTaskInvalid
	}
	
	open class func recordFromObject(_ object: NSManagedObject) -> CKRecord? {
		return recordFromData(object.data)
	}
	
	// MARK: - Helpers
	open class func recordFromData(_ archivedData:Data) -> CKRecord? {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: archivedData)
		unarchiver.requiresSecureCoding = true
		if let unarchivedRecord = CKRecord(coder: unarchiver) {
			return unarchivedRecord
		}
		else {
			return nil
		}
	}
	
	open class func shareFromObject(_ object: ShareMO) -> CKShare? {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: object.data)
		unarchiver.requiresSecureCoding = true
		let unarchivedRecord = CKShare(coder: unarchiver)
		object.addAttributes(to: unarchivedRecord, for: object.allKeys())
		return unarchivedRecord
	}
	
	open class func fetchMessageObject(forGame game: GameMO, recordZone zone: CKRecordZone = CKRecordZone.default()) -> GameMessageMO? {
		var messageObject: GameMessageMO? = nil
		// Get the local message for the game if it exists
		if let user = AccountManager.currentUser(), let recordName = game.recordName {
			let objects = DataManager.fetchLocalEntities(withType: GameMessageMO.recordType(),
														 in: DataManager.backgroundContext,
														 predicate: NSPredicate(format: "sender = %@ AND game.recordName = %@", user, recordName))
			
			if let object: GameMessageMO = objects?.first as? GameMessageMO {
				messageObject = object
			}
			else if let fetchedObject = DataManager.fetchRemoteObject(recordType:GameMessageMO.recordType(), for: game)  {
				messageObject = fetchedObject as? GameMessageMO
			}
			else if let createdObject = DataManager.createManagedObject(forRecordType: GameMessageMO.recordType()) as? GameMessageMO {
				createdObject.game = game
				messageObject = createdObject
			}
		}
		return messageObject
	}
	
	open class func fetchRemoteObject(recordType: String, for game: GameMO) -> NSManagedObject? {
		
		let group = DispatchGroup()
		group.enter()
		var remoteObject: NSManagedObject? = nil
		var predicate =  NSPredicate(format: "TRUEPREDICATE")
		DataManager.Container.fetchUserRecordID { (recordID, error) in
			if let recordID = recordID {
				let reference = CKReference(recordID: recordID, action: CKReferenceAction.none)
				Log.message("User Record ID \(String(describing: recordID.recordName))")
				predicate = NSPredicate(format: "sender = %@ AND game == %@", reference, game.recordName)
			}
			group.leave()
		}
		_ = group.wait(timeout: .distantFuture)
		
		group.enter()
		
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: recordType, predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys =  nil
		queryOperation.qualityOfService = .userInteractive
		let operation = FetchRemoteObjectsOperation(with: queryOperation, DataManager.Container.publicCloudDatabase)
		operation.fetchRemoteObjectsCompletionBlock = {(objects) in
			if let objects = objects, let object = objects.first {
				remoteObject = object
			}
			group.leave()
		}
		operation.start()
		_ = group.wait(timeout: .distantFuture)
		return remoteObject
	}
	
	
	open class func fetchShareObjectsFromGame(_ game: GameMO, shouldFetchRootRecord: Bool? = false, desiredKeys: [String]? = nil) -> (GameShareMO?, ShareMO?)? {
		var gameShareObject: GameShareMO? = nil
		var shareObject : ShareMO? = nil
		
		let operationQueue = OperationQueue()
		
		if let path = game.path, let url = URL(string: path) {
			
			let operation = CKFetchShareMetadataOperation.init(shareURLs: [url])
			let configuration = CKOperation.Configuration()
			configuration.container = DataManager.Container
			operation.configuration = configuration
			operation.shouldFetchRootRecord = shouldFetchRootRecord!
			operation.rootRecordDesiredKeys = desiredKeys
			operation.perShareMetadataBlock = { (url, shareMetaData, error) in
				if let rootRecord = shareMetaData?.rootRecord {
					let objects = DataManager.fetchLocalEntities(withType: rootRecord.recordType,
																 in: DataManager.backgroundContext,
																 predicate: NSPredicate(format: "recordName = %@", rootRecord.recordID.recordName))
					if let fetchedObject:GameShareMO = objects?.first as? GameShareMO {
						fetchedObject.data = DataManager.dataFromRecord(rootRecord)
						Log.message("Local Root Object: \(fetchedObject)")
						gameShareObject = fetchedObject
					}
					else {
						if let createdObject: GameShareMO = DataManager.createManagedObject(forRecord: rootRecord) as? GameShareMO {
							createdObject.game = game
							createdObject.adventureRecordName = game.adventure
							createdObject.name = game.name
							Log.message("Create GameShare Object: \(createdObject)")
							gameShareObject = createdObject
						}
					}
				}
				if let share = shareMetaData?.share {
					let objects = DataManager.fetchLocalEntities(withType: share.recordType,
																 in: DataManager.backgroundContext,
																 predicate: NSPredicate(format: "recordName = %@",
																						share.recordID.recordName))
					if let fetchedObject:NSManagedObject = objects?.first {
						fetchedObject.data = DataManager.dataFromRecord(share)
						Log.message("Local Share Object: \(fetchedObject)")
					}
					else {
						if let createdShareObject: ShareMO = DataManager.createManagedObject(forRecord: share) as? ShareMO {
							shareObject = createdShareObject
							if let gameShareObject = gameShareObject {
								createdShareObject.gameShare = gameShareObject
								createdShareObject.name = gameShareObject.name
							}
							Log.message("Create Share Object: \(createdShareObject)")
						}
					}
				}
			}
			
			operation.fetchShareMetadataCompletionBlock = { (error) in
				Log.error(with: #line, functionName: #function, error: error)
			}
			operationQueue.addOperation(operation)
			operationQueue.waitUntilAllOperationsAreFinished()
		}
		return (gameShareObject, shareObject)
	}
	
	open class func dataFromRecord(_ record:CKRecord) -> Data {
		let archivedData = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: archivedData)
		archiver.requiresSecureCoding = true
		record.encodeSystemFields(with: archiver)
		archiver.finishEncoding()
		return archivedData as Data
	}
}

extension DataManager {
	
	open class func directoryURL(forWebArchive webArchive: WebArchiveMO) -> URL? {
		if let archive: Data = webArchive.asset,
			let fileName = webArchive.fileName {
			// The archive name changes when a new archive is upload. Only unzips it if there is a new file.
			
			// Create a cache directory if need and unzip to there
			var cachDirectoryPath: String? = nil
			let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
			if !paths.isEmpty {
				cachDirectoryPath = paths.first! + "/Adventures"
			}
			
			if let cachDirectoryPath = cachDirectoryPath {
				var url: URL
				let filePath = cachDirectoryPath + "/" + fileName
				let pathURL = URL(fileURLWithPath: filePath)
				
				var isDirectory: ObjCBool = false
				if !FileManager.default.fileExists(atPath: cachDirectoryPath, isDirectory: &isDirectory) && isDirectory.boolValue == false {
					do {
						try FileManager.default.createDirectory(atPath: cachDirectoryPath, withIntermediateDirectories: false, attributes: nil)
					}
					catch let error {
						Log.error(with: #line, functionName: #function, error: error)
					}
				}
				if !FileManager.default.fileExists(atPath: filePath) {
					Log.message("File Name: \(fileName)")
					
					// Save the data to the tmp directory
					url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName + ".zip")
					do {
						try archive.write(to: url, options: .atomicWrite)
					}
					catch let error {
						Log.error(with: #line, functionName: #function, error: error)
					}
					let group = DispatchGroup()
					group.enter()
					do {
						try Zip.unzipFile(url, destination: pathURL, overwrite: true, password: nil, progress:  { (progress) in
							//Log.message("Progress: \(progress)", enabled: false)
							if progress >= 1.0 {
								group.leave()
							}
						})
					} catch  let error {
						Log.error(with: #line, functionName: #function, error: error)
					}
					group.wait()
					do {
						try FileManager.default.removeItem(at: url)
					}
					catch let error {
						Log.error(with: #line, functionName: #function, error: error)
					}
				}
				return pathURL
			}
			else {
				Log.message("ERROR URL == nil")
				return nil
			}
			
		}
		else {
			Log.message("ERROR URL == nil")
			return nil
		}
	}
}



