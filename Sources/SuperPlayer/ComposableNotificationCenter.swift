//
//  ComposableNotificationCenter.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 18/10/20.
//

import ComposableArchitecture

public enum ComposableNotificationCenterMethod: Equatable {
    case startLifecycleObservers
    case startPlayerItemObservers
    case stopPlayerItemObservers
}

public enum ComposableNotificationCenterEvent: Equatable {
    case didEnterBackgroundNotification
    case willEnterForegroundNotification
    case playerItemPlaybackStalled
    case playerItemDidPlayToEndTime
}

public struct ComposableNotificationCenterState: Equatable {
    public var method: ComposableNotificationCenterMethod?
    public var event: ComposableNotificationCenterEvent?
    public var playerItemLogs: [PlayerItemLog] = []
}

public enum ComposableNotificationCenterAction: Equatable {
    case callMethod(ComposableNotificationCenterMethod?)
    case event(ComposableNotificationCenterEvent?)
    case playerItemLog(PlayerItemLog)
}

public let composableNotificationCenterReducer = Reducer<ComposableNotificationCenterState, ComposableNotificationCenterAction, Void> { state, action, _ in

    switch action {
    case let .callMethod(method):
        guard let method = method else {
            state.method = nil
            return .none
        }

        state.method = method
        return Effect(value: .callMethod(nil))

    case let .event(event):
        guard let event = event else {
            state.event = nil
            return .none
        }

        state.event = event
        return Effect(value: .event(nil))

    case let .playerItemLog(playerItemLog):
        state.playerItemLogs.insert(playerItemLog, at: 0)
        return .none
    }
}
