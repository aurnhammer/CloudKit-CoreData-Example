//
//  ImageMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 11/3/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


extension ImageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageMO> {
        return NSFetchRequest<ImageMO>(entityName: "Image");
    }
	@NSManaged public var imageData: Data?
	@NSManaged public var thumbnailData: Data?
	@NSManaged public var hasImage: NSNumber?
    @NSManaged public var titleText: String?
	@NSManaged public var descriptiveText: String?
	@NSManaged public var captionText: String?
    @NSManaged public var order: NSNumber?
}
