//
//  ImageMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 11/3/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(ImageMO)
public class ImageMO: BaseMO {
	
	@objc open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		super.addAttributes(from:record, for: keys != nil ? keys : record.allKeys())
    }
}
