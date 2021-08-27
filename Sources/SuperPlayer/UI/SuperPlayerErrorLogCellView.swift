//
//  SuperPlayerErrorLogCellView.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 23/11/20.
//

import UIKit

internal class SuperPlayerErrorLogCellView: UITableViewCell {
    private let stackView = UIStackView()

    internal var index: Int?
    internal var log: PlayerItemErrorLog? {
        didSet {
            setupView()
        }
    }

    private func setupView() {
        guard let index = index, let log = log else { return }

        stackView.removeAllSubviews()

        if let url = log.url {
            let label = UILabel()
            label.attributedText = NSAttributedString(attributedString: .body3("[\(index)] \(url.relativePath)", color: .red))
            label.numberOfLines = 4
            label.lineBreakMode = .byTruncatingTail
            stackView.addArrangedSubview(label)
        }

        let errorStatusCode = UILabel()
        errorStatusCode.attributedText = .body3(String("Code: \(log.errorStatusCode)"), color: .red)
        stackView.addArrangedSubview(errorStatusCode)

        if let errorComment = log.errorComment {
            let label = UILabel()
            label.attributedText = .body3("Comment: \(errorComment)", color: .red)
            label.numberOfLines = 4
            label.lineBreakMode = .byTruncatingTail
            stackView.addArrangedSubview(label)
        }
    }

    override internal init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        stackView.axis = .vertical
        stackView.alignment = .fill
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
