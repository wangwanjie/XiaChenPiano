//
//  AppEnvironment.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

final class AppEnvironment {
    let settingsStore: PracticeSettingsStore
    let melodyStore: MelodyLibraryStore
    let soundPlayer: SampledSoundPlayer
    let practiceTracker: PracticeSessionTracker

    init(
        settingsStore: PracticeSettingsStore = PracticeSettingsStore(),
        melodyStore: MelodyLibraryStore = MelodyLibraryStore(),
        soundPlayer: SampledSoundPlayer = SampledSoundPlayer(),
        practiceTracker: PracticeSessionTracker = PracticeSessionTracker()
    ) {
        self.settingsStore = settingsStore
        self.melodyStore = melodyStore
        self.soundPlayer = soundPlayer
        self.practiceTracker = practiceTracker
    }
}
