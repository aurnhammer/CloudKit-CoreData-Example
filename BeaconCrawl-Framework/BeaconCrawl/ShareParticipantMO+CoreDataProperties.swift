//
//  ShareParticipantMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/29/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

extension ShareParticipantMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShareParticipantMO> {
        return NSFetchRequest<ShareParticipantMO>(entityName: "ShareParticipant")
    }
	
    @NSManaged public var acceptanceStatus: NSNumber?
    @NSManaged public var participantID: CKRecordID!
    @NSManaged public var permission: NSNumber?
    @NSManaged public var type: NSNumber?
    @NSManaged public var share: ShareMO?
}
