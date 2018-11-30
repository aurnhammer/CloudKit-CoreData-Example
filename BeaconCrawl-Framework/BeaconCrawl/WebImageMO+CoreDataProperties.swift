//
//  WebImageMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 7/25/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension WebImageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WebImageMO> {
        return NSFetchRequest<WebImageMO>(entityName: "WebImage")
    }

//    @NSManaged public var data: NSData?
//    @NSManaged public var name: String?
//    @NSManaged public var recordChangeTag: String?
//    @NSManaged public var recordID: CKRecordID?
//    @NSManaged public var recordName: String?
    @NSManaged public var webArchive: WebArchiveMO?

}
