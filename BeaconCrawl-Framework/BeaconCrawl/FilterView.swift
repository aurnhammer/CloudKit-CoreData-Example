//
//  FilterView.swift
//  District1
//
//  Created by WCA on 2/10/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit

open class FilterView: UIView {
	
	public enum Filter: String {
		case none = "none"
		case game = "Game"
		case tour = "Tour"
		case place = "Place"
		case event = "Event"
	}
	

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var arrow: UIImageView!

    public var filter: Filter = .none
    
    @IBAction public func filterPlaces(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3){
            self.arrow.alpha = 1.0 - self.arrow.alpha
        }

        let location = sender.location(in: sender.view)
        let view = sender.view
        let views = view?.subviews
        if let selectedView = sender.view?.hitTest(location, with: nil) {
            guard selectedView.isKind(of: RoundView.self) else {return}
            guard !(views?.isEmpty)! else {return}
            for view in views! {
                if view != selectedView  {
                    UIView.animate(withDuration: 0.3){
                        view.isHidden = !view.isHidden
                    }
                }
            }
            switch selectedView.tag {
            case 200:
                filter = filter != .game ? .game : .none
            case 201:
                filter = filter != .tour ? .tour : .none
            case 202:
                filter = filter != .place ? .place : .none
            case 203:
                filter = filter != .event ? .event : .none
            default:
                filter = .none
            }
        }
    }
}
