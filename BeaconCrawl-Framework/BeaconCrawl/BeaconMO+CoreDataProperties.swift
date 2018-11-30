//
//  BeaconMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 8/15/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

extension BeaconMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BeaconMO> {
        return NSFetchRequest<BeaconMO>(entityName: District.beacon)
    }

	@NSManaged public var accuracy: NSNumber!
	@NSManaged public var minor: NSNumber?
	@NSManaged public var major: NSNumber?
    @NSManaged public var imageData: Data?

}
