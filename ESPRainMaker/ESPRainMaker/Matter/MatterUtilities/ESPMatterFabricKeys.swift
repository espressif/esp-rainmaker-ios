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
//  ESPMatterFabricKeys.swift
//  ESPRainmaker
//

import Foundation

enum Storyboard {
    
    case main
    case clusters
    case deviceDetails
    case user
    case login
    case sharing
    
    var storyboardId: String {
        switch self {
        case .login:
            return  "Login"
        case .user:
            return  "User"
        case .main:
            return  "Main"
        case .deviceDetails:
            return  "DeviceDetail"
        case .clusters:
            return  "Clusters"
        case .sharing:
            return  "Sharing"
        }
    }
}

class ESPMatterFabricKeys {
    
    static let shared = ESPMatterFabricKeys()
    
    let devicesKey: String = "matter.devices"
    let deviceIdsKey: String = "matter.devices.ids"
    let matterGroupsKey: String = "matter.groups.key"
    let matterCustomDatakey: String = "matter.custom.data.key"
    let sharingRequestsSentKey: String = "matter.sharing.requests.sent.key"
    let nodeGroupSharingRequestsSentKey: String = "node.group.sharing.requests.sent.key"
    let nodeGroupSharingRequestsReceivedKey: String = "node.group.sharing.requests.received.key"
    let nodeGroupSharingKey: String = "node.group.sharing.key"
    let ipkKey: String = "node.group.ipk"
    var matterNodeGroupDetailsKey: (_ groupId: String) -> String = { groupId in
        return "\(groupId).matter.node.group.details"
    }
    var matterNodeDetailsKey: (_ nodeId: String) -> String = { groupId in
        return "\(groupId).matter.node.details"
    }
    var matterFabricDataKey: (_ groupId: String) -> String = { id in
        return "\(id).matter.fabric.details"
    }
    var userNOCKey: (_ groupId: String) -> String = { id in
        return "\(id).matter.user.noc"
    }
    var addNodeToFabricDataKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).add.node.to.matter.fabric"
    }
    var issueUserNOCKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).issue.user.noc.matter.fabric"
    }
    var addNodeToFabricMatterNodeIdDataKey: (_ groupId: String, _ matterNodeId: String) -> String = { groupId, matterNodeId in
        return "\(groupId).\(matterNodeId).add.node.to.matter.fabric"
    }
    var deviceNameKey: (_ groupId: String, _ matterNodeId: String) -> String = {
        groupId, matterNodeId in
            return "\(groupId).\(matterNodeId).device.name.key"
    }
    var deviceTypeKey: (_ deviceId: UInt64) -> String = { deviceId in
        return "\(deviceId).device.type"
    }
    var endpointsDataKey: (_ deviceId: UInt64) -> String = { deviceId in
        return "\(deviceId).endpoints.data"
    }
    var clientsDataKey: (_ deviceId: UInt64) -> String = { deviceId in
        return "\(deviceId).clients.data"
    }
    var serversDataKey: (_ deviceId: UInt64) -> String = { deviceId in
        return "\(deviceId).servers.data"
    }
    var groupDeviceTypeKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).device.type"
    }
    var groupNodeLabelKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).node.label"
    }
    var groupDeviceRainmakerTypeKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).rainmaker.type"
    }
    var groupEndpointsDataKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).endpoints.data"
    }
    var groupClientsDataKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).clients.data"
    }
    var groupServersDataKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).servers.data"
    }
    var groupLinkedDevicesKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).linked.devices"
    }
    var groupUnlinkedDevicesKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).unlinked.devices"
    }
    var groupVendorIdKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).vendor.id"
    }
    var groupProductIdKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).product.id"
    }
    var groupSwVersionKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).software.version"
    }
    var groupSerialNumberKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).matter.serial.version"
    }
    var groupManufacturerNameKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).matter.manufacturer.name"
    }
    var groupProductNameKey: (_ groupId: String, _ deviceId: UInt64) -> String = { groupId, deviceId in
        return "\(groupId).\(deviceId).matter.product.name"
    }
}

