
//
//  BeaconsDetectionDataSource.swift
//  District-1 Admin
//
//  Created by WCA on 7/25/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import BeaconCrawl
import GameplayKit

protocol FetchedDetectedBeacons: class {

	typealias Object = BeaconMO
	var beaconsDetectionDataSource: BeaconsDetectionDataSource! { get set }
	var collectionView: UICollectionView! { get }
	func configure(_ cell: UICollectionViewCell, at indexPath:IndexPath)
}

class BeaconsDetectionDataSource: NSObject {
	
	fileprivate var animatedUpdates = false
	fileprivate let reuseIdentifier = "Cell"
	fileprivate weak var viewController: FetchedDetectedBeacons!
	fileprivate var dataManager: DataManager = DataManager.shared
	fileprivate var blockOperation: BlockOperation?
	fileprivate var beacons: [(NSNumber, [CLBeacon])]?
	var objects: [(NSNumber, [CLBeacon])]? {
		get {
			return beacons
		}
	}
	
	convenience init(withViewController viewController: FetchedDetectedBeacons) {
		self.init()
		self.viewController = viewController
		setup()
	}
	
	deinit {
		removeObservers()
	}
	
	func setup(withViewController viewController: FetchedDetectedBeacons) {
		self.viewController = viewController
		setup()
	}

	func setup() {
		setupObservers()
	}
	
	func setupObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(BeaconsDetectionDataSource.handleUpdate(withNotification:)), name: Notification.Name.BeaconsUpdatedNotification, object: nil)
	}
	
	func removeObservers() {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func handleUpdate(withNotification notification : NSNotification) {
		if let beacons = notification.object as? [(NSNumber, [CLBeacon])] {
			self.beacons = beacons
			viewController.collectionView?.reloadData()
		}
	}
}

// MARK: - UICollectionViewDataSource

extension BeaconsDetectionDataSource: UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		guard let sections = beacons else {
			return 0
		}
		return sections.count
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let sections = beacons else { return 0 }
		Log.message ("ExploreViewDataSource Items in Section \(sections[section].1.count)", enabled: false, alert: false)
		
		return sections[section].1.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
		// Set up the cell
		self.viewController.configure(cell, at: indexPath)
		return cell
	}
}
