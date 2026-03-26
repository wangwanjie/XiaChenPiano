//
//  MusicCatalog.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

enum MusicCatalog {
    static let allNotes: [PianoNote] = (1...5).flatMap { octave in
        PitchClass.allCases.compactMap { pitchClass in
            PianoNote(octave: octave, pitchClass: pitchClass)
        }
    }

    static let whiteNotes: [PianoNote] = allNotes.filter(\.isWhiteKey)

    static func blackNotes(for viewport: KeyboardViewport) -> [PianoNote] {
        allNotes.filter { note in
            guard !note.isWhiteKey else {
                return false
            }

            let leadingWhiteIndex = note.leadingWhiteKeyIndex
            let trailingWhiteIndex = leadingWhiteIndex + 1
            let visibleRange = viewport.startWhiteKeyIndex..<(viewport.startWhiteKeyIndex + viewport.visibleWhiteKeyCount)
            return visibleRange.contains(leadingWhiteIndex) && visibleRange.contains(trailingWhiteIndex)
        }
    }

    static func whiteNotes(for viewport: KeyboardViewport) -> [PianoNote] {
        let endIndex = min(viewport.startWhiteKeyIndex + viewport.visibleWhiteKeyCount, whiteNotes.count)
        guard viewport.startWhiteKeyIndex < endIndex else {
            return []
        }
        return Array(whiteNotes[viewport.startWhiteKeyIndex..<endIndex])
    }
}

extension InstrumentID {
    var samplePrefix: String {
        switch self {
        case .piano: return "piano"
        case .weddingOrgan: return "WeddingOrgan"
        case .acousticGuitar: return "AcousticGuitar"
        case .trumpets: return "Trumpets"
        case .marimba: return "Marimba"
        case .dirtyFifth: return "DirtyFifth"
        }
    }

    var displayName: String {
        switch self {
        case .piano: return "钢琴"
        case .weddingOrgan: return "风琴"
        case .acousticGuitar: return "吉他"
        case .trumpets: return "小号"
        case .marimba: return "马林巴"
        case .dirtyFifth: return "合成器"
        }
    }
}

extension PracticeTheme {
    var displayName: String {
        switch self {
        case .classicDark: return "经典黑"
        case .warmWood: return "木纹暖色"
        }
    }

    var toolbarTextureName: String {
        switch self {
        case .classicDark: return "texture_Normal"
        case .warmWood: return "texture2-2_Normal"
        }
    }

    var footerTextureName: String {
        toolbarTextureName
    }

    var keyTintHex: String {
        switch self {
        case .classicDark: return "#F6F6F4"
        case .warmWood: return "#F7DDA9"
        }
    }
}

extension PianoNote {
    static var sampledRange: [PianoNote] {
        MusicCatalog.allNotes
    }

    var whiteKeyIndex: Int {
        let octaveOffset = (octave - 1) * 7
        switch pitchClass {
        case .c, .cSharp: return octaveOffset
        case .d, .dSharp: return octaveOffset + 1
        case .e: return octaveOffset + 2
        case .f, .fSharp: return octaveOffset + 3
        case .g, .gSharp: return octaveOffset + 4
        case .a, .aSharp: return octaveOffset + 5
        case .b: return octaveOffset + 6
        }
    }

    var leadingWhiteKeyIndex: Int {
        switch pitchClass {
        case .cSharp: return whiteKeyIndex
        case .dSharp: return whiteKeyIndex
        case .fSharp: return whiteKeyIndex
        case .gSharp: return whiteKeyIndex
        case .aSharp: return whiteKeyIndex
        default: return whiteKeyIndex
        }
    }
}
