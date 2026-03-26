//
//  KeyboardViewport.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

struct KeyboardViewport: Equatable {
    let totalWhiteKeyCount: Int
    private(set) var visibleWhiteKeyCount: Int
    private(set) var startWhiteKeyIndex: Int

    let minimumVisibleWhiteKeyCount: Int = 8
    let zoomStep: Int = 2
    let panStep: Int = 1

    private var maximumVisibleWhiteKeyCount: Int {
        totalWhiteKeyCount
    }

    init(totalWhiteKeyCount: Int, visibleWhiteKeyCount: Int, startWhiteKeyIndex: Int) {
        self.totalWhiteKeyCount = totalWhiteKeyCount
        let maximumVisibleWhiteKeyCount = totalWhiteKeyCount
        let resolvedVisibleWhiteKeyCount = min(
            max(visibleWhiteKeyCount, minimumVisibleWhiteKeyCount),
            min(maximumVisibleWhiteKeyCount, totalWhiteKeyCount)
        )
        self.visibleWhiteKeyCount = resolvedVisibleWhiteKeyCount
        self.startWhiteKeyIndex = min(max(startWhiteKeyIndex, 0), max(totalWhiteKeyCount - self.visibleWhiteKeyCount, 0))
    }

    mutating func zoomIn() {
        updateVisibleWhiteKeyCount(to: visibleWhiteKeyCount - zoomStep)
    }

    mutating func zoomOut() {
        updateVisibleWhiteKeyCount(to: visibleWhiteKeyCount + zoomStep)
    }

    mutating func panLeft() {
        startWhiteKeyIndex = max(startWhiteKeyIndex - panStep, 0)
    }

    mutating func panRight() {
        startWhiteKeyIndex = min(startWhiteKeyIndex + panStep, max(totalWhiteKeyCount - visibleWhiteKeyCount, 0))
    }

    private mutating func updateVisibleWhiteKeyCount(to newValue: Int) {
        let oldVisibleCount = visibleWhiteKeyCount
        let center = Double(startWhiteKeyIndex) + Double(oldVisibleCount) / 2.0
        visibleWhiteKeyCount = min(max(newValue, minimumVisibleWhiteKeyCount), min(maximumVisibleWhiteKeyCount, totalWhiteKeyCount))
        let unclampedStart = Int(round(center - Double(visibleWhiteKeyCount) / 2.0))
        startWhiteKeyIndex = min(max(unclampedStart, 0), max(totalWhiteKeyCount - visibleWhiteKeyCount, 0))
    }
}
