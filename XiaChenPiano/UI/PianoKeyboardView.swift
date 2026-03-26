//
//  PianoKeyboardView.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import UIKit

final class PianoKeyboardView: UIView {
    var noteHandler: ((PianoNote) -> Void)?

    private var viewport = KeyboardViewport(
        totalWhiteKeyCount: MusicCatalog.whiteNotes.count,
        visibleWhiteKeyCount: MusicCatalog.whiteNotes.count,
        startWhiteKeyIndex: 0
    )
    private var settings = PracticeSettings.default
    private var lastLaidOutSize: CGSize = .zero
    private var touchTracker = PianoTouchTracker<ObjectIdentifier, ObjectIdentifier>()
    private var buttonsByIdentifier: [ObjectIdentifier: PianoKeyButton] = [:]
    private var notesByButtonIdentifier: [ObjectIdentifier: PianoNote] = [:]

    private let whiteLabelColor = UIColor(white: 0.55, alpha: 1)
    private let blackPressedImage = UIImage(named: "black_pushed_Normal")
    private let blackImage = UIImage(named: "black_Normal")
    private let whiteImage = UIImage(named: "白鍵_Normal")

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isMultipleTouchEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastLaidOutSize else {
            return
        }
        lastLaidOutSize = bounds.size
        rebuildKeys()
    }

    func apply(viewport: KeyboardViewport, settings: PracticeSettings) {
        self.viewport = viewport
        self.settings = settings
        rebuildKeys()
    }

    private func rebuildKeys() {
        subviews.compactMap { $0 as? PianoKeyButton }.forEach { $0.isPressed = false }
        subviews.forEach { $0.removeFromSuperview() }
        touchTracker.reset()
        buttonsByIdentifier.removeAll()
        notesByButtonIdentifier.removeAll()
        guard bounds.width > 0, bounds.height > 0 else {
            return
        }

        let whiteNotes = MusicCatalog.whiteNotes(for: viewport)
        let blackNotes = MusicCatalog.blackNotes(for: viewport)
        let whiteKeyWidth = bounds.width / CGFloat(max(whiteNotes.count, 1))
        let blackKeyWidth = whiteKeyWidth * 0.56
        let blackKeyHeight = bounds.height * 0.62

        for (index, note) in whiteNotes.enumerated() {
            let button = keyButton(for: note, isWhiteKey: true)
            let frame = CGRect(
                x: CGFloat(index) * whiteKeyWidth,
                y: 0,
                width: whiteKeyWidth + 0.5,
                height: bounds.height
            )
            button.frame = frame.integral
            if settings.showNoteLabels {
                let label = UILabel(frame: CGRect(x: 2, y: button.bounds.height - 40, width: button.bounds.width - 4, height: 26))
                label.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                label.text = note.label
                label.font = .systemFont(ofSize: max(10, min(15, whiteKeyWidth * 0.35)), weight: .medium)
                label.textColor = whiteLabelColor
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.55
                button.addSubview(label)
            }
            addSubview(button)
        }

        for note in blackNotes {
            let leadingVisibleIndex = note.leadingWhiteKeyIndex - viewport.startWhiteKeyIndex
            let xPosition = CGFloat(leadingVisibleIndex + 1) * whiteKeyWidth - blackKeyWidth / 2.0
            let button = keyButton(for: note, isWhiteKey: false)
            button.frame = CGRect(x: xPosition, y: 0, width: blackKeyWidth, height: blackKeyHeight).integral
            addSubview(button)
        }
    }

    private func keyButton(for note: PianoNote, isWhiteKey: Bool) -> UIButton {
        let button = PianoKeyButton(isWhiteKey: isWhiteKey)
        let identifier = ObjectIdentifier(button)
        button.tag = note.midiNote
        button.accessibilityLabel = note.label
        button.isUserInteractionEnabled = false
        buttonsByIdentifier[identifier] = button
        notesByButtonIdentifier[identifier] = note

        if isWhiteKey {
            button.setBackgroundImage(whiteImage, for: .normal)
            button.backgroundColor = .white
            button.layer.borderColor = UIColor(white: 0.15, alpha: 0.9).cgColor
            button.layer.borderWidth = 0.5
        } else {
            button.setBackgroundImage(blackImage, for: .normal)
            button.setBackgroundImage(blackPressedImage, for: .highlighted)
        }

        return button
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handleMovedTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handleMovedTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleEndedTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handleEndedTouches(touches)
    }

    private func handleMovedTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let touchID = ObjectIdentifier(touch)
            let keyID = keyIdentifier(at: touch.location(in: self))
            let change = touchTracker.moveTouch(touchID, to: keyID)
            apply(change)
        }
    }

    private func handleEndedTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let change = touchTracker.endTouch(ObjectIdentifier(touch))
            apply(change)
        }
    }

    private func apply(_ change: PianoTouchChange<ObjectIdentifier>) {
        for keyID in change.releasedKeys {
            buttonsByIdentifier[keyID]?.isPressed = false
        }

        for keyID in change.pressedKeys {
            buttonsByIdentifier[keyID]?.isPressed = true
        }

        for keyID in change.triggeredKeys {
            guard let note = notesByButtonIdentifier[keyID] else {
                continue
            }
            noteHandler?(note)
        }
    }

    private func keyIdentifier(at location: CGPoint) -> ObjectIdentifier? {
        guard let button = subviews.reversed().compactMap({ $0 as? PianoKeyButton }).first(where: { $0.frame.contains(location) }) else {
            return nil
        }
        return ObjectIdentifier(button)
    }
}

private final class PianoKeyButton: UIButton {
    private let isWhiteKeyStyle: Bool
    private let pressedOverlay = UIView()

    var isPressed = false {
        didSet {
            updatePressedAppearance()
        }
    }

    init(isWhiteKey: Bool) {
        self.isWhiteKeyStyle = isWhiteKey
        super.init(frame: .zero)
        setupAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pressedOverlay.frame = bounds
    }

    private func setupAppearance() {
        pressedOverlay.isUserInteractionEnabled = false
        pressedOverlay.alpha = 0

        if isWhiteKeyStyle {
            pressedOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.12)
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.08
        } else {
            pressedOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            pressedOverlay.layer.cornerRadius = 8
            pressedOverlay.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowRadius = 8
            layer.shadowOpacity = 0.18
        }

        addSubview(pressedOverlay)
    }

    private func updatePressedAppearance() {
        if isWhiteKeyStyle {
            pressedOverlay.alpha = isPressed ? 1 : 0
            layer.shadowOpacity = isPressed ? 0.02 : 0.08
        } else {
            pressedOverlay.alpha = isPressed ? 1 : 0
            layer.shadowOpacity = isPressed ? 0.08 : 0.18
        }

        if isPressed {
            transform = CGAffineTransform(translationX: 0, y: isWhiteKeyStyle ? 5 : 3).scaledBy(x: 0.992, y: 0.985)
        } else {
            transform = .identity
        }
    }
}
