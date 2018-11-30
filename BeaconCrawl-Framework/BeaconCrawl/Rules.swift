//
//  Rules.swift
//  BeaconCrawl
//
//  Created by WCA on 5/31/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import GameplayKit

enum Fact: String {
    case placeDistanceImmediate = "placeDistanceImmediate"
    case placeDistanceNear = "placeDistanceNear"
    case placeDistanceFar = "placeDistanceFar"
}

class PlaceDistanceImmediateRule: FuzzyPlaceRule {
    override func grade() -> Float {
        guard let distance = snapshot.nearestPlaceTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }
    init() { super.init(fact: .placeDistanceImmediate) }
}

class PlaceDistanceNearRule: FuzzyPlaceRule {
    override func grade() -> Float {
        guard let distance = snapshot.nearestPlaceTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }
    init() { super.init(fact: .placeDistanceNear) }
}

class PlaceDistanceFarRule: FuzzyPlaceRule {
    override func grade() -> Float {
        guard let distance = snapshot.nearestPlaceTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    init() { super.init(fact: .placeDistanceFar) }
}

class FuzzyPlaceRule: GKRule {
    // MARK: Properties

    var snapshot: EntitySnapshot!

    func grade() -> Float { return 0.0 }

    let fact: Fact

    // MARK: Initializers

    init(fact: Fact) {
        self.fact = fact

        super.init()

        // Set the salience so that 'fuzzy' rules will evaluate first.
        salience = Int.max
    }

    // MARK: GPRule Overrides

    override func evaluatePredicate(in system: GKRuleSystem) -> Bool {
		snapshot = system.state["snapshot"] as? EntitySnapshot

        if grade() >= 0.0 {
            return true
        }

        return false
    }

    override func performAction(in system: GKRuleSystem) {
        system.assertFact(fact.rawValue as NSObject, grade: grade())
    }
}

