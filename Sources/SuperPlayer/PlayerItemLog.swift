//
//  PlayerItemLog.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 18/10/20.
//

import AVFoundation

public enum PlayerItemLog: Equatable {
    case access(PlayerItemAccessLog)
    case error(PlayerItemErrorLog)
}

public enum PlaybackType: String {
    case vod = "VOD"
    case live = "LIVE"
    case file = "FILE"
}

public struct PlayerItemAccessLog: Equatable {
    public let uri: String?
    public let serverAddress: String?
    public let transferDuration: TimeInterval
    public let numberOfBytesTransferred: Int64
    public let numberOfMediaRequests: Int
    public let playbackSessionID: String?
    public let playbackType: PlaybackType?
    public let numberOfDroppedVideoFrames: Int
    public let numberOfStalls: Int
    public let segmentsDownloadedDuration: TimeInterval
    public let downloadOverdue: Int
    public let switchBitrate: Double
    public let indicatedBitrate: Double
    public let observedBitrate: Double
    public var url: URL? {
        if let uri = uri {
            return URL(string: uri)
        } else {
            return nil
        }
    }

    public init(
        uri: String?,
        serverAddress: String?,
        transferDuration: TimeInterval,
        numberOfBytesTransferred: Int64,
        numberOfMediaRequests: Int,
        playbackSessionID: String?,
        playbackType: String?,
        numberOfDroppedVideoFrames: Int,
        numberOfStalls: Int,
        segmentsDownloadedDuration: TimeInterval,
        downloadOverdue: Int,
        switchBitrate: Double,
        indicatedBitrate: Double,
        observedBitrate: Double
    ) {
        self.uri = uri
        self.serverAddress = serverAddress
        self.transferDuration = transferDuration
        self.numberOfBytesTransferred = numberOfBytesTransferred
        self.numberOfMediaRequests = numberOfMediaRequests
        self.playbackSessionID = playbackSessionID
        self.playbackType = PlaybackType(rawValue: playbackType ?? "")
        self.numberOfDroppedVideoFrames = numberOfDroppedVideoFrames
        self.numberOfStalls = numberOfStalls
        self.segmentsDownloadedDuration = segmentsDownloadedDuration
        self.downloadOverdue = downloadOverdue
        self.switchBitrate = switchBitrate
        self.indicatedBitrate = indicatedBitrate
        self.observedBitrate = observedBitrate
    }

    public init(_ accessLogEvent: AVPlayerItemAccessLogEvent) {
        self.init(
            uri: accessLogEvent.uri,
            serverAddress: accessLogEvent.serverAddress,
            transferDuration: accessLogEvent.transferDuration,
            numberOfBytesTransferred: accessLogEvent.numberOfBytesTransferred,
            numberOfMediaRequests: accessLogEvent.numberOfMediaRequests,
            playbackSessionID: accessLogEvent.playbackSessionID,
            playbackType: accessLogEvent.playbackType,
            numberOfDroppedVideoFrames: accessLogEvent.numberOfDroppedVideoFrames,
            numberOfStalls: accessLogEvent.numberOfStalls,
            segmentsDownloadedDuration: accessLogEvent.segmentsDownloadedDuration,
            downloadOverdue: accessLogEvent.downloadOverdue,
            switchBitrate: accessLogEvent.switchBitrate,
            indicatedBitrate: accessLogEvent.indicatedBitrate,
            observedBitrate: accessLogEvent.observedBitrate
        )
    }
}

public struct PlayerItemErrorLog: Equatable {
    public let uri: String?
    public let serverAddress: String?
    public let playbackSessionID: String?
    public let errorStatusCode: Int
    public let errorDomain: String
    public let errorComment: String?
    public var url: URL? {
        if let uri = uri {
            return URL(string: uri)
        } else {
            return nil
        }
    }

    public init(
        uri: String?,
        serverAddress: String?,
        playbackSessionID: String?,
        errorStatusCode: Int,
        errorDomain: String,
        errorComment: String?
    ) {
        self.uri = uri
        self.serverAddress = serverAddress
        self.playbackSessionID = playbackSessionID
        self.errorStatusCode = errorStatusCode
        self.errorDomain = errorDomain
        self.errorComment = errorComment
    }

    public init(_ errorLogEvent: AVPlayerItemErrorLogEvent) {
        self.init(
            uri: errorLogEvent.uri,
            serverAddress: errorLogEvent.serverAddress,
            playbackSessionID: errorLogEvent.playbackSessionID,
            errorStatusCode: errorLogEvent.errorStatusCode,
            errorDomain: errorLogEvent.errorDomain,
            errorComment: errorLogEvent.errorComment
        )
    }
}
