//
//  MelodyRecording.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

struct RecordedNoteEvent: Codable, Hashable {
    let note: PianoNote
    let offset: TimeInterval
}

struct MelodyRecording: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
    let duration: TimeInterval
    let events: [RecordedNoteEvent]

    init(id: UUID = UUID(), title: String, createdAt: Date, duration: TimeInterval, events: [RecordedNoteEvent]) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.events = events
    }
}

final class MelodyRecordingSession {
    private let startTime: Date
    private var events: [RecordedNoteEvent] = []

    init(startTime: Date = Date()) {
        self.startTime = startTime
    }

    func record(note: PianoNote, at date: Date = Date()) {
        let offset = max(date.timeIntervalSince(startTime), 0)
        events.append(RecordedNoteEvent(note: note, offset: offset))
    }

    func finish(title: String?, endTime: Date = Date()) -> MelodyRecording {
        let resolvedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? title!.trimmingCharacters(in: .whitespacesAndNewlines)
            : Self.defaultTitle(for: startTime)

        return MelodyRecording(
            title: resolvedTitle,
            createdAt: startTime,
            duration: max(endTime.timeIntervalSince(startTime), 0),
            events: events
        )
    }

    private static func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: date)) 练习录音"
    }
}
