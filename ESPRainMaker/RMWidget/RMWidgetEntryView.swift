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
//  RMWidgetEntryView.swift
//  ESPRainMaker
//

import SwiftUI
import Intents

struct RMWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        // Define background colors
        let backColor1 = #colorLiteral(red: 0.3396473527, green: 0.2636059225, blue: 0.594558239, alpha: 1)
        let backColor2 = #colorLiteral(red: 0.5748691559, green: 0.4462535381, blue: 1, alpha: 1)
        // Check if userDevice is available
        if let userDevice = entry.device {
            ZStack {
                // Create a linear gradient background
                LinearGradient(gradient: Gradient(colors: [Color(uiColor: backColor1),Color(uiColor: backColor2)]), startPoint: .topLeading, endPoint: .topTrailing).edgesIgnoringSafeArea(.all)
                GeometryReader { metrics in
                    VStack {
                        HStack {
                            Spacer()
                            Text("ESP RainMaker")
                                .font(.system(size: 6, weight: .bold, design: .monospaced))
                                .foregroundColor(.white).padding(EdgeInsets(top: 6, leading: 0, bottom: 1, trailing: 10))
                        }
                        Spacer(minLength: 4)
                        HStack {
                            // Get device icon details
                            if let iconDetails = ESPRMDeviceType(rawValue: userDevice.type ?? "")?.getImageFromDeviceType(device: userDevice) {
                                // Display system icon
                                Spacer()
                                if iconDetails.isSystemIcon == true {
                                    Image(systemName: iconDetails.iconName)
                                        .resizable()
                                        .symbolRenderingMode(.monochrome)
                                        .renderingMode(.original)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(iconDetails.color)
                                        .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                                } else {
                                    // Display custom icon
                                    Image(iconDetails.iconName)
                                        .resizable()
                                        .renderingMode(.original)
                                        .aspectRatio(contentMode: .fit)
                                        .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                                }
                            }
                            Spacer()
                            VStack {
                                Spacer()
                                // Display primary parameter of the device
                                Text(userDevice.primary_param ?? "")
                                    .font(.system(size: 12, weight: .bold, design: .default))
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                                    .foregroundColor(.white).symbolRenderingMode(.monochrome)
                                Divider().overlay(.white)
                                // Display parameter value of the device
                                Text(userDevice.param_value ?? "")
                                    .font(.system(size: 17, weight: .regular, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                            }.frame(width: metrics.size.width * 0.55)
                            Spacer()
                        }
                        Spacer()
                        // Display device name
                        Text(userDevice.name ?? "")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        // Define text color
                        let textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                        // Display device status (Online/Offline) and timestamp
                        Text(userDevice.connected == 1 ? "Online":("Offline"+(userDevice.timestamp?.getShortDate() ?? "")))
                            .font(.system(size: 13, weight: .light, design: .rounded))
                            .foregroundColor(Color(uiColor: textColor))
                        Spacer()
                    }
                }
            }
        } else {
            ZStack {
                // Create a linear gradient background
                LinearGradient(gradient: Gradient(colors: [Color(uiColor: backColor1),Color(uiColor: backColor2)]), startPoint: .topLeading, endPoint: .topTrailing).edgesIgnoringSafeArea(.all)
                GeometryReader { metrics in
                    VStack {
                        HStack {
                            Spacer()
                            Text("ESP RainMaker")
                                .font(.system(size: 6, weight: .bold, design: .monospaced))
                                .foregroundColor(.white).padding(EdgeInsets(top: 6, leading: 0, bottom: 1, trailing: 10))
                        }.frame(height: metrics.size.height * 0.1)
                        Text("No device information")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(.white).frame(height: metrics.size.height * 0.9)
                    }
                }
            }
        }
    }
}

enum ESPRMDeviceType: String {
    case switchDevice = "esp.device.switch"
    case lightbulb = "esp.device.lightbulb"
    case fan = "esp.device.fan"
    case thermostat = "esp.device.thermostat"
    case temperatureSensor = "esp.device.temperature-sensor"
    case lock = "esp.device.lock"
    case sensor = "esp.device.sensor"
    case outlet = "esp.device.outlet"
    case gateway = "esp.device.gateway"
    case zigbeeGateway = "esp.device.zigbee_gateway"
    
    // Retrieve icon and color information based on the device type and status
    func getImageFromDeviceType(device: UserDevice) -> (iconName: String, color: Color, isSystemIcon: Bool) {
        switch self {
        case .switchDevice:
            if device.connected == 1 {
                if device.primary_type == RMIntentConstants.powerParamType, device.param_value == RMIntentConstants.onDisplayString {
                    return (RMIntentConstants.switchOn, Color(.white), true)
                } else {
                    return (RMIntentConstants.switchOff, Color(.white), true)
                }
            } else {
                return (RMIntentConstants.switchOn, Color(.lightGray), true)
            }
        case .lightbulb:
            if device.connected == 1 {
                if device.primary_type == RMIntentConstants.powerParamType, device.param_value == RMIntentConstants.onDisplayString {
                    let lightColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
                    return (RMIntentConstants.lightBulbIconFilled, Color(uiColor: lightColor), true)
                } else {
                    return (RMIntentConstants.lightBulbIconFilled, Color(.gray), true)
                }
            } else {
                return (RMIntentConstants.lightBulbIconFilled, Color(.lightGray), true)
            }
        case .fan:
            if device.connected == 1 {
                if device.primary_type == RMIntentConstants.powerParamType, device.param_value == RMIntentConstants.onDisplayString {
                    return (RMIntentConstants.fanIconFilled, Color(.brown), true)
                } else {
                    return (RMIntentConstants.fanIconFilled, Color(.gray), true)
                }
            } else {
                return (RMIntentConstants.fanIcon, Color(.lightGray), true)
            }
        case .thermostat:
            if device.connected == 1 {
                return (RMIntentConstants.thermostatIconFilled, Color(.blue), true)
            } else {
                return (RMIntentConstants.thermostatIcon, Color(.lightGray), true)
            }
        case .temperatureSensor:
            if device.connected == 1 {
                return (RMIntentConstants.tempSensorIcon, Color(.blue), false)
            } else {
                return (RMIntentConstants.tempSensorInactiveIcon, Color(.lightGray), false)
            }
        case .lock:
            if device.connected == 1 {
                if device.primary_type == RMIntentConstants.lockParamType {
                    switch device.param_value {
                    case RMIntentConstants.locked:
                        let lockColor = #colorLiteral(red: 0.6387372017, green: 0.6871353984, blue: 1, alpha: 1)
                        return (RMIntentConstants.lockIconFilled, Color(uiColor: lockColor), true)
                    case RMIntentConstants.unlocked:
                        let lockColor = #colorLiteral(red: 0.6387372017, green: 0.6871353984, blue: 1, alpha: 1)
                        return (RMIntentConstants.unlocked, Color(uiColor: lockColor), true)
                    default:
                        let lockColor = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
                        return (RMIntentConstants.lockIconJammed, Color(uiColor: lockColor), true)
                    }
                }
            } else {
                return (RMIntentConstants.lockIcon, Color(.lightGray), true)
            }
        case .sensor:
            if device.connected == 1 {
                return (RMIntentConstants.sensorIconFilled, Color(.blue), true)
            } else {
                return (RMIntentConstants.sensorIcon, Color(.lightGray), true)
            }
        case .outlet:
            if device.connected == 1 {
                return (RMIntentConstants.outletIcon, Color(.white), true)
            } else {
                return (RMIntentConstants.outletIcon, Color(.lightGray), true)
            }
        case .gateway, .zigbeeGateway:
            if device.connected == 1 {
                return (RMIntentConstants.defaultIcon, Color(.white), false)
            } else {
                return (RMIntentConstants.outletIcon, Color(.lightGray), false)
            }
        }
        return (RMIntentConstants.defaultIcon, Color(.lightGray), false)
    }
}

