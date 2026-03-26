//
//  SettingsViewController.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import SnapKit
import UIKit

final class SettingsViewController: UIViewController {
    var onApply: ((PracticeSettings) -> Void)?

    private var settings: PracticeSettings
    private let practiceDurationText: String

    private let backdropView = UIControl()
    private let cardView = UIView()
    private let showLabelsSwitch = UISwitch()
    private let metronomeSwitch = UISwitch()
    private let themeControl = UISegmentedControl(items: PracticeTheme.allCases.map(\.displayName))

    init(settings: PracticeSettings, practiceDurationText: String) {
        self.settings = settings
        self.practiceDurationText = practiceDurationText
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
        applyCurrentSettings()
    }

    private func setupViews() {
        view.backgroundColor = .clear

        backdropView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        backdropView.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(backdropView)
        backdropView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cardView.backgroundColor = UIColor(white: 0.12, alpha: 0.96)
        cardView.layer.cornerRadius = 20
        cardView.layer.masksToBounds = true
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(420)
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(24)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-24)
        }

        let titleLabel = UILabel()
        titleLabel.text = "设置"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("完成", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.tintColor = .systemYellow
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let practiceItem = settingRow(title: "累计练习时间", accessoryView: makeValueLabel(practiceDurationText))
        let labelsItem = settingRow(title: "显示键名", accessoryView: showLabelsSwitch)
        let metronomeItem = settingRow(title: "节拍器", accessoryView: metronomeSwitch)

        let themeTitle = UILabel()
        themeTitle.text = "钢琴主题"
        themeTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        themeTitle.textColor = .white

        themeControl.selectedSegmentTintColor = .systemYellow
        themeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        themeControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)

        let stack = UIStackView(arrangedSubviews: [titleLabel, practiceItem, labelsItem, metronomeItem, themeTitle, themeControl])
        stack.axis = .vertical
        stack.spacing = 18
        cardView.addSubview(stack)
        cardView.addSubview(closeButton)

        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-20)
        }
    }

    private func applyCurrentSettings() {
        showLabelsSwitch.isOn = settings.showNoteLabels
        metronomeSwitch.isOn = settings.metronomeEnabled
        themeControl.selectedSegmentIndex = PracticeTheme.allCases.firstIndex(of: settings.theme) ?? 0
    }

    private func settingRow(title: String, accessoryView: UIView) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .white

        container.addSubview(titleLabel)
        container.addSubview(accessoryView)

        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        accessoryView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }

        return container
    }

    private func makeValueLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemYellow
        return label
    }

    @objc
    private func closeTapped() {
        settings.showNoteLabels = showLabelsSwitch.isOn
        settings.metronomeEnabled = metronomeSwitch.isOn
        if PracticeTheme.allCases.indices.contains(themeControl.selectedSegmentIndex) {
            settings.theme = PracticeTheme.allCases[themeControl.selectedSegmentIndex]
        }
        onApply?(settings)
        dismiss(animated: true)
    }
}
