//
//  PianoCoreTests.swift
//  XiaChenPianoTests
//
//  Created by Codex on 2026/3/26.
//

import Foundation
import Testing
import UIKit
@testable import XiaChenPiano

struct PianoCoreTests {

    @Test
    func touchTrackerAllowsMultipleTouchesOnDifferentKeys() {
        var tracker = PianoTouchTracker<Int, Int>()

        let firstTouch = tracker.moveTouch(1, to: 60)
        let secondTouch = tracker.moveTouch(2, to: 64)
        let releaseFirstTouch = tracker.endTouch(1)

        #expect(firstTouch.pressedKeys == [60])
        #expect(firstTouch.triggeredKeys == [60])
        #expect(firstTouch.releasedKeys.isEmpty)

        #expect(secondTouch.pressedKeys == [64])
        #expect(secondTouch.triggeredKeys == [64])
        #expect(secondTouch.releasedKeys.isEmpty)

        #expect(releaseFirstTouch.pressedKeys.isEmpty)
        #expect(releaseFirstTouch.triggeredKeys.isEmpty)
        #expect(releaseFirstTouch.releasedKeys == [60])
    }

    @Test
    func touchTrackerKeepsSharedKeyPressedUntilLastTouchEnds() {
        var tracker = PianoTouchTracker<Int, Int>()

        _ = tracker.moveTouch(1, to: 60)
        let secondTouch = tracker.moveTouch(2, to: 60)
        let releaseFirstTouch = tracker.endTouch(1)
        let releaseSecondTouch = tracker.endTouch(2)

        #expect(secondTouch.pressedKeys.isEmpty)
        #expect(secondTouch.triggeredKeys == [60])
        #expect(secondTouch.releasedKeys.isEmpty)

        #expect(releaseFirstTouch.pressedKeys.isEmpty)
        #expect(releaseFirstTouch.triggeredKeys.isEmpty)
        #expect(releaseFirstTouch.releasedKeys.isEmpty)

        #expect(releaseSecondTouch.pressedKeys.isEmpty)
        #expect(releaseSecondTouch.triggeredKeys.isEmpty)
        #expect(releaseSecondTouch.releasedKeys == [60])
    }

    @Test
    func touchTrackerReleasesPreviousKeyWhenFingerSlidesToNextKey() {
        var tracker = PianoTouchTracker<Int, Int>()

        _ = tracker.moveTouch(1, to: 60)
        let slide = tracker.moveTouch(1, to: 62)

        #expect(slide.pressedKeys == [62])
        #expect(slide.triggeredKeys == [62])
        #expect(slide.releasedKeys == [60])
    }

    @Test
    func sampleCodeMapsToExpectedNotes() {
        let c1 = PianoNote(sampleCode: "111")
        let gSharp3 = PianoNote(sampleCode: "322")
        let b5 = PianoNote(sampleCode: "526")

        #expect(c1?.label == "C2")
        #expect(c1?.isWhiteKey == true)
        #expect(gSharp3?.label == "G#4")
        #expect(gSharp3?.isWhiteKey == false)
        #expect(b5?.label == "B6")
        #expect(b5?.midiNote == 95)
    }

    @Test
    func sampleCodeRoundTripsFromPitch() {
        let note = PianoNote(octave: 4, pitchClass: .aSharp)

        #expect(note.sampleCode == "425")
        #expect(note.label == "A#5")
        #expect(note.midiNote == 82)
    }

    @Test
    func viewportZoomAndPanStayWithinBounds() {
        var viewport = KeyboardViewport(totalWhiteKeyCount: 35, visibleWhiteKeyCount: 14, startWhiteKeyIndex: 10)

        viewport.zoomIn()
        #expect(viewport.visibleWhiteKeyCount == 12)
        #expect(viewport.startWhiteKeyIndex == 11)

        viewport.panLeft()
        #expect(viewport.startWhiteKeyIndex == 10)

        for _ in 0..<40 {
            viewport.panRight()
        }
        #expect(viewport.startWhiteKeyIndex == 23)

        for _ in 0..<20 {
            viewport.zoomOut()
        }
        #expect(viewport.visibleWhiteKeyCount == 35)
        #expect(viewport.startWhiteKeyIndex == 0)
    }

    @Test
    func recordingSessionCapturesRelativeOffsetsAndDuration() {
        let calendar = Calendar(identifier: .gregorian)
        let startTime = calendar.date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 3,
            day: 26,
            hour: 8,
            minute: 0,
            second: 0
        ))!
        let session = MelodyRecordingSession(startTime: startTime)
        let first = PianoNote(sampleCode: "111")!
        let second = PianoNote(sampleCode: "122")!

        session.record(note: first, at: startTime.addingTimeInterval(0.05))
        session.record(note: second, at: startTime.addingTimeInterval(0.38))
        let recording = session.finish(title: nil, endTime: startTime.addingTimeInterval(2.0))

        #expect(recording.title == "2026-03-26 练习录音")
        #expect(abs(recording.duration - 2.0) < 0.0001)
        #expect(recording.events.count == 2)
        #expect(abs(recording.events[0].offset - 0.05) < 0.0001)
        #expect(abs(recording.events[1].offset - 0.38) < 0.0001)
        #expect(recording.events[1].note.sampleCode == "122")
    }

    @Test
    func settingsStorageFallsBackToPracticeDefaults() throws {
        let defaults = UserDefaults(suiteName: "PianoCoreTests-\(UUID().uuidString)")!
        let storage = PracticeSettingsStore(userDefaults: defaults)

        let settings = try storage.load()

        #expect(settings.showNoteLabels == true)
        #expect(settings.theme == .classicDark)
        #expect(settings.instrument == .piano)
        #expect(settings.metronomeEnabled == false)
    }

    @Test
    func sampleLookupPrefersBundleRootResource() {
        let expectedURL = URL(fileURLWithPath: "/tmp/piano111.mp3")
        var lookupOrder: [String?] = []

        let resolvedURL = SampledSoundPlayer.resolveSampleURL(named: "piano111") { resourceName, fileExtension, subdirectory in
            lookupOrder.append(subdirectory)
            #expect(resourceName == "piano111")
            #expect(fileExtension == "mp3")
            return subdirectory == nil ? expectedURL : nil
        }

        #expect(resolvedURL == expectedURL)
        #expect(lookupOrder == [nil])
    }

    @Test
    func sampleLookupFallsBackToResourcesSoundDirectory() {
        let expectedURL = URL(fileURLWithPath: "/tmp/Resources/Sound/piano111.mp3")
        var lookupOrder: [String?] = []

        let resolvedURL = SampledSoundPlayer.resolveSampleURL(named: "piano111") { _, _, subdirectory in
            lookupOrder.append(subdirectory)
            return subdirectory == "Resources/Sound" ? expectedURL : nil
        }

        #expect(resolvedURL == expectedURL)
        #expect(lookupOrder == [nil, "Sound", "Resources/Sound"])
    }

    @Test
    func sampleCacheSupportsConcurrentReadsAndWrites() {
        let cache = AudioSampleCache()
        let expected = Data("piano111".utf8)
        let group = DispatchGroup()

        for index in 0..<64 {
            group.enter()
            DispatchQueue.global().async {
                if index.isMultiple(of: 2) {
                    cache.store(expected, for: "piano111")
                } else {
                    _ = cache.data(for: "piano111")
                }
                group.leave()
            }
        }

        group.wait()

        #expect(cache.data(for: "piano111") == expected)
    }

    @Test
    func playbackTimelineTriggersNotesAsProgressAdvances() {
        let recording = MelodyRecording(
            title: "测试录音",
            createdAt: Date(),
            duration: 0.5,
            events: [
                RecordedNoteEvent(note: PianoNote(sampleCode: "111")!, offset: 0.1),
                RecordedNoteEvent(note: PianoNote(sampleCode: "122")!, offset: 0.35)
            ]
        )
        var timeline = RecordingPlaybackTimeline(recording: recording)

        let firstStep = timeline.advance(by: 0.05)
        let secondStep = timeline.advance(by: 0.10)
        let thirdStep = timeline.advance(by: 0.25)
        let finalStep = timeline.advance(by: 0.20)

        #expect(firstStep.triggeredNotes.isEmpty)
        #expect(abs(firstStep.progress - 0.05) < 0.0001)
        #expect(firstStep.isFinished == false)

        #expect(secondStep.triggeredNotes.map(\.sampleCode) == ["111"])
        #expect(abs(secondStep.progress - 0.15) < 0.0001)
        #expect(secondStep.isFinished == false)

        #expect(thirdStep.triggeredNotes.map(\.sampleCode) == ["122"])
        #expect(abs(thirdStep.progress - 0.40) < 0.0001)
        #expect(thirdStep.isFinished == false)

        #expect(finalStep.triggeredNotes.isEmpty)
        #expect(abs(finalStep.progress - 0.5) < 0.0001)
        #expect(finalStep.isFinished == true)
    }

    @Test
    func playbackTimelineRestartResetsProgressAndTriggersNotesAgain() {
        let recording = MelodyRecording(
            title: "测试录音",
            createdAt: Date(),
            duration: 0.3,
            events: [
                RecordedNoteEvent(note: PianoNote(sampleCode: "111")!, offset: 0.1)
            ]
        )
        var timeline = RecordingPlaybackTimeline(recording: recording)

        _ = timeline.advance(by: 0.2)
        timeline.restart()
        let replayStep = timeline.advance(by: 0.15)

        #expect(abs(timeline.progress - 0.15) < 0.0001)
        #expect(replayStep.triggeredNotes.map(\.sampleCode) == ["111"])
        #expect(replayStep.isFinished == false)
    }

    @MainActor
    @Test
    func recordingListCardFitsWithinLandscapeViewport() throws {
        let recording = MelodyRecording(
            title: "横屏测试录音",
            createdAt: Date(),
            duration: 12,
            events: [RecordedNoteEvent(note: PianoNote(sampleCode: "111")!, offset: 0.1)]
        )
        let viewController = RecordingListViewController(recordings: [recording])

        viewController.loadViewIfNeeded()

        let mirror = Mirror(reflecting: viewController)
        let cardView = try #require(mirror.descendant("cardView") as? UIView)
        let externalConstraints = viewController.view.constraints.filter { constraint in
            (constraint.firstItem as AnyObject?) === cardView || (constraint.secondItem as AnyObject?) === cardView
        }
        let constraints = externalConstraints + cardView.constraints

        let hasRequiredFixedHeight = constraints.contains { constraint in
            let cardIsHeightItem =
                ((constraint.firstItem as AnyObject?) === cardView && constraint.firstAttribute == .height) ||
                ((constraint.secondItem as AnyObject?) === cardView && constraint.secondAttribute == .height) ||
                (constraint.firstItem == nil && constraint.secondItem == nil && constraint.firstAttribute == .height)

            return cardIsHeightItem &&
                constraint.relation == .equal &&
                abs(constraint.constant) == 430 &&
                constraint.priority == .required
        }

        let hasVerticalSafetyConstraint = externalConstraints.contains { constraint in
            let firstItem = constraint.firstItem
            let secondItem = constraint.secondItem
            let touchesCard =
                (firstItem as AnyObject?) === cardView ||
                (secondItem as AnyObject?) === cardView
            let touchesSafeArea =
                firstItem is UILayoutGuide || secondItem is UILayoutGuide
            let isVerticalRelation: Bool = {
                switch (constraint.firstAttribute, constraint.secondAttribute) {
                case (.top, _), (.bottom, _), (.centerY, _), (.height, _), (_, .top), (_, .bottom), (_, .centerY), (_, .height):
                    return true
                default:
                    return false
                }
            }()

            return touchesCard && touchesSafeArea && isVerticalRelation
        }

        #expect(hasRequiredFixedHeight == false)
        #expect(hasVerticalSafetyConstraint)
    }

    @MainActor
    @Test
    func practiceScreenUsesSafeAreaForToolbarAndKeyboardHorizontally() throws {
        let viewController = PianoPracticeViewController()

        viewController.loadViewIfNeeded()

        let mirror = Mirror(reflecting: viewController)
        let keyboardView = try #require(mirror.descendant("keyboardView") as? UIView)
        let toolbarContentView = try #require(mirror.descendant("toolbarContentView") as? UIView)

        let rootConstraints = viewController.view.constraints
        let keyboardUsesHorizontalSafeArea = rootConstraints.contains { constraint in
            let touchesKeyboard =
                (constraint.firstItem as AnyObject?) === keyboardView ||
                (constraint.secondItem as AnyObject?) === keyboardView
            let touchesSafeArea =
                constraint.firstItem is UILayoutGuide || constraint.secondItem is UILayoutGuide
            let isHorizontal =
                constraint.firstAttribute == .leading ||
                constraint.firstAttribute == .trailing ||
                constraint.secondAttribute == .leading ||
                constraint.secondAttribute == .trailing

            return touchesKeyboard && touchesSafeArea && isHorizontal
        }

        let toolbarUsesSafeArea = rootConstraints.contains { constraint in
            let touchesToolbar =
                (constraint.firstItem as AnyObject?) === toolbarContentView ||
                (constraint.secondItem as AnyObject?) === toolbarContentView
            let touchesSafeArea =
                constraint.firstItem is UILayoutGuide || constraint.secondItem is UILayoutGuide
            let isHorizontal =
                constraint.firstAttribute == .leading ||
                constraint.firstAttribute == .trailing ||
                constraint.secondAttribute == .leading ||
                constraint.secondAttribute == .trailing

            return touchesToolbar && touchesSafeArea && isHorizontal
        }

        #expect(keyboardUsesHorizontalSafeArea)
        #expect(toolbarUsesSafeArea)
    }

}
