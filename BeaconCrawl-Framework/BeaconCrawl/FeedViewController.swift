//
//  FeedViewController.swift
//  District1
//
//  Created by WCA on 11/28/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

open class FeedViewController: BaseCollectionViewController {

	public typealias Object = PhotoMO
	
	var photos: [Object]? {
		get {
			return objects as? [Object]
		}
	}

	public var recordID: CKRecordID!	

	override open func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override open func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning: \((#file as NSString).lastPathComponent): \(#function)\n")
	}
	
	override open func setup() {
		super.setup()
		setupDatasource()
	}
	
	override open func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = false
	}
	
	override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.collectionView?.collectionViewLayout.invalidateLayout()
	}

	@IBAction func shareButtonPressed(_ sender: UIButton) {
		let index = sender.tag
		
		if let photo = photos?[index] {
			var activityItems = [Any]()
			if let data = photo.imageData, let image = UIImage(data: data) {
				activityItems.append(image)
			}
			let viewController = UIActivityViewController(activityItems:activityItems, applicationActivities: [])
			self.present(viewController, animated: true)
		}
	}
}

extension FeedViewController {
	
	func setupDatasource() {
		dataSource = FeedDataSource(withFetchedController: self, recordID: recordID)
		bindDataSource()
		guard let dataSource = dataSource as? FeedDataSource else { return }
		dataSource.fetchData()
	}
	
	func fetchPhotos() {
		dataSource.fetchLocalCompletionBlock = {  (photos) in
			if let photos = photos, !photos.isEmpty {
				self.removeLoadingView()
			}
			self.dataSource.updateObjects()
		}
		dataSource.updateObjectsCompletionBlock = { (photos) in
			if let photos = photos, !photos.isEmpty {
				self.removeLoadingView()
			}
		}
		dataSource.fetchLocal()
		setupDataSourcePrefetching()
	}
	
	private func bindDataSource() {
		// When Prop changed, do something in the closure
		guard let dataSource = dataSource as? FeedDataSource else {
			return
		}
		dataSource.removeLoadingView = { [weak self] in
			DispatchQueue.main.async {
				self?.removeLoadingView()
			}
		}
		dataSource.reloadCollectionView = { [weak self] in
			DispatchQueue.main.async {
				self?.collectionView?.reloadData()
			}
		}
	}
	
	override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let selectedObject: Object = objects?[indexPath.row] as? Object {
			performSegue(withIdentifier: .detail, sender: selectedObject)
		}
	}
	
	override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let destinationViewController = segue.destination
		guard let identifier = segue.identifier,
			let sequeIndentifier = SegueIdentifier(rawValue:identifier)
			else {
				fatalError("Invalid Segue Identifier \(String(describing: segue.identifier))")
		}
		switch sequeIndentifier {
		case .detail:
			if let viewController = destinationViewController as? FeedDetailViewController {
				if let object = sender as? Object {
					viewController.photo = object
				}
			}
		}
	}

}

// MARK: - UICollectionViewFlowLayoutDelegate

// MARK: - UICollectionViewDataSourcePrefetching
extension FeedViewController: Prefetching {
	
	public var fetchedController: NSFetchedResultsController<Object>! {
		return fetchedResultsController as! NSFetchedResultsController<Object>?
	}
	
	public func setupDataSourcePrefetching() {
		collectionView?.prefetchDataSource = self as UICollectionViewDataSourcePrefetching
	}
	
	public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])  {
		prefetch(collectionView, itemsAt: indexPaths)
	}
}

extension FeedViewController: MasonaryFlowLayout   {
	
	override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
	}
	
	override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 2.0
	}

	override open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return flowLayout(collectionView:collectionView, sizeForItemAt: indexPath)
	}
}

extension FeedViewController: SegueHandlerType {
	
	public enum SegueIdentifier: String {
		case detail = "detail"
	}
}
