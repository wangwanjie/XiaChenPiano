//
//  SampledSoundPlayer.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import AVFAudio
import Foundation

final class AudioSampleCache {
    private let cache = NSCache<NSString, NSData>()

    func data(for resourceName: String) -> Data? {
        cache.object(forKey: resourceName as NSString) as Data?
    }

    func store(_ data: Data, for resourceName: String) {
        cache.setObject(data as NSData, forKey: resourceName as NSString)
    }
}

final class SampledSoundPlayer {
    typealias ResourceLookup = (_ resourceName: String, _ fileExtension: String, _ subdirectory: String?) -> URL?

    private let sampleDataCache = AudioSampleCache()
    private var activePlayers: [AVAudioPlayer] = []
    private var scheduledPlaybackItems: [DispatchWorkItem] = []
    private var metronomeTimer: Timer?

    init() {
        configureAudioSession()
    }

    func play(note: PianoNote, instrument: InstrumentID) {
        let resourceName = instrument.samplePrefix + note.sampleCode
        guard let data = loadSampleData(named: resourceName),
              let player = try? AVAudioPlayer(data: data) else {
            return
        }

        player.prepareToPlay()
        activePlayers.append(player)
        player.play()
        cleanup(player: player, after: player.duration + 0.25)
    }

    func play(recording: MelodyRecording, instrument: InstrumentID) {
        stopScheduledPlayback()
        for event in recording.events {
            let item = DispatchWorkItem { [weak self] in
                self?.play(note: event.note, instrument: instrument)
            }
            scheduledPlaybackItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + event.offset, execute: item)
        }
    }

    func stopActiveNotes() {
        stopScheduledPlayback()
        activePlayers.forEach { $0.stop() }
        activePlayers.removeAll()
    }

    func stopAll() {
        stopActiveNotes()
        metronomeTimer?.invalidate()
        metronomeTimer = nil
    }

    func setMetronomeEnabled(_ enabled: Bool) {
        metronomeTimer?.invalidate()
        metronomeTimer = nil

        guard enabled else {
            return
        }

        metronomeTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.playMetronome()
        }
        metronomeTimer?.tolerance = 0.1
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure audio session: \(error)")
        }
    }

    private func playMetronome() {
        guard let data = loadSampleData(named: "metronome"),
              let player = try? AVAudioPlayer(data: data) else {
            return
        }

        player.prepareToPlay()
        activePlayers.append(player)
        player.play()
        cleanup(player: player, after: player.duration + 0.25)
    }

    private func loadSampleData(named resourceName: String) -> Data? {
        if let cached = sampleDataCache.data(for: resourceName) {
            return cached
        }

        guard let url = Self.resolveSampleURL(named: resourceName),
              let data = try? Data(contentsOf: url) else {
#if DEBUG
            assertionFailure("Missing audio sample: \(resourceName).mp3")
#endif
            return nil
        }
        sampleDataCache.store(data, for: resourceName)
        return data
    }

    static func resolveSampleURL(
        named resourceName: String,
        lookup: ResourceLookup = { resourceName, fileExtension, subdirectory in
            Bundle.main.url(forResource: resourceName, withExtension: fileExtension, subdirectory: subdirectory)
        }
    ) -> URL? {
        let searchPaths: [String?] = [nil, "Sound", "Resources/Sound"]
        for subdirectory in searchPaths {
            if let url = lookup(resourceName, "mp3", subdirectory) {
                return url
            }
        }
        return nil
    }

    private func cleanup(player: AVAudioPlayer, after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak player] in
            guard let self, let player else {
                return
            }
            self.activePlayers.removeAll { $0 === player }
        }
    }

    private func stopScheduledPlayback() {
        scheduledPlaybackItems.forEach { $0.cancel() }
        scheduledPlaybackItems.removeAll()
    }
}
