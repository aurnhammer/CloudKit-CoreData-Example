//
//  BeaconDetectionViewController.swift
//  District-1 Admin
//
//  Created by WCA on 7/26/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import BeaconCrawl


class BeaconDetectionViewController: UICollectionViewController {
	
	
	fileprivate let reuseIdentifier = "Cell"
	@IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
	var beaconsDetectionDataSource: BeaconsDetectionDataSource!
	
	let locationManager: CLLocationManager = CLLocationManager()
	var currentLocation: CLLocation?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.setup()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning \(self)")
	}
	
	func setup() {
		setupLocationManager()
		setupCollectionView()
		setupDatasource()
	}
	
	func setupLocationManager() {
		self.checkAuthorizationAndSetupLocationManager(required:true)
		self.locationManager.requestLocation()
	}
	
	func setupCollectionView() {
		if let collectionView = self.collectionView {
			collectionView.delegate = self
			self.clearsSelectionOnViewWillAppear = true
		}
	}
	
	func setupDatasource () {
		beaconsDetectionDataSource = BeaconsDetectionDataSource(withViewController: self)
		self.collectionView?.dataSource = beaconsDetectionDataSource
	}
	
	// MARK: - Rotation
	//
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		guard let flowLayout = flowLayout else { return }
		flowLayout.invalidateLayout()
	}
}

extension BeaconDetectionViewController: FetchedDetectedBeacons {
	
	func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
		guard let sections = objects else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		guard let cell = cell as? BaseCollectionViewCell else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		let minor = sections[indexPath.section].1[indexPath.row].minor
		let major = sections[indexPath.section].0
		let accuracy = sections[indexPath.section].1[indexPath.row].accuracy
		let rssi = sections[indexPath.section].1[indexPath.row].rssi
		let name = major.stringValue + ":" + minor.stringValue
		DispatchQueue.main.async {
			cell.set(name, detail:"RSSI: " + String(format: "%.2d", rssi) , accuracy: String(format: "%.2f", accuracy) + "m")
		}
		
	}
	
	internal var objects: [(NSNumber, [CLBeacon])]? {
		get {
			return beaconsDetectionDataSource.objects
		}
	}
}

// MARK: - CLLocationManagerDelegate

extension BeaconDetectionViewController: LocationManager {

	func updateLocation() {
		self.collectionView?.reloadData()
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		didFail(with: error)
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdate(locations: locations)
	}
}

// MARK: - UICollectionViewFlowLayoutDelegate

extension BeaconDetectionViewController: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return CGFloat(2)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let cellWidth = collectionView.bounds.size.width-16
		let cellHeight = flowLayout.itemSize.height
		return CGSize(width: cellWidth, height: cellHeight)
	}
}
