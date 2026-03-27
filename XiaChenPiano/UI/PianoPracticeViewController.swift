//
//  PianoPracticeViewController.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import SnapKit
import UIKit

final class PianoPracticeViewController: UIViewController {
    private let environment: AppEnvironment

    private var settings: PracticeSettings
    private var viewport = KeyboardViewport(
        totalWhiteKeyCount: MusicCatalog.whiteNotes.count,
        visibleWhiteKeyCount: MusicCatalog.whiteNotes.count,
        startWhiteKeyIndex: 0
    )
    private var recordings: [MelodyRecording]
    private var recordingSession: MelodyRecordingSession?
    private lazy var playbackController = RecordingPlaybackController(soundPlayer: environment.soundPlayer)
    private var hasPresentedPreview = false

    private let topTextureView = UIImageView()
    private let bottomTextureView = UIImageView()
    private let toolbarContentView = UIView()
    private let keyboardView = PianoKeyboardView()
    private let toastLabel = InsetLabel(contentInsets: UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18))
    private weak var recordingListController: RecordingListViewController?

    private lazy var zoomOutButton = ToolbarActionButton(title: "缩小", image: UIImage(systemName: "minus"))
    private lazy var zoomInButton = ToolbarActionButton(title: "放大", image: UIImage(systemName: "plus"))
    private lazy var moveLeftButton = ToolbarActionButton(title: "左移", image: UIImage(systemName: "arrow.left"))
    private lazy var moveRightButton = ToolbarActionButton(title: "右移", image: UIImage(systemName: "arrow.right"))
    private lazy var instrumentButton = ToolbarActionButton(title: settings.instrument.displayName, image: UIImage(systemName: "music.note"))
    private lazy var recordingsButton = ToolbarActionButton(title: "录音列表", image: UIImage(named: "list_Normal"))
    private lazy var recordButton = ToolbarActionButton(title: "录音", image: UIImage(named: "record_off_Normal"))
    private lazy var settingsButton = ToolbarActionButton(title: "设置", image: UIImage(named: "setting_Normal"))

    init(environment: AppEnvironment = AppEnvironment()) {
        self.environment = environment
        self.settings = (try? environment.settingsStore.load()) ?? .default
        self.recordings = environment.melodyStore.load()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeRight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupActions()
        applyTheme()
        reloadKeyboard()
        environment.soundPlayer.setMetronomeEnabled(settings.metronomeEnabled)
        setupPlaybackController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        environment.practiceTracker.startSession()
        presentPreviewIfNeeded()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        bottomTextureView.snp.updateConstraints { make in
            make.height.equalTo(max(view.safeAreaInsets.bottom + 24, 34))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        environment.practiceTracker.stopSession()
    }

    private func setupViews() {
        view.backgroundColor = .black

        topTextureView.contentMode = .scaleAspectFill
        topTextureView.clipsToBounds = true
        topTextureView.isUserInteractionEnabled = true
        bottomTextureView.contentMode = .scaleAspectFill
        bottomTextureView.clipsToBounds = true

        view.addSubview(topTextureView)
        view.addSubview(bottomTextureView)
        view.addSubview(toolbarContentView)
        view.addSubview(keyboardView)
        view.addSubview(toastLabel)

        let leftStack = makeActionStack([zoomOutButton, zoomInButton, moveLeftButton, moveRightButton])
        let rightStack = makeActionStack([instrumentButton, recordingsButton, recordButton, settingsButton])
        toolbarContentView.addSubview(leftStack)
        toolbarContentView.addSubview(rightStack)

        topTextureView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(116)
        }

        bottomTextureView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(34)
        }

        toolbarContentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(topTextureView)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        keyboardView.snp.makeConstraints { make in
            make.top.equalTo(topTextureView.snp.bottom)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(bottomTextureView.snp.top)
        }

        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-12)
        }

        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-12)
        }

        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 14
        toastLabel.layer.masksToBounds = true
        toastLabel.alpha = 0
        toastLabel.numberOfLines = 0
        toastLabel.text = nil
        toastLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        toastLabel.setContentHuggingPriority(.required, for: .vertical)
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(keyboardView.snp.bottom).offset(-16)
            make.width.lessThanOrEqualTo(320)
            make.height.greaterThanOrEqualTo(40)
        }
    }

    private func setupActions() {
        zoomOutButton.addTarget(self, action: #selector(handleZoomOut), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(handleZoomIn), for: .touchUpInside)
        moveLeftButton.addTarget(self, action: #selector(handleMoveLeft), for: .touchUpInside)
        moveRightButton.addTarget(self, action: #selector(handleMoveRight), for: .touchUpInside)
        instrumentButton.addTarget(self, action: #selector(handleInstrument), for: .touchUpInside)
        recordingsButton.addTarget(self, action: #selector(handleRecordingList), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(handleRecordToggle), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)

        keyboardView.noteHandler = { [weak self] note in
            self?.play(note: note)
        }
    }

    private func setupPlaybackController() {
        playbackController.onNotePlayback = { [weak self] note in
            self?.keyboardView.flashPlayback(note: note)
        }
        playbackController.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }
            self.recordingListController?.updatePlayback(snapshot)
            if snapshot.state == .stopped,
               let recording = snapshot.recording,
               snapshot.progress >= snapshot.duration,
               snapshot.duration > 0 {
                self.showToast("播放完成：\(recording.title)")
            }
        }
    }

    private func makeActionStack(_ buttons: [ToolbarActionButton]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = 10
        buttons.forEach { button in
            button.snp.makeConstraints { make in
                make.width.equalTo(60)
            }
        }
        return stack
    }

    private func applyTheme() {
        topTextureView.image = UIImage(named: settings.theme.toolbarTextureName)
        bottomTextureView.image = UIImage(named: settings.theme.footerTextureName)
        instrumentButton.configure(title: settings.instrument.displayName, image: UIImage(systemName: "music.note"))
        let recordImageName = recordingSession == nil ? "record_off_Normal" : "record_on_Normal"
        recordButton.configure(title: recordingSession == nil ? "录音" : "保存", image: UIImage(named: recordImageName))
        environment.soundPlayer.setMetronomeEnabled(settings.metronomeEnabled)
        playbackController.updateInstrument(settings.instrument)
        keyboardView.apply(viewport: viewport, settings: settings)
    }

    private func reloadKeyboard() {
        keyboardView.apply(viewport: viewport, settings: settings)
    }

    private func play(note: PianoNote) {
        environment.soundPlayer.play(note: note, instrument: settings.instrument)
        recordingSession?.record(note: note)
    }

    private func persistSettings() {
        try? environment.settingsStore.save(settings)
    }

    private func saveRecordings() {
        try? environment.melodyStore.save(recordings)
    }

    private func showToast(_ text: String) {
        toastLabel.text = text
        UIView.animate(withDuration: 0.2) {
            self.toastLabel.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 1.2, options: []) {
                self.toastLabel.alpha = 0
            }
        }
    }

    private func presentPreviewIfNeeded() {
        guard hasPresentedPreview == false else {
            return
        }

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiPreviewPlaybackPanel") {
            hasPresentedPreview = true
            presentPlaybackPreview()
        } else if arguments.contains("-uiPreviewSettings") {
            hasPresentedPreview = true
            presentSettingsPreview()
        }
    }

    private func presentPlaybackPreview() {
        let previewRecordings = makePreviewRecordings()
        let controller = RecordingListViewController(recordings: previewRecordings)
        controller.updatePlayback(
            RecordingPlaybackSnapshot(
                recording: previewRecordings.first,
                state: .paused,
                progress: 7.4,
                duration: previewRecordings.first?.duration ?? 0
            )
        )
        recordingListController = controller
        present(controller, animated: false)
    }

    private func presentSettingsPreview() {
        let controller = SettingsViewController(
            settings: settings,
            practiceDurationText: environment.practiceTracker.formattedPracticeDuration()
        )
        controller.onApply = { _ in }
        present(controller, animated: false)
    }

    private func makePreviewRecordings() -> [MelodyRecording] {
        [
            MelodyRecording(
                title: "小星星练习",
                createdAt: Date(),
                duration: 12,
                events: [
                    RecordedNoteEvent(note: PianoNote(sampleCode: "111")!, offset: 0.0),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "111")!, offset: 0.6),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "211")!, offset: 1.2),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "211")!, offset: 1.8),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "224")!, offset: 2.4),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "224")!, offset: 3.0)
                ]
            ),
            MelodyRecording(
                title: "和弦滑奏练习",
                createdAt: Date().addingTimeInterval(-3600),
                duration: 18,
                events: [
                    RecordedNoteEvent(note: PianoNote(sampleCode: "321")!, offset: 0.3),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "324")!, offset: 0.9),
                    RecordedNoteEvent(note: PianoNote(sampleCode: "421")!, offset: 1.5)
                ]
            )
        ]
    }

    @objc
    private func handleZoomOut() {
        viewport.zoomOut()
        reloadKeyboard()
    }

    @objc
    private func handleZoomIn() {
        viewport.zoomIn()
        reloadKeyboard()
    }

    @objc
    private func handleMoveLeft() {
        viewport.panLeft()
        reloadKeyboard()
    }

    @objc
    private func handleMoveRight() {
        viewport.panRight()
        reloadKeyboard()
    }

    @objc
    private func handleInstrument() {
        let alert = UIAlertController(title: "切换音色", message: nil, preferredStyle: .actionSheet)
        InstrumentID.allCases.forEach { instrument in
            let title = instrument == settings.instrument ? "\(instrument.displayName) ✓" : instrument.displayName
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.settings.instrument = instrument
                self?.persistSettings()
                self?.applyTheme()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = instrumentButton
        alert.popoverPresentationController?.sourceRect = instrumentButton.bounds
        present(alert, animated: true)
    }

    @objc
    private func handleRecordingList() {
        let controller = RecordingListViewController(recordings: recordings)
        controller.updatePlayback(playbackController.snapshot)
        controller.onPlayRequested = { [weak self] recording in
            guard let self else { return }
            self.keyboardView.clearPlaybackHighlights()
            if self.playbackController.snapshot.recording?.id == recording.id,
               self.playbackController.snapshot.state == .paused {
                self.playbackController.resumePlayback()
                self.showToast("继续播放：\(recording.title)")
            } else {
                self.playbackController.startPlayback(recording: recording, instrument: self.settings.instrument)
                self.showToast("正在播放：\(recording.title)")
            }
        }
        controller.onPauseRequested = { [weak self] in
            self?.keyboardView.clearPlaybackHighlights()
            self?.playbackController.pausePlayback()
        }
        controller.onStopRequested = { [weak self] in
            self?.keyboardView.clearPlaybackHighlights()
            self?.playbackController.stopPlayback()
        }
        controller.onDelete = { [weak self, weak controller] recording in
            guard let self else { return }
            if self.playbackController.snapshot.recording?.id == recording.id {
                self.keyboardView.clearPlaybackHighlights()
                self.playbackController.stopPlayback(clearSelection: true)
            }
            self.recordings.removeAll { $0.id == recording.id }
            self.saveRecordings()
            controller?.updateRecordings(self.recordings)
        }
        controller.onRename = { [weak self, weak controller] recording, title in
            guard let self else { return }
            self.recordings = self.recordings.map {
                guard $0.id == recording.id else { return $0 }
                return MelodyRecording(id: $0.id, title: title, createdAt: $0.createdAt, duration: $0.duration, events: $0.events)
            }
            self.saveRecordings()
            controller?.updateRecordings(self.recordings)
            controller?.updatePlayback(self.playbackController.snapshot)
        }
        recordingListController = controller
        present(controller, animated: true)
    }

    @objc
    private func handleRecordToggle() {
        if let recordingSession {
            let recording = recordingSession.finish(title: nil)
            recordings.insert(recording, at: 0)
            saveRecordings()
            self.recordingSession = nil
            applyTheme()
            recordingListController?.updateRecordings(recordings)
            showToast("已保存 \(recording.title)")
        } else {
            keyboardView.clearPlaybackHighlights()
            playbackController.stopPlayback()
            environment.soundPlayer.stopActiveNotes()
            recordingSession = MelodyRecordingSession()
            applyTheme()
            showToast("开始录音")
        }
    }

    @objc
    private func handleSettings() {
        let controller = SettingsViewController(
            settings: settings,
            practiceDurationText: environment.practiceTracker.formattedPracticeDuration()
        )
        controller.onApply = { [weak self] settings in
            guard let self else { return }
            self.settings = settings
            self.persistSettings()
            self.applyTheme()
            self.reloadKeyboard()
        }
        present(controller, animated: true)
    }
}

private final class InsetLabel: UILabel {
    private let contentInsets: UIEdgeInsets

    init(contentInsets: UIEdgeInsets) {
        self.contentInsets = contentInsets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: contentInsets)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        return CGRect(
            x: textRect.origin.x - contentInsets.left,
            y: textRect.origin.y - contentInsets.top,
            width: textRect.width + contentInsets.left + contentInsets.right,
            height: textRect.height + contentInsets.top + contentInsets.bottom
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
