//
//  DebugHelper.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 13/11/20.
//

import AVFoundation
import UIKit

public protocol CustomDebugString: CustomDebugStringConvertible {
    var color: UIColor { get }
}

extension AVPlayer.Status: CustomDebugString {
    public var debugDescription: String {
        switch self {
        case .failed:
            return "Failed"
        case .readyToPlay:
            return "Ready To Play"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Undefined"
        }
    }

    public var color: UIColor {
        switch self {
        case .failed:
            return .red
        case .readyToPlay:
            return .green
        case .unknown:
            return .red
        @unknown default:
            return .white
        }
    }
}

extension AVPlayer.TimeControlStatus: CustomDebugString {
    public var debugDescription: String {
        switch self {
        case .paused:
            return "Paused"
        case .playing:
            return "Playing"
        case .waitingToPlayAtSpecifiedRate:
            return "Waiting"
        @unknown default:
            return "Undefined"
        }
    }

    public var color: UIColor {
        switch self {
        case .paused:
            return .white
        case .playing:
            return .green
        case .waitingToPlayAtSpecifiedRate:
            return .yellow
        @unknown default:
            return .white
        }
    }
}

extension AVPlayer.WaitingReason: CustomDebugString {
    public var debugDescription: String {
        switch self {
        case .evaluatingBufferingRate:
            return "Evaluating"
        case .toMinimizeStalls:
            return "Buffering"
        case .noItemToPlay:
            return "No Item"
        default:
            return "Undefined"
        }
    }

    public var color: UIColor {
        switch self {
        case .evaluatingBufferingRate:
            return .yellow
        case .toMinimizeStalls:
            return .yellow
        case .noItemToPlay:
            return .red
        default:
            return .white
        }
    }
}
