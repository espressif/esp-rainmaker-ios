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
//  ESPBarChartViewProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts
import UIKit

struct ESPBarChartViewProvider {
    var tsArguments: ESPTSArguments
    var frame: CGRect
    var barChartPoints: [ChartPoint]!
    var timezone:String?
    var view: UIView?
    var chart: Chart?
    
    /// Method to get instance of Bar Chart object.
    ///
    /// - Returns: `Chart` object with Bar plotting.
    func barsChart() -> Chart {
        
        // Set Chart properties
        let chartFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height - 100.0)
        
        var chartSettings = Env.iPad ? ESPChartSettings.iPadChartSettings:ESPChartSettings.iPhoneChartSettings
        
        // Configure X-Axis for different time duration
        let xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
        
        // Prepare Y-Axis using Chart data.
        var yValues:[Double] = []
        for data in barChartPoints {
            yValues.append(data.y.scalar)
        }
        let yModel = ESPYAxisGenerator(range: (yValues.min() ?? 0,yValues.max() ?? 50)).getYAxis()

        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
        
        var groups:[ChartPointsBarGroup] = []
        for barChartPoint in barChartPoints {
            let bars = ChartBarModel(constant: ChartAxisValueDouble(Double(barChartPoint.x.scalar)), axisValue1: ChartAxisValue(scalar: 0), axisValue2: barChartPoint.y, bgColor: AppConstants.shared.getBGColor())
            groups.append(ChartPointsBarGroup(constant: ChartAxisValueDouble(Double(barChartPoint.x.scalar)), bars: [bars]))
        }
        
        // Current tapped bar
        var currentSelectedGroupBar: ChartTappedGroupBar?
        // Current chart point view
        var currentDescriptionView: UIView?
        // Handle tap action in Bar chart view
        let barViewSettings = ChartBarViewSettings(animDuration: 0.5, roundedCorners: .allCorners)
        let groupsLayer = ChartGroupedPlainBarsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, groups: groups, horizontal: false, barWidth: self.calculateBarWidth(), barSpacing: 0, groupSpacing: 0, settings: barViewSettings, tapHandler: { tappedGroupBar /*ChartTappedGroupBar*/ in
            currentSelectedGroupBar?.tappedBar.view.backgroundColor = AppConstants.shared.getBGColor()
            currentDescriptionView?.removeFromSuperview()
            currentSelectedGroupBar = tappedGroupBar
            currentSelectedGroupBar?.tappedBar.view.backgroundColor = AppConstants.shared.getBGColor().darker(by: 20.0)
            
            let tappedBarView = tappedGroupBar.tappedBar.view
            let chartPointView = ESPChartPointView.instanceFromNib()
            chartPointView.valueLabel.textColor = AppConstants.shared.getBGColor()
            chartPointView.timeLabel.textColor = AppConstants.shared.getBGColor()
            chartPointView.timeLabel.text = ESPTimeStampInfo(timestamp: tappedGroupBar.tappedBar.model.constant.scalar).timeDescription(aggregate: tsArguments.aggregate, timeInterval: tsArguments.timeInterval)
            chartPointView.valueLabel.text = "\(tappedGroupBar.tappedBar.model.axisValue2.scalar.roundToDecimal(2))"
            tappedBarView.superview?.bringSubviewToFront(tappedBarView)
            currentDescriptionView = chartPointView
            if tappedBarView.frame.minX + chartPointView.frame.width > UIScreen.main.bounds.width {
                chartPointView.frame.origin.x = -(tappedBarView.frame.minX - chartPointView.frame.width)
            }
            tappedBarView.addSubview(chartPointView)
        })
        
        // Remove point description on tap of chart view area.
        let thumbSettings = ChartPointsLineTrackerLayerThumbSettings(thumbSize: Env.iPad ? 20 : 10, thumbBorderWidth: Env.iPad ? 4 : 2, thumbBorderColor: UIColor.gray)
        let trackerLayerSettings = ChartPointsLineTrackerLayerSettings(thumbSettings: thumbSettings)
        // Handle touch on empty area of Bar chart
        let chartPointsTrackerLayer = ChartPointsLineTrackerLayer<ChartPoint, Any>(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lines: [barChartPoints], lineColor: UIColor.clear, animDuration: 1, animDelay: 2, settings: trackerLayerSettings, positionUpdateHandler: { chartPointsWithScreenLoc in
            currentDescriptionView?.removeFromSuperview()
            currentSelectedGroupBar?.tappedBar.view.backgroundColor = AppConstants.shared.getBGColor()
        })
        
        // Add zoom functionality if aggregate is of Raw type.
        if tsArguments.aggregate == .raw {
            chartSettings.zoomPan.panEnabled = true
            chartSettings.zoomPan.zoomEnabled = true
            chartSettings.zoomPan.maxZoomX = 5.0
            chartSettings.zoomPan.gestureMode = .onlyX
        }
        
        return Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsTrackerLayer,
                groupsLayer
            ]
        )
    }
    
    /// Method to calculate width of each Bar in chart.
    ///
    /// - Returns: Width of each Bar in chart.
    private func calculateBarWidth() -> CGFloat {
        
        var barWidth = 20.0
        if Env.iPad {
            barWidth = 25.0
        }
        
        let chartWidth = frame.width - 100.0
        
        switch tsArguments.timeInterval {
            case .hour:
                barWidth = min(chartWidth/CGFloat(barChartPoints.count), chartWidth/24.0)
            case .day:
                barWidth = min(chartWidth/CGFloat(barChartPoints.count), 20.0)
            case .month:
            barWidth = min(chartWidth/CGFloat(barChartPoints.count), chartWidth/14.0)
           default:
                break
        }
        return barWidth
    }
}
