//
//  FetchObjectsOperation.swift
//  BeaconCrawl
//
//  Created by WCA on 10/15/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MapKit

// MARK: - FetchObjectsOperation
open class FetchObjectsOperation: AsynchronousOperation, ProgressReporting {
	
	private var localThenRemote: Bool!
	public var fetchLocalObjectsCompletionBlock: ((_ localObjects: [NSManagedObject]?) -> Swift.Void)?
	public var fetchRemoteObjectsCompletionBlock:((_ remoteObjects:[NSManagedObject]?) -> Swift.Void)?
	private var fetchRequest: NSFetchRequest<NSManagedObject>!
	private var queryOperation: CKQueryOperation!
	private weak var database: CKDatabase!
	public var progress: Progress = Progress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	private var localObjects: [NSManagedObject]?
	private var _remoteObjects: [NSManagedObject]?
	
	/// A lock to guard reads and writes to the `_remoteObjects` property
	private let stateLock = NSLock()

	private var remoteObjects: [NSManagedObject]? {
		get {
			return stateLock.withCriticalScope {
				_remoteObjects
			}
		}
		
		set(newState) {
			stateLock.withCriticalScope { () -> Void in
				_remoteObjects = newState
			}
			
		}
	}

	private var desiredKeys: [String]!
	
	static var serialQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	
	public convenience init(with fetchRequest: NSFetchRequest<NSManagedObject>, queryOperation:CKQueryOperation, _ database: CKDatabase = DataManager.Container.publicCloudDatabase, localThenRemote: Bool = true) {
		self.init()
		self.fetchRequest = fetchRequest
		self.queryOperation = queryOperation
		self.database = database
		self.localThenRemote = localThenRemote
		self.desiredKeys = queryOperation.desiredKeys
	}
	
	override open func main() {
		
		if FetchObjectsOperation.serialQueue.operationCount > 0 {
			Log.message("FetchCurrentUserOperation count > 0")
		}
		
		FetchObjectsOperation.serialQueue.addOperation {
			
			// Add a completion block to start progress reporting
			self.progressStartedOperation?.start()
			
			// This block fetches the local records
			let fetchLocalObjectsOperation = FetchLocalObjectsOperation(with: self.fetchRequest)
			fetchLocalObjectsOperation.qualityOfService = .userInitiated
			
			// This block fetches all the Records as Faults
			// Using a query, fetch remote records matching the predicate, return just the records with no keys
			let fetchRemoteRecordsQueryOperation = FetchRemoteRecordsQueryOperation(with: (self.queryOperation)!, self.database)
			
			// This operation compares the Local Records with the Remote Records
			let compareRecordsOperation = CompareRecordsOperation()
			
			// This operation adds the found records to Core Data
			let updateRecordsObjectsOperation = UpdateRecordsToObjectsOperation()
			
			fetchLocalObjectsOperation.fetchLocalObjectsCompletionBlock = { [unowned self] (objects) in
				self.localObjects = objects
				self.fetchLocalObjectsCompletionBlock?(self.localObjects)
				guard let localObjects = objects, localObjects.isEmpty || self.localThenRemote else {
					self.state(.finished)
					return
				}
				self.progress.addChild(fetchRemoteRecordsQueryOperation.progress, withPendingUnitCount: 8)
				fetchRemoteRecordsQueryOperation.start()
				Log.message("fetchRemoteQuery", enabled: false, alert: false)
			}
			
			fetchLocalObjectsOperation.start()
			
			
			fetchRemoteRecordsQueryOperation.fetchRemoteRecordsQueryCompletionBlock = {(remoteRecords) in
//				guard let remoteRecords = records else {
//					self.state(.finished)
//					return
//				}
				var localRecords = [CKRecord]()
				if let localObjects = self.localObjects {
					for object in localObjects {
						if let data = object.data,
							let record = DataManager.recordFromData(data) {
							localRecords.append(record)
						}
					}
				}
				compareRecordsOperation.setup(with: localRecords, remoteRecords: remoteRecords)
				compareRecordsOperation.start()
				Log.message("compareRecordsOperation", enabled: false, alert: false)
			}
			
			compareRecordsOperation.compareRecordsCompletionBlock = { (recordsToObjects) in
				guard let records = recordsToObjects, !records.isEmpty else {
					self.state(.finished)
					return
				}
				updateRecordsObjectsOperation.setup(with: records, database: self.database)
				updateRecordsObjectsOperation.start()
				Log.message("updateRecordsOperation", enabled: false, alert: false)
			}
			
			updateRecordsObjectsOperation.updateRecordsToObjectsCompletionBlock = { (objects) in
				guard let objects = objects else {
					self.state(.finished)
					return
				}
				self.remoteObjects = objects
				self.state(.finished)
			}
		}
	}
	
	override open func state(_ newState: State) {
		if newState == .finished {
			fetchRemoteObjectsCompletionBlock?(remoteObjects)
			progress.completedUnitCount = progress.totalUnitCount
		}
		super.state(newState)
	}
}

open class FetchRemoteObjectsOperation: AsynchronousOperation {
	private var queryOperation: CKQueryOperation!
	private var database: CKDatabase!
	public var fetchRemoteObjectsCompletionBlock:((_ objects: [NSManagedObject]?) -> Swift.Void)?
	
	public convenience init(with queryOperation:CKQueryOperation, _ database: CKDatabase = DataManager.Container.publicCloudDatabase) {
		self.init()
		self.queryOperation = queryOperation
		self.database = database
	}
	
	override open func main() {
		// This block fetches all the Records using the desiredKeys to filter results
		let fetchRemoteObjectsQueryOperation = FetchRemoteRecordsQueryOperation(with: queryOperation, database)
		// This operation adds the found records to Core Data
		let updateRecordsOperation = UpdateRecordsToObjectsOperation()
		
		fetchRemoteObjectsQueryOperation.fetchRemoteRecordsQueryCompletionBlock = { [unowned self] (records) in
			if let records = records {
				updateRecordsOperation.setup(with: records, database: self.database)
				updateRecordsOperation.start()
			}
			else {
				self.state(.finished)
				self.fetchRemoteObjectsCompletionBlock?(nil)
			}
		}
		
		updateRecordsOperation.updateRecordsToObjectsCompletionBlock = { (objects) in
			self.state(.finished)
			self.fetchRemoteObjectsCompletionBlock?(objects)
		}
		fetchRemoteObjectsQueryOperation.start()
	}
}

open class FetchUsersOperation: AsynchronousOperation, ProgressReporting {
	
	private var localThenRemote: Bool!
	private var recordIDs: [CKRecordID]!
	private var currentUsers = [UserMO]()
	private var desiredKeys: [String]?
	
	public var fetchUsersCompletionBlock:(([UserMO]?) -> Swift.Void)?
	public var progress: Progress = Progress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	
	static var serialQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		return queue
	}()
	
	public convenience init(with recordIDs: [CKRecordID], localThenRemote: Bool = false, desiredKeys: [String]? = nil, progress: Progress? = nil ) {
		self.init()
		self.recordIDs = recordIDs
		self.localThenRemote = localThenRemote
		self.desiredKeys = desiredKeys
	}
	
	func setup (with recordIDs: [CKRecordID], localThenRemote: Bool = false, desiredKeys: [String]? = nil, progress: Progress? = nil  ) {
		self.recordIDs = recordIDs
		self.localThenRemote = localThenRemote
		self.desiredKeys = desiredKeys
	}
	
	override open func main() {
		
		guard let recordIDs = recordIDs else {
			self.state(.finished)
			return
		}
		
		if FetchUsersOperation.serialQueue.operationCount > 0 {
			Log.message("FetchCurrentUserOperation count > 0")
		}
		
		FetchUsersOperation.serialQueue.addOperation {
			
			self.progressStartedOperation?.start()
			
			let request:NSFetchRequest<UserMO> = UserMO.fetchRequest()
			let sort = NSSortDescriptor(key: "name", ascending: true)
			request.sortDescriptors = [sort]
			request.returnsObjectsAsFaults = false
			request.predicate = NSPredicate(format: "recordName IN %@", recordIDs.map{$0.recordName})
			
			/* This operation fetches the local users
			*/
			let fetchLocalUsersRecordOperation = FetchLocalUsersObjectOperation(with: request as! NSFetchRequest<NSManagedObject>)
			
			/** This operation fetches the user from CloudKIt
			*/
			let fetchRecordsDictionaryOperation = FetchRecordsDictionaryOperation(with: recordIDs, database: DataManager.Container.publicCloudDatabase, desiredKeys: self.desiredKeys, progress: self.progress)
			
			// This operation compares the Local Records with the Remote Records
			let compareRecordsOperation = CompareRecordsOperation()
			
			// This operation adds the found records to Core Data
			let updateRecordsOperation = UpdateRecordsToObjectsOperation()

			
			let group = DispatchGroup()
			group.enter()
			
			fetchLocalUsersRecordOperation.fetchLocalUsersObjectCompletionBlock = { (users) in
				if let localUsers = users, !localUsers.isEmpty, self.localThenRemote == false {
					if self.desiredKeys != nil && self.desiredKeys! == [] {
						self.currentUsers = localUsers
						group.leave()
					}
					else {
						fetchRecordsDictionaryOperation.start()
					}
				}
				else {
					// Fetch Remote
					fetchRecordsDictionaryOperation.start()
				}
				
				fetchRecordsDictionaryOperation.fetchRecordsDictionaryCompletionBlock = {(recordsDictionary) in
					guard let recordsDictionary = recordsDictionary, !recordsDictionary.isEmpty else {
						group.leave()
						return
					}
					let remoteRecords = Array(recordsDictionary.values)
					
					var localRecords = [CKRecord]()
					for object in self.currentUsers {
						if let data = object.data,
							let record = DataManager.recordFromData(data) {
							localRecords.append(record)
						}
					}
					compareRecordsOperation.setup(with: localRecords, remoteRecords: remoteRecords)
					compareRecordsOperation.start()
					Log.message("compareRecordsOperation", enabled: false, alert: false)
				}
				
				
				compareRecordsOperation.compareRecordsCompletionBlock = { (recordsToFetch) in
					guard let records = recordsToFetch, !records.isEmpty else {
						group.leave()
						return
					}
					updateRecordsOperation.setup(with: records, database: DataManager.Container.publicCloudDatabase, desiredKeys: self.desiredKeys)
					updateRecordsOperation.start()
					Log.message("updateRecordsOperation", enabled: false, alert: false)
				}
				
				updateRecordsOperation.updateRecordsToObjectsCompletionBlock = { (objects) in
					guard let objects: [UserMO] = objects as? [UserMO] else {
						group.leave()
						return
					}
					self.currentUsers = objects
					group.leave()
				}
			}
			// Add operation to queue
			fetchLocalUsersRecordOperation.start()
			
			group.wait()
			self.state(.finished)
		}
	}
	
	override open func state(_ newState: State) {
		if newState == .finished {
			self.progress.completedUnitCount = self.progress.totalUnitCount
			fetchUsersCompletionBlock?(self.currentUsers)
			Log.message("FetchCurrentUsersOperation Finished Count: \(FetchUsersOperation.serialQueue.operationCount)")
		}
		super.state(newState)
	}
}

extension CKFetchRecordsOperation {
	
	func setup(with recordIDs: [CKRecordID]?) {
		self.recordIDs = recordIDs
	}
}

class FetchLocalUsersObjectOperation: AsynchronousOperation {
	
	private var fetchRequest:NSFetchRequest<NSManagedObject>!
	var fetchLocalUsersObjectCompletionBlock: (([UserMO]?) -> Swift.Void)?
	
	convenience init(with fetchRequest: NSFetchRequest<NSManagedObject>) {
		self.init()
		self.fetchRequest = fetchRequest
	}
	
	func setup(with fetchRequest: NSFetchRequest<NSManagedObject>) {
		self.fetchRequest = fetchRequest
	}
	
	override public func main() {
		let objects = DataManager.fetchLocalEntities(withFetchRequest: fetchRequest)
		self.fetchLocalUsersObjectCompletionBlock?(objects as? [UserMO])
		self.state(.finished)
	}
}


public class RequestAdminstratorStatus: AsynchronousOperation {
	
	public var requestAdministratorStatusCompletionBlock: ((Bool) -> Swift.Void)?
	
	override public func main () {
		
		let predicate = NSPredicate(format: "TRUEPREDICATE")
		let query: CKQuery = CKQuery(recordType: "RoleAdministrator", predicate: predicate)
		let queryOperation: CKQueryOperation = CKQueryOperation(query: query)
		queryOperation.resultsLimit = 1
		queryOperation.qualityOfService = QualityOfService.userInteractive
		
		let operation = FetchRemoteRecordsQueryOperation(with: queryOperation, DataManager.Container.publicCloudDatabase)
		
		operation.fetchRemoteRecordsQueryCompletionBlock = { (records) in
			self.requestAdministratorStatusCompletionBlock? (records != nil && !records!.isEmpty)
			self.state(.finished)
		}
		operation.start()
	}
}

public class RequestStatusForApplicationPermissionOperation: AsynchronousOperation{
	
	private var user: UserMO!
	private var applicationPermissionStatus: CKApplicationPermissionStatus!
	public var requestStatusForApplicationPermissionCompletionBlock: ((UserMO, CKApplicationPermissionStatus) -> Swift.Void)?
	public convenience init(with user: UserMO) {
		self.init()
		self.user = user
	}
	
	override public func main() {
		
		DataManager.Container.status(forApplicationPermission: CKApplicationPermissions.userDiscoverability) { (applicationPermissionStatus, error) in
			self.requestStatusForApplicationPermissionCompletionBlock? (self.user, applicationPermissionStatus)
			self.state(.finished)
		}
	}
}

public class RequestApplicationPermissionsOperation: AsynchronousOperation  {
	
	private var user: UserMO!
	public var requestApplicationPermissionsCompletionBlock: ((UserMO, CKApplicationPermissionStatus) -> Swift.Void)?
	
	public convenience init(with user: UserMO) {
		self.init()
		self.user = user
	}
	
	override public func main() {
		DataManager.Container.requestApplicationPermission(CKApplicationPermissions.userDiscoverability) { requestStatus, requestError in
			switch requestStatus {
			case .initialState:
				let error = requestError ?? NSError(domain: CKErrorDomain, code: CKError.Code.permissionFailure.rawValue, userInfo: nil)
				Log.error(with: #line, functionName: #function, error: error)
				if let requestApplicationPermissionsCompletionBlock = self.requestApplicationPermissionsCompletionBlock {
					requestApplicationPermissionsCompletionBlock (self.user, requestStatus)
				}
				self.state(.finished)
			case .granted:
				// Once we've created our local user, populate it with the user's identity
				DataManager.Container.discoverUserIdentity(withUserRecordID: self.user.recordID, completionHandler: { (userIdentity, error) in
					if userIdentity != nil {
						if let familyName = userIdentity!.nameComponents?.familyName {
							self.user.familyName = familyName
						}
						if let givenName = userIdentity!.nameComponents?.givenName {
							self.user.givenName = givenName
						}
						if
							let givenName = userIdentity!.nameComponents?.givenName,
							let familyName = userIdentity!.nameComponents?.familyName {
							self.user.name = givenName + " " + familyName
						}
						DataManager.save([self.user])
					}
					if let requestApplicationPermissionsCompletionBlock = self.requestApplicationPermissionsCompletionBlock {
						requestApplicationPermissionsCompletionBlock (self.user, requestStatus)
					}
					self.state(.finished)
				})
			case .denied, .couldNotComplete:
				let error = requestError ?? NSError(domain: CKErrorDomain, code: CKError.Code.permissionFailure.rawValue, userInfo: nil)
				Log.error(with: #line, functionName: #function, error: error)
				if let requestApplicationPermissionsCompletionBlock = self.requestApplicationPermissionsCompletionBlock {
					requestApplicationPermissionsCompletionBlock (self.user, requestStatus)
				}
				self.state(.finished)
			}
		}
	}
}

class FetchLocalObjectsOperation: AsynchronousOperation {
	
	private var localObjects = [NSManagedObject]()
	private var predicate: NSPredicate!
	private var fetchRequest:NSFetchRequest<NSManagedObject>!
	var fetchLocalObjectsCompletionBlock: (([NSManagedObject]?) -> Swift.Void)?
	
	convenience init(with fetchRequest: NSFetchRequest<NSManagedObject>) {
		self.init()
		self.fetchRequest = fetchRequest
	}
	
	func setup(with fetchRequest: NSFetchRequest<NSManagedObject>) {
		self.fetchRequest = fetchRequest
	}
	
	override public func main() {
		let objects = DataManager.fetchLocalEntities(withFetchRequest: self.fetchRequest)
		if let objects = objects {
			
			// Load local data
			for object in objects {
				// Filter out Records that have not been saved to the local store
				var changedValues = object.changedValues()
				changedValues.removeValue(forKey: "currentDistance")
				
				if let data = object.data, let record = DataManager.recordFromData(data) {
					if !changedValues.isEmpty {
						object.addAttributes(to:record, for: Array(changedValues.keys))
					}
				}
			}
			self.localObjects = objects
		}
		self.fetchLocalObjectsCompletionBlock?(self.localObjects)
		self.state(.finished)
	}
}

class CompareRecordsOperation: AsynchronousOperation {
	
	private var localRecords: [CKRecord]?
	private var remoteRecords: [CKRecord]?
	private var records = [CKRecord]()
	
	var compareRecordsCompletionBlock: ((_ records: [CKRecord]?) -> Swift.Void)?
	
	convenience init(with localRecords: [CKRecord]?, remoteRecords: [CKRecord]?) {
		self.init()
		self.localRecords = localRecords
		self.remoteRecords = remoteRecords
	}
	
	func setup(with localRecords: [CKRecord]?, remoteRecords: [CKRecord]?) {
		self.localRecords = localRecords
		self.remoteRecords = remoteRecords
	}
	
	override public func main() {
		guard var remoteRecords = remoteRecords else {
			compareRecordsCompletionBlock?(nil)
			state(.finished)
			return
		}
		guard let localRecords = localRecords, !localRecords.isEmpty else {
			compareRecordsCompletionBlock?(remoteRecords)
			state(.finished)
			return
		}
		records.append(contentsOf: remoteRecords)
		
		let localRecordIDs = localRecords.map{$0.recordID}
		
		/* If there are local records that do not match a remote record remove it */
		
		for remoteRecord in remoteRecords {
			for localRecord in localRecords {
				if remoteRecord == localRecord {
					if let index = remoteRecords.index(of: remoteRecord) {
						remoteRecords.remove(at: index)
					}
				}
			}
		}
		
		/* Remote records different than our local Records. If remote and local have the same change tag then the remoteRecord count will be 0 */
		
		/* If we don't find any new remote records just present the last known records */
		
		/* If there are no remote records and the internet is unavailable */
		if records.isEmpty && DataManager.shared.internetReachability.currentReachabilityStatus != .notReachable {
			let removeRecordIDs = localRecordIDs
			guard let recordType = localRecords.first?.recordType else {
				Log.message("Guard Failed CompareRecordsOperation: \((#file as NSString).lastPathComponent): \(#function)\n")
				compareRecordsCompletionBlock?(remoteRecords)
				state(.finished)
				return
			}
			
			let operationQueue = OperationQueue()
			
			if !removeRecordIDs.isEmpty {
				
				for recordID in removeRecordIDs {
					
					let fetchRequest:NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName:recordType)
					fetchRequest.predicate = NSPredicate(format: "recordName = %@", recordID.recordName)
					
					let operation = FetchLocalObjectsOperation.init(with: fetchRequest)
					operation.fetchLocalObjectsCompletionBlock = { (objects) in
						if let fetchedObject = objects?.first {
							DataManager.backgroundContext.delete(fetchedObject)
							self.compareRecordsCompletionBlock?(remoteRecords)
							self.state(.finished)
						}
					}
					operationQueue.addOperation(operation)
				}
				
				operationQueue.waitUntilAllOperationsAreFinished()
				
			}
			else {
				compareRecordsCompletionBlock?(remoteRecords)
				state(.finished)
			}
		}
		else {
			let removeRecordIDs = localRecordIDs.filter { !records.map{$0.recordID}.contains($0) }
			guard let recordType = localRecords.first?.recordType else {
				Log.message("Guard Failed CompareRecordsOperation: \((#file as NSString).lastPathComponent): \(#function)\n")
				compareRecordsCompletionBlock?(remoteRecords)
				state(.finished)
				return
			}
			if !removeRecordIDs.isEmpty {
				
				let operationQueue = OperationQueue()
				operationQueue.maxConcurrentOperationCount = 1
				
				for recordID in removeRecordIDs {
					
					let fetchRequest:NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName:recordType)
					fetchRequest.predicate = NSPredicate(format: "recordName = %@", recordID.recordName)
					
					let operation = FetchLocalObjectsOperation(with: fetchRequest)
					operation.fetchLocalObjectsCompletionBlock = {(objects) in
						if let fetchedObject = objects?.first {
							DataManager.backgroundContext.delete(fetchedObject)
						}
					}
					operationQueue.addOperation(operation)
				}
				operationQueue.waitUntilAllOperationsAreFinished()
				self.compareRecordsCompletionBlock?(remoteRecords)
				self.state(.finished)

			}
			else {
				compareRecordsCompletionBlock?(remoteRecords)
				state(.finished)
			}
		}
	}
}

// MARK: - FetchRecordsDictionaryOperation
open class FetchRecordsDictionaryOperation: AsynchronousOperation, ProgressReporting {
	
	private var recordIDs = [CKRecordID]()
	open var progress = Progress.discreteProgress(totalUnitCount: 100)
	open var fetchRecordsDictionaryCompletionBlock: (([CKRecordID : CKRecord]?) -> Swift.Void)?
	public var fetchRecordsDictionaryPerRecordCompletionBlock: ((CKRecord?, CKRecordID?) -> Swift.Void)?
	private var desiredKeys: [String]!
	private var database:CKDatabase!
	
	/* Called on success or failure for each record. */
	open var perRecordCompletionBlock: ((CKRecord?, CKRecordID?, Error?) -> Swift.Void)?
	
	convenience public init(with recordIDs: [CKRecordID], database: CKDatabase, desiredKeys: [String]? = nil, progress: Progress? = nil) {
		self.init()
		self.recordIDs = recordIDs
		self.database = database
		self.desiredKeys = desiredKeys
	}
	
	public func setup (with recordIDs: [CKRecordID], database: CKDatabase, desiredKeys: [String]? = nil, progress: Progress? = nil) {
		self.recordIDs = recordIDs
		self.database = database
		self.desiredKeys = desiredKeys
	}
	
	override open func main() {
		guard !recordIDs.isEmpty else {
			if let fetchRecordsDictionaryCompletionBlock = fetchRecordsDictionaryCompletionBlock {
				fetchRecordsDictionaryCompletionBlock(nil)
			}
			self.state(.finished)
			self.progress.localizedDescription = "Testing"
			self.progress.completedUnitCount = 100
			return
		}
		// This block processes and fetches all Records
		let operation = CKFetchRecordsOperation(recordIDs:recordIDs)
		operation.database = database
		operation.desiredKeys = desiredKeys
		
		operation.perRecordCompletionBlock = self.perRecordCompletionBlock
		
		var fetchedDictionary = [CKRecordID : Double]()
		operation.perRecordProgressBlock = { (recordID: CKRecordID, proportion: Double)  in
			fetchedDictionary[recordID] = proportion
			let sum: Double = fetchedDictionary.values.reduce(0, +)
			DispatchQueue.main.async {
				self.progress.completedUnitCount = Int64(((sum/Double(self.recordIDs.count))*100))
				Log.message("Per Record Progress: \(String(describing: self.progress.localizedDescription))", enabled: false)
			}
		}
		operation.perRecordCompletionBlock = {(record: CKRecord?, recordID: CKRecordID?, error: Error?) in
			guard let record = record, let recordID = recordID else {
				Log.message("Guard Failed FetchRecordsDictionaryOperation: \((#file as NSString).lastPathComponent): \(#function)\n")
				return
			}
			self.fetchRecordsDictionaryPerRecordCompletionBlock?(record, recordID)
		}
		operation.fetchRecordsCompletionBlock = { (recordsDictionary: [CKRecordID : CKRecord]?, error: Error?)  -> Void in
			guard error == nil else {
				if let recordsDictionary = recordsDictionary {
					for (_, record) in recordsDictionary {
						Log.message("Failed Query: \(String(describing: record.recordType))")
					}
				}
				if let error:NSError = error as NSError? {
					if let errors = error.userInfo[CKPartialErrorsByItemIDKey] {
						for (_, ckerror) in (errors as? [CKRecordID: NSError])! {
							
							operation.checkFetchError(ckerror, completionHandler: { (errorRecordsDictionary, error) in
								self.fetchRecordsDictionaryCompletionBlock?(recordsDictionary)
								self.state(.finished)
								self.progress.totalUnitCount = -1
								Log.message(self.progress.localizedDescription, enabled: true)
							})
						}
					}
					else {
						operation.checkFetchError(error, completionHandler: { (recordsDictionary, error) in
							self.fetchRecordsDictionaryCompletionBlock?(recordsDictionary)
							self.state(.finished)
							self.progress.totalUnitCount = -1
						})
					}
				}
				return
			}
			// No errors
			self.fetchRecordsDictionaryCompletionBlock?(recordsDictionary)
			self.state(.finished)
			self.progress.completedUnitCount = self.progress.totalUnitCount
			Log.message("FetchRecordsDictionaryOperation Completed", enabled: false, alert: false)
			Log.message(self.progress.localizedDescription, enabled: false, alert: false)
		}
		database.add(operation)
	}
}

// MARK: - UpdateRecordsToObjectsOperation
class UpdateRecordsToObjectsOperation: AsynchronousOperation {
	
	private var records: [CKRecord]!
	private var keys: [String]?
	private var database: CKDatabase!
	var updateRecordsToObjectsCompletionBlock: (([NSManagedObject]?) -> Swift.Void)?
	
	convenience init(with records: [CKRecord], database: CKDatabase, desiredKeys keys: [String]? = nil) {
		self.init()
		self.records = records
		self.database = database
		self.keys = keys
	}
	
	func setup(with records: [CKRecord], database: CKDatabase, desiredKeys keys: [String]? = nil)  {
		self.records = records
		self.database = database
		self.keys = keys
	}
	
	public override func main() {
		guard records != nil else {
			state(.finished)
			return
		}
		
		var objects = [NSManagedObject]()
		
		let operationQueue = OperationQueue()
		
		for rootRecord in self.records {
			Log.message("Record: \(rootRecord)", enabled: false)
			
			// We are fetching this for the first time. Update the locally created record.
			let fetchRequest:NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName:rootRecord.recordType)
			fetchRequest.predicate = NSPredicate(format: "recordName = %@", rootRecord.recordID.recordName)
			fetchRequest.returnsObjectsAsFaults = false
			
			let group = DispatchGroup()
			group.enter()
			
			let localObjectsOperation = FetchLocalObjectsOperation(with: fetchRequest)
			localObjectsOperation.fetchLocalObjectsCompletionBlock = { (fetchedObjects) in
				DataManager.backgroundContext.performAndWait {
					if let fetchedObject = fetchedObjects?.first {
						fetchedObject.addAttributes(from:rootRecord, for: self.keys)
						objects.append(fetchedObject)
					}
					else {
						if let createdObject = DataManager.createManagedObject(forRecord: rootRecord) {
							objects.append(createdObject)
						}
					}
					group.leave()
				}
			}
			operationQueue.addOperation(localObjectsOperation)
			
	
			group.wait()
			
		}
		operationQueue.waitUntilAllOperationsAreFinished()
		

		if DataManager.backgroundContext.hasChanges {
			DataManager.backgroundContext.performAndWait {
				do {
					Log.message("Update Records To Objects Operation \(objects)", enabled: false)
					try DataManager.backgroundContext.save()
				} catch {
					Log.message("Updated : \(DataManager.backgroundContext.updatedObjects)")
					Log.message("Deleted : \(DataManager.backgroundContext.deletedObjects)")
					Log.message("Created : \(DataManager.backgroundContext.insertedObjects)")
					Log.message((error as NSError).debugDescription)
					Log.message((error as NSError).localizedDescription)
				}
			}
		}
		self.updateRecordsToObjectsCompletionBlock?(objects)
		self.state(.finished)
	}
}

/// Fetch for multiple records by type
// We submit our CKQuery to a CKQueryOperation. The CKQueryOperation has the concept of cursor and a resultsLimit. This will allow you to bundle your query results into chunks, avoiding very long query times. In our case we limit to 100 at a time, and keep refetching more if available.

open class FetchRemoteRecordsQueryOperation: AsynchronousOperation {
	/// This supports implicit progress composition.
	var type: String!
	private var queryOperation: CKQueryOperation?
	private var database: CKDatabase?
	open var fetchRemoteRecordsQueryCompletionBlock: (([CKRecord]?) -> Swift.Void)?
	
	open var progress: Progress = Progress.discreteProgress(totalUnitCount: 100)
	
	convenience public init(with queryOperation: CKQueryOperation, _ database: CKDatabase = DataManager.Container.publicCloudDatabase) {
		self.init()
		self.queryOperation = queryOperation
		self.database = database
	}
	
	func setup(with queryOperation: CKQueryOperation, _ database: CKDatabase = DataManager.Container.publicCloudDatabase) {
		self.queryOperation = queryOperation
		self.database = database
	}
	
	override open func main() {
		guard let queryOperation = self.queryOperation, let database = self.database else {
			if let fetchRemoteRecordsQueryCompletionBlock = self.fetchRemoteRecordsQueryCompletionBlock {
				fetchRemoteRecordsQueryCompletionBlock(nil)
			}
			self.state(.finished)
			return
		}
		self.progress.completedUnitCount = 0
		var records = [CKRecord]()
		// defined our fetched record block so we can add records to our results array
		let recordFetchedBlock = { (record: CKRecord) in
			records.append(record)
		}
		queryOperation.recordFetchedBlock = recordFetchedBlock
		
		// Define and add our completion block to fetch possibly more records, or finish by calling our caller's completion block
		var queryCompletionBlock: ((CKQueryCursor?, Error?) -> Void)?
		queryCompletionBlock = { (cursor:CKQueryCursor?, error:Error?) in
			if let ckError = error {
				Log.message("Failed Query: \(String(describing: queryOperation.query?.recordType))")
				queryOperation.checkFetchError(ckError, completionHandler: { (errorRecordsDictionary, error) in
					Log.message("\(String(describing: errorRecordsDictionary))")
					self.fetchRemoteRecordsQueryCompletionBlock?(nil)
				})
			}
			if cursor != nil {
				let continuedQueryOperation: CKQueryOperation = CKQueryOperation.init(cursor: cursor!)
				continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
				continuedQueryOperation.recordFetchedBlock = recordFetchedBlock
				continuedQueryOperation.desiredKeys = queryOperation.desiredKeys
				database.add(continuedQueryOperation)
			}
			else {
				self.fetchRemoteRecordsQueryCompletionBlock?(records)
				self.state(.finished)
				self.progress.completedUnitCount = self.progress.totalUnitCount
				self.progress.localizedDescription = "Fetch Remote Record Query"
			}
		}
		queryOperation.queryCompletionBlock = queryCompletionBlock
		database.add(queryOperation)
	}
}


/// Wrapper for CKModifyRecordsOperation. Adds per record progress tracking and Error Handling
open class ModifyRecordsOperation: AsynchronousOperation, ProgressReporting {
	
	private var updatedRecords:[CKRecord]?
	private var deletedRecordIDs: [CKRecordID]?
	private var database:CKDatabase!
	public let progress = Progress.discreteProgress(totalUnitCount: 100)
	public var progressStartedOperation: BlockOperation?
	
	open var modifyRecordsCompletionBlock: (([CKRecord]?, [CKRecordID]? ) -> Swift.Void)?
	
	
	convenience public init(recordsToSave: [CKRecord]?, recordIDsToDelete: [CKRecordID]?, database: CKDatabase) {
		self.init()
		self.updatedRecords = recordsToSave
		self.deletedRecordIDs = recordIDsToDelete
		self.database = database
	}
	
	override open func main() {
		if let updatedRecords = updatedRecords,
			let first = updatedRecords.first {
			let type: String = first.recordType
			Log.message("Modify Records Start \(type)", enabled: false)
		}
		else if let deletedRecordIDs = deletedRecordIDs,
			let first = deletedRecordIDs.first {
			let name: String = first.recordName
			Log.message("Modify Deleted Records Start \(name)")
		}
		else {
			Log.message("Modify Records Start", enabled: false)
		}
		self.progressStartedOperation?.start()
		let operation: CKModifyRecordsOperation = CKModifyRecordsOperation(recordsToSave:updatedRecords, recordIDsToDelete: deletedRecordIDs)
		// The following Quality of Service (QoS) is used to indicate to the system the nature and importance of this work. Higher QoS classes receive more resources than lower ones during resource contention.
		operation.savePolicy = CKRecordSavePolicy.ifServerRecordUnchanged
		
		var modifiedDictionary = [CKRecordID : Double]()
		operation.perRecordProgressBlock = { (record: CKRecord, progress: Double)  in
			DispatchQueue.main.async {
				modifiedDictionary[record.recordID] = progress
				let sum: Double = modifiedDictionary.values.reduce(0, +)
				guard !modifiedDictionary.isEmpty else {
					Log.message("Modified Type \(record.recordType) Dictionary Count \(modifiedDictionary.count)", enabled: false)
					return
				}
				self.progress.completedUnitCount = Int64((sum/Double(modifiedDictionary.count)) * 100)
				Log.message("Modified Type \(record.recordType) Record Progress \(String(describing: self.progress.localizedDescription))", enabled: false)
			}
		}

		operation.perRecordCompletionBlock = { (record, error)  in
			DispatchQueue.main.async {
				modifiedDictionary.removeValue(forKey: record.recordID)
			}
		}
		
		// Start the long-running task and return immediately.
		//let backgroundTaskIdentifier  = DataManager.shared.startBackgroundOperation(operation, queue: queue)
		
		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			if error == nil {
				// No errors
				if let recordType = savedRecords?.first?.recordType {
					Log.message("Modify Records Success " + recordType, enabled: false)
					if recordType == "GameShare" {
						if let record = savedRecords?.first {
							if let state = record["state"] {
								Log.message("Game Share State \(record.debugDescription) ---- \(state)")
							}
							else {
								Log.message("Game Share Not Set \(record.debugDescription)")
							}
						}
					}
				}
				self.updatedRecords = savedRecords
				self.deletedRecordIDs = deletedRecordIDs
				self.state(.finished)
				self.progress.completedUnitCount = 100
				self.modifyRecordsCompletionBlock?(savedRecords, deletedRecordIDs)
				return
			}
			if let error = error as NSError? {
				if let errors = error.userInfo[CKPartialErrorsByItemIDKey] {
					for (recordID, ckerror) in (errors as? [CKRecordID: NSError])! {
						if let updatedRecords = self.updatedRecords {
							let failedRecord = updatedRecords.filter {$0.recordID == recordID}.first
							operation.checkModifyError(ckerror, forRecord:failedRecord, completionHandler: { (savedRecords, deletedRecordIDs, error) in
								self.updatedRecords = savedRecords
								self.deletedRecordIDs = deletedRecordIDs
								self.state(.finished)
								self.progress.completedUnitCount = 100
								self.modifyRecordsCompletionBlock?(savedRecords, deletedRecordIDs)
								Log.message("RecordID: \(recordID)")
							})
						}
					}
				}
				else {
					operation.checkModifyError(error, completionHandler: { (savedRecords, deletedRecordIDs, error) in
						self.updatedRecords = savedRecords
						self.deletedRecordIDs = deletedRecordIDs
						self.state(.finished)
						self.progress.completedUnitCount = 100
						self.modifyRecordsCompletionBlock?(savedRecords, deletedRecordIDs)
					})
				}
			}
		}
		database.add(operation)
	}
}

open class FetchPlaceOperation: AsynchronousOperation, ProgressReporting {
	
	open var progress = Progress.discreteProgress(totalUnitCount: 1)
	public var fetchPlaceCompletionBlock: ((PlaceMO?) -> Swift.Void)?
	private var place: PlaceMO?
	private var major: NSNumber!
	
	convenience public init(major: NSNumber) {
		self.init()
		self.major = major
	}
	
	override open func main() {
		guard let fetchRequest = createFetchRequest(for: major) as? NSFetchRequest<NSManagedObject> else { return }
		Log.message("FetchRequest: \(fetchRequest)", enabled: false)
		
		let queryOperation = createQueryOperation(for: major)
		queryOperation.desiredKeys = nil
		let fetchOperation = FetchObjectsOperation(with: fetchRequest, queryOperation: queryOperation, localThenRemote: false) // Fetch only local unless there is no local data
		
		fetchOperation.fetchLocalObjectsCompletionBlock = {(places) in
			guard let places: [PlaceMO] = places as? [PlaceMO], let place = places.first else {
				return
			}
			self.place = place
		}
		
		fetchOperation.fetchRemoteObjectsCompletionBlock = { (places) in
			guard let places: [PlaceMO] = places as? [PlaceMO], let place = places.first else {
				self.state(.finished)
				return
			}
			self.place = place
			self.state(.finished)
		}
		fetchOperation.start()
	}
	
	override open func state(_ newState: State) {
		if newState == .finished {
			if let fetchPlaceCompletionBlock = self.fetchPlaceCompletionBlock {
				fetchPlaceCompletionBlock(self.place)
			}
			self.progress.completedUnitCount = 1
		}
		super.state(newState)
	}
	
	func createFetchRequest(for major: NSNumber) -> NSFetchRequest<PlaceMO> {
		let request:NSFetchRequest<PlaceMO> = PlaceMO.fetchRequest()
		request.fetchLimit = 1
		request.returnsObjectsAsFaults = false
		request.predicate = NSPredicate(format: "major = %@", major)
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		return request
	}
	
	func createQueryOperation(for major: NSNumber) -> CKQueryOperation {
		let predicate = NSPredicate(format: "major = %@", major)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "Place", predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys = nil
		return queryOperation
	}
}

open class FetchPlacesOperation: AsynchronousOperation {
	
	private var majors: [NSNumber]!
	private var places: [PlaceMO]?
	public var fetchPlacesCompletionBlock: (([PlaceMO]?) -> Swift.Void)?
	
	convenience public init(_ majors: [NSNumber]) {
		self.init()
		self.majors = majors
	}
	
	override open func main() {
		guard let fetchRequest = createFetchRequest(for: majors) as? NSFetchRequest<NSManagedObject> else {
			self.state(.finished)
			return }
		let query = createQueryOperation(for: majors)
		let fetchOperation = FetchObjectsOperation(with: fetchRequest, queryOperation: query, localThenRemote: false) // Fetch only local unless there is no local data
		
		fetchOperation.fetchLocalObjectsCompletionBlock = {(localRecords) in
			guard let records = localRecords else {
				self.state(.finished)
				return
			}
			let recordNames: [String] = records.map{$0.recordID.recordName}
			self.places = DataManager.fetchLocalEntities(withType: "Place", predicate: NSPredicate(format: "recordID IN %@", recordNames)) as? [PlaceMO]
			self.state(.finished)
		}
		
		fetchOperation.fetchRemoteObjectsCompletionBlock = { (remoteRecords) in
			guard let records = remoteRecords else {
				self.state(.finished)
				return
			}
			DispatchQueue.main.async {
				let recordIDs: [CKRecordID] = records.map{$0.recordID}
				self.places = DataManager.fetchLocalEntities(withType: "Place", predicate: NSPredicate(format: "recordID IN %@", recordIDs)) as? [PlaceMO]
				self.state(.finished)
				
			}
		}
		fetchOperation.start()
	}
	
	
	func createFetchRequest(for majors: [NSNumber]) -> NSFetchRequest<PlaceMO> {
		let request:NSFetchRequest<PlaceMO> = PlaceMO.fetchRequest()
		request.fetchLimit = 7
		request.returnsObjectsAsFaults = true
		request.predicate = NSPredicate(format: "major IN %@", majors)
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		return request
	}
	
	func createQueryOperation(for majors: [NSNumber]) -> CKQueryOperation {
		let predicate = NSPredicate(format: "major IN %@", majors)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "Place", predicate: predicate))
		queryOperation.resultsLimit = 7
		queryOperation.desiredKeys = nil
		return queryOperation
	}
	
	override open func state(_ newState: State) {
		if newState == .finished {
			if let fetchPlacesCompletionBlock = self.fetchPlacesCompletionBlock {
				fetchPlacesCompletionBlock(self.places)
			}
		}
		super.state(newState)
	}
}

open class FetchBeaconsOperation: AsynchronousOperation, ProgressReporting {
	open var progress = Progress.discreteProgress(totalUnitCount: 1)
	private var dictionaries:  [[NSNumber: NSNumber]]!
	convenience public init(_ dictionaries : [[NSNumber: NSNumber]]) {
		self.init()
		self.dictionaries   = dictionaries
	}
	
	override open func main() {
	}
}


open class FetchBeaconOperation: AsynchronousOperation, ProgressReporting {
	
	open var progress = Progress.discreteProgress(totalUnitCount: 1)
	public var fetchBeaconCompletionBlock: ((BeaconMO?) -> Swift.Void)?
	private var beacon: BeaconMO?
	private var major: NSNumber!
	private var minor: NSNumber!
	convenience public init(major: NSNumber, minor: NSNumber) {
		self.init()
		self.major = major
		self.minor = minor
	}
	
	override open func main() {
		let fetchPlaceOperation = FetchPlaceOperation(major: major)
		fetchPlaceOperation.start()
		fetchPlaceOperation.fetchPlaceCompletionBlock = { (place) in
			if  place != nil {
				let fetchRequest = self.createFetchRequest(for: self.major, self.minor)
				let query = self.createQueryOperation(for: self.major, self.minor)
				let fetchOperation = FetchObjectsOperation(with: fetchRequest as! NSFetchRequest<NSManagedObject>, queryOperation: query, localThenRemote: false) // Fetch only local unless there is no local data
				
				fetchOperation.fetchLocalObjectsCompletionBlock = {(beacons) in
					guard let beacons: [BeaconMO] = beacons as? [BeaconMO], let beacon = beacons.first else {
						return
					}
					self.beacon = beacon//self.beacon(for: record)
				}
				
				fetchOperation.fetchRemoteObjectsCompletionBlock = { (beacons) in
					guard let beacons: [BeaconMO] = beacons as? [BeaconMO], let beacon = beacons.first else {
						self.state(.finished)
						return
					}
					self.beacon = beacon//self.beacon(for: record)
					self.state(.finished)
				}
				fetchOperation.start()
			}
		}
	}
	
	func beacon(for record: CKRecord) -> BeaconMO? {
		let fetchedObject = DataManager.fetchLocalEntities(withType: "Beacon", predicate: NSPredicate(format: "recordName = %@", record.recordID.recordName))?.first
		return fetchedObject as? BeaconMO
	}
	
	override open func state(_ newState: State) {
		if newState == .finished {
			if let fetchBeaconCompletionBlock = self.fetchBeaconCompletionBlock {
				fetchBeaconCompletionBlock(self.beacon)
			}
			self.progress.completedUnitCount = 1
		}
		super.state(newState)
	}
	
	
	func createFetchRequest(for major: NSNumber, _ minor: NSNumber) -> NSFetchRequest<BeaconMO> {
		let request:NSFetchRequest<BeaconMO> = BeaconMO.fetchRequest()
		request.fetchLimit = 1
		request.returnsObjectsAsFaults = false
		request.predicate = NSPredicate(format: "major == %@ && minor = %@", major, minor)
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		return request
	}
	
	func createQueryOperation(for major: NSNumber, _ minor: NSNumber) -> CKQueryOperation {
		let predicate = NSPredicate(format: "major == %@ && minor = %@", major, minor)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "Beacon", predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys = nil
		return queryOperation
	}
}

open class UpdateMapImageOperation: AsynchronousOperation {
	
	private var coordinate: CLLocationCoordinate2D!
	private var size: CGSize!
	public var updateImageCompletionBlock: ((UIImage?) -> Swift.Void)?
	
	convenience public init(_ coordinate: CLLocationCoordinate2D, size: CGSize) {
		self.init()
		self.coordinate = coordinate
		self.size = size
	}
	
	override open func main() {
		guard let coordinate = self.coordinate else {
			self.state(.finished)
			return
		}
		
		let mapSnapshotOptions = MKMapSnapshotOptions()
		let newCamera = MKMapCamera()
		let offsetCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude - 0.0001)
		newCamera.centerCoordinate = offsetCoordinate
		newCamera.pitch = 45
		newCamera.heading = 0.0
		newCamera.altitude = 15
		mapSnapshotOptions.camera = newCamera
		mapSnapshotOptions.showsBuildings = false
		mapSnapshotOptions.showsPointsOfInterest = false
		if #available(iOS 11.0, *) {
			mapSnapshotOptions.mapType = MKMapType.mutedStandard
		} else {
			mapSnapshotOptions.mapType = MKMapType.standard
		}
		
		// Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
		mapSnapshotOptions.scale = UIScreen.main.scale
		
		// Set the size of the image output.
		mapSnapshotOptions.size = self.size
		
		let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
		
		snapShotter.start(with: DispatchQueue(label: "snapshotQueue", qos:DispatchQoS.background )) {(snapshot, error) in
			if let snapshot = snapshot {
				UIGraphicsBeginImageContextWithOptions(mapSnapshotOptions.size, true, 0)
				snapshot.image.draw(at: .zero)
				
				let pinView = MKAnnotationView(annotation: nil, reuseIdentifier: "pin")
				pinView.image = UIImage(named: "PlacesRed")
				let pinImage = pinView.image
				
				var point = snapshot.point(for: coordinate)
				let pinCenterOffset = pinView.centerOffset
				point.x -= pinView.bounds.size.width / 2.0
				point.y -= pinView.bounds.size.height / 2.0
				point.x += pinCenterOffset.x
				point.y += pinCenterOffset.y
				pinImage?.draw(at: point)
				
				let image = UIGraphicsGetImageFromCurrentImageContext()
				
				UIGraphicsEndImageContext()
				
				self.updateImageCompletionBlock?(image)
				self.state(.finished)
			}
		}
	}
}

open class FetchAdventureImageOperation: AsynchronousOperation {
	
	private var adventure: AdventureMO!
	convenience public init(_ adventure: AdventureMO) {
		self.init()
		self.adventure = adventure
	}
	
	override open func main() {
		
		let queryOperation = createQueryOperation()
		queryOperation.desiredKeys = ["imageData"]
		
		// This block fetches all the Records using the desiredKeys to filter results
		let fetchOperation = FetchRemoteRecordsQueryOperation(with: queryOperation)
		
		fetchOperation.fetchRemoteRecordsQueryCompletionBlock = { (records) in
			if let records = records, let record = records.first {
				// We are fetching this for the first time. Update the locally created record.
				DispatchQueue.main.async {
					if let fetchedObjects = DataManager.fetchLocalEntities(withType: record.recordType, predicate: NSPredicate(format: "recordName = %@", record.recordID.recordName)) as? [AdventureMO],
						let fetchedObject = fetchedObjects.first {
						if let
							assetSmall = record["imageData"] as? CKAsset {
							do {
								let imageData = try Data(contentsOf: assetSmall.fileURL)
								fetchedObject.imageData = imageData
							}
							catch {
								Log.message("Error returning Image in AdventureMO")
							}
						}
					}
					else {
						_ = DataManager.createManagedObject(forRecord: record)
					}
				}
			}
			self.state(.finished)
		}
		fetchOperation.start()
	}
	func createQueryOperation() -> CKQueryOperation {
		let predicate = NSPredicate(format: "recordID = %@", adventure.recordID)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "Adventure", predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys = nil
		return queryOperation
	}
}
