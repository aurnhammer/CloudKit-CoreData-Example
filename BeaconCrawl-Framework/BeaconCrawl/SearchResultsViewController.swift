/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A table view controller that displays filtered strings based on callbacks from a UISearchController.
*/

import UIKit

open class SearchResultsViewController: SearchControllerBaseViewController, UISearchResultsUpdating {
    // MARK: - Types
    
    public struct StoryboardConstants {
        /**
            The identifier string that corresponds to the `SearchResultsViewController`'s
            view controller defined in the main storyboard.
        */
        public static let identifier = "SearchResultsViewControllerStoryboardIdentifier"
    }
    
    // MARK: - UISearchResultsUpdating
    
    public func updateSearchResults(for searchController: UISearchController) {
        /*
            `updateSearchResultsForSearchController(_:)` is called when the controller is
            being dismissed to allow those who are using the controller they are search
            as the results controller a chance to reset their state. No need to update
            anything if we're being dismissed.
        */
        guard searchController.isActive else { return }
        
        filterString = searchController.searchBar.text
    }
}
