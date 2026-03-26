//
//  PracticeSessionTracker.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

final class PracticeSessionTracker {
    private let userDefaults: UserDefaults
    private let totalKey = "practice.total.seconds"
    private var activeStartDate: Date?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var totalPracticeSeconds: TimeInterval {
        var total = userDefaults.double(forKey: totalKey)
        if let activeStartDate {
            total += Date().timeIntervalSince(activeStartDate)
        }
        return total
    }

    func startSession() {
        guard activeStartDate == nil else {
            return
        }
        activeStartDate = Date()
    }

    func stopSession() {
        guard let activeStartDate else {
            return
        }
        let updatedTotal = userDefaults.double(forKey: totalKey) + max(Date().timeIntervalSince(activeStartDate), 0)
        userDefaults.set(updatedTotal, forKey: totalKey)
        self.activeStartDate = nil
    }

    func formattedPracticeDuration() -> String {
        let totalSeconds = Int(totalPracticeSeconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
}
