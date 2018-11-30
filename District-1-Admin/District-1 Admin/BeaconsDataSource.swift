//
//  BeaconsDataSource.swift
//  District1
//
//  Created by WCA on 5/9/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import BeaconCrawl

class BeaconsDataSource: BaseDataSource {
	
	public var reloadView: (() -> Swift.Void)?
	public var removeLoadingView: (() -> Swift.Void)?
	public var animateFilters: ((NSPredicate?) -> Swift.Void)?
	
	internal let locationManager =  CLLocationManager()
	public var currentLocation: CLLocation?

	typealias Object = BeaconMO

	var queuedIndexPaths = Set<IndexPath>()
	var operationQueue = OperationQueue()

	var fetchedObjects: [NSManagedObject]? {
		get {
			return objects as? [Object]
		}
	}

	var beacons: [BeaconMO]? {
		get {
			return fetchedObjects as? [Object]
		}
	}
	
	override var sort: Sort? {
		didSet {
			updateUsingCachedData()
		}
	}
	
	private var animatedFilters: NSPredicate? {
		didSet {
			self.animateFilters?(animatedFilters)
		}
	}

	override var sortDescriptors: [NSSortDescriptor]! {
		get {
			switch sort {
			case Sort.name:
				return [NSSortDescriptor(key: "name", ascending: true)]
			case Sort.distance:
				return [NSSortDescriptor(key: "currentDistance", ascending: true)]
			case Sort.major:
				return [NSSortDescriptor(key: "major", ascending: true), NSSortDescriptor(key: "minor", ascending: true)]
			default:
				return [NSSortDescriptor(key: "name", ascending: true)]
			}
		}
	}

	override func setup() {
		super.setup()
		setupObservers()
	}
	
	public init(withFetchedController fetchedController: FetchedController?, recordID: CKRecord.ID) {
		
		let desiredKeys: [String]? = ["name", "major", "minor", "location", "accuracy"]
		let database: CKDatabase = DataManager.Container.publicCloudDatabase
		let isLocalThenRemote = true
		
		var request: NSFetchRequest<NSManagedObject>! {
			let request:NSFetchRequest<Object> = Object.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
			request.predicate = NSPredicate(format: "recordID == %@", recordID)
			request.fetchBatchSize = 1
			request.returnsObjectsAsFaults = false
			return request as? NSFetchRequest<NSManagedObject>
		}
		var query: CKQuery! {
			let query = CKQuery(recordType: District.beacon, predicate: NSPredicate(format: "recordID == %@", recordID))
			return query
		}
		
		super.init(withFetchedController: fetchedController, request: request, query: query, database: database, desiredKeys: desiredKeys, localThenRemote: isLocalThenRemote)
	}
	
	public init(withFetchedController fetchedController: FetchedController) {
		
		let desiredKeys: [String]? = ["name", "major", "minor", "location", "accuracy"]
		let database: CKDatabase = DataManager.Container.publicCloudDatabase
		let isLocalThenRemote = true

		var request: NSFetchRequest<NSManagedObject>! {
			let request:NSFetchRequest<Object> = Object.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
			request.fetchBatchSize = 7
			request.returnsObjectsAsFaults = false
			return request as? NSFetchRequest<NSManagedObject>
		}
		
		var query: CKQuery! {
			let query = CKQuery(recordType: Object.recordType(), predicate: NSPredicate(format: "TRUEPREDICATE"))
			return query
		}

		super.init(withFetchedController: fetchedController, request: request, query: query, database: database, desiredKeys: desiredKeys, localThenRemote: isLocalThenRemote)
	}

	
	deinit {
		Log.message("deinit: \((#file as NSString).lastPathComponent): \(#function)\n")
		removeObservers()
	}

	private func setupObservers() {
		NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification:Notification) in
			if CLLocationManager.authorizationStatus() != .notDetermined {
				self.checkAuthorizationAndSetupLocationManager(required:true)
			}
		}
	}
	
	private func removeObservers() {
		NotificationCenter.default.removeObserver(self)
	}
	
	open func fetchData() {
		fetchLocalCompletionBlock = {[unowned self] (beacons) in
			if let beacons = beacons as? [BeaconMO], !beacons.isEmpty {
				if CloudKitManager.isUploadingToNewDatabase {
					Log.message("Beacons: \(String(describing: beacons))")
					DataManager.forceSave(objects: beacons, with: "Beacon", to: DataManager.Container.publicCloudDatabase)
				}
				else {
					self.update(with: beacons)
				}
			}
			self.updateObjectsCompletionBlock = { [unowned self] (beacons) in
				if let beacons = beacons as? [BeaconMO] {
					self.update(with: beacons)
				}
			}
			self.updateObjects()
		}
		fetchLocal()
	}
	
	// MARK - Update
	private func updateUsingCachedData() {
		if sort == .distance {
			if let location = self.locationManager.location {
				let predicate = CLLocationManager.predicateBoundingBoxFromLocation(location, withRadius: self.radius)
				self.fetchedResultsController?.fetchRequest.sortDescriptors = self.sortDescriptors
				animatedFilters = predicate
			}
			else {
				checkAuthorizationAndSetupLocationManager(required:true)
			}
		}
		else {
			let predicate = NSPredicate(format: "TRUEPREDICATE")
			self.fetchedResultsController?.fetchRequest.sortDescriptors = self.sortDescriptors
			animatedFilters = predicate
		}
	}
	
	private func update(with beacons: [BeaconMO]?) {
		DispatchQueue.main.async { [unowned self] in
			self.reloadView?()
		}
		guard let beacons = objects, !beacons.isEmpty else {
			return
		}
		removeLoadingView?()
	}
	
	@objc override func configure(collectionViewCell cell: UICollectionViewCell, at indexPath: IndexPath) {
		guard let cell = cell as? BaseCollectionViewCell else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		if let beacon = objects?[indexPath.row] as? BeaconMO {
			var description: String = ""
			if let major = beacon.major {
				description = major.stringValue
			}
			if let minor = beacon.minor {
				description =  description + ":" + minor.stringValue
			}
			
			cell.set(beacon.name, detail: description)
			
			if let imageData = beacon.imageData {
				cell.imageView?.image = UIImage(data: imageData)
			}
			else if !queuedIndexPaths.contains(indexPath), operationQueue.operations.filter({$0.name == beacon.recordName}).isEmpty {
				cell.imageView?.image = UIImage(named: "CellBackground")
				queuedIndexPaths.insert(indexPath)
				if let latitude = beacon.latitude?.doubleValue, let longitude = beacon.longitude?.doubleValue {
					let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
					let operation = UpdateMapImageOperation(coordinate, size: cell.frame.size)
					operation.name = beacon.recordName
					operation.updateImageCompletionBlock = {[unowned self] (image) in
						if let image = image {
							DispatchQueue.main.async {
								Log.message("Index Path Removed \(indexPath.description)", enabled: false)
								self.queuedIndexPaths.remove(indexPath)
								beacon.imageData = image.jpegData(compressionQuality: 0.6)
								try? DataManager.backgroundContext.save()
							}
						}
					}
					operationQueue.addOperation(operation)
				}
			}
		}
	}

}

extension BeaconsDataSource: MapViewDataSource {
	
	func loadData() {
		
	}
	
	func numberOfAnnotations() -> Int {
		guard let sections = fetchedResultsController?.sections else { return 0 }
		return sections[0].numberOfObjects
	}
	
	func objectForIndex(_ index: Int) -> NSManagedObject? {
		let indexPath: IndexPath = IndexPath(row: index, section: 0)
		if let object = objects {
			return object[indexPath.row]
		}
		return nil
	}

	func createAnnotations() -> [Annotation]? {
		var annotations = [Annotation]()
		
		let annotationCount: Int = numberOfAnnotations()
		for i in 0..<annotationCount {
			guard let beacons: [BeaconMO] = objects as? [BeaconMO] else { return nil }
			let beacon = beacons[i]
			var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
			var title: String = ""
			var subtitle: String = ""
			var accuracy: Double = 0
			if let latitude = beacon.latitude?.doubleValue,
				let longitude = beacon.longitude?.doubleValue {
				coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			}
			else {
				let locationManager = BeaconCrawlManager.shared.locationManager
				if let location = locationManager.location {
					coordinate = location.coordinate
					let floor = location.floor
					Log.message("\(String(describing: floor))")
				}
			}
			if let name = beacon.name {
				title = name
			}
			if let major = beacon.major?.stringValue, let minor = beacon.minor?.stringValue {
				subtitle =  major + ":" + minor
			}
			if let beaconAccuracy = beacon.accuracy?.doubleValue {
				accuracy = beaconAccuracy
			}
			let annotation: Annotation = Annotation.init(recordID: beacon.recordID, coordinate: coordinate, image:nil, title: title, subtitle: subtitle, radius: accuracy)
			annotations.append(annotation)
			
		}
		return annotations
	}
	
	func updateAnnotation(_ locationAnnotation: Annotation) {
		let recordID = locationAnnotation.recordID
		if let beacons: [BeaconMO] = self.objects as? [BeaconMO] {
			guard let beacon = beacons.filter ( { $0.recordID == recordID } ).first else { return }
			
			let latitude = locationAnnotation.coordinate.latitude
			let longitude = locationAnnotation.coordinate.longitude
			beacon.latitude = NSNumber(value: latitude)
			beacon.longitude = NSNumber(value: longitude)
			locationAnnotation.title = beacon.name
			if let major = beacon.major?.stringValue, let minor = beacon.minor?.stringValue {
				locationAnnotation.subtitle =  major + ":" + minor
			}
			if let accuracy = beacon.accuracy?.doubleValue {
				locationAnnotation.radius = accuracy
			}
			let operation = UpdateMapImageOperation(locationAnnotation.coordinate, size: CGSize(width: UIScreen.main.bounds.size.width, height: 100))
			operation.updateImageCompletionBlock = { (image) in
				if let image = image {
					DispatchQueue.main.async {
						beacon.imageData = image.jpegData(compressionQuality: 0.6)
					}
				}
			}
			operation.start()
			
			let locationManager = BeaconCrawlManager.shared.locationManager
			guard let userLocation = locationManager.location  else {
				Log.message("Could not determine userLocation")
				return
			}
			beacon.updateCurrentDistance(from:userLocation)
		}
	}

}

// MARK: - CLLocationManagerDelegate

extension BeaconsDataSource: LocationManager {
	
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdate(locations: locations)
	}
	
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		Log.error(with: #line, functionName: #function, error: error)
	}
	
	public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined:
			manager.requestWhenInUseAuthorization()
		case .authorizedWhenInUse:
			manager.requestLocation()
		case .authorizedAlways:
			manager.requestLocation()
		case .restricted:
			// restricted by e.g. parental controls. User can't enable Location Services
			break
		case .denied:
			// user denied your app access to Location Services, but can grant access from Settings.app
			break
		}
	}
	
	public func updateLocation() {
		updateUsingCachedData()
	}
}

