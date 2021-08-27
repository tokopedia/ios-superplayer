//
//  SuperPlayerControlView.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 21/10/20.
//

import Combine
import UIKit
import ComposableArchitecture

public final class SuperPlayerControlView: UIView {
    private let store: Store<SuperPlayerControlState, SuperPlayerAction>
    private let viewStore: ViewStore<SuperPlayerControlState, SuperPlayerAction>
    private var disposeBag = Set<AnyCancellable>()

    internal static let height: CGFloat = 32

    private let playButton: UIButton = {
        let node = UIButton()
        node.accessibilityIdentifier = "playPauseButton"
        node.setImage(UIImage(named: "pip_play"), for: .normal)
        
        NSLayoutConstraint.activate([
            node.widthAnchor.constraint(equalToConstant: height / 2)
        ])
//        node.hitTestSlop = UIEdgeInsets(insetsWithInset: -8)
        return node
    }()

    public var playButtonTapped: Effect<Void, Never> {
        return playButton.publisher(for: UIControl.Event.touchUpInside).map { _ in }.eraseToEffect()
    }

    private let seekBar: SuperPlayerSeekBarView
    public var doneSeeking: Publishers.Merge<UIControlPublisher<UIControl>, UIControlPublisher<UIControl>> {
        seekBar.doneSeeking
    }

    private let timeIndicator = UILabel()

    public init(store: Store<SuperPlayerControlState, SuperPlayerAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
        seekBar = SuperPlayerSeekBarView(
            store: store.scope(state: { $0 })
        )

        super.init()
        
        addSubview(playButton)
        addSubview(seekBar)
        addSubview(timeIndicator)
        
        let timeIndicatorWidthConstraint = timeIndicator.widthAnchor.constraint(equalToConstant: 80)
        
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            seekBar.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 4),
            seekBar.trailingAnchor.constraint(equalTo: timeIndicator.leadingAnchor, constant: -4),
            seekBar.centerYAnchor.constraint(equalTo: centerYAnchor),
            timeIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            timeIndicatorWidthConstraint,
            timeIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        viewStore.publisher.playIcon
            .map(UIImage.init(named:))
            .sink { [weak self] image in
                guard let self = self else { return }
                self.playButton.setImage(image, for: .normal)
                self.setNeedsLayout()
            }
            .store(in: &disposeBag)
        
        viewStore.publisher.actualDuration
            .sink { [weak self] actualDuration in
                guard let self = self else { return }

                // need to statically set the time indicator width
                // otherwise the seekBar width will always change
                if actualDuration.seconds >= 3600 {
                    // 00:00:00 / 00:00:00
                    timeIndicatorWidthConstraint.constant = 118
                } else {
                    // 00:00 / 00:00
                    timeIndicatorWidthConstraint.constant = 80
                }

                self.setNeedsLayout()
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(viewStore.publisher.currentTimeLabel, viewStore.publisher.actualDurationLabel)
            .map { currentTimeLabel, actualDuration in
                NSAttributedString .body3(currentTimeLabel + " / " + actualDuration, color: .white)
            }
            .sink { [weak self] currentTimeLabel in
                guard let self = self else { return }
                self.timeIndicator.attributedText = currentTimeLabel
                self.setNeedsLayout()
            }
            .store(in: &disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
