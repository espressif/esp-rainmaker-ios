// Copyright 2023 Espressif Systems
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
//  ParamSliderTableViewCell+ParamSliderColorControlProtocol.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation
import UIKit
import Matter

@available(iOS 16.4, *)
protocol ParamSliderColorControlProtocol {
    func setupInitialHueValues()
    func setCurrentHueValue()
    func getColorController(timeout: TimeInterval, completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void)
    func getCurrentHueValue(completionHandler: @escaping (NSNumber?, Error?) -> Void)
    func changeHue(toValue _: CGFloat)
}

@available(iOS 16.4, *)
extension ParamSliderTableViewCell: ParamSliderColorControlProtocol {
    
    func setupInitialHueValues() {
        DispatchQueue.main.async {
            self.title.text = "Hue"
            self.hueSlider.minimumValue = 0.0
            self.hueSlider.maximumValue = 254.0
            self.hueSlider.hasRainbow = false
            self.hueSlider.setGradientVaryingHue(saturation: 1.0, brightness: 1.0)
            self.minLabel.text = "0"
            self.maxLabel.text = "254"
            self.hueSlider.value = 0.0
            self.minImage.image = UIImage(named: "saturation_low")
            self.maxImage.image = UIImage(named: "saturation_high")
        }
    }
    
    func setCurrentHueValue() {
        self.getCurrentHueValue() { hue, error in
            DispatchQueue.main.async {
                if let hue = hue {
                    self.currentHueValue = CGFloat(hue.intValue)
                    self.hueSlider.value = self.currentHueValue
                    self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                }
            }
        }
    }
    
    func getColorController(timeout: TimeInterval, completionHandler: @escaping (MTRBaseClusterColorControl?) -> Void) {
        if let group = nodeGroup, let groupId = group.groupID, let id = deviceId, let controller = ESPMTRCommissioner.shared.sController {
            let (_, endpoint) = ESPMatterClusterUtil.shared.isColorControlServerSupported(groupId: groupId, deviceId: id)
            controller.getBaseDevice(id, queue: ESPMTRCommissioner.shared.matterQueue) { device, _ in
                if let device = device, let endpoint = endpoint, let point = UInt16(endpoint), let colorControlCluster = MTRBaseClusterColorControl(device: device, endpoint: UInt16(truncating: NSNumber(value: point)), queue: ESPMTRCommissioner.shared.matterQueue) {
                    completionHandler(colorControlCluster)
                } else {
                    completionHandler(nil)
                }
            }
        } else {
            completionHandler(nil)
        }
    }
    
    
    
    func getCurrentHueValue(completionHandler: @escaping (NSNumber?, Error?) -> Void) {
        self.getColorController(timeout: 10.0) { controller in
            if let controller = controller {
                controller.readAttributeCurrentHue() { hue, error in
                    completionHandler(hue, error)
                }
            } else {
                completionHandler(nil, nil)
            }
        }
    }
    
    func changeHue(toValue val: CGFloat) {
        self.getColorController(timeout: 10.0) { controller in
            if let controller = controller {
                let params = MTRColorControlClusterMoveToHueParams()
                let finalHue = Float((val*255.0)/360.0)
                params.hue = NSNumber(value: finalHue)
                controller.moveToHue(with: params) { error in
                    DispatchQueue.main.async {
                        if let _ = error {
                            self.hueSlider.value = self.currentHueValue
                            self.paramChipDelegate?.alertUserError(message: "Failed to update hue!")
                            self.hueSlider.thumbColor = UIColor(hue: self.currentHueValue/360.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                        } else {
                            self.currentHueValue = val
                        }
                    }
                }
            }
        }
    }
}
#endif
