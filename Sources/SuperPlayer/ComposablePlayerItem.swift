//
//  ComposablePlayerItem.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 04/10/20.
//

import AVFoundation
import ComposableArchitecture

public enum ComposablePlayerItemMethod: Equatable {
    // MARK: AVPlayerItem methods

    case startObservers
    case stopObservers
}

public struct ComposablePlayerItemState: Equatable {
    public var method: ComposablePlayerItemMethod?

    public var preferredForwardBufferDuration: Double = 0
    public var assetTracks: [PlayerItemAssetTrack] = []
    public var isPlaybackBufferEmpty: Bool = true
    public var isPlaybackBufferFull: Bool = false
    public var isPlaybackLikelyToKeepUp: Bool = false
    public var duration: CMTime = .zero
    public var loadedTimeRanges: [CMTimeRange] = []
}

public enum ComposablePlayerItemAction: Equatable {
    case callMethod(ComposablePlayerItemMethod?)

    // MARK: AVPlayerItem properties

    case preferredForwardBufferDuration(Double)
    case assetTracks([PlayerItemAssetTrack])
    case isPlaybackBufferEmpty(Bool)
    case isPlaybackBufferFull(Bool)
    case isPlaybackLikelyToKeepUp(Bool)
    case duration(CMTime)
    case loadedTimeRanges([CMTimeRange])
}

public let composablePlayerItemReducer = Reducer<ComposablePlayerItemState, ComposablePlayerItemAction, Void> { state, action, _ in
    switch action {
    case let .callMethod(method):
        guard let method = method else {
            state.method = nil
            return .none
        }

        state.method = method
        return Effect(value: .callMethod(nil))
    case let .preferredForwardBufferDuration(preferredForwardBufferDuration):
        state.preferredForwardBufferDuration = preferredForwardBufferDuration
        return .none
    case let .assetTracks(assetTracks):
        state.assetTracks = assetTracks
        return .none
    case let .isPlaybackBufferEmpty(isPlaybackBufferEmpty):
        state.isPlaybackBufferEmpty = isPlaybackBufferEmpty
        return .none
    case let .isPlaybackBufferFull(isPlaybackBufferFull):
        state.isPlaybackBufferFull = isPlaybackBufferFull
        return .none
    case let .isPlaybackLikelyToKeepUp(isPlaybackLikelyToKeepUp):
        state.isPlaybackLikelyToKeepUp = isPlaybackLikelyToKeepUp
        return .none
    case let .duration(duration):
        state.duration = duration
        return .none
    case let .loadedTimeRanges(loadedTimeRanges):
        state.loadedTimeRanges = loadedTimeRanges
        return .none
    }
}

extension TimeInterval {
    internal func stringFromTimeInterval() -> String {
        let time = NSInteger(self)

        let ms = Int(truncatingRemainder(dividingBy: 1) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d", hours, minutes, seconds, ms)
    }
}

extension AVPlayerItem {
    public var url: URL? {
        (asset as? AVURLAsset)?.url
    }
}
