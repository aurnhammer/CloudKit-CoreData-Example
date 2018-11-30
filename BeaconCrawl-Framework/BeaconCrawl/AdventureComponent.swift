//
//  AdventureComponent.swift
//  BeaconCrawl
//
//  Created by WCA on 6/1/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import GameplayKit
class AdventureComponent: GKComponent {

    var adventure: AdventureMO!
    init(adventure: AdventureMO) {
        super.init()
        self.adventure = adventure
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        adventure.gkEntity = entity
    }

    override func willRemoveFromEntity() {
        adventure.gkEntity = nil
    }

}

