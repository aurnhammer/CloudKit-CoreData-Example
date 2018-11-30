//
//  ParticipantsSnapshot.swift
//  BeaconCrawl
//
//  Created by WCA on 11/28/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

public struct ParticipantsSnapshot: Equatable {
	
	public var string: String {
		get {
			return self.participantsSnapShotAsJsonString()
		}
	}
	
	public var array:  [[String: Any]] {
		get {
			return self.participantsSnapShotAsArray()
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

	public static func ==(lParticipants: ParticipantsSnapshot, rParticipants: ParticipantsSnapshot) -> Bool {
		return lParticipants.string == rParticipants.string
	}
	
	public func participantsSnapShotAsJsonString() -> String {
		let jsonData = participantsSnapShotAsData()
		let string = String(data: jsonData, encoding:.utf8)
		if string != nil {
			return string!
		}
		else {
			return ""
		}
	}
	
	public func participantsSnapShotAsArray() -> [[String: Any]] {
		var participantsArray = [[String: Any]]()
		if let participants = share.participants {
			for participant in participants {
				var typeString: String = ""
				if (participant.type?.intValue) != nil {
					Log.message("Participant Type: \(String(describing: participant.type?.intValue))")
					switch participant.type!.intValue {
					case 1:
						typeString = "owner"
					case 2:
						typeString = "privateUser"
					case 3:
						typeString = "publicUser"
					default:
						typeString = "unknown"
					}
				}
				var permissionString: String = ""
				if (participant.permission?.intValue) != nil {
					switch participant.permission!.intValue {
					case 1:
						permissionString = "none"
					case 2:
						permissionString = "readOnly"
					case 3:
						permissionString = "readWrite"
					default:
						permissionString = "unknown"
					}
				}
				var acceptanceStatusString: String = ""
				if (participant.acceptanceStatus?.intValue) != nil {
					switch participant.acceptanceStatus!.intValue {
					case 1:
						acceptanceStatusString = "pending"
					case 2:
						acceptanceStatusString = "accepted"
					case 3:
						acceptanceStatusString = "removed"
					default:
						acceptanceStatusString = "unknown"
					}
				}
				let dictionary: [String: String] = [
					"name" : participant.name != nil ? participant.name! : "",
					"participantID" : participant.participantID?.recordName != nil ? (participant.participantID?.recordName)! : "",
					"type" : typeString,
					"permission" : permissionString,
					"acceptanceStatus" : acceptanceStatusString
				]
				participantsArray.append(dictionary)
			}
		}
		return participantsArray
	}
	
	public func participantsSnapShotAsData() -> Data {
		var participantsArray = [[String: Any]]()
		if let participants = share.participants {
			for participant in participants {
				var typeString: String = ""
				if (participant.type?.intValue) != nil {
					switch participant.type!.intValue {
					case 1:
						typeString = "owner"
					case 2:
						typeString = "privateUser"
					case 3:
						typeString = "publicUser"
					default:
						typeString = "unknown"
					}
				}
				var permissionString: String = ""
				if (participant.permission?.intValue) != nil {
					switch participant.permission!.intValue {
					case 1:
						permissionString = "none"
					case 2:
						permissionString = "readOnly"
					case 3:
						permissionString = "readWrite"
					default:
						permissionString = "unknown"
					}
				}
				var acceptanceStatusString: String = ""
				if (participant.acceptanceStatus?.intValue) != nil {
					switch participant.acceptanceStatus!.intValue {
					case 1:
						acceptanceStatusString = "pending"
					case 2:
						acceptanceStatusString = "accepted"
					case 3:
						acceptanceStatusString = "removed"
					default:
						acceptanceStatusString = "unknown"
					}
				}
				let dictionary: [String: String] = [
					"name" : participant.name != nil ? participant.name! : "",
					"participantID" : participant.participantID?.recordName != nil ? (participant.participantID?.recordName)! : "",
					"type" : typeString,
					"permission" : permissionString,
					"acceptanceStatus" : acceptanceStatusString
				]
				participantsArray.append(dictionary)
			}
		}
		do {
			return try JSONSerialization.data(withJSONObject: participantsArray, options: [])
			
		} catch {
			fatalError("Failed to create Data From GameSessionProperties: \(error)")
		}
	}
}
