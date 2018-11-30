//
//  AdventureConfigurationMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 2/26/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData


extension AdventureConfigurationMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AdventureConfigurationMO> {
        return NSFetchRequest<AdventureConfigurationMO>(entityName: "AdventureConfiguration");
    }

    @NSManaged public var proximityFactor: NSNumber!
    @NSManaged public var adventure: AdventureMO?

}
