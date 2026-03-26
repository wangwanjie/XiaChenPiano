//
//  MelodyLibraryStore.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

final class MelodyLibraryStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        let applicationSupport = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = (applicationSupport ?? fileManager.temporaryDirectory)
            .appendingPathComponent("XiaChenPiano", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("recordings.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> [MelodyRecording] {
        guard let data = try? Data(contentsOf: fileURL),
              let recordings = try? decoder.decode([MelodyRecording].self, from: data) else {
            return []
        }
        return recordings.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ recordings: [MelodyRecording]) throws {
        let data = try encoder.encode(recordings.sorted { $0.createdAt > $1.createdAt })
        try data.write(to: fileURL, options: .atomic)
    }
}
