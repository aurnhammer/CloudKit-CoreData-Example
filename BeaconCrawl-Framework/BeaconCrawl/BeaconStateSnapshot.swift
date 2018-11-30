//
//  BeaconStateSnapshot.swift
//  BeaconCrawl
//
//  Created by WCA on 6/16/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit

public struct BeaconStateSnapshot: Equatable {

    private var beaconName: String!
    private var beaconID: String!

    var player: PlayerEntity!

    public var snapShot: String!

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
            case is InsideBeaconState:
                let beaconState = currentState as? InsideBeaconState
                if let beacon = beaconState?.beacon {
                    self.beaconName = beacon.name
                    self.beaconID = beacon.recordName
                }
            case is InsidePlaceState, is InsideRegionState:
                self.beaconName = ""
                self.beaconID = ""
                self.snapShot = self.beaconStateSnapShotAsJsonString()
            default:
                break
            }
        }
    }

    // MARK: Equatable

    public static func ==(leftBeaconState: BeaconStateSnapshot, rightBeaconState: BeaconStateSnapshot) -> Bool {
        return leftBeaconState.snapShot == rightBeaconState.snapShot
    }

    public func beaconStateSnapShotAsJsonString() -> String {
        let jsonData = beaconStateSnapShotAsData()
        let string = String(data: jsonData, encoding:.utf8)
        if string != nil {
            return string!
        }
        else {
            return ""
        }
    }

    public func beaconStateSnapShotAsData() -> Data {
        do {
            let dictionary: [String: String] = [
                "beaconName" : beaconName != nil ? beaconName! : "",
                "beaconID" : beaconID != nil ? beaconID! : "",
                ]
            return try JSONSerialization.data(withJSONObject: dictionary, options: [])

        } catch {
            fatalError("Failed to create Data From GameSessionProperties: \(error)")
        }
    }
}
