//
//  PianoTouchTracker.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/27.
//

import Foundation

struct PianoTouchChange<KeyID: Hashable>: Equatable {
    let pressedKeys: [KeyID]
    let releasedKeys: [KeyID]
    let triggeredKeys: [KeyID]

    static var none: Self {
        Self(pressedKeys: [], releasedKeys: [], triggeredKeys: [])
    }
}

struct PianoTouchTracker<TouchID: Hashable, KeyID: Hashable> {
    private var touchAssignments: [TouchID: KeyID] = [:]
    private var activeKeyTouchCounts: [KeyID: Int] = [:]

    mutating func moveTouch(_ touchID: TouchID, to keyID: KeyID?) -> PianoTouchChange<KeyID> {
        let previousKeyID = touchAssignments[touchID]
        guard previousKeyID != keyID else {
            return .none
        }

        var pressedKeys: [KeyID] = []
        var releasedKeys: [KeyID] = []
        var triggeredKeys: [KeyID] = []

        if let previousKeyID {
            releaseTouch(for: previousKeyID, releasedKeys: &releasedKeys)
            touchAssignments.removeValue(forKey: touchID)
        }

        if let keyID {
            touchAssignments[touchID] = keyID
            let updatedCount = (activeKeyTouchCounts[keyID] ?? 0) + 1
            activeKeyTouchCounts[keyID] = updatedCount
            if updatedCount == 1 {
                pressedKeys.append(keyID)
            }
            triggeredKeys.append(keyID)
        }

        return PianoTouchChange(
            pressedKeys: pressedKeys,
            releasedKeys: releasedKeys,
            triggeredKeys: triggeredKeys
        )
    }

    mutating func endTouch(_ touchID: TouchID) -> PianoTouchChange<KeyID> {
        moveTouch(touchID, to: nil)
    }

    mutating func reset() {
        touchAssignments.removeAll()
        activeKeyTouchCounts.removeAll()
    }

    private mutating func releaseTouch(for keyID: KeyID, releasedKeys: inout [KeyID]) {
        let remainingCount = (activeKeyTouchCounts[keyID] ?? 0) - 1
        if remainingCount > 0 {
            activeKeyTouchCounts[keyID] = remainingCount
            return
        }

        activeKeyTouchCounts.removeValue(forKey: keyID)
        releasedKeys.append(keyID)
    }
}
