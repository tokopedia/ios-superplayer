//
//  ComposablePictureInPicture.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 08/11/20.
//

import ComposableArchitecture

public enum ComposablePictureInPictureMethod: Equatable {
    case start
    case stop
}

public enum ComposablePictureInPictureDelegate: Equatable {
    case willStart
    case didStart
    case willStop
    case didStop
    case didClose
    case didRestore
    case restoreUI
}

public struct ComposablePictureInPictureState: Equatable {
    public var isEnabled: Bool = false
    public var isPossible: Bool = false
    public var isBeingRestored: Bool = false

    public var method: ComposablePictureInPictureMethod?
    // swiftlint:disable:next weak_delegate
    public var delegate: ComposablePictureInPictureDelegate?
}

public enum ComposablePictureInPictureAction: Equatable {
    case isEnabled(Bool)
    case isPossible(Bool)
    case callMethod(ComposablePictureInPictureMethod)
    case callDelegate(ComposablePictureInPictureDelegate)
}

public let composablePictureInPictureReducer = Reducer<ComposablePictureInPictureState, ComposablePictureInPictureAction, Void> { state, action, _ in
    switch action {
    case let .isEnabled(isEnabled):
        state.isEnabled = isEnabled
        return .none
    case let .isPossible(isPossible):
        state.isPossible = isPossible
        return .none
    case let .callMethod(method):
        state.method = method
        return .none
    case let .callDelegate(delegate):

        /// PiP delegates are not called in consistent orders.
        /// if PiP is stopped by calling stopPictureInPicture(), the delegates are called in this orders: willStop -> restoreUI -> didStop
        /// if PiP is stopped by tapping on restore button, the delegates are called in this orders: restoreUI -> willStop -> didStop
        /// so we need to add `isBeingRestored` flag to determine whether PiP is being restored or closed

        if delegate == .restoreUI {
            state.isBeingRestored = true
            state.delegate = delegate
        } else if delegate == .didStop {
            /// create custom delegates that listen for PiP close or restore button being tapped
            if state.isBeingRestored {
                state.delegate = .didRestore
            } else {
                state.delegate = .didClose
            }

            state.isBeingRestored = false

        } else {
            state.delegate = delegate
        }

        return .none
    }
}
