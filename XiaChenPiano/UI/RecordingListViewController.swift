//
//  RecordingListViewController.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import SnapKit
import UIKit

final class RecordingListViewController: UIViewController {
    var onPlay: ((MelodyRecording) -> Void)?
    var onDelete: ((MelodyRecording) -> Void)?
    var onRename: ((MelodyRecording, String) -> Void)?

    private var recordings: [MelodyRecording]

    private let backdropView = UIControl()
    private let cardView = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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
            make.height.equalTo(360)
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
            make.leading.trailing.bottom.equalToSuperview()
        }
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
}

extension RecordingListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recordings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let recording = recordings[indexPath.row]
        content.text = recording.title
        content.secondaryText = "\(recording.events.count) 个音符 · \(Int(recording.duration.rounded())) 秒"
        content.textProperties.color = .white
        content.secondaryTextProperties.color = UIColor.white.withAlphaComponent(0.6)
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onPlay?(recordings[indexPath.row])
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
