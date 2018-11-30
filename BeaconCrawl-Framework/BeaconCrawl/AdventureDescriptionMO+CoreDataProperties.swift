//
//  AdventureDescriptionMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 9/1/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension AdventureDescriptionMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AdventureDescriptionMO> {
        return NSFetchRequest<AdventureDescriptionMO>(entityName: "AdventureDescription")
    }

	@NSManaged public var adventure: AdventureMO?

}
