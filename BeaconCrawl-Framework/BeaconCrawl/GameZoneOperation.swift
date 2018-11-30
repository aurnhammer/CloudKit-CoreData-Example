//
//  GameZoneOperation.swift
//  BeaconCrawl
//
//  Created by WCA on 5/3/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData


open class GameZoneOperation: AsynchronousOperation {
	
	public var fetchZoneOperationCompletionBlock: ((GameZoneMO?) -> Swift.Void)?

	private var zoneName: String!
	private var database: CKDatabase!
	private var context = DataManager.backgroundContext
	private let container = DataManager.Container
	public convenience init(withName name: String, database: CKDatabase) {
		self.init()
		self.zoneName = name
		self.database = database
	}
	
	override open func main() {
		// Use a consistent zone ID across the user's devices
		// CKCurrentUserDefaultName specifies the current user's ID when creating a zone ID
		let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
		let recordZone = CKRecordZone(zoneID: zoneID)
		
		let fetchRequest: NSFetchRequest<GameZoneMO> = GameZoneMO.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "recordZoneID = %@", zoneID)
		
		if let fetchedObject = try? context.fetch(fetchRequest).first, fetchedObject != nil {
			fetchZoneOperationCompletionBlock?(fetchedObject)
			// Check if the server had deleted
			self.state(.finished)
			
		}
		else {
			let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [] )
			createZoneOperation.modifyRecordZonesCompletionBlock = { (savedRecordZones, _, error) in
				let gameZoneEntity = GameZoneMO.entity()
				if error == nil, let savedRecordZone = savedRecordZones?.first {
					gameZoneEntity.userInfo = ["recordZone" : savedRecordZone]
					let gameZoneObject = GameZoneMO(entity: gameZoneEntity, insertInto: self.context)
					self.fetchZoneOperationCompletionBlock?(gameZoneObject)
					self.state(.finished)
				}
				else {
					// else custom error handling
					createZoneOperation.checkModifyError(error! as NSError, completionHandler: { (recordZones, _, error) in
						if error == nil, let recordZone = recordZones?.first {
							gameZoneEntity.userInfo = ["recordZone" : recordZone]
							let gameZoneObject = GameZoneMO(entity: gameZoneEntity, insertInto: self.context)
							self.fetchZoneOperationCompletionBlock?(gameZoneObject)
							self.state(.finished)
						}
						else {
							Log.error(with: #line, functionName: #function, error: error)
							self.fetchZoneOperationCompletionBlock?(nil)
							self.state(.finished)
						}
					})
				}
			}
			createZoneOperation.qualityOfService = .userInitiated
			createZoneOperation.database = self.database
			createZoneOperation.start()
		}
	}
	
	func createLoadingViewController() -> UIViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")
		controller.modalPresentationStyle = UIModalPresentationStyle.custom;
		return controller
	}
	

}

open class FetchZonesOperation: AsynchronousOperation {
	
	public var fetchZonesOperationCompletionBlock: (([GameZoneMO]?) -> Swift.Void)?
	
	private var managedObjects: [GameMO]!
	private var database: CKDatabase!
	private var context: NSManagedObjectContext = DataManager.backgroundContext
	private let container = DataManager.Container
	public convenience init(withGames managedObjects: [GameMO], database: CKDatabase) {
		self.init()
		self.managedObjects = managedObjects
		self.database = database
	}
	
	override open func main() {
		
		// Use a consistent zone ID across the user's devices
		// CKCurrentUserDefaultName specifies the current user's ID when creating a zone ID
		let zoneNames = managedObjects.map({$0.name!})
		let recordZoneIDs = zoneNames.map { CKRecordZoneID(zoneName: $0, ownerName: CKCurrentUserDefaultName)}
		let recordZones = zoneNames.map { CKRecordZone(zoneID: CKRecordZoneID(zoneName: $0, ownerName: CKCurrentUserDefaultName))}
		
		let fetchRequest: NSFetchRequest<GameZoneMO> = GameZoneMO.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "recordZoneID IN %@", recordZoneIDs)
		
		if let fetchedObjects = try? context.fetch(fetchRequest), !fetchedObjects.isEmpty {
			fetchZonesOperationCompletionBlock?(fetchedObjects)
			self.state(.finished)
		}
		else {
			let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: recordZones, recordZoneIDsToDelete: [] )
			createZoneOperation.modifyRecordZonesCompletionBlock = { (recordZones, _, error) in
				if error == nil, let recordZones = recordZones {
					let zoneObjects = recordZones.map({ (recordZone)  -> GameZoneMO in
						let gameZoneEntity = GameZoneMO.entity()
						gameZoneEntity.userInfo = ["recordZone" : recordZone]
						return GameZoneMO(entity: gameZoneEntity, insertInto: self.context)
					})
					self.fetchZonesOperationCompletionBlock?(zoneObjects)
					self.state(.finished)
				}
				else {
					// else custom error handling
					createZoneOperation.checkModifyError(error! as NSError, completionHandler: { (recordZones, _, error) in
						if error == nil, let recordZones = recordZones {
							let zoneObjects = recordZones.map({ (recordZone)  -> GameZoneMO in
								let gameZoneEntity = GameZoneMO.entity()
								gameZoneEntity.userInfo = ["recordZone" : recordZone]
								return GameZoneMO(entity: gameZoneEntity, insertInto: self.context)
							})
							self.fetchZonesOperationCompletionBlock?(zoneObjects)
							self.state(.finished)
						}
						else {
							Log.error(with: #line, functionName: #function, error: error)
							self.fetchZonesOperationCompletionBlock?(nil)
							self.state(.finished)
						}
					})
				}
			}
			createZoneOperation.qualityOfService = .userInitiated
			database.add(createZoneOperation)
		}
	}
}

