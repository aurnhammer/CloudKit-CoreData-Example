//
//  UserMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/24/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension UserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMO> {
        return NSFetchRequest<UserMO>(entityName: "Users")
    }

	@NSManaged public var about: String?
	@NSManaged public var birthday: Date?
	@NSManaged public var city: String?
	@NSManaged public var details: String?
	@NSManaged public var email: String?
	@NSManaged public var familyName: String?
	@NSManaged public var gender: String?
	@NSManaged public var givenName: String?
	@NSManaged public var imageData: Data?
	@NSManaged public var isDeveloper: NSNumber?
	@NSManaged public var occupation: String?
	@NSManaged public var phone: String?
	@NSManaged public var status: String?
	@NSManaged public var thumbnailData: Data?
	@NSManaged public var photos: Set<PhotoMO>?
    @NSManaged public var messageSent: GameMessageMO?
    @NSManaged public var messageRecieved: GameMessageMO?

}

// MARK: Generated accessors for photos
extension UserMO {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: PhotoMO)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: PhotoMO)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}
