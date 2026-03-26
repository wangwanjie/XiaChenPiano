//
//  PianoNote.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import Foundation

enum PitchClass: Int, CaseIterable, Codable {
    case c = 0
    case cSharp = 1
    case d = 2
    case dSharp = 3
    case e = 4
    case f = 5
    case fSharp = 6
    case g = 7
    case gSharp = 8
    case a = 9
    case aSharp = 10
    case b = 11

    init?(sampleDigits: String) {
        switch sampleDigits {
        case "11": self = .c
        case "12": self = .cSharp
        case "13": self = .d
        case "14": self = .dSharp
        case "15": self = .e
        case "16": self = .f
        case "17": self = .fSharp
        case "21": self = .g
        case "22": self = .gSharp
        case "24": self = .a
        case "25": self = .aSharp
        case "26": self = .b
        default: return nil
        }
    }

    var sampleDigits: String {
        switch self {
        case .c: return "11"
        case .cSharp: return "12"
        case .d: return "13"
        case .dSharp: return "14"
        case .e: return "15"
        case .f: return "16"
        case .fSharp: return "17"
        case .g: return "21"
        case .gSharp: return "22"
        case .a: return "24"
        case .aSharp: return "25"
        case .b: return "26"
        }
    }

    var label: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }

    var isWhiteKey: Bool {
        switch self {
        case .c, .d, .e, .f, .g, .a, .b:
            return true
        case .cSharp, .dSharp, .fSharp, .gSharp, .aSharp:
            return false
        }
    }
}

struct PianoNote: Hashable, Codable, Identifiable {
    static let displayedOctaveOffset = 1

    let octave: Int
    let pitchClass: PitchClass

    var id: String { sampleCode }

    init(octave: Int, pitchClass: PitchClass) {
        self.octave = octave
        self.pitchClass = pitchClass
    }

    init?(sampleCode: String) {
        guard sampleCode.count == 3,
              let octave = Int(sampleCode.prefix(1)),
              let pitchClass = PitchClass(sampleDigits: String(sampleCode.suffix(2))) else {
            return nil
        }
        self.init(octave: octave, pitchClass: pitchClass)
    }

    var sampleCode: String {
        "\(octave)\(pitchClass.sampleDigits)"
    }

    var label: String {
        "\(pitchClass.label)\(displayedOctave)"
    }

    var isWhiteKey: Bool {
        pitchClass.isWhiteKey
    }

    var midiNote: Int {
        (displayedOctave + 1) * 12 + pitchClass.rawValue
    }

    var displayedOctave: Int {
        octave + Self.displayedOctaveOffset
    }
}
