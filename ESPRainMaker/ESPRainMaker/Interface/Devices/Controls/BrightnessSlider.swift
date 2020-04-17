// Copyright 2020 Espressif Systems
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
//  BrightnessSlider.swift
//  ESPRainMaker
//

import UIKit

class BrightnessSlider: UISlider {
    @IBInspectable open var trackWidth: CGFloat = 2 {
        didSet { setNeedsDisplay() }
    }

    open override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height / 2 - trackWidth / 2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let defaultBounds = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let thumbOffsetToApplyOnEachSide: CGFloat = defaultBounds.size.width / 2.0
        let minOffsetToAdd = -thumbOffsetToApplyOnEachSide
        let maxOffsetToAdd = thumbOffsetToApplyOnEachSide
        let offsetForValue = minOffsetToAdd + (maxOffsetToAdd - minOffsetToAdd) * CGFloat(value / (maximumValue - minimumValue))
        var origin = defaultBounds.origin
        origin.x += offsetForValue
        return CGRect(
            x: origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height / 2 - trackWidth / 2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }
}
