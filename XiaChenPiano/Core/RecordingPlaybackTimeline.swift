//
//  RecordingPlaybackTimeline.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/27.
//

import Foundation

struct RecordingPlaybackTick: Equatable {
    let triggeredNotes: [PianoNote]
    let progress: TimeInterval
    let isFinished: Bool
}

struct RecordingPlaybackTimeline {
    let recording: MelodyRecording

    private(set) var progress: TimeInterval = 0
    private var nextEventIndex = 0

    init(recording: MelodyRecording) {
        self.recording = recording
    }

    mutating func advance(by delta: TimeInterval) -> RecordingPlaybackTick {
        let targetProgress = progress + max(delta, 0)
        return move(to: targetProgress, shouldTriggerNotes: true)
    }

    mutating func move(to targetProgress: TimeInterval, shouldTriggerNotes: Bool) -> RecordingPlaybackTick {
        let previousProgress = progress
        let clampedProgress = min(max(targetProgress, 0), recording.duration)
        progress = clampedProgress

        if shouldTriggerNotes == false || clampedProgress < previousProgress {
            nextEventIndex = recording.events.partitioningIndex { $0.offset > clampedProgress }
            return RecordingPlaybackTick(
                triggeredNotes: [],
                progress: clampedProgress,
                isFinished: clampedProgress >= recording.duration
            )
        }

        var triggeredNotes: [PianoNote] = []
        while nextEventIndex < recording.events.count {
            let event = recording.events[nextEventIndex]
            guard event.offset <= clampedProgress else {
                break
            }
            if event.offset >= previousProgress {
                triggeredNotes.append(event.note)
            }
            nextEventIndex += 1
        }

        return RecordingPlaybackTick(
            triggeredNotes: triggeredNotes,
            progress: clampedProgress,
            isFinished: clampedProgress >= recording.duration
        )
    }

    mutating func restart() {
        progress = 0
        nextEventIndex = 0
    }
}

private extension Array {
    func partitioningIndex(where predicate: (Element) -> Bool) -> Int {
        var low = 0
        var high = count

        while low < high {
            let mid = low + (high - low) / 2
            if predicate(self[mid]) {
                high = mid
            } else {
                low = mid + 1
            }
        }

        return low
    }
}
