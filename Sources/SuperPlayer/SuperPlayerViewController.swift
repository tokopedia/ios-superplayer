//
//  SuperPlayerViewController.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 17/11/20.
//

import AVKit
import Combine
import CasePaths
import ComposableArchitecture
import UIKit

public class SuperPlayerViewController: UIViewController {
    private var playerDisposeBag = Array<AnyCancellable>()
    private var playerItemDisposeBag = Array<AnyCancellable>()
    private var notificationCenterForPlayerItemDisposeBag = Array<AnyCancellable>()
    private var notificationCenterForLifecycleDisposeBag = Array<AnyCancellable>()
    private var pictureInPictureControllerDisposeBag = Array<AnyCancellable>()
    private var disposeBag = Array<AnyCancellable>()
    private var timeObserverToken: Any?

    private var player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var playerLooper: AVPlayerLooper?
    private let audioSession = AVAudioSession.sharedInstance()
    private var pictureInPictureController: AVPictureInPictureController?

    private let reloadInterval = 1
    private var reloadIntervalTimer: Timer?
    private var reloadIntervalCountdownTimer: Timer?

    private let store: Store<SuperPlayerState, SuperPlayerAction>
    private let viewStore: ViewStore<SuperPlayerState, SuperPlayerAction>
    private var storeSender: (SuperPlayerAction) -> Void {
        { [weak self] action in
            self?.viewStore.send(action)
        }
    }

    public init(
        store: Store<SuperPlayerState, SuperPlayerAction> = Store(
            initialState: SuperPlayerState(),
            reducer: superPlayerReducer,
            environment: SuperPlayerEnvironment.live()
        )
    ) {
        self.store = store
        self.viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)

        bindStore()
        viewStore.send(.begin)

        // set default audio session to be mixed with other audio session outside app
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            try? self?.audioSession.setCategory(AVAudioSession.Category.playback, options: .mixWithOthers)
        }

        view.layer.insertSublayer(playerLayer, at: 0)
        view.isUserInteractionEnabled = false
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }

    private func bindStore() {
        // MARK: SuperPlayerMethod

        viewStore.publisher.videoGravity
            .sink(receiveValue: {  [weak self] videoGravity in
                self?.playerLayer.videoGravity = videoGravity
            })
            .store(in: &disposeBag)

        viewStore.publisher.isLooperEnabled
            .sink(receiveValue: { [weak self] isLooperEnabled in
                guard let self = self else { return }

                if isLooperEnabled {
                    guard let playerItem = self.player.currentItem else { return }
                    self.playerLooper = .init(player: self.player, templateItem: playerItem)
                } else {
                    self.playerLooper?.disableLooping()
                    self.playerLooper = nil
                }
            })
            .store(in: &disposeBag)

        viewStore.publisher.method
            .compactMap(/SuperPlayerMethod.shutOtherAudioApps)
            .sink(receiveValue: { [weak self] in
                try? self?.audioSession.setCategory(AVAudioSession.Category.playback, mode: .default, options: [])
                try? self?.audioSession.setActive(true, options: [])
            })
            .store(in: &disposeBag)

        // MARK: ComposablePlayerState

        viewStore.publisher.player.reasonForWaitingToPlay
            .sink(receiveValue: { [weak self] reasonForWaitingToPlay in
                guard let self = self, self.viewStore.state.isLive else { return }

                self.reloadIntervalTimer?.invalidate()
                self.reloadIntervalCountdownTimer?.invalidate()

                if reasonForWaitingToPlay == .some(.noItemToPlay) {
                    self.viewStore.send(.setReloadCountdown(self.reloadInterval))

                    self.reloadIntervalTimer = Timer.scheduledTimer(
                        timeInterval: .init(self.reloadInterval),
                        target: self,
                        selector: #selector(self.reload),
                        userInfo: nil,
                        repeats: true
                    )

                    #if DEBUG
                        self.reloadIntervalCountdownTimer = Timer.scheduledTimer(
                            timeInterval: .init(1),
                            target: self,
                            selector: #selector(self.decreaseReloadCountdown),
                            userInfo: nil,
                            repeats: true
                        )
                    #endif
                }
            })
            .store(in: &disposeBag)

        viewStore.publisher.player.automaticallyWaitsToMinimizeStalling
            .sink(receiveValue: { [weak self] automaticallyWaitsToMinimizeStalling in
                self?.player.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
            })
            .store(in: &disposeBag)

        viewStore.publisher.player.isMuted
            .sink(receiveValue: { [weak self] isMuted in
                self?.player.isMuted = isMuted
            })
            .store(in: &disposeBag)

        viewStore.publisher.player.volume
            .sink(receiveValue: { [weak self] volume in
                self?.player.volume = volume
            })
            .store(in: &disposeBag)

        // MARK: ComposablePlayerMethod

        viewStore.publisher.player.method
            .sink(receiveValue: { [weak self] method in
                guard let self = self, let method = method else { return }

                switch method {
                case .startObservers:
                    self.startPlayerObservers()

                case let .replaceCurrentItem(with: url):
                    guard let url = url else {
                        self.player.replaceCurrentItem(with: nil)
                        return
                    }

                    let playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
                    self.player.replaceCurrentItem(with: playerItem)

                    /// reassign `preferredForwardBufferDuration` when playerItem is reloaded
                    self.player.currentItem?.preferredForwardBufferDuration = self.viewStore.state.playerItem.preferredForwardBufferDuration

                case .play:
                    self.player.play()

                case .playImmediately:
                    self.player.playImmediately(atRate: 1)

                case .pause:
                    self.player.pause()

                case let .seek(to: requestedTime):
                    self.player.seek(to: requestedTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
            })
            .store(in: &disposeBag)

        // MARK: ComposablePlayerItemState

        viewStore.publisher.playerItem.preferredForwardBufferDuration
            .sink(receiveValue: { [weak self] preferredForwardBufferDuration in
                self?.player.currentItem?.preferredForwardBufferDuration = preferredForwardBufferDuration
            })
            .store(in: &disposeBag)

        // MARK: ComposablePlayerItemMethod

        viewStore.publisher.playerItem.method
            .sink(receiveValue: { [weak self] method in
                guard let method = method else { return }
                switch method {
                case .startObservers:
                    self?.startPlayerItemObservers()
                case .stopObservers:
                    self?.playerItemDisposeBag = Array()
                }
            })
            .store(in: &disposeBag)

        // MARK: ComposableNotificationCenterEvent

        viewStore.publisher.notificationCenter.method
            .sink(receiveValue: { [weak self] event in
                guard let event = event else { return }
                switch event {
                case .startPlayerItemObservers:
                    self?.startNotificationCenterForPlayerItemObservers()
                case .startLifecycleObservers:
                    self?.startNotificationCenterForLifecycleObservers()

                case .stopPlayerItemObservers:
                    self?.notificationCenterForPlayerItemDisposeBag = Array()
                }
            })
            .store(in: &disposeBag)

        // MARK: ComposablePictureInPicture

        viewStore.publisher.pictureInPicture.isEnabled
            .sink(receiveValue: { [weak self] isPictureInPictureEnabled in
                guard let self = self else { return }

                self.pictureInPictureControllerDisposeBag = Array()
                if isPictureInPictureEnabled {
                    guard
                        AVPictureInPictureController.isPictureInPictureSupported(),
                        let pictureInPictureController = AVPictureInPictureController(playerLayer: self.playerLayer)
                    else {
                        self.viewStore.send(.pictureInPicture(.isPossible(false)))
                        return
                    }

                    pictureInPictureController.delegate = self
                    pictureInPictureController.publisher(for: \.isPictureInPicturePossible)
                        .map(ComposablePictureInPictureAction.isPossible)
                        .map(SuperPlayerAction.pictureInPicture)
                        .sink(receiveValue: self.storeSender)
                        .store(in: &self.pictureInPictureControllerDisposeBag)

                    self.pictureInPictureController = pictureInPictureController
                    self.startNotificationCenterForLifecycleObservers()
                } else {
                    self.notificationCenterForLifecycleDisposeBag = Array()
                    self.pictureInPictureController = nil
                }
            })
            .store(in: &disposeBag)

        viewStore.publisher.pictureInPicture.method
            .sink(receiveValue: { [weak self] method in
                guard let method = method else { return }
                switch method {
                case .start:
                    guard
                        let pictureInPictureController = self?.pictureInPictureController,
                        pictureInPictureController.isPictureInPicturePossible
                    else { return }
                    pictureInPictureController.startPictureInPicture()
                case .stop:
                    self?.pictureInPictureController?.stopPictureInPicture()
                }
            })
            .store(in: &disposeBag)
    }

    private func startPlayerObservers() {
        // unsubscribe current running player subsriber if any
        playerDisposeBag = Array()
        player.publisher(for: \.status)
            .map(ComposablePlayerAction.status)
            .map(SuperPlayerAction.player)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerDisposeBag)

        player.publisher(for: \.timeControlStatus)
            .map(ComposablePlayerAction.timeControlStatus)
            .map(SuperPlayerAction.player)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerDisposeBag)

        player.publisher(for: \.reasonForWaitingToPlay)
            .map(ComposablePlayerAction.reasonForWaitingToPlay)
            .map(SuperPlayerAction.player)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerDisposeBag)

        player.publisher(for: \.rate)
            .map(ComposablePlayerAction.rate)
            .map(SuperPlayerAction.player)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerDisposeBag)

        removeTimeObserver()
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: .init(value: 1, timescale: 1), queue: .main) { [weak self] time in
            self?.viewStore.send(.player(.currentTime(time)))
        }
    }

    private func startPlayerItemObservers() {
        guard let playerItem = player.currentItem else {
            playerItemDisposeBag = Array()
            return
        }

        playerItemDisposeBag = Array()
        playerItem.publisher(for: \.duration)
            .map(ComposablePlayerItemAction.duration)
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)

        playerItem.publisher(for: \.loadedTimeRanges)
            .map { ComposablePlayerItemAction.loadedTimeRanges($0.map(\.timeRangeValue)) }
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)

        playerItem.publisher(for: \.tracks)
            .map {
                $0.compactMap { track in
                    guard let assetTrack = track.assetTrack else { return nil }
                    return PlayerItemAssetTrack(
                        mediaType: assetTrack.mediaType,
                        isEnabled: assetTrack.isEnabled,
                        isPlayable: assetTrack.isPlayable,
                        isDecodable: assetTrack.isDecodable,
                        naturalSize: assetTrack.naturalSize
                    )
                }
            }
            .map(ComposablePlayerItemAction.assetTracks)
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)

        playerItem.publisher(for: \.isPlaybackBufferFull)
            .map(ComposablePlayerItemAction.isPlaybackBufferFull)
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)

        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .map(ComposablePlayerItemAction.isPlaybackBufferEmpty)
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)

        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .map(ComposablePlayerItemAction.isPlaybackLikelyToKeepUp)
            .map(SuperPlayerAction.playerItem)
            .sink(receiveValue: self.storeSender)
            .store(in: &playerItemDisposeBag)
    }

    private func startNotificationCenterForPlayerItemObservers() {
        notificationCenterForPlayerItemDisposeBag = Array()
        NotificationCenter.default.publisher(for: .AVPlayerItemNewAccessLogEntry, object: player.currentItem)
            .compactMap { $0.object as? AVPlayerItem }
            .compactMap { $0.accessLog()?.events.last }
            .map(PlayerItemAccessLog.init)
            .map(PlayerItemLog.access)
            .map(ComposableNotificationCenterAction.playerItemLog)
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForPlayerItemDisposeBag)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemNewAccessLogEntry, object: player.currentItem)
            .compactMap { $0.object as? AVPlayerItem }
            .compactMap { $0.errorLog()?.events.last }
            .map(PlayerItemErrorLog.init)
            .map(PlayerItemLog.error)
            .map(ComposableNotificationCenterAction.playerItemLog)
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForPlayerItemDisposeBag)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: player.currentItem)
            .compactMap { $0.object as? AVPlayerItem }
            .map { _ in ComposableNotificationCenterAction.event(.playerItemPlaybackStalled) }
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForPlayerItemDisposeBag)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            .compactMap { $0.object as? AVPlayerItem }
            .map { _ in ComposableNotificationCenterAction.event(.playerItemDidPlayToEndTime) }
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForPlayerItemDisposeBag)
    }

    private func startNotificationCenterForLifecycleObservers() {
        notificationCenterForLifecycleDisposeBag = Array()
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .map { _ in ComposableNotificationCenterAction.event(.didEnterBackgroundNotification) }
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForLifecycleDisposeBag)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .map { _ in ComposableNotificationCenterAction.event(.willEnterForegroundNotification) }
            .map(SuperPlayerAction.notificationCenter)
            .sink(receiveValue: storeSender)
            .store(in: &notificationCenterForLifecycleDisposeBag)
    }

    private func removeTimeObserver() {
        // remove current running time observer if any
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }

    @objc private func reload() {
        guard let url = viewStore.state.currentURL else { return }
        viewStore.send(.load(url, autoPlay: true))
    }

    @objc private func decreaseReloadCountdown() {
        if viewStore.state.reloadCountdown == 1 {
            viewStore.send(.setReloadCountdown(reloadInterval))
        } else {
            viewStore.send(.setReloadCountdown(viewStore.state.reloadCountdown - 1))
        }
    }
}

extension SuperPlayerViewController: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pictureInPicture(.callDelegate(.willStart)))
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pictureInPicture(.callDelegate(.didStart)))
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pictureInPicture(.callDelegate(.willStop)))
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_: AVPictureInPictureController) {
        viewStore.send(.pictureInPicture(.callDelegate(.didStop)))
    }

    public func pictureInPictureController(_: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        viewStore.send(.pictureInPicture(.callDelegate(.restoreUI)))
        completionHandler(true)
    }
}
