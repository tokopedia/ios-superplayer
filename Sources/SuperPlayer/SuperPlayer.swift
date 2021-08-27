//
//  SuperPlayer.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 14/10/20.
//

import AVFoundation
import AVKit
import Combine
import ComposableArchitecture
import UIKit

public enum SuperPlayerMethod: Equatable {
    case shutOtherAudioApps
}

public struct SuperPlayerState: Equatable {
    public var method: SuperPlayerMethod?

    public var currentURL: URL?
    public var isLive: Bool = false
    public var availableMedia: [MediaInfo] = []
    public var playbackTimeRange: CMTimeRange?
    public var retryCount: Int = 0 // TODO: remove this if retry algorithm works as expected
    public var reloadCountdown: Int = 0
    public var numberOfStalls: Int = 0

    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    public var isLooperEnabled: Bool = false
    public var isPictureInPictureMode: Bool = false

    public var control = SuperPlayerControlState()
    public var player = ComposablePlayerState()
    public var playerItem = ComposablePlayerItemState()
    public var notificationCenter = ComposableNotificationCenterState()
    public var pictureInPicture = ComposablePictureInPictureState()

    public init() {}
}

public struct SuperPlayerControlState: Equatable {
    public var actualDuration: CMTime = .zero
    public var actualDurationLabel = "00:00"
    public var currentTimeLabel = "00:00"
    public var remainingTimeLabel = "00:00"
    public var loadedTimes: [LoadedTime] = []
    public var seekBarWidth: CGFloat = 0
    public var seekerPosition: CGFloat = 0
    public var playIcon = "pip_play"
}

public enum SuperPlayerAction: Equatable {
    case callMethod(SuperPlayerMethod?)

    case begin
    case resetPlayerItem(URL)
    case load(URL, autoPlay: Bool)
    case unload
    case end
    case seekBarWidth(CGFloat)
    case backward(by: Int64)
    case forward(by: Int64)
    case slidingSeeker(to: CGFloat)
    case doneSeeking
    case playbackTimeRange(CMTimeRange?)
    case checkResource(URL)
    case setReloadCountdown(Int)

    case videoGravity(AVLayerVideoGravity)
    case isLooperEnabled(Bool)
    case isPictureInPictureMode(Bool)

    case player(ComposablePlayerAction)
    case playerItem(ComposablePlayerItemAction)
    case notificationCenter(ComposableNotificationCenterAction)
    case pictureInPicture(ComposablePictureInPictureAction)
}

public struct SuperPlayerEnvironment {
    internal typealias HTTPStatusCode = Int

    internal var scheduler: AnySchedulerOf<DispatchQueue>

    // MARK: 404 error utilities

    internal var checkResource: (URL) -> Effect<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>
    internal var maximumRetryCount: Int // TODO: remove this if retry algorithm works as expected
    internal var reloadInterval: Int
}

extension SuperPlayerEnvironment {
    public static var live = {
        SuperPlayerEnvironment(
            scheduler: .main,
            checkResource: { url in
                URLSession.shared.dataTaskPublisher(for: url)
                    .eraseToEffect()
            },
            maximumRetryCount: 90,
            reloadInterval: 15
        )
    }
}

public var superPlayerReducer: Reducer<SuperPlayerState, SuperPlayerAction, SuperPlayerEnvironment> = .combine(
    Reducer { state, action, environment in

        struct PlaybackTimeRangeCancelID: Hashable {}

        switch action {
        case let .callMethod(method):
            state.method = method
            return .none

        case .begin:

            return Effect(value: .player(.callMethod(.startObservers)))

        case let .resetPlayerItem(url):

            // reset playerItem state everytime it's reloaded
            state.currentURL = url
            state.playerItem = ComposablePlayerItemState()
            state.retryCount = 0 // reset retry count if any

            return .merge(
                Effect(value: .playerItem(.callMethod(.startObservers))),
                Effect(value: .notificationCenter(.callMethod(.startPlayerItemObservers)))
            )

        case let .load(url, autoPlay):

            var actions: [Effect<SuperPlayerAction, Never>] = [
                Effect(value: .player(.callMethod(.replaceCurrentItem(with: url)))),
                Effect(value: .resetPlayerItem(url))
            ]

            if autoPlay {
                actions.append(Effect(value: .player(.callMethod(.play))))
            } else {
                actions.append(Effect(value: .player(.callMethod(.pause))))
            }

            return .merge(actions)

        case .unload:

            state.currentURL = nil
            return .merge(
                Effect(value: .player(.callMethod(.replaceCurrentItem(with: nil)))),
                Effect(value: .playerItem(.callMethod(.stopObservers))),
                Effect(value: .notificationCenter(.callMethod(.stopPlayerItemObservers)))
            )

        case .end:
            state.retryCount = 0
            return .none

        case let .seekBarWidth(seekBarWidth):

            state.control.seekBarWidth = seekBarWidth

            // recalculate seekBar views everytime seekBar width is changed. e.g: when rotate screen to horizontal
            return .merge(
                Effect(value: .player(.currentTime(state.player.currentTime))),
                Effect(value: .playerItem(.loadedTimeRanges(state.playerItem.loadedTimeRanges)))
            )

        case let .backward(seconds):

            let requestedTime = max(state.player.currentTime - CMTimeMake(value: seconds, timescale: 1), .zero)

            return .merge(
                Effect(value: .player(.currentTime(requestedTime))),
                Effect(value: .player(.callMethod(.seek(to: requestedTime))))
            )

        case let .forward(seconds):

            let requestedTime = min(state.player.currentTime + CMTimeMake(value: seconds, timescale: 1), state.playerItem.duration)

            return .merge(
                Effect(value: .player(.currentTime(requestedTime))),
                Effect(value: .player(.callMethod(.seek(to: requestedTime))))
            )

        case let .slidingSeeker(position):

            let requestedSeconds = Double(position / state.control.seekBarWidth) * state.playerItem.duration.seconds
            let requestedTime = CMTimeMake(
                value: Int64(max(0, min(requestedSeconds, state.playerItem.duration.seconds))),
                timescale: 1
            )

            return Effect(value: .player(.currentTime(requestedTime)))

        case .doneSeeking:

            return .merge(
                Effect(value: .player(.callMethod(.seek(to: state.player.currentTime)))),
                Effect(value: .player(.callMethod(.play)))
            )

        case let .playbackTimeRange(playbackTimeRange):
            state.playbackTimeRange = playbackTimeRange
            return .cancel(id: PlaybackTimeRangeCancelID())

//        case let .notificationCenter(.playerItemLog(playerItemLog)):
//
//            if case let .error(error) = playerItemLog {
//                guard
//                    state.retryCount == 0, // need to check there is no checkResource is running
//                    let url = error.url,
//                    let errorComment = error.errorComment,
//                    errorComment.contains("404")
//                else { return .none }
//
//                return Effect(.just(.checkResource(url)))
//            }
//
//            return .none
//
//        case let .checkResource(url):
//
//            state.retryCount += 1
//            guard state.retryCount <= environment.maximumRetryCount, let currentURL = state.currentURL else { return Effect(value: .end) }
//
//            return environment
//                .checkResource(url)
//                .flatMapLatest { [environment] result -> Effect<SuperPlayerAction> in
//
//                    switch result {
//                    case let .success(statusCode):
//
//                        if statusCode >= 200, statusCode < 300 {
//                            return Effect(.just(.load(currentURL, autoPlay: true)))
//                                /*
//                                 need to set a delay before reloading item to wait for the live playback has enough buffer to stream
//                                 otherwise the player will stall and dead
//                                 */
//                                .delay(.seconds(15), scheduler: environment.scheduler)
//                                .eraseToEffect()
//
//                        } else if statusCode >= 400, statusCode < 500 {
//                            return Effect(.just(.checkResource(url)))
//                                .delay(.seconds(environment.reloadInterval), scheduler: environment.scheduler)
//                                .eraseToEffect()
//                        }
//
//                    case let .failure(error):
//
//                        let retryableErrors: [URLError.Code] = [
//                            .notConnectedToInternet,
//                            .networkConnectionLost,
//                            .cannotConnectToHost,
//                            .timedOut
//                        ]
//
//                        if retryableErrors.contains(error.code) {
//                            return Effect(.just(.checkResource(url)))
//                                .delay(.seconds(environment.reloadInterval), scheduler: environment.scheduler)
//                                .eraseToEffect()
//                        }
//                    }
//
//                    return Effect(.just(.end))
//                }
//                .eraseToEffect()

        case let .player(.rate(rate)):
            state.control.playIcon = rate > 0 ? "pip_pause" : "pip_play"
            return .none

        case let .playerItem(.duration(duration)):
            // initialize duration
            state.isLive = duration.isIndefinite
            state.control.actualDuration = state.isLive ? .zero : duration
            state.control.actualDurationLabel = state.control.actualDuration.readable
            return .none

        case let .player(.currentTime(currentTime)):
            // set current time label & seeker position
            state.control.currentTimeLabel = currentTime.readable
            state.control.remainingTimeLabel = CMTime(
                seconds: state.control.actualDuration.seconds - currentTime.seconds,
                preferredTimescale: 1
            ).readable
            state.control.seekerPosition = state.control.seekBarWidth * CGFloat(currentTime.seconds / max(state.control.actualDuration.seconds, 1))
            return .none

        case let .playerItem(.loadedTimeRanges(loadedTimeRanges)):
            /*
                 ComposablePlayerItemAction.loadedTimeRanges play an important role in SuperPlayer.
                 Many business and UI logic are constructed based on observing this value such as:
                 1. Displaying information in SeekBar UI
                 2. Play Immediately when player has sufficient buffer to play
                 3. Schedule automatic pause playback and stop buffer when playbackTimeRange.end has been loaded
             */

            // MARK: Setup loadedTimes. This state is used to calculate seekBar UI

            state.control.loadedTimes = loadedTimeRanges.map {
                if state.isLive {
                    return LoadedTime(
                        barWidth: state.control.seekBarWidth,
                        barOffset: 0
                    )
                }

                return LoadedTime(
                    barWidth: state.control.seekBarWidth * CGFloat($0.duration.seconds / max(state.control.actualDuration.seconds, 1)),
                    barOffset: state.control.seekBarWidth * CGFloat($0.start.seconds / max(state.control.actualDuration.seconds, 1))
                )
            }

            guard let lastLoadedTimeRange = loadedTimeRanges.last else { return .none }
            var effects: [Effect<SuperPlayerAction, Never>] = []

            // MARK: Play Immediately when player has sufficient buffer to play

            /*
                 playerHasSufficientBufferToPlay:
                 if system has loaded 3 seconds of content
             */
            let playerHasSufficientBufferToPlay = (lastLoadedTimeRange.end.seconds - state.player.currentTime.seconds) >= 3
            if playerHasSufficientBufferToPlay, state.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                effects.append(Effect(value: .player(.callMethod(.playImmediately))))
            }

            // MARK: Schedule automatic pause playback and stop buffer when playbackTimeRange.end has been loaded

            /*
             When loaded duration has reach playbackTimeRange.end,
             player needs to stop loading more data from the API,
             and immediately pause the playback when it has reached the specified playbackTimeRange.end

             - set automaticallyWaitsToMinimizeStalling to false would give us full control to currently playing item
             - set preferredForwardBufferDuration to 1 is basically scalling down the buffer used to fetch the Asset from API
             */
            if let playbackTimeRange = state.playbackTimeRange,
                playbackTimeRange.end.seconds <= lastLoadedTimeRange.end.seconds {
                let previousPreferredForwardBufferDuration = state.playerItem.preferredForwardBufferDuration
                effects.append(Effect(value: .player(.automaticallyWaitsToMinimizeStalling(false))))
                effects.append(Effect(value: .playerItem(.preferredForwardBufferDuration(1))))

                /*
                 remainingSecondsUntilPause:
                 when you set playbackTimeRange this way
                    CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), end: CMTime(seconds: 20, preferredTimescale: 1))
                 means you have playbackTimeRange.end.seconds of 20.
                 When loadedDuration reaches 23, in addition to stop the buffer, we also need to calculate how long until we can actually pause the playback.
                 The correct way to do it would be subtracting the total duration of playbackTimeRange (20) with the current playback time (let's say 15),
                 that way we can automatically pause the playback in 5 seconds.
                 */
                let remainingSecondsUntilPause = Int(playbackTimeRange.end.seconds - state.player.currentTime.seconds)
                effects.append(
                    Effect<SuperPlayerAction, Never>.merge(
                        Effect(value: .player(.callMethod(.pause))),
                        Effect(value: .player(.automaticallyWaitsToMinimizeStalling(true))),
                        Effect(value: .playerItem(.preferredForwardBufferDuration(previousPreferredForwardBufferDuration))),
                        Effect(value: .playbackTimeRange(nil))
                    )
                    .delay(for: .seconds(remainingSecondsUntilPause), scheduler: environment.scheduler)
                    .eraseToEffect()
                    .cancellable(id: PlaybackTimeRangeCancelID(), cancelInFlight: true)
                )
            }

            return .merge(effects)

        case .notificationCenter(.event(.playerItemPlaybackStalled)):
            state.numberOfStalls += 1
            return .none

        case .notificationCenter(.event(.playerItemDidPlayToEndTime)):

            // if not live stream, go back to first frame to be able to replay
            if !state.isLive, let currentURL = state.currentURL {
                return Effect(value: .load(currentURL, autoPlay: false))
                    .delay(for: .milliseconds(500), scheduler: environment.scheduler)
                    .eraseToEffect()
            }

            return .none

        case let .videoGravity(videoGravity):
            state.videoGravity = videoGravity
            return .none
        case let .isLooperEnabled(isLooperEnabled):
            state.isLooperEnabled = isLooperEnabled
            return .none

        case let .isPictureInPictureMode(isPictureInPictureMode):
            state.isPictureInPictureMode = isPictureInPictureMode

            if isPictureInPictureMode, state.pictureInPicture.isPossible {
                return Effect(value: .pictureInPicture(.callMethod(.start)))
            } else {
                return Effect(value: .pictureInPicture(.callMethod(.stop)))
            }

        case let .pictureInPicture(.callDelegate(delegate)):

            if delegate == .didStart {
                return Effect(value: .player(.callMethod(.play)))
            }

            if delegate == .restoreUI {
                return Effect(value: .pictureInPicture(.callMethod(.stop)))
            }

            return .none

        default:
            return .none
        }

    },
    debugReducer,
    composablePlayerItemReducer.pullback(
        state: \.playerItem,
        action: /SuperPlayerAction.playerItem,
        environment: { _ in () }
    ),
    composablePlayerReducer.pullback(
        state: \.player,
        action: /SuperPlayerAction.player,
        environment: { _ in () }
    ),
    composableNotificationCenterReducer.pullback(
        state: \.notificationCenter,
        action: /SuperPlayerAction.notificationCenter,
        environment: { _ in () }
    ),
    composablePictureInPictureReducer.pullback(
        state: \.pictureInPicture,
        action: /SuperPlayerAction.pictureInPicture,
        environment: { _ in () }
    )
)

public struct MediaInfo: Equatable {
    public let type: String
    public var error: String?
}

extension CMTime {
    public var readable: String {
        if self == .indefinite { return "∞" }
        let totalSeconds = Int(CMTimeGetSeconds(self))
        let hours: Int = Int(totalSeconds / 3600)
        let minutes: Int = Int(totalSeconds % 3600 / 60)
        let seconds: Int = Int((totalSeconds % 3600) % 60)

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}

public struct LoadedTime: Equatable {
    public var barWidth: CGFloat
    public var barOffset: CGFloat
    public var startValue: String = ""
    public var startOffset: CGFloat = 0
    public var endValue: String = ""
    public var endOffset: CGFloat = 0
    public var timeColor: UIColor = .clear
}
