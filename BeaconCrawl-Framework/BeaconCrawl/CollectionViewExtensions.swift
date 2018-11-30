//
//  MasonaryFlowLayout.swift
//  District1
//
//  Created by WCA on 11/16/16.
//  Copyright © 2016 District-1. All rights reserved.
//

import Foundation
import CoreData

public protocol MasonaryFlowLayout: UICollectionViewDelegateFlowLayout {
    
	associatedtype Object
    var objects: [NSManagedObject]? { get }
}

public extension UICollectionViewDelegateFlowLayout where Self: MasonaryFlowLayout  {
	
	public var minimumInteritemSpacing: CGFloat {
		get {
			return 4.0
		}
	}
	
	public func width(of collectionView: UICollectionView) -> CGFloat {
		if #available(iOS 11.0, *) {
			return collectionView.bounds.size.width - (collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right)
		}
		else {
			return collectionView.bounds.size.width
		}
	}
	
	public func fullWidth(of collectionView: UICollectionView) -> CGFloat {
		guard let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
			return 0
		}
		return width(of: collectionView)-collectionViewLayout.sectionInset.left-collectionViewLayout.sectionInset.right
	}
	
	public func halfWidth(of collectionView: UICollectionView) -> CGFloat {
		return fullWidth(of: collectionView)/2.0 - 16
	}
	
	public func quarterWidth(of collectionView: UICollectionView) -> CGFloat {
		return fullWidth(of: collectionView)/4.0 - 24
	}
	
	public func height(of collectionView: UICollectionView) -> CGFloat {
		switch UIDevice.current.userInterfaceIdiom {
		case .pad,
			 .phone where UIApplication.shared.statusBarOrientation == .landscapeRight,
			 .phone where UIApplication.shared.statusBarOrientation == .landscapeLeft:
			return quarterWidth(of: collectionView)
		default:
			return halfWidth(of: collectionView)
		}
	}
	
	// For this layout thera are 16 objects per group
	// We use 16 because it is a multiple of four and two (quarter and half) and gives us a nice variety
	
	// For portrait we use half and full width cells
	// [ 0][ 1]
	// [ 2][ 3]
	// [     4]
	// [ 5][ 6]
	// [     7]
	// [ 8][ 9]
	// [    10]
	// [    11]
	// [    12]
	// [13][14]
	// [    15]
	
	
	// For landscape we need to create a layout that fits 16 cells with quarter and half widths
	// layed out like this
	// [ 0][ 1][   2]
	// [ 3][   4][ 5]
	// [    6][    7]
	// [ 8][   9][10]
	// [   11][   12]
	// [  13][14][15]

	
	public func flowLayout(collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		
		guard let objectsCount = objects?.count, objectsCount != 0 else {
			return CGSize(width: 0, height: 0)
		}
		
		let countPerGroup = 16
		let index = indexPath.row
		
		// Get the current group by getting the number of objects modulo objects per group and subtract by one to make it zero based numbering
		let currentGroup = (objectsCount%countPerGroup)-1
		// The last group is when the objects divided by the the number of objects in a group is equal to the current index divided by the number of objects in a group
		let isLastGroup = index/countPerGroup == objectsCount/countPerGroup
		
		//UIApplication.shared.statusBarOrientation,
		//.landscapeLeft, .landscapeRight),
		switch UIDevice.current.userInterfaceIdiom {
		case .pad,
			 .phone where UIApplication.shared.statusBarOrientation == .landscapeRight,
			 .phone where UIApplication.shared.statusBarOrientation == .landscapeLeft:
			if !isLastGroup {
				switch (index%countPerGroup) {
				// Based on the pattern the large cells are 2, 4, 6, 7, 9, 11, 12 & 13
				case (2), (4), (6), (7), (9), (11), (12), (13):
					return CGSize(width: halfWidth(of: collectionView), height: height(of: collectionView))
				default:
					return CGSize(width: quarterWidth(of: collectionView), height: height(of: collectionView))
				}
			}
			else {
				// There is a definiative pattern to follow unless it is the last group of cells then adjust the pattern so there are no hanging cells
				// Each grouping has its own layout. For example the first group (or index 0) has only one cell to mange and therefore and stretches across the full width of the collectionView. The second group (or index 1) has two cells so both cells are halfwidth. The third group (index 2) has three cells where the second cell is half width. There is somewhat of a pattern here but I decided to hand tune each one of the 16 possible cases to get the best appearance
				
				switch (currentGroup, index%countPerGroup) {
				case (0, _):
					// If we are the only cell present full width
					return CGSize(width: fullWidth(of: collectionView), height: height(of: collectionView))
				case (1, _), (2, 2), (4, 2), (4, 3), (4, 4), (5, 2), (5, 3), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (7, 2), (7, 4), (7, 6), (7, 7), (8, 2), (8, 4), (8, 6), (9, 2), (9, 4), (9, 6), (9, 7), (9, 8), (9, 9), (10, 2), (10, 4), (10, 6), (10, 7), (10, 9), (11, 2), (11, 4), (11, 6), (11, 7), (12, 2), (12, 4), (12, 6), (12, 7), (12, 9), (12, 11), (12, 12), (13, 2), (13, 4), (13, 6), (13, 7), (13, 9), (13, 11), (14, 2), (14, 4), (14, 6), (14, 7), (14, 9), (14, 11), (14, 12), (14, 13), (14, 14), (15, 2), (15, 4), (15, 6), (15, 7), (15, 9), (15, 11), (15, 12), (15, 13), (15, 14):
					// This changes the standard pattern to avoid a hanging cell. It follows the illustrated patern above, modifes some cells to be longer, and falls through to the most common case which is a quarter cell.
					return CGSize(width: halfWidth(of: collectionView), height: height(of: collectionView))
				default:
					// The default case is a quarter cell
					return CGSize(width: quarterWidth(of: collectionView), height: height(of: collectionView))
				}
			}
		default: // Can be .unknown .portrait or .flat
			// Works similar to Landscape following the Porrait pattern illustrated above.
			if !isLastGroup {
				switch (index%countPerGroup) {
				case  (4), (7), (10),(11), (14), (15):
					return CGSize(width: fullWidth(of: collectionView), height: height(of: collectionView))
				default:
					return CGSize(width: halfWidth(of: collectionView), height: height(of: collectionView))
				}
			}
			else {
				switch (currentGroup, index%countPerGroup) {
				case  (0, 0), (1, _), (2, 2), (4, 4), (5, 4), (5, 5), (6, 4), (7, 4), (7, 7), (8, 4), (9, 4), (9, 7), (10, 4), (10, 7), (10, 10), (11, 4), (11, 7), (11, 8), (11, 9), (12, 4), (12, 7), (12, 10), (13, 4), (13, 7), (13, 8), (13, 9), (14, 4), (14, 7), (14, 10), (14, 11), (14, 12), (15, 4), (15, 7), (15, 9), (15, 10), (15, 11), (15, 12), (15, 15):
					return CGSize(width: fullWidth(of: collectionView), height: height(of: collectionView))
				default:
					return CGSize(width: halfWidth(of: collectionView), height: height(of: collectionView))
				}
			}
		}
	}
}


// MARK: - UICollectionViewDataSourcePrefetching

public protocol Prefetching: UICollectionViewDataSourcePrefetching {
    
    associatedtype Object: NSManagedObject
    func setupDataSourcePrefetching()
    var fetchedController: NSFetchedResultsController<Object>! { get }
}

public extension UICollectionViewDataSourcePrefetching where Self: Prefetching {
    
    public func prefetch(_ collectionView: UICollectionView, itemsAt indexPaths: [IndexPath])  {
        let fetchRequest = Object.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        let objects = indexPaths.map({ (index) -> Object in
            self.fetchedController.object(at: index)
        })
        fetchRequest.predicate = NSPredicate(format: "SELF IN %@", objects as CVarArg)
        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest,
                                                           completionBlock: nil)
		do {
			try self.fetchedController.managedObjectContext.execute(asyncFetchRequest)
		} catch {
			fatalError("Failed to execute fetch: \(error)")
		}
    }
}

