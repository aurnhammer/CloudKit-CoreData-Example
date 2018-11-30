//
//  PlaceMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 2/18/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData


extension PlaceMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaceMO> {
        return NSFetchRequest<PlaceMO>(entityName: "Place");
    }

    @NSManaged public var accuracy: NSNumber?
    @NSManaged public var city: String?
    @NSManaged public var descriptiveText: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var major: NSNumber?
    @NSManaged public var state: String?
    @NSManaged public var street: String?
    @NSManaged public var zip: String?
}
