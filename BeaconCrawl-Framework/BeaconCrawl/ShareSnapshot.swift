//
//  ShareSnapshot.swift.swift
//  BeaconCrawl
//
//  Created by WCA on 11/28/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

public struct ShareSnapshot: Equatable {
	
	public var string: String {
		get {
			return self.shareSnapshotAsJsonString()
		}
	}
	private var share: ShareMO!
	
	public init(share: ShareMO) {
		self.share = share
	}
	
	mutating public func set(share: ShareMO) {
		self.share = share
	}
	
	// MARK: Equatable
	
	public static func ==(lShare: ShareSnapshot, rShare: ShareSnapshot) -> Bool {
		return lShare.string == rShare.string
	}
	
	public func shareSnapshotAsJsonString() -> String {
		let jsonData = shareSnapshotAsData()
		let string = String(data: jsonData, encoding:.utf8)
		if string != nil {
			return string!
		}
		else {
			return ""
		}
	}
	
	public func shareSnapshotAsData() -> Data {
		let participants = ParticipantsSnapshot(share: share)

		do {
			let dictionary: [String: Any] = [
				"participants" : participants.array
			]
			return try JSONSerialization.data(withJSONObject: dictionary, options: [])
			
		} catch {
			fatalError("Failed to create Data From GameSessionProperties: \(error)")
		}
	}
}
