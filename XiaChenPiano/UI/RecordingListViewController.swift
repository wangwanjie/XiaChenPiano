//
//  RecordingListViewController.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import SnapKit
import UIKit

final class RecordingListViewController: UIViewController {
    var onPlayRequested: ((MelodyRecording) -> Void)?
    var onPauseRequested: (() -> Void)?
    var onStopRequested: (() -> Void)?
    var onDelete: ((MelodyRecording) -> Void)?
    var onRename: ((MelodyRecording, String) -> Void)?

    private var recordings: [MelodyRecording]
    private var selectedRecordingID: UUID?
    private var playbackSnapshot = RecordingPlaybackSnapshot(recording: nil, state: .stopped, progress: 0, duration: 0)

    private let backdropView = UIControl()
    private let cardView = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let playbackPanel = UIView()
    private let selectedTitleLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    init(recordings: [MelodyRecording]) {
        self.recordings = recordings
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func updateRecordings(_ recordings: [MelodyRecording]) {
        self.recordings = recordings
        if let selectedRecordingID, recordings.contains(where: { $0.id == selectedRecordingID }) == false {
            self.selectedRecordingID = nil
        }
        tableView.reloadData()
        refreshPlaybackPanel()
    }

    func updatePlayback(_ snapshot: RecordingPlaybackSnapshot) {
        playbackSnapshot = snapshot
        if let recordingID = snapshot.recording?.id {
            selectedRecordingID = recordingID
        }
        refreshPlaybackPanel()
        tableView.reloadData()
    }

    private func setupViews() {
        view.backgroundColor = .clear
        backdropView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        backdropView.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(backdropView)
        backdropView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.backgroundColor = UIColor(white: 0.10, alpha: 0.97)
        cardView.layer.cornerRadius = 22
        cardView.layer.masksToBounds = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(520)
            make.height.equalTo(430)
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(24)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-24)
        }

        let titleLabel = UILabel()
        titleLabel.text = "录音列表"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.tintColor = .systemYellow
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        cardView.addSubview(titleLabel)
        cardView.addSubview(closeButton)
        cardView.addSubview(tableView)
        cardView.addSubview(playbackPanel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(24)
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
        }

        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.08)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 64
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(playbackPanel.snp.top)
        }

        setupPlaybackPanel()
        refreshPlaybackPanel()
    }

    private func setupPlaybackPanel() {
        playbackPanel.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        playbackPanel.layer.borderWidth = 1
        playbackPanel.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        selectedTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        selectedTitleLabel.textColor = .white
        selectedTitleLabel.numberOfLines = 2

        progressLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        progressLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        progressLabel.textAlignment = .right

        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progressView.progressTintColor = .systemYellow

        [playButton, pauseButton, stopButton].forEach { button in
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 1
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
            button.tintColor = .white
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(UIColor.white.withAlphaComponent(0.35), for: .disabled)
            playbackPanel.addSubview(button)
        }

        playButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.30)
        pauseButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.26)
        stopButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.24)

        playButton.addTarget(self, action: #selector(handlePlayTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(handlePauseTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(handleStopTapped), for: .touchUpInside)

        playbackPanel.addSubview(selectedTitleLabel)
        playbackPanel.addSubview(progressLabel)
        playbackPanel.addSubview(progressView)

        playbackPanel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120)
        }

        selectedTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(progressLabel.snp.leading).offset(-12)
        }

        progressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(selectedTitleLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(104)
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(selectedTitleLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        playButton.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(92)
            make.height.equalTo(36)
        }

        pauseButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton)
            make.centerX.equalToSuperview()
            make.width.equalTo(92)
            make.height.equalTo(36)
        }

        stopButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(92)
            make.height.equalTo(36)
        }
    }

    private func refreshPlaybackPanel() {
        let selectedRecording = recordings.first(where: { $0.id == selectedRecordingID }) ?? playbackSnapshot.recording
        let isSelectedCurrentPlayback = selectedRecording?.id == playbackSnapshot.recording?.id
        let progress = isSelectedCurrentPlayback ? playbackSnapshot.progress : 0
        let duration = selectedRecording?.duration ?? playbackSnapshot.duration

        selectedTitleLabel.text = selectedRecording?.title ?? "选择一条录音后可播放并查看进度"
        progressLabel.text = "\(Self.formatTime(progress)) / \(Self.formatTime(duration))"
        progressView.setProgress(duration > 0 ? Float(progress / duration) : 0, animated: isSelectedCurrentPlayback)

        playButton.isEnabled = selectedRecording != nil
        pauseButton.isEnabled = isSelectedCurrentPlayback && playbackSnapshot.state == .playing
        stopButton.isEnabled = isSelectedCurrentPlayback && (playbackSnapshot.state != .stopped || playbackSnapshot.progress > 0.001)

        if isSelectedCurrentPlayback, playbackSnapshot.state == .paused {
            playButton.setTitle("继续", for: .normal)
        } else if isSelectedCurrentPlayback, playbackSnapshot.state == .stopped, duration > 0, progress >= duration {
            playButton.setTitle("重播", for: .normal)
        } else {
            playButton.setTitle("播放", for: .normal)
        }
        pauseButton.setTitle("暂停", for: .normal)
        stopButton.setTitle("停止", for: .normal)
    }

    private func presentRenameAlert(for recording: MelodyRecording) {
        let alert = UIAlertController(title: "重命名录音", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = recording.title
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let title = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else {
                return
            }
            self?.onRename?(recording, title)
        })
        present(alert, animated: true)
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func handlePlayTapped() {
        guard let recording = recordings.first(where: { $0.id == selectedRecordingID }) ?? playbackSnapshot.recording else {
            return
        }
        selectedRecordingID = recording.id
        refreshPlaybackPanel()
        onPlayRequested?(recording)
    }

    @objc
    private func handlePauseTapped() {
        onPauseRequested?()
    }

    @objc
    private func handleStopTapped() {
        onStopRequested?()
    }

    private static func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(Int(time.rounded(.down)), 0)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

extension RecordingListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let recording = recordings[indexPath.row]
        let isSelected = recording.id == selectedRecordingID
        let isPlaying = recording.id == playbackSnapshot.recording?.id && playbackSnapshot.state == .playing
        content.text = recording.title
        let statusText = isPlaying ? " · 播放中" : ""
        content.secondaryText = "\(recording.events.count) 个音符 · \(Int(recording.duration.rounded())) 秒\(statusText)"
        content.textProperties.color = .white
        content.secondaryTextProperties.color = UIColor.white.withAlphaComponent(0.6)
        cell.contentConfiguration = content
        cell.backgroundColor = isSelected ? UIColor.systemYellow.withAlphaComponent(0.14) : .clear
        cell.accessoryType = isSelected ? .checkmark : .disclosureIndicator
        cell.tintColor = .systemYellow
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recording = recordings[indexPath.row]
        selectedRecordingID = recording.id
        refreshPlaybackPanel()
        tableView.reloadData()
        onPlayRequested?(recording)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recording = recordings[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.onDelete?(recording)
            completion(true)
        }

        let renameAction = UIContextualAction(style: .normal, title: "重命名") { [weak self] _, _, completion in
            self?.presentRenameAlert(for: recording)
            completion(true)
        }
        renameAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }
}
