//
//  RecordingPlaybackController.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/27.
//

import Foundation

enum RecordingPlaybackTransportState: Equatable {
    case stopped
    case playing
    case paused
}

struct RecordingPlaybackSnapshot: Equatable {
    let recording: MelodyRecording?
    let state: RecordingPlaybackTransportState
    let progress: TimeInterval
    let duration: TimeInterval

    var progressFraction: Double {
        guard duration > 0 else {
            return 0
        }
        return min(max(progress / duration, 0), 1)
    }
}

final class RecordingPlaybackController {
    var onSnapshotChange: ((RecordingPlaybackSnapshot) -> Void)?
    var onNotePlayback: ((PianoNote) -> Void)?

    private let soundPlayer: SampledSoundPlayer
    private var timeline: RecordingPlaybackTimeline?
    private var currentRecording: MelodyRecording?
    private var currentInstrument: InstrumentID = .piano
    private var state: RecordingPlaybackTransportState = .stopped
    private var timer: Timer?
    private var lastTickDate: Date?

    init(soundPlayer: SampledSoundPlayer) {
        self.soundPlayer = soundPlayer
    }

    deinit {
        timer?.invalidate()
    }

    var snapshot: RecordingPlaybackSnapshot {
        RecordingPlaybackSnapshot(
            recording: currentRecording,
            state: state,
            progress: timeline?.progress ?? 0,
            duration: currentRecording?.duration ?? 0
        )
    }

    func startPlayback(recording: MelodyRecording, instrument: InstrumentID) {
        timer?.invalidate()
        soundPlayer.stopActiveNotes()

        currentRecording = recording
        currentInstrument = instrument
        state = .playing
        timeline = RecordingPlaybackTimeline(recording: recording)
        lastTickDate = Date()

        emitCurrentTick(shouldTriggerNotes: true)

        guard recording.duration > 0 else {
            finishPlayback()
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        timer?.tolerance = 0.02
    }

    func updateInstrument(_ instrument: InstrumentID) {
        currentInstrument = instrument
    }

    func resumePlayback() {
        guard state == .paused, currentRecording != nil else {
            return
        }

        soundPlayer.stopActiveNotes()
        state = .playing
        lastTickDate = Date()
        emitCurrentSnapshot()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.handleTimerTick()
        }
        timer?.tolerance = 0.02
    }

    func pausePlayback() {
        guard state == .playing else {
            return
        }

        timer?.invalidate()
        timer = nil
        lastTickDate = nil
        state = .paused
        soundPlayer.stopActiveNotes()
        emitCurrentSnapshot()
    }

    func stopPlayback(clearSelection: Bool = false) {
        timer?.invalidate()
        timer = nil
        lastTickDate = nil
        soundPlayer.stopActiveNotes()

        if clearSelection {
            timeline = nil
            currentRecording = nil
        } else if var timeline {
            timeline.restart()
            self.timeline = timeline
        }

        state = .stopped
        emitCurrentSnapshot()
    }

    private func handleTimerTick() {
        guard state == .playing, var timeline else {
            return
        }

        let now = Date()
        let delta = max(now.timeIntervalSince(lastTickDate ?? now), 0)
        lastTickDate = now
        let tick = timeline.advance(by: delta)
        self.timeline = timeline
        handle(tick: tick)
    }

    private func emitCurrentTick(shouldTriggerNotes: Bool) {
        guard var timeline else {
            emitCurrentSnapshot()
            return
        }
        let tick = timeline.move(to: timeline.progress, shouldTriggerNotes: shouldTriggerNotes)
        self.timeline = timeline
        handle(tick: tick)
    }

    private func handle(tick: RecordingPlaybackTick) {
        for note in tick.triggeredNotes {
            soundPlayer.play(note: note, instrument: currentInstrument)
            onNotePlayback?(note)
        }

        emitCurrentSnapshot()

        if tick.isFinished {
            finishPlayback()
        }
    }

    private func finishPlayback() {
        timer?.invalidate()
        timer = nil
        lastTickDate = nil
        state = .stopped
        emitCurrentSnapshot()
    }

    private func emitCurrentSnapshot() {
        onSnapshotChange?(snapshot)
    }
}
