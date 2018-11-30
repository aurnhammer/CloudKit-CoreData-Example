//
//  PlaceStateSnapshot.swift
//  BeaconCrawl
//
//  Created by WCA on 6/16/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit

public struct  PlaceStateSnapshot: Equatable {

    private var placeName: String!
    private var placeID: String!
    private var city: String!
    private var state: String!
    private var street: String!
    private var zip: String!
    private var accuracy: NSNumber?
    private var currentDistance: NSNumber?
    private var descriptiveText: String?
    private var latitude: NSNumber?
    private var longitude: NSNumber?
    private var major: NSNumber?
    private var adventures: Set<AdventureMO>?

    var player: PlayerEntity!

    var snapShot: String = ""

    init(player: PlayerEntity) {
        self.player = player
        setup()
    }

    mutating func set(player: PlayerEntity) {
        self.player = player
        setup()
    }

    mutating func setup() {

        let stateMachine = player.stateMachine
        if let currentState = stateMachine?.currentState {
            switch currentState {
            case is InsidePlaceState:
                let placeState = currentState as? InsidePlaceState
                if let place = placeState?.place {
                    self.placeName = place.name
                    self.placeID = place.recordName
                    self.city = place.city
                    self.state = place.state
                    self.street = place.street
                    self.zip = place.zip
                    self.accuracy = place.accuracy
                    self.currentDistance = place.currentDistance
                    self.descriptiveText = place.descriptiveText
                    self.latitude = place.latitude
                    self.longitude = place.longitude
                    self.major = place.major
                    self.snapShot = self.placeStateSnapShotAsJsonString()
                }
			case is InsideRegionState:
				Log.message("Inside Region", enabled: false)
				self.placeName = ""
				self.placeID = ""
				self.city = ""
				self.state = ""
				self.street = ""
				self.zip = ""
				self.accuracy = nil
				self.currentDistance = nil
				self.descriptiveText = ""
				self.latitude = nil
				self.longitude = nil
				self.major = nil
				self.snapShot = self.placeStateSnapShotAsJsonString()
			case is OutsideRegionState:
				Log.message("Outside Region")
            case is InsideBeaconState:
				Log.message("Inside Beacon", enabled: false)
                break
            default:
                break
            }
        }
    }

    // MARK: Equatable

    public static func ==(leftPlayerState: PlaceStateSnapshot, rightPlayerState: PlaceStateSnapshot) -> Bool {
        return leftPlayerState.snapShot == rightPlayerState.snapShot
    }

    public func placeStateSnapShotAsJsonString() -> String {
        let jsonData = placeStateSnapShotAsData()
        let string = String(data: jsonData, encoding:.utf8)
        if string != nil {
            return string!
        }
        else {
            return ""
        }
    }

    public func placeStateSnapShotAsData() -> Data {
		var adventureString: String? = ""
        if let adventures = self.adventures {
            let adventureRecords = Array(adventures).map{$0.recordName}
            if let adventureData = try? JSONSerialization.data(withJSONObject: adventureRecords, options: []) {
                adventureString = String(data: adventureData, encoding: .utf8)
            }
        }

        do {
            let dictionary: [String: String] = [
                "placeName" : placeName != nil ? placeName! : "",
                "placeID" : placeID != nil ? placeID! : "",
                "city" : city != nil ? city! : "",
                "state": state != nil ? state! : "",
                "zip": zip != nil ? zip! : "",
                "accuracy": accuracy != nil ? accuracy!.stringValue : "30",
                "currentDistance": currentDistance != nil ? currentDistance!.stringValue : "0",
                "descriptiveText": descriptiveText != nil ? descriptiveText! : "",
                "latitude": latitude != nil ? latitude!.stringValue : "0",
                "longitude": longitude != nil ? longitude!.stringValue : "0",
                "major": major != nil ? major!.stringValue : "",
                "adventures": adventures != nil ? adventureString! : ""
             ]
            return try JSONSerialization.data(withJSONObject: dictionary, options: [])

        } catch {
            fatalError("Failed to create Data From GameSessionProperties: \(error)")
        }
    }
}
