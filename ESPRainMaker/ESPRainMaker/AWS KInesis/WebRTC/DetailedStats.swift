// Copyright 2026 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  DetailedStats.swift
//  ESPRainMaker
//

import Foundation

private enum DetailedStatsDefaults {
    static let currentFps: Double = 0
    static let receivedFps: Double = 0
    static let droppedFps: Double = 0
    static let totalFramesDropped: Int64 = 0
    static let totalBytesReceived: Int64 = 0
    static let totalPacketsReceived: Int64 = 0
    static let totalPacketsLost: Int64 = 0
    static let jitterMs: Double = 0
    static let videoCodec = "N/A"
    static let currentFrameWidth: Int = 0
    static let currentFrameHeight: Int = 0
}

struct DetailedStats {
    var currentFps: Double = DetailedStatsDefaults.currentFps
    var receivedFps: Double = DetailedStatsDefaults.receivedFps
    var droppedFps: Double = DetailedStatsDefaults.droppedFps
    var totalFramesDropped: Int64 = DetailedStatsDefaults.totalFramesDropped
    var totalBytesReceived: Int64 = DetailedStatsDefaults.totalBytesReceived
    var totalPacketsReceived: Int64 = DetailedStatsDefaults.totalPacketsReceived
    var totalPacketsLost: Int64 = DetailedStatsDefaults.totalPacketsLost
    var jitterMs: Double = DetailedStatsDefaults.jitterMs
    var videoCodec: String = DetailedStatsDefaults.videoCodec
    var currentFrameWidth: Int = DetailedStatsDefaults.currentFrameWidth
    var currentFrameHeight: Int = DetailedStatsDefaults.currentFrameHeight
}
