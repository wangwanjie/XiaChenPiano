//
//  ToolbarActionButton.swift
//  XiaChenPiano
//
//  Created by Codex on 2026/3/26.
//

import SnapKit
import UIKit

final class ToolbarActionButton: UIControl {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    init(title: String, image: UIImage?) {
        super.init(frame: .zero)
        setupViews()
        configure(title: title, image: image)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.68 : 1.0
        }
    }

    func configure(title: String, image: UIImage?) {
        titleLabel.text = title
        imageView.image = image
    }

    private func setupViews() {
        addSubview(imageView)
        addSubview(titleLabel)

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white

        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
