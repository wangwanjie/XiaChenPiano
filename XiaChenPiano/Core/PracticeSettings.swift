//
//  PracticeSettings.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

enum InstrumentID: String, CaseIterable, Codable {
    case piano
    case weddingOrgan
    case acousticGuitar
    case trumpets
    case marimba
    case dirtyFifth
}

enum PracticeTheme: String, CaseIterable, Codable {
    case classicDark
    case warmWood
}

struct PracticeSettings: Codable, Equatable {
    var showNoteLabels: Bool
    var theme: PracticeTheme
    var instrument: InstrumentID
    var metronomeEnabled: Bool

    static let `default` = PracticeSettings(
        showNoteLabels: true,
        theme: .classicDark,
        instrument: .piano,
        metronomeEnabled: false
    )
}

final class PracticeSettingsStore {
    private let userDefaults: UserDefaults
    private let key = "practice.settings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() throws -> PracticeSettings {
        guard let data = userDefaults.data(forKey: key) else {
            return .default
        }

        return try JSONDecoder().decode(PracticeSettings.self, from: data)
    }

    func save(_ settings: PracticeSettings) throws {
        let data = try JSONEncoder().encode(settings)
        userDefaults.set(data, forKey: key)
    }
}
