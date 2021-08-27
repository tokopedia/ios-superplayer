//
//  ComposablePlayer.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 04/10/20.
//

import AVFoundation
import ComposableArchitecture

public enum ComposablePlayerMethod: Equatable {
    // MARK: AVPlayer methods

    case startObservers
    case replaceCurrentItem(with: URL?)
    case play
    case playImmediately
    case pause
    case seek(to: CMTime)
}

public struct ComposablePlayerState: Equatable {
    public var method: ComposablePlayerMethod? = .none

    public var status: AVPlayer.Status = .unknown
    public var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    public var reasonForWaitingToPlay: AVPlayer.WaitingReason?
    public var rate: Float = .zero
    public var currentTime: CMTime = .zero
    public var automaticallyWaitsToMinimizeStalling: Bool = true
    public var isMuted: Bool = false
    public var volume: Float = 1.0
}

public enum ComposablePlayerAction: Equatable {
    case callMethod(ComposablePlayerMethod?)

    // MARK: AVPlayer properties

    case status(AVPlayer.Status)
    case timeControlStatus(AVPlayer.TimeControlStatus)
    case reasonForWaitingToPlay(AVPlayer.WaitingReason?)
    case rate(Float)
    case currentTime(CMTime)
    case automaticallyWaitsToMinimizeStalling(Bool)
    case isMuted(Bool)
    case volume(Float)
}

public let composablePlayerReducer = Reducer<ComposablePlayerState, ComposablePlayerAction, Void> { state, action, _ in
    switch action {
    // MARK: AVPlayer properties

    case let .callMethod(method):
        guard let method = method else {
            state.method = nil
            return .none
        }
        state.method = method
        return .none
    case let .status(status):
        state.status = status
        return .none
    case let .timeControlStatus(timeControlStatus):
        state.timeControlStatus = timeControlStatus
        return .none
    case let .reasonForWaitingToPlay(reasonForWaitingToPlay):
        state.reasonForWaitingToPlay = reasonForWaitingToPlay
        return .none
    case let .rate(rate):
        state.rate = rate
        return .none
    case let .currentTime(currentTime):
        state.currentTime = currentTime
        return .none
    case let .automaticallyWaitsToMinimizeStalling(automaticallyWaitsToMinimizeStalling):
        state.automaticallyWaitsToMinimizeStalling = automaticallyWaitsToMinimizeStalling
        return .none
    case let .isMuted(isMuted):
        state.isMuted = isMuted
        return .none
    case let .volume(volume):
        state.volume = volume
        return .none
    }
}
