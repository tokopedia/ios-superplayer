//
//  SuperPlayerSeekBarView.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 21/10/20.
//

import UIKit
import Combine
import ComposableArchitecture

internal final class SuperPlayerSeekBarView: UIView {
    private let store: Store<SuperPlayerControlState, SuperPlayerAction>
    private let viewStore: ViewStore<SuperPlayerControlState, SuperPlayerAction>
    private var disposeBag = Set<AnyCancellable>()

    private static var timelineHeight: CGFloat {
        SuperPlayerControlView.height / 8
    }

    private static var seekerRadius: CGFloat {
        SuperPlayerControlView.height / 4
    }

    private static let cornerRadius: CGFloat = 4

    private let barNode: UIView = {
        let node = UIView()
        NSLayoutConstraint.activate([
            node.heightAnchor.constraint(equalToConstant: timelineHeight)
        ])
        node.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        return node
    }()

    private let seekerNode: UIButton = {
        let node = UIButton()
        NSLayoutConstraint.activate([
            node.heightAnchor.constraint(equalToConstant: SuperPlayerControlView.height / 2),
            node.widthAnchor.constraint(equalToConstant: SuperPlayerControlView.height / 2),
        ])
        node.backgroundColor = .white
//        node.hitTestSlop = UIEdgeInsets(insetsWithInset: -8)
        return node
    }()

    internal lazy var doneSeeking = Publishers.Merge(
        seekerNode.publisher(for: UIControl.Event.touchUpInside),
        seekerNode.publisher(for: UIControl.Event.touchUpOutside))

    private let loadedTimeNode: UIView = {
        let node = UIView()
        node.backgroundColor = .white
        NSLayoutConstraint.activate([
            node.heightAnchor.constraint(equalToConstant: timelineHeight)
        ])
        node.layer.cornerRadius = SuperPlayerSeekBarView.cornerRadius
        return node
    }()

    public init(store: Store<SuperPlayerControlState, SuperPlayerAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init()
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: SuperPlayerControlView.height)
        ])
        seekerNode.layer.cornerRadius = SuperPlayerSeekBarView.seekerRadius
        barNode.layer.cornerRadius = SuperPlayerSeekBarView.cornerRadius
        
        addSubview(barNode)
        addSubview(loadedTimeNode)
        addSubview(seekerNode)
        
        let loadedTimeNodeWidthConstraint = loadedTimeNode.widthAnchor.constraint(equalToConstant: 0)
        let seekerPositionConstraint = seekerNode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SuperPlayerSeekBarView.seekerRadius)
        NSLayoutConstraint.activate([
            barNode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            barNode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            barNode.topAnchor.constraint(equalTo: topAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            barNode.bottomAnchor.constraint(equalTo: bottomAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            loadedTimeNode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            loadedTimeNode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            loadedTimeNode.topAnchor.constraint(equalTo: topAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            loadedTimeNode.bottomAnchor.constraint(equalTo: bottomAnchor, constant: SuperPlayerSeekBarView.seekerRadius),
            seekerNode.centerYAnchor.constraint(equalTo: barNode.centerYAnchor),
            seekerPositionConstraint,
        ])
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(pan:)))
        pan.cancelsTouchesInView = false
        seekerNode.addGestureRecognizer(pan)
        barNode.publisher(for: \.frame)
            .compactMap { $0.width }
            .sink { [viewStore] width in
                viewStore.send(.seekBarWidth(width))
            }
            .store(in: &disposeBag)

        viewStore.publisher.loadedTimes
            .sink { [weak self] loadedTimes in
                guard let self = self, let lastLoadedTime = loadedTimes.last else { return }
                loadedTimeNodeWidthConstraint.constant = lastLoadedTime.barOffset + lastLoadedTime.barWidth
                self.setNeedsLayout()
            }
            .store(in: &disposeBag)

        // observing seeker position from currentTime
        viewStore.publisher.seekerPosition
            .sink { [weak self] seekerPosition in
                seekerPositionConstraint.constant = seekerPosition
                self?.setNeedsLayout()
            }
            .store(in: &disposeBag)

        seekerNode.publisher(for: UIControl.Event.touchDown)
            .sink { [viewStore] _ in
                // before we start seeking time, we need to pause the player first
                // common UX used in almost streaming platforms (Youtube, Netflix, Hotstar, etc.)
                viewStore.send(.player(.callMethod(.pause)))
            }
            .store(in: &disposeBag)

        doneSeeking
            .sink { [viewStore] _ in
                viewStore.send(.doneSeeking)
            }
            .store(in: &disposeBag)
    }

    @objc internal func panAction(pan: UIPanGestureRecognizer) {
        let velocity = pan.velocity(in: seekerNode)
        guard abs(velocity.x) > abs(velocity.y) else {
            return
        }

        let point = pan.location(in: barNode)
        if point.x >= 0, point.x <= barNode.frame.width {
            viewStore.send(.slidingSeeker(to: point.x))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
