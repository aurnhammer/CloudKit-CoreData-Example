//
//  BaseDataSource.swift
//  District-1 Admin
//
//  Created by WCA on 7/30/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import MapKit

@objc public protocol FetchedDatasource: class {
	var fetchedResultsController: NSFetchedResultsController<NSManagedObject>! { get set }
	var updateObjectsCompletionBlock: ((_ records: [NSManagedObject]?) -> Swift.Void)? { get set }
	func updateObjects()
}

open class BaseDataSource: NSObject, FetchedDatasource {
	
	public typealias ManagedObject = NSManagedObject
	
	fileprivate let reuseIdentifier = "Cell"
	open weak var fetchedController: FetchedController?

	open var animatedUpdates = true

	fileprivate var dataManager: DataManager = DataManager.shared
	
	var sectionDictionary: [NSFetchedResultsChangeType : [Int]]!
	var rowDictionary: [NSFetchedResultsChangeType : [IndexPath]]!

	public var fetchLocalCompletionBlock: ((_ objects: [ManagedObject]?) -> Swift.Void)?
	public var updateObjectsCompletionBlock: ((_ objects: [ManagedObject]?) -> Swift.Void)?

	public var fetchedResultsController: NSFetchedResultsController<ManagedObject>?

	fileprivate var request: NSFetchRequest<NSManagedObject>!
	fileprivate var query: CKQuery!
	fileprivate var desiredKeys: [String]?
	fileprivate var database: CKDatabase!
	private var localThenRemote: Bool!

	open var sort: Sort?
//	open var filter: FilterView.Filter = .none
	
	public var objects: [ManagedObject]? {
		get {
			return fetchedResultsController?.fetchedObjects
		}
	}
	
	open var sortDescriptors: [NSSortDescriptor]! {
		get {
			switch sort {
			case Sort.name:
				return [NSSortDescriptor(key: "name", ascending: true)]
			case Sort.distance:
				return [NSSortDescriptor(key: "currentDistance", ascending: true)]
			default:
				return [NSSortDescriptor(key: "name", ascending: true)]
			}
		}
	}

	public init(withFetchedController fetchedController: FetchedController? = nil,
				request: NSFetchRequest<ManagedObject>,
				query: CKQuery,
				database: CKDatabase? = DataManager.Container.publicCloudDatabase,
				desiredKeys: [String]? = nil,
				localThenRemote: Bool = true) {
		super.init()
		self.fetchedController = fetchedController
		self.desiredKeys = desiredKeys
		self.request = request
		self.query = query
		self.database = database
		self.localThenRemote = localThenRemote
		setup()
	}
	
	open func setup() {
		setupFetchedResultsController()
	}
	
	func setupFetchedResultsController () {
		if let fetchRequest = self.request {
			fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:DataManager.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			fetchedResultsController?.delegate = self
		}
	}
	
	public func fetchLocal() {
		do {
			try fetchedResultsController?.performFetch()
		} catch {
			fatalError("Failed to initialize FetchedResultsController: \(error)")
		}
		fetchLocalCompletionBlock?(objects)
	}
	
	public func updateObjects() {
		if let query = self.query, let fetchRequest = request {
			let queryOperation = CKQueryOperation(query: query)
			queryOperation.desiredKeys = desiredKeys
			queryOperation.database = database
			Log.message("Desired Keys \(String(describing: desiredKeys))", enabled: false)
			let fetchRecordsOperation = FetchObjectsOperation(with:fetchRequest,  queryOperation:queryOperation, database, localThenRemote: localThenRemote)
			fetchRecordsOperation.fetchRemoteObjectsCompletionBlock = {(objects) in
				self.updateObjectsCompletionBlock?(objects)
			}
			fetchRecordsOperation.start()
		}
	}
}

extension BaseDataSource: NSFetchedResultsControllerDelegate {
	
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		animatedUpdates = UIApplication.shared.applicationState != .background
		if let fetchedController = self.fetchedController, fetchedController.collectionView == nil || animatedUpdates == false {
			DispatchQueue.main.async {
				fetchedController.update(with: controller.fetchedObjects as? [NSManagedObject])
			}
		}
		else {
			rowDictionary = [.insert : [], .delete : [], .update : [],  .move : []]
			sectionDictionary = [.insert : [], .delete : [], .update : []]
		}
	}
		
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		
		guard let fetchedController = self.fetchedController,
			fetchedController.collectionView != nil,
			animatedUpdates else {
			return
		}
		
		switch type {
		case .insert:
			guard let newIndexPath = newIndexPath else { return }
			rowDictionary[type]?.append(newIndexPath)
		case .delete, .update:
			guard let indexPath = indexPath else { return }
			rowDictionary[type]?.append(indexPath)
		case .move:
			guard let indexPath = indexPath, let newIndexPath = newIndexPath  else { return }
			rowDictionary[.delete]?.append(indexPath)
			rowDictionary[.insert]?.append(newIndexPath)
		}
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		
		guard let fetchedController = self.fetchedController,
			fetchedController.collectionView != nil,
			animatedUpdates else {
				return
		}
		
		sectionDictionary[type]?.append(sectionIndex)

	}
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

		guard let viewController = fetchedController, let collectionView = viewController.collectionView, animatedUpdates else {
			return
		}
		
		collectionView?.performBatchUpdates({ () -> Void in
			for type in sectionDictionary.keys {
				if let sectionIndexs = sectionDictionary[type] {
					for sectionIndex in sectionIndexs {
						switch type {
						case .insert:
							collectionView?.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
						case .update:
							collectionView?.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
						case .delete:
							collectionView?.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
						default:
							break
						}
					}
				}
			}
			for type in rowDictionary.keys {
				if let indexPaths = rowDictionary[type] {
					for indexPath in indexPaths {
						switch type {
						case .insert:
							collectionView?.insertItems(at: [indexPath])
						case .update:
							collectionView?.reloadItems(at: [indexPath])
						case .delete:
							collectionView?.deleteItems(at: [indexPath])
						case .move:
							break
						}
					}
				}
			}
		}, completion: { (finished) -> Void in
			self.rowDictionary.removeAll(keepingCapacity: false)
			self.sectionDictionary.removeAll(keepingCapacity: false)
		})
	}
}

// MARK: - UICollectionViewDataSource

extension BaseDataSource: UICollectionViewDataSource {
	
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		guard let sections = fetchedResultsController?.sections else {
			return 0
		}
		return sections.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let sections = fetchedResultsController?.sections else { return 0 }
		Log.message ("ExploreViewDataSource Items in Section \(sections[section].numberOfObjects)", enabled: false, alert: false)
			return sections[section].numberOfObjects
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
		configure(collectionViewCell:cell, at: indexPath)
		return cell
	}
	
	@objc open func configure(collectionViewCell cell: UICollectionViewCell, at indexPath:IndexPath) {
		
	}
}

extension BaseDataSource: UITableViewDataSource {
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// If the cell is static
		if let numberOfRows = fetchedController?.numberOfRows?(inSection: section) {
			return numberOfRows
		}
		// Otherwise it’s dynamic
		guard let sections = fetchedResultsController?.sections else { return 0 }
		Log.message ("ExploreViewDataSource Items in Section \(sections[section].numberOfObjects)", enabled: true, alert: false)
		return sections[section].numberOfObjects
	}
	
	public func  numberOfSections(in tableView: UITableView) -> Int {
		// If the cell is static
		if let numberOfSections = fetchedController?.numberOfSections {
			return numberOfSections
		}
		// Otherwise it’s dynamic
		guard let sections = fetchedResultsController?.sections else {
			return 0
		}
		return sections.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let fetchedController = fetchedController	else {
			fatalError("There is no FetchedController")
		}
		let cell = fetchedController.cell!(forRowAt:indexPath)
		fetchedController.configure?(tableViewCell:cell, at: indexPath)
		return cell
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return fetchedController?.title?(forHeaderInSection: section)
	}
}
