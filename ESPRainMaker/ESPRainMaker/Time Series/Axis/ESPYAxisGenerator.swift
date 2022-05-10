// Copyright 2022 Espressif Systems
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
//  ESPYAxisGenerator.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

// Generates Y-Axis for the chart display.
struct ESPYAxisGenerator {
    // Range of Y-Axis values
    var range: (firstValue: Double, lastValue: Double)
    
    /// Method to get Y-Axis for the Chart display.
    ///
    /// - Returns: ChartAxisModel of SwiftCharts library.
    func getYAxis() -> ChartAxisModel {
        
        let labelSettings = ChartLabelSettings(font: ESPChartSettings.defaultLabel)
        //Let range
        let offsets = calculateMultiplier()
        
        // Generate Y-Axis label
        let generator = ChartAxisGeneratorMultiplier(Double(offsets.multiplier))
        let labelsGenerator = ChartAxisLabelsGeneratorFunc {scalar in
            return ChartAxisLabel(text: "\(Int(scalar))", settings: labelSettings)
        }
        // Generate Y-Axis model
        let yModel = ChartAxisModel(firstModelValue: Double(offsets.firstValue), lastModelValue: Double(offsets.lastValue), axisTitleLabels: [], axisValuesGenerator: generator, labelsGenerator: labelsGenerator)
        
        return yModel
    }
    
    
    /// Method to calucate offsets for Y-axis
    /// - Returns: tuple containing value for first and last point with multiplier.
    func calculateMultiplier() -> (firstValue: Int, lastValue: Int, multiplier:Int) {
        let firstIntegerValue = Int(range.firstValue)
        let lastIntegerValue = Int(range.lastValue)
        let firstModulus = abs(firstIntegerValue%10)
        let lastModulus = abs(lastIntegerValue%10)
        var firstOffset = firstIntegerValue + (firstIntegerValue > 0 ? -firstModulus - 10 :firstModulus - 10)
        let lastOffset = lastIntegerValue + (lastIntegerValue > 0 ? -lastModulus + 10 :lastModulus + 10)
        firstOffset = (range.firstValue > 0 && firstOffset < 0) ? 0: firstOffset
        var multiplier = (lastOffset - firstOffset)/5
        multiplier = (multiplier - multiplier%10) > 0 ? (multiplier - multiplier%10):10
        return (firstValue: firstOffset, lastValue: lastOffset, multiplier:multiplier)
    }
    
}
