//
//  PlaceEntity.swift
//  BeaconCrawl
//
//  Created by WCA on 5/31/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import GameplayKit

class PlaceEntity: GKEntity {

    /**
     A `PlaceEntity` is only targetable when it is part of an Adventure and Favorited
     */
    var isTargetable: Bool {
        return true
    }


}
