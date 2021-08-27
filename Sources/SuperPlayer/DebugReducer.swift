//
//  DebugReducer.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 21/10/20.
//

import ComposableArchitecture

public let debugReducer = Reducer<SuperPlayerState, SuperPlayerAction, SuperPlayerEnvironment> { state, action, _ in
    switch action {
    case let .setReloadCountdown(reloadCountdown):
        state.reloadCountdown = reloadCountdown
        return .none

    case let .player(.reasonForWaitingToPlay(reasonForWaitingToPlay)):

        state.control.loadedTimes = state.control.loadedTimes.map { loadedTime in
            var loadedTime = loadedTime
            loadedTime.timeColor = loadedTime.endValue == state.player.currentTime.readable ? .yellow : .green
            return loadedTime
        }

        return .none

    case let .playerItem(.loadedTimeRanges(loadedTimeRanges)):

        state.control.loadedTimes = zip(
            loadedTimeRanges,
            state.control.loadedTimes
        )
        .map { loadedTimeRange, loadedTime in
            var loadedTime = loadedTime
            loadedTime.startValue = loadedTimeRange.start.readable
            loadedTime.startOffset = min(loadedTime.barOffset, state.control.seekBarWidth - 32)
            loadedTime.endValue = loadedTimeRange.end.readable
            loadedTime.endOffset = min(loadedTime.barOffset + loadedTime.barWidth, state.control.seekBarWidth - 32)
            loadedTime.timeColor = loadedTimeRange.end.seconds == state.player.currentTime.seconds ? .yellow : .green
            return loadedTime
        }

        guard let lastLoadedTimeRange = loadedTimeRanges.last else { return .none }

        if state.isLive {
            state.control.actualDuration = lastLoadedTimeRange.end
            state.control.actualDurationLabel = state.control.actualDuration.readable
        }

        return .none

    case let .playerItem(.assetTracks(assetTracks)):
        state.availableMedia = assetTracks
            .map { assetTrack in

                var type = ""
                switch assetTrack.mediaType {
                case .audio:
                    type = "audio"
                case .closedCaption:
                    type = "closedCaption"
                case .depthData:
                    type = "depthData"
                case .metadata:
                    type = "metadata"
                case .metadataObject:
                    type = "metadataObject"
                case .muxed:
                    type = "muxed"
                case .subtitle:
                    type = "subtitle"
                case .text:
                    type = "text"
                case .timecode:
                    type = "timecode"
                case .video:
                    type = "video"
                default:
                    type = "undefined"
                }

                var mediaInfo = MediaInfo(type: type)
                var error = ""
                if !assetTrack.isEnabled {
                    error = error + ":not_enabled"
                }

                if !assetTrack.isPlayable {
                    error = error + ":not_playable"
                }

                if !assetTrack.isDecodable {
                    error = error + ":not_decodable"
                }

                if !error.isEmpty {
                    mediaInfo.error = error
                }

                return mediaInfo
            }
        return .none
    default:
        return .none
    }
}
