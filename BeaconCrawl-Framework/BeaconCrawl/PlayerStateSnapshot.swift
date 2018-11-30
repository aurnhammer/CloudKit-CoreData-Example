//
//  PlayerStateSnapshot.swift
//  BeaconCrawl
//
//  Created by WCA on 3/27/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit

public struct PlayerStateSnapshot: Equatable {

    private var playerID: String!
    private var playerDisplayName: String!
	
	private var isDeveloper: String!
	//private var thumbnailData: Data!

	private var familyName: String!
	private var email: String!
	private var phone: String!
	private var details: String!
	private var city: String!
	private var occupation: String!
	private var birthday: String!
	private var gender: String!
	
	private var latitude: Double!
	private var longitude: Double!
    private var placeName: String!
    private var placeID: String!
    private var beaconName: String!
    private var beaconID: String!

    var player: PlayerEntity!

    public var snapShot: String!

    public init(player: PlayerEntity) {
        self.player = player
        setup()
    }

    mutating public func set(player: PlayerEntity) {
        self.player = player
        setup()
    }

	mutating func setup() {
		if let user = player.user {
			playerID = user.recordID.recordName
			playerDisplayName = user.name
			if let isDeveloper = user.isDeveloper?.boolValue {
				self.isDeveloper = "\(isDeveloper)"
			}
			familyName = user.familyName
			email = user.email
			phone = user.phone
			details = user.details
			city = user.city
			occupation = user.occupation
			if let birthday = user.birthday {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "MMMM d, yyyy"
				self.birthday = dateFormatter.string(from: birthday)
			}
			else {
				birthday = ""
			}
			gender = user.gender
			latitude = user.latitude?.doubleValue
			longitude = user.longitude?.doubleValue
			
			let stateMachine = player.stateMachine
			if let currentState = stateMachine?.currentState {
				switch currentState {
				case is InsideBeaconState:
					let beaconState = currentState as? InsideBeaconState
					if let beacon = beaconState?.beacon {
						self.beaconName = beacon.name
						self.beaconID = beacon.recordName
					}
					let placeState = stateMachine?.state(forClass: InsidePlaceState.self)
					if let place = placeState?.place {
						self.placeName = place.name
						self.placeID = place.recordName
					}
				case is InsidePlaceState:
					let placeState = currentState as? InsidePlaceState
					if let place = placeState?.place {
						self.placeName = place.name
						self.placeID = place.recordName
					}
				case is InsideRegionState:
					self.beaconName = ""
					self.beaconID = ""
					self.placeID = ""
					self.placeName = ""
					break
				default:
					break
				}
				self.snapShot = self.playerStateSnapShotAsJsonString()
			}
		}
    }

    // MARK: Equatable

    public static func ==(lplayerState: PlayerStateSnapshot, rplayerState: PlayerStateSnapshot) -> Bool {
        return lplayerState.snapShot == rplayerState.snapShot
    }

    public func playerStateSnapShotAsJsonString() -> String {
        let jsonData = playerStateSnapShotAsData()
        let string = String(data: jsonData, encoding:.utf8)
        if string != nil {
            return string!
        }
        else {
            return ""
        }
    }

    public func playerStateSnapShotAsData() -> Data {
        do {
            let dictionary: [String: String] = [
				"isDeveloper" : isDeveloper != nil ? isDeveloper! : "",
                "placeName" : placeName != nil ? placeName! : "",
                "placeID" : placeID != nil ? placeID! : "",
                "beaconName" : placeName != nil ? placeName! : "",
                "beaconID" : beaconID != nil ? self.beaconID! : "",
                "playerDisplayName" : self.playerDisplayName != nil ? self.playerDisplayName! : "",
                "playerID" : playerID != nil ? self.playerID! : "",
                "familyName" : familyName != nil ? self.familyName! : "",
                "email" : email != nil ? self.email! : "",
                "phone" : phone != nil ? self.phone! : "",
                "latitude" : latitude != nil ? String(self.latitude!) : "",
                "longitude" : longitude != nil ? String(self.longitude!) : "",
                "details" : details != nil ? self.details! : "",
                "city" : city != nil ? self.city! : "",
                "occupation" : occupation != nil ? self.occupation! : "",
                "birthday" : birthday != nil ? self.birthday! : "",
                "gender" : gender != nil ? self.gender! : ""
			]
            return try JSONSerialization.data(withJSONObject: dictionary, options: [])

        } catch {
            fatalError("Failed to create Data From GameSessionProperties: \(error)")
        }
    }
}

