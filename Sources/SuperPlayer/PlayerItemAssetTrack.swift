//
//  PlayerItemAssetTrack.swift
//  SuperPlayer_SuperPlayer
//
//  Created by Adityo Rancaka on 14/10/20.
//

import AVFoundation

public struct PlayerItemAssetTrack: Equatable {
    public var mediaType: AVMediaType
    public var isEnabled: Bool
    public var isPlayable: Bool
    public var isDecodable: Bool
    public var naturalSize: CGSize
}
