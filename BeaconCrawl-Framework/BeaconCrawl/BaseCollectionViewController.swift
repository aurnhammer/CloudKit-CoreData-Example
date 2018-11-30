//
//  BaseCollectionViewController.swift
//  District-1 Admin
//
//  Created by WCA on 7/24/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import MapKit

@objc public protocol FetchedController: class {
	
	func update(with objects: [NSManagedObject]?)
	
	@objc optional func animateFilter (with predicate: NSPredicate)
	
	@objc optional var collectionView: UICollectionView? { get }
	@objc optional func configure(collectionViewCell cell: UICollectionViewCell, at indexPath:IndexPath)
	
	@objc optional var tableView: UITableView! { get }
	@objc optional func configure(tableViewCell cell: UITableViewCell, at indexPath:IndexPath)
	
	@objc optional var numberOfSections: Int { get }
	@objc optional func numberOfRows(inSection section: Int) -> Int
	@objc optional func cell(forRowAt indexPath: IndexPath) -> UITableViewCell
	@objc optional func shouldHighlight(rowAt: IndexPath) -> Bool
	@objc optional func title(forHeaderInSection section: Int) -> String?
	
	@objc optional var mapView: MKMapView { get }
	
}

open class BaseCollectionViewController: UICollectionViewController {
	
	public let locationManager =  CLLocationManager()
	public var currentLocation: CLLocation?
	var playerStateSnapshot: PlayerStateSnapshot?

	fileprivate let reuseIdentifier = "Cell"
	@IBOutlet weak public var flowLayout: UICollectionViewFlowLayout!
	
	public var fetchedResultsController: NSFetchedResultsController<NSManagedObject>? {
		get {
			return dataSource.fetchedResultsController
		}
	}
	
	public var dataSource: BaseDataSource! {
		didSet {
			self.collectionView?.dataSource = dataSource
		}
	}
	
	public var objects: [NSManagedObject]? {
		get {
			return dataSource.objects
		}
	}

	override open func viewDidLoad() {
		super.viewDidLoad()
		setup()
	}
	
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	deinit {
		Log.message("deinit: \((#file as NSString).lastPathComponent): \(#function)\n")
	}
	
	override open func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning: \((#file as NSString).lastPathComponent): \(#function)\n")
	}
	
	open func setup() {
		setupCollectionView()
	}
	
	open func setupCollectionView() {
		collectionView?.refreshControl = UIRefreshControl()
		collectionView?.refreshControl?.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
		collectionView?.refreshControl?.layer.zPosition -= 1;
		collectionView?.refreshControl?.isEnabled = false
		collectionView?.delegate = self
		self.clearsSelectionOnViewWillAppear = true
		addLoadingView()
	}
	
	public func addLoadingView() {
		if collectionView?.backgroundView == nil {
			let storyboard = UIStoryboard(name: "Loading", bundle: Bundle(identifier: "com.beaconcrawl.BeaconCrawl"))
			if let viewController = storyboard.instantiateInitialViewController() {
				let frame = self.view.frame
				collectionView?.backgroundView = viewController.view
				collectionView?.backgroundView?.frame = frame
			}
		}
	}
	
	public func removeLoadingView() {
		DispatchQueue.main.async {
			self.collectionView?.backgroundView = nil
		}
	}
	
	// MARK: - Rotation
	//
	override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.collectionView?.collectionViewLayout.invalidateLayout()
	}
	
	// MARK: - Refreshing
	
	@IBAction func refreshControlValueChanged(_ refreshControl: UIRefreshControl) {
		self.reloadRemote()
	}
		
	func reloadRemote() {
		dataSource?.updateObjects()
		dataSource?.updateObjectsCompletionBlock = { [unowned self] (objects) in
			self.finishReloadRemote()
		}
	}
	
	func finishReloadRemote() {
		DispatchQueue.main.async { [unowned self] in
			if self.collectionView?.refreshControl?.isRefreshing == true {
				self.collectionView?.refreshControl?.endRefreshing()
				self.collectionView?.reloadData()
			}
		}
	}
}

extension BaseCollectionViewController: FetchedController {
	
	open func update(with objects: [NSManagedObject]?) {
		collectionView?.reloadData()
	}
	
	open func animateFilter (with predicate: NSPredicate) {
		
		guard let collectionView = self.collectionView,
			let dataSource = self.dataSource else {
				return
		}
		collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.contentInset.top), animated: true)
		
		collectionView.performBatchUpdates({ [weak self] in
			
			guard dataSource.animatedUpdates != false else {
				self?.fetchedResultsController?.fetchRequest.predicate = predicate
				try? self?.fetchedResultsController?.performFetch()
				self?.collectionView?.reloadData()
				return
			}
			
			guard let objectsBefore = self?.fetchedResultsController?.fetchedObjects else {
				Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
				return
			}
			self?.fetchedResultsController?.fetchRequest.predicate = predicate
			self?.fetchedResultsController?.fetchRequest.sortDescriptors = dataSource.sortDescriptors
			
			do {
				try self?.fetchedResultsController?.performFetch()
			} catch {
				fatalError("Failed to initialize FetchedResultsController: \(error)")
			}
			
			guard let objectsAfter = self?.fetchedResultsController?.fetchedObjects else {
				Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
				return
			}
			
			for objectBefore in objectsBefore  {
				if objectsAfter.index(of: objectBefore) == nil {
					guard let beforeIndex = objectsBefore.index(of: objectBefore) else {
						Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
						return
					}
					let indexPath = IndexPath(item: beforeIndex, section:0)
					self?.collectionView?.deleteItems(at: [indexPath])
				}
			}
			for objectAfter in objectsAfter {
				if objectsBefore.index(of: objectAfter) == nil {
					guard let afterIndex = objectsAfter.index(of: objectAfter) else {
						Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
						return
					}
					let indexPath = IndexPath(item: afterIndex, section:0)
					self?.collectionView?.insertItems(at: [indexPath])
				}
				else {
					guard let beforeIndex = objectsBefore.index(of: objectAfter) else {
						Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
						return
					}
					guard let afterIndex = objectsAfter.index(of: objectAfter) else {
						Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
						return
					}
					let beforeIndexPath = IndexPath(item: beforeIndex, section:0)
					let afterIndexPath = IndexPath(item: afterIndex, section:0)
					self?.collectionView?.moveItem(at: beforeIndexPath, to: afterIndexPath)
				}
			}
		})
	}

}


public struct Sort: Equatable {
	
	public static func ==(lhs: Sort, rhs: Sort) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
	var rawValue: String
	static public let name = Sort(rawValue: "name")
	static public let distance = Sort(rawValue: "distance")
	static public let major = Sort(rawValue: "major")
}

// MARK: - UICollectionViewFlowLayoutDelegate

extension BaseCollectionViewController: UICollectionViewDelegateFlowLayout {
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return CGFloat(4)
	}
	
	open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if let flowLayout = flowLayout {
			let cellWidth = collectionView.bounds.size.width-16
			let cellHeight = flowLayout.itemSize.height
			return CGSize(width: cellWidth, height: cellHeight)
		}
		else {
			return CGSize(width: 0, height: 0)
		}
	}
}
