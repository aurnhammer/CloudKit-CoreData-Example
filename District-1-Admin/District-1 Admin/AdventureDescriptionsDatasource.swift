//
//  AdventureDescriptionsDatasource.swift
//  District-1 Admin
//
//  Created by Bill A on 8/27/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import BeaconCrawl

class AdventureDescriptionsDatasource: BaseDataSource {
	
	var fetchedObjects: [NSManagedObject]? {
		get {
			return objects
		}
	}
}

class FetchAdventureDescriptionsOperation: AsynchronousOperation {
	typealias AdventureDescription = AdventureDescriptionMO
	
	private var adventure: AdventureMO!
	private var desiredKeys: [String]?
	var fetchAdventureDescriptionsCompletionBlock: (([AdventureDescription]?) -> Swift.Void)?
	
	convenience public init(_ adventure: AdventureMO, desiredKeys: [String]? = nil) {
		self.init()
		self.adventure = adventure
		self.desiredKeys = desiredKeys
	}
	
	override open func main() {
		let queryOperation = createQueryOperation()
		queryOperation.desiredKeys = desiredKeys
		// This block fetches all the Records using the desiredKeys to filter results
		let fetchOperation = FetchRemoteRecordsQueryOperation(with: queryOperation, DataManager.Container.publicCloudDatabase)
		
		fetchOperation.fetchRemoteRecordsQueryCompletionBlock = { (records) in
			DispatchQueue.main.async {
				var adventureDescriptions = [AdventureDescription]()
				if let records = records, !records.isEmpty {
					//self.adventure.hasDescriptions = true
					for record in records {
						// We are fetching this for the first time. Update the locally created record.
						if let fetchedObjects = DataManager.fetchLocalEntities(withType: record.recordType, predicate: NSPredicate(format: "recordName = %@", record.recordID.recordName)) as? [AdventureDescription],
							let fetchedObject = fetchedObjects.first {
							fetchedObject.addAttributes(from:record)
							adventureDescriptions.append(fetchedObject)
						}
						else {
							if let adventureDescription = DataManager.createManagedObject(forRecord: record)  as? FetchAdventureDescriptionsOperation.AdventureDescription {
								let fetchedAdventure = DataManager.backgroundContext.object(with: self.adventure.objectID) as? AdventureMO
								adventureDescription.adventure = fetchedAdventure
								adventureDescriptions.append(adventureDescription)
							}
						}
					}
				}
				if let descriptions = self.adventure.descriptions{
					self.fetchAdventureDescriptionsCompletionBlock?(Array(descriptions))
				}
				self.state(.finished)
			}
		}
		fetchOperation.start()
	}
	
	func createQueryOperation() -> CKQueryOperation {
		let reference = CKRecord.Reference(recordID:adventure.recordID, action: .none)
		// Create the query object.
		let predicate = NSPredicate(format: "reference = %@", reference)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "AdventureDescription", predicate: predicate))
		queryOperation.resultsLimit = 1
		return queryOperation
	}
}

