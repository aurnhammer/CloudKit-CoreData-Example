//
//  PhotoMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 7/8/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData


extension PhotoMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoMO> {
        return NSFetchRequest<PhotoMO>(entityName: "Photo")
    }

	@NSManaged public var createdAt: Date?
    @NSManaged public var game: GameMO?
    @NSManaged public var user: UserMO?

}
