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
//  ESPMatterConstants.swift
//  ESPRainmaker
//

import Foundation

struct ESPMatterConstants {
    
    /// Utils
    static let emptyString = ""
    static let commissioning = "Commissioning"
    static let controller = "controller"
    static let acceptedSharings = "acceptedSharings"
    static let pendingNodeGroupRequests = "pendingNodeGroupRequests"
    static let requestsSent = "requestsSent"
    static let sharingsAcceptedBy = "sharingsAcceptedBy"
    static let vendorId = "vendorId"
    static let productId = "productId"
    static let softwareVersion = "softwareVersion"
    static let softwareVersionString = "softwareVersionString"
    static let serialNumber = "serialNumber"
    static let manufacturerName = "manufacturerName"
    static let productName = "productName"
    static let warning = "Warning"
    static let info = "Info"
    static let matterPrefix = "MT:"
    static let matterStoryboardId = "ESPMatter"
    static let lightDevice = "light"
    static let switchDevice = "switch"
    static let outletDevice = "outlet"
    static let defaultDevice = "default"
    static let airConditioner = "air_conditioner"
    static let pureMatter = "pure_matter"
    static let rainmakerMatter = "rainmaker_matter"

    static let noTxt = "No"
    static let okTxt = "OK"
    static let yesTxt = "Yes"
    static let backTxt = "Back"
    static let doneTxt = "Done"
    static let retryTxt = "Retry"
    static let errorTxt = "Error"
    static let shareTxt = "Share"
    static let switchTxt = "Switch"
    static let cancelTxt = "Cancel"
    static let logoutTxt = "Logout"
    static let removeTxt = "Remove"
    static let deviceTxt = "Device"
    static let updateTxt = "Update"
    static let createTxt = "Create"
    static let successTxt = "Success"
    static let confirmTxt = "Confirm"
    static let dismissTxt = "Dismiss"
    static let devicesTxt = "Devices"
    static let failureTxt = "Failure"
    static let emailIdTxt = "Email ID"
    static let addGroupTxt = "Add Group"
    static let rmDeviceTxt = "Remove device"
    static let shareGroupTxt = "Share Group"
    static let createGroupTxt = "Create Group"
    static let updateGroupTxt = "Update Group"
    static let sendRequestTxt = "Send Request"
    static let selectGroupTxt = "Select Group"
    static let groupSharingTxt = "Group Sharing"
    static let cancelRequestTxt = "Cancel Request"
    static let revokeRequestTxt = "Revoke Request"
    static let deviceBindingTxt = "Device Binding"
    static let enterGroupNameTxt = "Enter group name"
    static let requestsReceivedTxt = "Requests received"
    static let enterGroupNameRequestTxt = "Please enter a group name"
    static let localTemperatureTxt = "Local Temperature"
    static let measuredTemperatureTxt = "Measured Temperature"
    static let occupiedCoolingSetpointTxt = "Occupied Cooling Setpoint"
    static let occupiedHeatingSetpointTxt = "Occupied Heating Setpoint"
    
    /// UI keys
    static let no = "NO"
    static let ipk = "ipk"
    static let add = "add"
    static let yes = "YES"
    static let edit = "Edit"
    static let home = "Home"
    static let share = "share"
    static let matter = "Matter"
    static let revoke = "Revoke"
    static let delete = "delete"
    static let linking = "Linking"
    static let bindings = "bindings"
    static let email = "Enter email"
    static let matterDeviceName = "matterDeviceName"
    static let deviceName = "deviceName"
    static let deviceType = "deviceType"
    static let isRainmaker = "isRainmaker"
    static let serversData = "serversData"
    static let clientsData = "clientsData"
    static let attributesData = "attributesData"
    static let deviceLinks = "Device Links"
    static let endpointsData = "endpointsData"
    static let linkedDevices = "LINKED DEVICES"
    static let unlinkedDevices = "AVAILABLE DEVICES"
    static let navigationController = "NavigationViewController"

    /// Device view controller
    static let name = "name"
    static let onOff = "onOff"
    static let openCW = "openCW"
    static let binding = "binding"
    static let levelControl = "levelControl"
    static let colorControl = "colorControl"
    static let saturationControl = "saturationControl"
    static let cctControl = "cctControl"
    static let rainmakerController = "rainmakerController"
    static let participantData = "participantData"
    static let localTemperature = "localTemperature"
    static let measuredTemperature = "measuredTemperature"
    static let occupiedCoolingSetpoint = "occupiedCoolingSetpoint"
    static let occupiedHeatingSetpoint = "occupiedHeatingSetpoint"
    static let controlSequenceOfOperation = "controlSequenceOfOperation"
    static let systemMode = "systemMode"
    static let borderRouter = "borderRouter"
    static let updateMetadata = "updateMetadata"
    
    static let onOffCluster = "OnOff Cluster"
    static let tempMeasurementCluster = "Termperature Measurement Cluster"
    
    /// API keys
    static let id = "id"
    static let csr = "csr"
    static let onTxt = "On"
    static let tags = "tags"
    static let node = "node"
    static let user = "user"
    static let code = "code"
    static let type = "type"
    static let offTxt = "Off"
    static let nodes = "nodes"
    static let status = "status"
    static let accept = "accept"
    static let groups = "groups"
    static let remove = "remove"
    static let trueFlag = "true"
    static let userId = "user_id"
    static let nodeId = "node_id"
    static let primary = "primary"
    static let failure = "failure"
    static let success = "success"
    static let devices = "devices"
    static let falseFlag = "false"
    static let pending = "pending"
    static let addIcon = "add_icon"
    static let groupId = "group_id"
    static let csrType = "csr_type"
    static let password = "password"
    static let clientId = "client_id"
    static let isMatter = "is_matter"
    static let userName = "user_name"
    static let groupIds = "group_ids"
    static let operation = "operation"
    static let challenge = "challenge"
    static let structure = "Structure"
    static let grantType = "grant_type"
    static let groupName = "group_name"
    static let metadata = "metadata"
    static let requestId = "request_id"
    static let secretKey = "secret_key"
    static let contextTag = "contextTag"
    static let redirctURI = "redirect_uri"
    static let newPassword = "newpassword"
    static let description = "description"
    static let csrRequests = "csr_requests"
    static let contentType = "Content-Type"
    static let nodeDetails = "node_details"
    static let refreshToken = "refreshtoken"
    static let authorization = "Authorization"
    static let groupMetadata = "group_metadata"
    static let requestStatus = "request_status"
    static let deviceNameTag = "esp.device.name"
    static let applicationJSON = "application/json"
    static let rainmakerNodeId = "rainmaker_node_id"
    static let amazonRootCAFileName = "amazonRootCA"
    static let verificationCode = "verification_code"
    static let authorizationCode = "authorization_code"
    static let mutuallyExclusive = "mutually_exclusive"
    static let applicationURLEncoded = "application/x-www-form-urlencoded"
    
    static let espressif = "Espressif"
    static let matterVendorId: UInt16 = 4891
    
    
    /// Messages
    static let noThreadBRHeader = "No Thread Border Router"
    static let noThreadBRDescription = "Please ensure that you have added a Thread Border Router to your Apple Id."
    static let noMatchingThreadDescription = "The preferred credentials on the app don't match any of the scanned thread networks. Please ensure your Thread Border Router is powered on and connected."
    static let noThreadScanResult = "Device could not find any thread networks to join."
    static let copyCodeMsg = "Copy code"
    static let shareNodeMsg = "Share Node"
    static let operationFailedMsg = "Operation failed"
    static let sharingGroupMsg = "Sharing group..."
    static let chipDeviceId: String = "ChipDeviceId"
    static let challengeFailedMsg = "Challenge failed."
    static let removingDeviceMsg = "Removing device..."
    static let linkingDevicesMeg = "Linking devices..."
    static let unlinkingDevicesMsg = "Unlinking devices..."
    static let revokingRequestMsg = "Cancelling request..."
    static let bindingFailureMsg = "Failed to bind devices."
    static let mtrPairingFailedMsg = "Failed to pair device."
    static let groupShareFailedMsg = "Failed to share group."
    static let fetchingEndpointsMsg = "Fetching endpoints..."
    static let cancellingRequestMsg = "Cancelling request..."
    static let pairingModeTitle = "Accessory Ready to Connect"
    static let updatingNodeGroupMsg = "Fetching groups data..."
    static let commissioningFailedMsg = "Commissioning failed!"
    static let fetchingGroupsDataMsg = "Fetching groups data..."
    static let unbindingFailureMsg = "Failed to unbind devices."
    static let matterRainmakerDevices = "matter.rainmaker.devices"
    static let checkingMatterConnMsg = "Checking matter connection"
    static let fetchingDevicesDataMsg = "Fetching devices data...."
    static let fetchBindingMsg = "Fetching node binding details..."
    static let cancelRequestFailedMsg = "Failed to cancel request."
    static let revokeRequestFailedMsg = "Failed to cancel request."
    static let requestAcceptFailedMsg = "Failed to accept request."
    static let requestDeclinedMsg = "Request declined successfully."
    static let groupDeletionSuccessMsg = "Group deleted successfully"
    static let matterNotSupportedMsg = "App does not support Matter."
    static let fetchingRainmakerDataMsg = "Fetching Rainmaker data..."
    static let commissioningFailureMsg = "Failed to commission device."
    static let updatingDeviceListMsg: String = "Updating device list..."
    static let failedToRemoveDeviceMsg: String = "Failed to remove device."
    static let fetchSharingRequestsMsg = "Fetching node sharing requests..."
    static let fetchingDeviceDetailsMsg: String = "Fetching device details..."
    static let updatingDeviceDetailsMsg: String = "Updating device details..."
    static let fetchChallengeFailedMsg = "Failed to get challenge from device."
    static let removeDeviceMsg = "Are you sure you want to remove this device?"
    static let groupShareSuccessMsg = "Group sharing request sent successfully."
    static let cancelRequestMsg = "Are you sure you want to cancel this request?"
    static let enterNodeLabelMsg = "Enter new node label"
    static let enterDeviceNameMsg = "Enter device name of length 1-32 characters"
    static let removeGroupSharingMsg = "Are you sure you want to remove this group?"
    static let revokeRequestMsg = "Are you sure you want revoke access to this group?"
    static let commissioningWindowOpenFailedMsg = "Failed to open commissioning window."
    static let shareGroupEmailMessage = "Enter email id of user to share the device with"
    static let openCWFailureMsg = "Failed to open commissioning window. Please try later!"
    static let commissioningWindowAlreadyOpenMsg = "Commissioning window is already open."
    static let shareGroupMsg = "Enter email of user with whom you want to share the group."
    static let paramUpdateFailureMsg = "Fail to update parameter. Please check you network connection!!"
    static let enterValidDeviceNameMsg = "Please enter a valid device name within a range of 1-32 characters"
    static let upgradeOSVersionMsg = "You must upgrade to iOS 16.4 or above in order to commission matter nodes."
    static let scannErrorMsg: String = "Something went wrong! Please go back and try scanning the QR code again."
    static let pairingModeMessage = "\"Matter Accessory\" is now in pairing mode. Use the setup code to connect.\n\n Setup Code: "
    static let deviceNotReachableMsg: String = "Device not reachable! Please ensure that the device is powered on and connected to the same network."
    static let controllerNeedsAccessMsg: String = "Matter Controller needs access to your RainMaker account to fetch all nodes under the account. Proceed?"
    static let scanQRCodeMsg = "Since you are trying to commission a matter device, you will have to scan the QR code again using the scanner that will appear next."
    
    /// Matter data keys
    static let groupIdKey = "group.com.espressif.rainmaker.softap"
    static let homesDataKey: String = "com.espressif.hmmatterdemo.homes"
    static let roomsDataKey: String = "com.espressif.hmmatterdemo.rooms"
    static let matterDevicesKey: String = "com.espressif.hmmatterdemo.devices"
    static let matterDevicesName: String = "com.espressif.hmmatterdemo.deviceName"
    static let matterStepsKey: String = "com.espressif.hmmatterdemo.step"
    static let matterUUIDKey: String = "com.espressif.hmmatterdemo.commissionerUUID"
    static let onboardingPayloadKey: String = "com.espressif.hmmatterdemo.onboardingPayload"
    static let commissioningSB: String = "ESPCommissioning"
    
    /// Create new home keys
    static let createNewHomeTitle: String = "Create new Home?"
    static let createNewHomeMsg: String = "Enter the name of your new home and give it a Room"
    static let removeDeviceMessage: String = "Would you like to remove this device?"
    static let updateNodeGroupMsg: String = "Do you want to update node group to matter fabric?"
    
    /// color hexcodes
    static let customBackgroundColor: String = "#005493"
    
    static let csrHeader = "-----BEGIN CERTIFICATE REQUEST-----"
    static let csrFooter = "-----END CERTIFICATE REQUEST-----"
    
    static let UTF8String = "UTF8String"
    static let data = "data"
    static let value = "value"
    
    static let prefixCATId = "FFFFFFFD"
    
    static let enterBadgeDetails = "Enter Badge Details"
    static let enterBadgeUserNameMsg = "Please enter a valid user name. Only spaces are not allowed."
    static let enterBadgeCompanyNameMsg = "Please enter a valid company name. Only spaces are not allowed."
    static let enterBadgeEventNameMsg = "Please enter a valid event name. Only spaces are not allowed."
    static let commissioningWindowOpenMsg = "Commissioning window is already open. Please try after a few minutes"
    
    //Air conditioner device
    static let cool = "Cool"
    static let heat = "Heat"
    static let off = "Off"
    static let controlSequence = "Control Sequence"
    static let systemModeTxt = "System Mode"
    static let tempDegreesCelsius = "Temperature(°C)"
    
    static let threadUpdateFailed = "Failed to update thread dataset!"
    
    static let ocwKey = "com.espressif.rainmaker.softap.open.commissioning.window"
    static let ocwDuration: TimeInterval = 300
}

extension String {
    
    var clusterId: UInt? {
        if self == ESPMatterConstants.onOffCluster {
            return 6
        }
        if self == ESPMatterConstants.tempMeasurementCluster {
            return 1026
        }
        return nil
    }
}
