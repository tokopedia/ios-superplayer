//
//  SuperPlayerAccessLogCellView.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 23/11/20.
//

import UIKit

internal class SuperPlayerAccessLogCellView: UITableViewCell {
    private let stackView = UIStackView()

    internal var index: Int?
    internal var log: PlayerItemAccessLog? {
        didSet {
            setupView()
        }
    }

    private func setupView() {
        guard let index = index, let log = log else { return }

        stackView.removeAllSubviews()

        if let url = log.url {
            let label = UILabel()
            label.attributedText = .body3("[\(index)] \(url.relativePath)", color: .white)
            label.numberOfLines = 4
            label.lineBreakMode = .byTruncatingTail
            stackView.addArrangedSubview(label)
        }

        let numberOfBytesTransferred = UILabel()
        numberOfBytesTransferred.attributedText = .body3("\(log.numberOfBytesTransferred / 1000)KB transferred in \(log.transferDuration.stringFromTimeInterval())", color: .white)
        stackView.addArrangedSubview(numberOfBytesTransferred)

        let segmentsDownloadedDuration = UILabel()
        segmentsDownloadedDuration.attributedText = .body3("Segment duration: \(log.segmentsDownloadedDuration.stringFromTimeInterval())", color: .white)
        stackView.addArrangedSubview(segmentsDownloadedDuration)

        let numberOfDroppedVideoFramesAndStalls = UILabel()
        numberOfDroppedVideoFramesAndStalls.attributedText = .body3("Dropped frames: \(log.numberOfDroppedVideoFrames), Stalls: \(log.numberOfStalls)", color: .white)
        stackView.addArrangedSubview(numberOfDroppedVideoFramesAndStalls)

        let bitRate = UILabel()
        bitRate.attributedText = .body3("Observed bitrate: \(convertBitToMbps(log.observedBitrate)), Indicated bitrate: \(convertBitToMbps(log.indicatedBitrate))", color: .white)
        stackView.addArrangedSubview(bitRate)
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

    private func convertBitToMbps(_ bit: Double) -> String {
        guard bit > 0 else { return "0 Mbps" }
        return String(format: "%.1f Mbps", bit / 1_000_000)
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
