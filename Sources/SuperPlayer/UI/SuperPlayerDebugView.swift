//
//  SuperPlayerDebugView.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 10/11/20.
//

import Combine
import ComposableArchitecture
import UIKit

public final class SuperPlayerDebugView: UIView {
    private var currentURL: Publishers.CompactMap<StorePublisher<URL?>, String> {
        viewStore.publisher.currentURL.compactMap { $0?.absoluteString }
    }

    private let closeButton: UIButton = {
        let button = UIButton()
        let icon = UIImage(named: "inAppClose")
        button.setImage(icon?.resizedImage(to: .init(squareWithSize: 16)), for: .normal)
        return button
    }()

    public var didCloseDebugView: (() -> Void)?

    private let playbackTypeAndURLLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let statusLabel = UILabel()
    private let timeControlStatusLabel = UILabel()
    private let waitingReasonLabel = UILabel()
    private let reloadCountdownLabel = UILabel()
    private let loadedTimesLabel = UILabel()
    private let currentTimeAndDurationLabel = UILabel()
    private let bufferStatusLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("Playback Buffer Status:", color: .white, isBold: true)
        return label
    }()

    private let bufferEmptyLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("Buffer Empty", color: .white)
        return label
    }()

    private let bufferFullLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("Buffer Full", color: .white)
        return label
    }()

    private let likelyToKeepUpLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("Likely To Keep Up", color: .white)
        return label
    }()

    private lazy var bufferStatusStack: UIStackView = {
        let view = UIStackView(
            arrangedSubviews: [UIView(), bufferEmptyLabel, bufferFullLabel, likelyToKeepUpLabel, UIView()]
        )
        view.axis = .horizontal
        view.distribution = .equalSpacing
        return view
    }()

    private let availableMediaLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("Available Media:", color: .white, isBold: true)
        return label
    }()

    private let noAvailableMediaLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .body3("No available media", color: .red)
        return label
    }()

    private let availableMediaStack: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .equalSpacing
        return view
    }()

    private lazy var mainStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [playbackTypeAndURLLabel, statusLabel, timeControlStatusLabel, loadedTimesLabel, currentTimeAndDurationLabel, bufferStatusLabel, bufferStatusStack, availableMediaLabel])
        view.axis = .vertical
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.clipsToBounds = true
        tableView.register(SuperPlayerAccessLogCellView.self, forCellReuseIdentifier: accessCellID)
        tableView.register(SuperPlayerErrorLogCellView.self, forCellReuseIdentifier: errorCellID)
        tableView.allowsSelection = false
        return tableView
    }()

    private let accessCellID = "SuperPlayerAccessLogCellNode"
    private let errorCellID = "SuperPlayerErrorLogCellNode"

    private let store: Store<SuperPlayerState, SuperPlayerAction>
    private let viewStore: ViewStore<SuperPlayerState, SuperPlayerAction>
    private var disposeBag = Set<AnyCancellable>()

    public init(store: Store<SuperPlayerState, SuperPlayerAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init(frame: .zero)

        backgroundColor = .black
        alpha = 0.75
        tableView.backgroundColor = .clear

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setupView()
            self.bindStore()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
    }

    private func setupView() {
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        closeButton.publisher(for: UIControl.Event.touchUpInside)
            .sink { [weak self] _ in
                self?.didCloseDebugView?()
            }
            .store(in: &disposeBag)

        addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true

        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: mainStackView.bottomAnchor, constant: 8).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 16).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.tableFooterView = UIView()
        
        playbackTypeAndURLLabel.isUserInteractionEnabled = true
        playbackTypeAndURLLabel.gesture(.tap())
            .filter { $0.get().state == .ended }
            .combineLatest(currentURL)
            .sink { currentURL in
                UIPasteboard.general.string = currentURL.1
            }
            .store(in: &disposeBag)
    }

    private func bindStore() {
        
        Publishers.CombineLatest(
            viewStore.publisher.notificationCenter.playerItemLogs.compactMap { $0.first }
                .compactMap { playerItemLog -> PlaybackType? in
                    guard case let .access(log) = playerItemLog else { return nil }
                    return log.playbackType
                },
            currentURL
        )
        .map { playbackType, url in
            let playbackTypeAndURL = NSMutableAttributedString(attributedString: .body3("[\(playbackType.rawValue)] \(url)", color: .white))

            if let copyIcon = UIImage(named: "icon-copy-grey") {
                let attachment = NSTextAttachment()
                attachment.image = copyIcon
                attachment.bounds = .init(x: 0, y: 0, width: 12, height: 12)
                playbackTypeAndURL.append(.body3(" "))
                playbackTypeAndURL.append(NSAttributedString(attachment: attachment))
            }

            return playbackTypeAndURL
        }
        .sink(receiveValue: { [weak self] attributedText in
            self?.playbackTypeAndURLLabel.attributedText = attributedText
        })
        .store(in: &disposeBag)
        
        viewStore.publisher.player.status
            .map(createDebugRow(label: "Status"))
            .sink(receiveValue: { [weak self] attributedText in
                self?.statusLabel.attributedText = attributedText
            })
            .store(in: &disposeBag)
        
        viewStore.publisher.player.timeControlStatus
            .map(createDebugRow(label: "Time Control Status"))
            .sink(receiveValue: { [weak self] attributedText in
                self?.timeControlStatusLabel.attributedText = attributedText
            })
            .store(in: &disposeBag)

        viewStore.publisher.player.reasonForWaitingToPlay
            .sink { [weak self] reasonForWaitingToPlay in
                guard let self = self else { return }
                if
                    let _reasonForWaitingToPlay = reasonForWaitingToPlay,
                    let timeControlStatusLabelIndex = self.mainStackView.arrangedSubviews.firstIndex(where: { $0 == self.timeControlStatusLabel }) {
                    self.waitingReasonLabel.removeFromSuperview()
                    self.reloadCountdownLabel.removeFromSuperview()

                    self.mainStackView.insertArrangedSubview(self.waitingReasonLabel, at: timeControlStatusLabelIndex + 1)
                    if _reasonForWaitingToPlay == .noItemToPlay {
                        self.mainStackView.insertArrangedSubview(self.reloadCountdownLabel, at: timeControlStatusLabelIndex + 2)
                    }
                } else {
                    self.waitingReasonLabel.removeFromSuperview()
                    self.reloadCountdownLabel.removeFromSuperview()
                }
                self.layoutIfNeeded()
                
                guard let waitingReason = reasonForWaitingToPlay else { return }
                self.waitingReasonLabel.attributedText = self.createDebugRow(label: "Waiting Reason")(waitingReason)
            }
            .store(in: &disposeBag)

        viewStore.publisher.reloadCountdown
            .map { reloadCountdown -> NSAttributedString in
                let label = NSMutableAttributedString(attributedString: .body3("Reload In: ", color: .white, isBold: true))
                label.append(NSAttributedString.body3("\(reloadCountdown)s", color: .yellow))
                return label
            }
            .sink { [weak self] attributedText in
                self?.reloadCountdownLabel.attributedText = attributedText
            }
            .store(in: &disposeBag)

        viewStore.publisher.control.loadedTimes
            .compactMap { $0.last }
            .map { lastLoadedTime -> NSAttributedString in
                let label = NSMutableAttributedString(attributedString: .body3("Loaded Times: ", color: .white, isBold: true))
                label.append(NSAttributedString.body3("\(lastLoadedTime.startValue) - \(lastLoadedTime.endValue)", color: lastLoadedTime.timeColor))
                return label
            }
            .sink { [weak self] attributedText in
                self?.loadedTimesLabel.attributedText = attributedText
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(viewStore.publisher.control.currentTimeLabel, viewStore.publisher.control.actualDurationLabel)
            .map { (currentTime, duration) -> NSAttributedString in
                let label = NSMutableAttributedString(attributedString: .body3("Current Time / Duration: ", color: .white, isBold: true))
                label.append(NSAttributedString.body3("\(currentTime) / \(duration)", color: .white))
                return label
            }
            .sink { [weak self] attributedText in
                self?.currentTimeAndDurationLabel.attributedText = attributedText
            }
            .store(in: &disposeBag)

        viewStore.publisher.playerItem.isPlaybackBufferEmpty
            .map { $0 ? 1 : 0.5 }
            .sink(receiveValue: { [weak self] alpha in
                self?.bufferEmptyLabel.alpha = alpha
            })
            .store(in: &disposeBag)

        viewStore.publisher.playerItem.isPlaybackBufferFull
            .map { $0 ? 1 : 0.5 }
            .sink(receiveValue: { [weak self] alpha in
                self?.bufferFullLabel.alpha = alpha
            })
            .store(in: &disposeBag)

        viewStore.publisher.playerItem.isPlaybackLikelyToKeepUp
            .map { $0 ? 1 : 0.5 }
            .sink(receiveValue: { [weak self] alpha in
                self?.likelyToKeepUpLabel.alpha = alpha
            })
            .store(in: &disposeBag)

        viewStore.publisher.availableMedia
            .map {
                $0.map { availableMedia -> NSAttributedString in

                    let mediaType = NSMutableAttributedString(attributedString: .body3(availableMedia.type, color: .white))
                    if let errorString = availableMedia.error {
                        mediaType.append(.body3(errorString, color: .white))
                    }

                    return mediaType
                }
            }
            .sink { [weak self] availableMedia in
                guard
                    let self = self,
                    let availableMediaLabelIndex = self.mainStackView.arrangedSubviews.firstIndex(where: { $0 == self.availableMediaLabel })
                else { return }

                self.availableMediaStack.removeAllSubviews()
                self.availableMediaStack.removeFromSuperview()
                self.noAvailableMediaLabel.removeFromSuperview()

                if availableMedia.count > 0 {
                    self.availableMediaStack.addArrangedSubview(UIView())
                    availableMedia.forEach { attributedText in
                        let label = UILabel()
                        label.attributedText = attributedText
                        self.availableMediaStack.addArrangedSubview(label)
                    }
                    self.availableMediaStack.addArrangedSubview(UIView())
                    self.mainStackView.insertArrangedSubview(self.availableMediaStack, at: availableMediaLabelIndex + 1)
                } else {
                    self.mainStackView.insertArrangedSubview(self.noAvailableMediaLabel, at: availableMediaLabelIndex + 1)
                }
            }
            .store(in: &disposeBag)

        viewStore.publisher.notificationCenter.playerItemLogs
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &disposeBag)
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createDebugRow<Value: CustomDebugString>(label: String) -> (Value) -> NSAttributedString {
        return { value in

            let label = NSMutableAttributedString(attributedString: .body3("\(label): ", color: .white, isBold: true))
            let value = NSAttributedString.body3("\(value)", color: value.color)
            label.append(value)

            return label
        }
    }
}

extension SuperPlayerDebugView: UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewStore.state.notificationCenter.playerItemLogs.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewStore.state.notificationCenter.playerItemLogs[indexPath.row] {
        case let .access(log):
            guard let cellView = tableView.dequeueReusableCell(withIdentifier: accessCellID, for: indexPath) as? SuperPlayerAccessLogCellView else {
                return UITableViewCell()
            }
            cellView.index = viewStore.state.notificationCenter.playerItemLogs.count - indexPath.row
            cellView.log = log
            return cellView
        case let .error(log):
            guard let cellView = tableView.dequeueReusableCell(withIdentifier: errorCellID, for: indexPath) as? SuperPlayerErrorLogCellView else {
                return UITableViewCell()
            }
            cellView.index = viewStore.state.notificationCenter.playerItemLogs.count - indexPath.row
            cellView.log = log
            return cellView
        }
    }
}
