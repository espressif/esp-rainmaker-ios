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
//  ESPLineChartViewProvider.swift
//  ESPRainMaker
//

import Foundation
import SwiftCharts

struct ESPLineChartViewProvider {
    
    var tsArguments: ESPTSArguments
    var lineChartPoints: [ChartPoint]!
    var frame: CGRect
    var timezone: String?
    var view: UIView?
    
    /// Method to get instance of Line Chart object.
    ///
    /// - Returns: `Chart` object with line plotting.
    func lineChart() -> Chart {
        
        // Configure X-Axis for different time duration
        let xModel = ESPTimeAxisGenerator(timeInterval: tsArguments.timeInterval, startTime: Double(tsArguments.duration.startTime), endTime: Double(tsArguments.duration.endTime), label: "", timezone: timezone).getTimeXAxis()
        
        // Prepare Y-Axis using Chart data.
        var yValues:[Double] = []
        for data in lineChartPoints {
            yValues.append(data.y.scalar)
        }
        let yModel = ESPYAxisGenerator(range: (yValues.min() ?? 0,yValues.max() ?? 50)).getYAxis()
        
        // Set Chart properties
        let chartFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height - 100.0)
        var chartSettings = Env.iPad ? ESPChartSettings.iPadChartSettings:ESPChartSettings.iPhoneChartSettings
        // Generate axes layers and calculate chart inner frame, based on the axis models
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
        let lineModel = ChartLineModel(chartPoints: lineChartPoints, lineColors: [AppConstants.shared.getBGColor()], lineWidth: 3, animDuration: 1, animDelay: 0)
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lineModels: [lineModel], pathGenerator: CatmullPathGenerator())
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.black, linesWidth: 0.1)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
        
        // Show data point on line chart in circular view.
        var currentChartPointView: [UIView] = []
        var selectedView: ChartPointTextCircleView?
        let circleViewGenerator = { (chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in

            let (chartPoint, screenLoc) = (chartPointModel.chartPoint, chartPointModel.screenLoc)

            let v = ChartPointTextCircleView(chartPoint: chartPoint, center: screenLoc, diameter: Env.iPad ? 30 : 20, cornerRadius: Env.iPad ? 15: 10, borderWidth: Env.iPad ? 2 : 1, font: UIFont.systemFont(ofSize: 6))
            v.text = String(chartPoint.y.scalar.roundToDecimal(2))
            v.borderColor = .lightGray
            
            v.viewTapped = {view in
                selectedView?.selected = false
                selectedView?.borderColor = .lightGray
                for subView in chart.view.subviews {
                    if subView.isKind(of: InfoBubble.self) {
                        subView.removeFromSuperview()
                    }
                }
                
                let w: CGFloat = Env.iPad ? 250 : 150
                let h: CGFloat = Env.iPad ? 100 : 80
                
                if let chartViewScreenLoc = layer.containerToGlobalScreenLoc(chartPoint) {
                    let x: CGFloat = {
                        let attempt = chartViewScreenLoc.x - (w/2)
                        let leftBound: CGFloat = chart.bounds.origin.x
                        let rightBound = chart.bounds.size.width - 5
                        if attempt < leftBound {
                            return view.frame.origin.x
                        } else if attempt + w > rightBound {
                            return rightBound - w
                        }
                        return attempt
                    }()

                    let frame = CGRect(x: x, y: chartViewScreenLoc.y - (h + (Env.iPad ? 30 : 12)), width: w, height: h)
                    
                    let bubbleView = InfoBubble(point: chartViewScreenLoc, frame: frame, arrowWidth: Env.iPad ? 40 : 28, arrowHeight: Env.iPad ? 20 : 14, bgColor: UIColor.clear, arrowX: chartViewScreenLoc.x - x, arrowY: -1)
                    chart.view.addSubview(bubbleView)
                    
                    bubbleView.transform = CGAffineTransform(scaleX: 0, y: 0).concatenating(CGAffineTransform(translationX: 0, y: 100))
                    let chartPointView = ESPChartPointView.instanceFromNib()
                    chartPointView.valueLabel.textColor = AppConstants.shared.getBGColor()
                    chartPointView.timeLabel.textColor = AppConstants.shared.getBGColor()
                    chartPointView.timeLabel.text = ESPTimeStampInfo(timestamp: chartPoint.x.scalar).timeDescription(aggregate: tsArguments.aggregate, timeInterval: tsArguments.timeInterval)
                    chartPointView.valueLabel.text = "\(chartPoint.y.scalar.roundToDecimal(2))"
                    let infoView = UILabel(frame: CGRect(x: 0, y: 10, width: w, height: h - 30))
                    infoView.textColor = AppConstants.shared.getBGColor()
                    infoView.backgroundColor = UIColor.white
                    infoView.text = "\(chartPoint.y.scalar.roundToDecimal(2))"
                    infoView.font = UIFont.systemFont(ofSize: 10)
                    infoView.textAlignment = NSTextAlignment.center
                    
                    bubbleView.addSubview(chartPointView)
                    currentChartPointView.append(bubbleView)
                    
                    UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions(), animations: {
                        view.selected = true
                        selectedView = view
                        bubbleView.transform = CGAffineTransform.identity
                    }, completion: {finished in})
                }
            }
                
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIView.AnimationOptions(), animations: {
                let w: CGFloat = v.frame.size.width
                let h: CGFloat = v.frame.size.height
                let frame = CGRect(x: screenLoc.x - (w/2), y: screenLoc.y - (h/2), width: w, height: h)
                v.frame = frame
            }, completion: nil)
            
            return v
        }
        
        let chartPointsCircleLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: lineChartPoints, viewGenerator: circleViewGenerator, displayDelay: 0.4, delayBetweenItems: 0.4, mode: .translate)
        
        // Remove point description on tap of chart view area.
        let thumbSettings = ChartPointsLineTrackerLayerThumbSettings(thumbSize: Env.iPad ? 20 : 10, thumbBorderWidth: Env.iPad ? 4 : 2, thumbBorderColor: UIColor.gray)
        let trackerLayerSettings = ChartPointsLineTrackerLayerSettings(thumbSettings: thumbSettings)
        let chartPointsTrackerLayer = ChartPointsLineTrackerLayer<ChartPoint, Any>(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lines: [lineChartPoints], lineColor: UIColor.clear, animDuration: 1, animDelay: 2, settings: trackerLayerSettings, positionUpdateHandler: { chartPointsWithScreenLoc in
            currentChartPointView.forEach{
                selectedView?.selected = false
                selectedView?.borderColor = .lightGray
                $0.removeFromSuperview()}
        })
        
        // Add zoom functionality if aggregate is of Raw type.
        if tsArguments.aggregate == .raw {
            chartSettings.zoomPan.panEnabled = true
            chartSettings.zoomPan.zoomEnabled = true
            chartSettings.zoomPan.maxZoomX = 5.0
            chartSettings.zoomPan.gestureMode = .onlyX
        }
        
        let chart = Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsLineLayer,
                chartPointsTrackerLayer,
                chartPointsCircleLayer
            ]
        )
        return chart
        
    }
}
