//
//  RangeSeekSliderDelegate.swift
//  RangeSeekSlider
//
//  Created by Keisuke Shoji on 2017/03/09.
//
//

import CoreGraphics

public protocol RangeSeekSliderDelegate: AnyObject {
    /// Called when the RangeSeekSlider values are changed
    ///
    /// - Parameters:
    ///   - slider: RangeSeekSlider
    ///   - minValue: minimum value
    ///   - maxValue: maximum value
    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat)

    /// Called when the user has started interacting with the RangeSeekSlider
    ///
    /// - Parameter slider: RangeSeekSlider
    func didStartTouches(in slider: RangeSeekSlider)

    /// Called when the user has finished interacting with the RangeSeekSlider
    ///
    /// - Parameter slider: RangeSeekSlider
    func didEndTouches(in slider: RangeSeekSlider)

    /// Called when the RangeSeekSlider values are changed. A return `String?` Value is displayed on the `minLabel`.
    ///
    /// - Parameters:
    ///   - slider: RangeSeekSlider
    ///   - minValue: minimum value
    /// - Returns: String to be replaced
    func rangeSeekSlider(_ slider: RangeSeekSlider, stringForMinValue minValue: CGFloat) -> String?

    /// Called when the RangeSeekSlider values are changed. A return `String?` Value is displayed on the `maxLabel`.
    ///
    /// - Parameters:
    ///   - slider: RangeSeekSlider
    ///   - maxValue: maximum value
    /// - Returns: String to be replaced
    func rangeSeekSlider(_ slider: RangeSeekSlider, stringForMaxValue: CGFloat) -> String?
}

// MARK: - Default implementation

public extension RangeSeekSliderDelegate {
    func rangeSeekSlider(_: RangeSeekSlider, didChange _: CGFloat, maxValue _: CGFloat) {}
    func didStartTouches(in _: RangeSeekSlider) {}
    func didEndTouches(in _: RangeSeekSlider) {}
    func rangeSeekSlider(_: RangeSeekSlider, stringForMinValue _: CGFloat) -> String? { return nil }
    func rangeSeekSlider(_: RangeSeekSlider, stringForMaxValue _: CGFloat) -> String? { return nil }
}
