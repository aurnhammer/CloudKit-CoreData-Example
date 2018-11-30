//
//  AdventureMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 11/29/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import GameplayKit

@objc(AdventureMO)
public class AdventureMO: BaseMO {

    weak public var gkEntity: GKEntity?

    @nonobjc public class func recordType() -> String {
        return District.adventure
    }
}
