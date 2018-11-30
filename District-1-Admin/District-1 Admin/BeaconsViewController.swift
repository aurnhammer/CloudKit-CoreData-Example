//
//  BeaconsViewController.swift
//  District-1 Admin
//
//  Created by WCA on 7/24/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import BeaconCrawl
import MapKit

class BeaconsViewController: BaseCollectionViewController {
    
    typealias Object = BeaconMO
	
	@IBOutlet private weak var sortButton: UIButton!

    var beacons: [Object]? {
        get {
			return objects as? [Object]
        }
    }
		
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning: \((#file as NSString).lastPathComponent): \(#function)\n")
    }
    
    public override func setup() {
		super.setup()
        setupDatasource()
    }
}

extension BeaconsViewController {
	
	func setupDatasource() {
		let dataSource = BeaconsDataSource(withFetchedController: self)
		self.dataSource = dataSource
		bindDataSource()
		dataSource.checkAuthorizationAndSetupLocationManager(required:false)
		dataSource.fetchData()
	}
	
	private func bindDataSource() {
		// When Prop changed, do something in the closure
		guard let dataSource = dataSource as? BeaconsDataSource else {
			return
		}
		dataSource.removeLoadingView = { [weak self] in
			DispatchQueue.main.async {
				self?.removeLoadingView()
			}
		}
		dataSource.reloadView = { [weak self] in
			DispatchQueue.main.async {
				self?.collectionView.reloadData()
			}
		}
		dataSource.animateFilters = { [weak self] (predicate) in
			guard let predicate = predicate else { return }
			self?.animateFilter(with: predicate)
		}
	}
	
}

// MARK: - UICollectionViewDataSourcePrefetching
extension BeaconsViewController: Prefetching {
	
	internal var fetchedController: NSFetchedResultsController<BeaconMO>! {
		return fetchedResultsController as! NSFetchedResultsController<BeaconMO>?
	}
	
	func setupDataSourcePrefetching() {
		collectionView?.prefetchDataSource = self as UICollectionViewDataSourcePrefetching
	}
	
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])  {
		prefetch(collectionView, itemsAt: indexPaths)
	}
}

// MARK: - SegueHandlerType

extension BeaconsViewController: SegueHandlerType {
	
	enum SegueIdentifier: String {
		case detail = "detail"
		case add = "add"
		case map = "map"
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier,
			let sequeIndentifier = SegueIdentifier(rawValue:identifier)
			else {
				fatalError("Invalid Segue Identifier \(String(describing: segue.identifier))")
		}
		switch sequeIndentifier {
		case .detail:
			if let
				detailViewController: BeaconDetailViewController = segue.destination as? BeaconDetailViewController,
				// Get the cell that generated this segue.
				let selectedCell = sender as? UICollectionViewCell,
				let indexPath = collectionView?.indexPath(for: selectedCell),
				let beacons = beacons {
				let selectedBeacon: Object = beacons[(indexPath as NSIndexPath).row]
				detailViewController.recordID = selectedBeacon.recordID
			}
		case .add:
			// Perform setup in DetailView
			break
		case .map:
			if let
				destinationViewController = segue.destination as? MapViewController {
				destinationViewController.dataSource = dataSource as? MapViewDataSource
				destinationViewController.setLocationTarget(visible: false)
			}
		}
	}
	
	@IBAction func unwindToBeaconsViewController(withSegue segue: UIStoryboardSegue?) {
	}
	
	@IBAction func presentSortOptions(withSender button: UIButton) {
		let sortController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
		sortController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
		let nameAction = UIAlertAction(title: "Name", style: UIAlertAction.Style.default, handler: { [unowned self] (UIAlertAction) in
			self.dataSource.sort = .name
		})
		
		nameAction.setValue(UIColor.gray, forKey: "titleTextColor")
		sortController.addAction(nameAction)
		
		let distanceAction = UIAlertAction(title: "Distance", style: UIAlertAction.Style.default, handler: { [unowned self] (UIAlertAction) in
			self.dataSource.sort = .distance
		})
		sortController.addAction(distanceAction)
		distanceAction.setValue(UIColor.gray, forKey: "titleTextColor")
		
		let majorAction = UIAlertAction(title: "Major", style: UIAlertAction.Style.default, handler: { [unowned self] (UIAlertAction) in
			self.dataSource.sort = .major
		})
		
		majorAction.setValue(UIColor.gray, forKey: "titleTextColor")
		sortController.addAction(majorAction)
		
		sortController.view.tintColor = UIColor.red
		
		if let popoverPresentationController = sortController.popoverPresentationController {
			popoverPresentationController.sourceRect = sortButton.bounds
			popoverPresentationController.sourceView = sortButton
		}

		self.present(sortController, animated:true)
	}
}
