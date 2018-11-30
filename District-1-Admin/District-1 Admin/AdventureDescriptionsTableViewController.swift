//
//  AdventureDescriptionsTableViewController.swift
//  District-1 Admin
//
//  Created by Bill A on 11/10/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import BeaconCrawl

class AdventureDescriptionsTableViewController: BaseTableViewController {
    
    var adventure: AdventureMO?

	typealias Object = AdventureDescriptionMO

	var adventureDescriptions: [Object]? {
		get {
			return objects as? [Object]
		}
	}
	
	var operationQueue = OperationQueue()
	var queuedIndexPaths = Set<IndexPath>()
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning: \((#file as NSString).lastPathComponent): \(#function)\n")
	}
	
	override func setup() {
		super.setup()
		setupDatasource()
	}
}

extension AdventureDescriptionsTableViewController {
	
	override var request: NSFetchRequest<NSManagedObject>! {
		guard let adventure = adventure else { return nil }
		let request:NSFetchRequest<Object> = Object.fetchRequest()
		request.sortDescriptors = sortDescriptors
		request.predicate = NSPredicate(format: "adventure == %@", adventure)
		request.fetchBatchSize = 7
		request.returnsObjectsAsFaults = false
		return request as? NSFetchRequest<NSManagedObject>
	}

	override var query: CKQuery! {
		guard let adventure = adventure else { return nil }
		let query = CKQuery(recordType: Object.recordType(), predicate: NSPredicate(format: "reference = %@", CKRecord.Reference(recordID: adventure.recordID, action: .none)))
		return query
	}
	
	func setupDatasource() {
		if request != nil, query != nil {
			dataSource = BaseDataSource(withFetchedController: self, request: request, query: query, desiredKeys:/*["name", "titleText"]*/ nil)
			tableView?.dataSource = dataSource
			dataSource.fetchLocalCompletionBlock = { (adventureDescriptions) in
				if adventureDescriptions != nil {
					//self.removeLoadingView()
				}
				if CloudKitManager.isUploadingToNewDatabase {
					if adventureDescriptions != nil {
					Log.message("AdventureDescriptions: \(String(describing: adventureDescriptions))")
					DataManager.forceSave(objects: adventureDescriptions!, with: "AdventureDescription", to: DataManager.Container.publicCloudDatabase)
					}
				}
				else {
					self.dataSource.updateObjects()
				}
			}
			dataSource.updateObjectsCompletionBlock = { (adventureDescriptions) in
				if adventureDescriptions != nil {
					//self.removeLoadingView()
				}
			}
			dataSource.fetchLocal()
		}
	}
	
	var numberOfSections:Int  {
		guard let sections = fetchedResultsController?.sections else {
			return 0
		}
		return sections.count
	}
	
	func numberOfRows(inSection section: Int) -> Int {
		guard let sections = fetchedResultsController?.sections else { return 0 }
		Log.message ("ExploreViewDataSource Items in Section \(sections[section].numberOfObjects)", enabled: false, alert: false)
		return sections[section].numberOfObjects
	}
	
	override func cell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath)
	}

	override func shouldHighlight(rowAt: IndexPath) -> Bool {
		return true
	}

	func configure(tableViewCell cell: UITableViewCell, at indexPath: IndexPath) {
		guard let cell = cell as? PromotionalPageTableViewCell else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		if let adventureDescription = adventureDescriptions?[indexPath.row] {
			cell.title?.text = adventureDescription.name
			cell.detail?.text = adventureDescription.titleText
			if let imageData = adventureDescription.imageData {
				cell.roundImageView?.image = UIImage(data: imageData)
			}
			/*else if !queuedIndexPaths.contains(indexPath), operationQueue.operations.filter({$0.name == adventureDescription.recordName}).isEmpty {
				cell.roundImageView?.image = UIImage(named: "CellBackground")
				queuedIndexPaths.insert(indexPath)
				let operation = FetchRemoteObjectsOperation(with: createImageQueryOperation(for: adventureDescription), DataManager.Container.publicCloudDatabase)
				operation.name = adventureDescription.recordName
				operation.fetchRemoteObjectsCompletionBlock = { (image) in
					if image != nil {
						DispatchQueue.main.async {
							self.queuedIndexPaths.remove(indexPath)
						}
					}
					else {
						if let image = UIImage(named: "CellBackground") {
							adventureDescription.imageData = UIImagePNGRepresentation(image)
						}
					}
				}
				operationQueue.addOperation(operation)
			}*/
		}
	}
	
	func createImageQueryOperation(for adventureDescription: AdventureDescriptionMO) -> CKQueryOperation {
		let predicate = NSPredicate(format: "recordID = %@", adventureDescription.recordID)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "AdventureDescription", predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys =  ["name", "imageData"]
		return queryOperation
	}

	func createDescriptionsQueryOperation(for adventure: AdventureMO) -> CKQueryOperation {
		let reference = CKRecord.Reference(recordID:adventure.recordID, action: .none)
		// Create the query object.
		let predicate = NSPredicate(format: "reference = %@", reference)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "AdventureDescription", predicate: predicate))
		queryOperation.resultsLimit = 1
		return queryOperation
	}
}

extension AdventureDescriptionsTableViewController: SegueHandlerType {
	
	enum SegueIdentifier: String {
		case detail = "detail"
		case add = "add"
	}

	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier,
			let sequeIndentifier = SegueIdentifier(rawValue:identifier)
			else {
				fatalError("Invalid Segue Identifier \(String(describing: segue.identifier))")
		}
		switch sequeIndentifier {
		case .detail:
			let detailViewController: AdventureDescriptionsDetailViewController = segue.destination as! AdventureDescriptionsDetailViewController
			// Get the cell that generated this segue.
			if let selectedCell = sender as? UITableViewCell,
				let indexPath = tableView.indexPath(for: selectedCell),
				let adventureDescriptions = adventureDescriptions {
				let selectedDescription: Object = adventureDescriptions[indexPath.row]
				detailViewController.recordID = selectedDescription.recordID
			}
		case .add:
			let detailViewController: AdventureDescriptionsDetailViewController = segue.destination as! AdventureDescriptionsDetailViewController
			detailViewController.adventure = adventure
		}
	}

	@IBAction func unwindToPagesTableViewController(withSegue segue: UIStoryboardSegue?) {
		tableView.reloadData()
	}
}

