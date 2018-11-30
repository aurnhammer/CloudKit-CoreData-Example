//
//  FeedDataSource.swift
//  BeaconCrawl
//
//  Created by WCA on 11/20/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class FeedDataSource: BaseDataSource {

	
	public var reloadCollectionView: (() -> Swift.Void)?
	public var removeLoadingView: (() -> Swift.Void)?
	public var updatePhotos: (([PhotoMO]?) -> Swift.Void)?
	
	private var operationQueue = OperationQueue()

	private typealias Object = PhotoMO

	private let database = DataManager.Container.publicCloudDatabase
	private let isLocalThenRemote = false
	private let desiredKeys: [String]? = ["thumbnailData"]
	private var recordID: CKRecordID!
	

	public init(withFetchedController fetchedController: FetchedController, recordID: CKRecordID) {
		
		var request: NSFetchRequest<NSManagedObject>! {
			let request:NSFetchRequest<Object> = Object.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
			request.predicate = NSPredicate(format: "game.recordID = %@", recordID)
			request.returnsObjectsAsFaults = false
			return request as? NSFetchRequest<NSManagedObject>
		}
		
		var query: CKQuery {
			return CKQuery(recordType: District.photo, predicate: NSPredicate(format: "game = %@", CKReference(recordID: recordID, action: .none)))
		}

		super.init(withFetchedController: fetchedController, request: request, query: query, database: database, desiredKeys: desiredKeys, localThenRemote: isLocalThenRemote)
	}
	
	open func fetchData() {
		fetchLocalCompletionBlock = { [weak self] (photos) in
			if let photos = photos, !photos.isEmpty {
				self?.update(with: photos)
			}
			self?.updateObjectsCompletionBlock = { (photos) in
				self?.update(with: photos)
			}
			self?.updateObjects()
		}
		fetchLocal()
	}
	
	private func update(with objects: [NSManagedObject]?) {
		guard let photos = objects as? [PhotoMO], !photos.isEmpty else {
			return
		}
		removeLoadingView?()
	}
	
	@objc override func configure(collectionViewCell cell: UICollectionViewCell, at indexPath: IndexPath) {
		guard let cell = cell as? BaseViewCell, let photos = objects as? [PhotoMO] else {
			return
		}
		let photo: PhotoMO = photos[indexPath.row]
		if let thumbnailData = photo.thumbnailData {
			cell.backgroundImage = UIImage(data: thumbnailData)
		}
		else if operationQueue.operations.filter({$0.name == photo.recordName}).isEmpty {
			cell.backgroundImage = UIImage(named: "CellBackground")
			let operation = FetchRemoteObjectsOperation(with: createImageQueryOperation(for: photo), DataManager.Container.publicCloudDatabase)
			operation.name = photo.recordName
			operation.fetchRemoteObjectsCompletionBlock = { (objects) in
				if let objects = objects {
					if objects.isEmpty, let imageData = photo.imageData, let image = UIImage(data: imageData) {
						if let thumbnailImage = image.scale(width: 640, height: 640) {
							photo.thumbnailData = UIImageJPEGRepresentation(thumbnailImage, 0.9)
							DataManager.save([photo],
											 to: DataManager.Container.privateCloudDatabase)
						}
					}
				}
			}
			operationQueue.addOperation(operation)
		}
	}
	
	func createImageQueryOperation(for photo: PhotoMO) -> CKQueryOperation {
		let predicate = NSPredicate(format: "recordID = %@", photo.recordID)
		let queryOperation = CKQueryOperation(query: CKQuery(recordType: "Photo", predicate: predicate))
		queryOperation.resultsLimit = 1
		queryOperation.desiredKeys =  ["thumbnailData"]
		queryOperation.qualityOfService = .userInitiated
		return queryOperation
	}

}
