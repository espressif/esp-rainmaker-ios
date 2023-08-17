## Matter API Reference

Most of the matter related code in the repository is present in the Matter directory in the following location: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter**.

![Matter Group](./Images/Matter_Group.png)

Some of the important classes used in the app: 

- *ESPMTRCommissioner*:

![ESPMTRCommissioner](./Images/ESPMTRCommissioner.png)

	This class is used to handle most of the matter operations including the following: 
	- Commissioning
	- On off cluster control 
	- Level control 
	- Open commissioning window 

	Files included: 
	ESPMTRCommissioner.swift contains API for the following: 
	- Start commissioning 
	- Device attestation callback
	- Issue node NOC

	ESPMTRCommissioner+Setup.swift contains API for the following: 
	- Initialize matter controller 
	- Shut down controller 
	- Commissioning establishment done 
	- Commissioning complete 

	ESPMTRCommissioner+GetClientDetails.swift: 
	- Get all client details from device cluster info 

	ESPMTRCommissioner+GetServerDetails.swift 
	- Get all server details from device cluster info 

	ESPMTRCommissioner+GetAllDeviceEndpoints.swift 
	- Get all device endpoints 

	ESPMTRCommissioner+GetDeviceDetails.swift: 
	- Add cat id operate to device access control list 

	ESPMTRCommissioner+GetDeviceList.swift 
	- Get device type list 

	ESPMTRCommissioner+GetDescriptor.swift 
	- Get descriptor cluster 

	ESPMTRCommissioner+CommissioningComplete.swift 
	- Perform post commissioning action 
	- Confirm  matter only node commissioning 
	- Confirm matter + rainmaker node commissioning 

	ESPMTRCommissioner+Utils.swift 
	- Is device connected via local network 
	- Get device metadata 

	ESPMTRCommissioner+BasicInformation.swift: 
	- Get basic information cluster 
	- Get vendor id 
	- Get product id 
	- Get software version

	ESPMTRCommissioner+OpCreds.swift:
	- Get op creds cluster 
	- Read current fabric index 
	- Remove fabric at index 

	ESPMTRCommissioner+AccessControl.swift: 
	- Read ACL attributes 
	- Write ACL attributes 

	ESPMTRCommissioner+OnOffCluster.swift: 
	- Get on off cluster 
	- Send Toggle command 
	- Send On command 
	- Send off command 

	ESPMTRCommissioner+Binding.swift: 
	- Bind devices 
	- Unbind devices 

	ESPMTRCommissioner+CustomCluster.swift: 
	- Fetch rainmaker node id 
	- Send matter node id 
	- Read attribute challenge
	- Read attribute refresh token 
	- Read attribute accesstoken 
	- Read attribute authorized 
	- Read attribute is User NOC installed 
	- Read attribute endpoint URL 
	- Read attribute rainmaker group id 
	- Append refresh token 
	- Reset refresh token 
	- Authorize 
	- Update user noc 
	- Update device list 

- *ESPAPILayer*:

![ESPAPILayer](./Images/ESPAPILayer.png)

	- ESPGetNodeGroupsService: Get node groups with matter fabric details
	- ESPCreateMatterFabricService: Create matter fabric
	- ESPNodeMetadataService: Get nodes metadata
	- ESPConvertGroupToMatterFabric: Convert node group to matter farbic
	- ESPIssueUserNOCService: Issue user NOC
	- ESPAddNodeToMatterFabricService: Add node to matter fabric
	- ESPConfirmNodeCommissioningService: Confirm node commissioning
	- ESPDeleteNodeGroupService: Remove matter fabric

### MatterSupport

Before commissioning the device to custom fabric, we will have to commission it to Apple's fabric using the MatterSupport app extension.

- Adding the Matter app extension. For commissioning we need to add Matter app extension. Follow the given steps on Xcode: 
	- Go to File -> New -> Target
	- Search for Matter and select the option
![Matter Support](./Images/Matter_Support.png)
	- Go to app Signing and Capabilities section
	- Select + Capability option
	- Select Matter Allow Setup Payload option 
![Matter Allow Setup Payload](./Images/Matter_Allow_Setup_Payload.png)
- Invoking MatterSupport workflow:
	- Go to file ESPMatterCommissioningVC.swift **(esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/Viewcontrollers/Matter\ Commissioning/Commissioning/ESPMatterCommissioningVC.swift)**
	- The method **func startCommissioningProcess()** is invoked to start commissioning to Apple’s ecosystem.
![ESPMatterCommissioningVC](./Images/ESPMatterCommissioningVC.png)
- MatterSupport commissioning workflow:
	- Go to following file RequestHandler.swift **(esp-rainmaker-ios/ESPRainMaker/MatterExtension/RequestHandler.swift)**
![RequestHandler](./Images/RequestHandler.png)
	- This file contains the various callback methods that are invoked when device is being commissioned to Apple’s ecosystem. The callbacks are the following:
		- This method is used to perform attestation checks: **override func validateDeviceCredential(_ deviceCredential: MatterAddDeviceExtensionRequestHandler.DeviceCredential) async throws**
		- This method is used to select wifi network for the device: **override func selectWiFiNetwork(from wifiScanResults: [MatterAddDeviceExtensionRequestHandler.WiFiScanResult]) async throws -> MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation**
		- This method is used to select threadnetwork for the device: **override func selectThreadNetwork(from threadScanResults: [MatterAddDeviceExtensionRequestHandler.ThreadScanResult]) async throws -> MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation**
		- Commission device callback: **override func commissionDevice(in home: MatterAddDeviceRequest.Home?, onboardingPayload: String, commissioningID: UUID) async throws**
		- This method is used to return array of rooms managed by the ecosystem: **override func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room]**
		- This method is used to configure device name: **override func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async**

  
### Matter Commissioning to custom Matter Fabric

- Initialize Matter controller: Controller is initialized using the following method: 

**func initializeMTRControllerWithUserNOC(matterFabricData: ESPNodeGroup, userNOCData: ESPIssueUserNOCResponse)**
file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner+Setup.swift**

- Start commissioning process using the following method: 

**func startCommissioning()**
file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/Viewcontrollers/Matter\ Commissioning/Commissioning/ESPMatterCommissioningVC.swift**

- Once commissioning session establishment is done, we get a callback in the following method:

**func controller(_ : MTRDeviceController, commissioningSessionEstablishmentDone error: Error?)**
file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner+Setup.swift**
We also call **MTRDeviceController->commissionNode(withID: NSNumber(value: deviceId), commissioningParams: params)** from this method to continue commissioning process.

- Next step is attestation verification. We get the callbacks in the following methods:

**func deviceAttestationCompleted(for controller: MTRDeviceController, opaqueDeviceHandle: UnsafeMutableRawPointer, attestationDeviceInfo: MTRDeviceAttestationDeviceInfo, error: Error?)**, when attestation succeeds.
file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

**func deviceAttestationCompleted(for controller: MTRDeviceController, opaqueDeviceHandle: UnsafeMutableRawPointer, attestationDeviceInfo: MTRDeviceAttestationDeviceInfo, error: Error?)**, when attestation fails.
file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

- We call the **MTRDeviceController->continueCommissioningDevice** from either of the above callbacks to continue the commissioning process.

file: **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

- Next we get CSR from the device and then use that to get node NOC, in the following callback: 

**func issueOperationalCertificate(forRequest csrInfo: MTROperationalCSRInfo, attestationInfo: MTRDeviceAttestationInfo, controller: MTRDeviceController, completion: @escaping (MTROperationalCertificateChain?, Error?) -> Void)**
file: **esp-rainmaker- ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

- Fetch Node NOC from device CSR:

Following code is used to fetch node NOC from device CSR:

```
let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion 
let service = ESPAddNodeToMatterFabricService(presenter: self) 
let finalCSR = "-----BEGIN CERTIFICATE REQUEST-----\n\(csrString)\n-----END CERTIFICATE REQUEST-----"                 
if let metadata = metadata, metadata.count > 0 { 
	service.addNodeToMatterFabric(url: nodeGroupURL, groupId: groupId, operation: "add", csr: finalCSR, metadata: metadata) 
} else { 
	service.addNodeToMatterFabric(url: nodeGroupURL, groupId: groupId, operation: "add", csr: finalCSR, metadata: nil) 
}
```
file: **esp-rainmaker- ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

- We get the NOC in the following callback: 

**func nodeNOCReceived(groupId: String, response: ESPAddNodeToFabricResponse?, error: Error?)**
file: **esp-rainmaker- ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner.swift**

- Node NOC received in the previous callback is sent to device using a completion handler received in the issueOperationalCertificate callback. 

- Once commissioning is complete we get the callback in the following method: 

**func controller(_ controller: MTRDeviceController, commissioningComplete error: Error?)**
file: **esp-rainmaker- ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/ESPMTRCommissioner+Setup.swift**


### How to work with custom clusters?

*Files included:* 
- **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/Custom\ Clusters/ESPCustomClusterInfo.swift**: This file is where we can define the custom clusters.
- **esp-rainmaker-ios/ESPRainMaker/ESPRainMaker/Matter/ESPMTRCommissioner/Custom\ Clusters/ESPMTRCommissioner+CustomCluster.swift**: This file contains the methods that are used to call matter custom cluster APIs.


*Defining custom cluster:*
- Go to file ESPCustomClusterInfo.swift
- The subsequent enum outlines the definition of the rainmaker cluster data:
```
enum rainmaker {
    
	enum attributes {
		case rainmakerNodeId
        case challenge
        
        var attributeId: NSNumber {
            switch self {
            case .rainmakerNodeId:
                return NSNumber(value: 1)
            case .challenge:
                return NSNumber(value: 2)
            }
        }
    }
    
    enum commands {
        case sendNodeId
        
        var commandId: NSNumber {
            switch self {
            case .sendNodeId:
                return NSNumber(value: 1)
            }
        }
    }
    
    static let clusterId: NSNumber = NSNumber(value: 320601088)
}
```
- enum rainmaker will have the following:
	- **static let clusterId: NSNumber**: this is the cluster id of the custom cluster
	- **enum attributes**: this enum contains info on the attributes supported by the cluster
		- **var attributeId: NSNumber**: attribute id for each attribute on the cluster
	- **enum commands**: this enum contains info on the commands supported by the cluster
		- **var commandId: NSNumber**: command id for each command supported by the cluster

*Calling custom cluster APIs:*
- Go to file ESPMTRCommissioner+CustomCluster.swift
- Before calling an API, we need to get an instance of MTRBaseDevice using the following method:
```
func getMatterDevice(deviceId: UInt64, completion: @escaping (MTRBaseDevice?) -> Void) {
	if let controller = sController {
		if let device = try? controller.getDeviceBeingCommissioned(deviceId) {
			completion(device)
			return
		}
		let device = MTRBaseDevice(nodeID: NSNumber(value: deviceId), controller: controller)
		completion(device)
		return
	}
	completion(nil)
}
```
- Sample method for reading attribute on a custom cluster:
	- Following is the method used for reading rainmaker node id from the device:
```
/// Read rainmaker node id
/// - Parameters:
///   - deviceId: device id
///   - completion: completion
func readAttributeRainmakerNodeIdFromDevice(deviceId: UInt64, _ completion: @escaping (String?) -> Void) {
	getMatterDevice(deviceId: deviceId) { device in
		if let device = device {
			device.readAttributes(withEndpointID: NSNumber(value: 0),
                                      clusterID: rainmaker.clusterId,
                                      attributeID: rainmaker.attributes.rainmakerNodeId.attributeId,
                                      params: nil,
                                      queue: self.matterQueue) { value, _  in
				if let value = value, let data = value.first?[ESPMatterConstants.data] as? [String: Any], let nodeId = data[ESPMatterConstants.value] as? String {
					completion(nodeId)
					return
				}
				completion(nil)
			}
		} else {
			completion(nil)
		}
	}
}
```
	- Read attribute method: This is the method of MTRBaseDevice class that can be used to read attribute for a given endpoint id, cluster id & attribute id.
```
/**
 * Reads attributes from the device.
 *
 * Nil values for endpointID, clusterID, attributeID indicate wildcards
 * (e.g. nil attributeID means "read all the attributes from the endpoint(s) and
 * cluster(s) that match endpointID/clusterID").
 *
 * If all of endpointID, clusterID, attributeID are non-nil, a single
 * attribute will be read.
 *
 * If all of endpointID, clusterID, attributeID are nil, all attributes on the
 * device will be read.
 *
 * A non-nil attributeID along with a nil clusterID will only succeed if the
 * attribute ID is for a global attribute that applies to all clusters.
 */
- (void)readAttributesWithEndpointID:(NSNumber * _Nullable)endpointID
                           clusterID:(NSNumber * _Nullable)clusterID
                         attributeID:(NSNumber * _Nullable)attributeID
                              params:(MTRReadParams * _Nullable)params
                               queue:(dispatch_queue_t)queue
                          completion:(MTRDeviceResponseHandler)completion
    API_AVAILABLE(ios(16.4), macos(13.3), watchos(9.4), tvos(16.4));
```
	- Sample method for sending command on a custom cluster:
		- Following is the method used for sending matter node id:
```
/// Send matter node id
/// - Parameters:
///   - deviceId: device id
///   - matterNodeId: matter node id
///   - completion: completion
func sendMatterNodeIdToDevice(deviceId: UInt64, matterNodeId: String, _ completion: @escaping (Bool) -> Void) {
	getMatterDevice(deviceId: deviceId) { device in
		if let device = device {
			let data = [ESPMatterConstants.type: ESPMatterConstants.UTF8String,
                            ESPMatterConstants.value: matterNodeId]
			device.invokeCommand(withEndpointID: NSNumber(value: 0),
                                     clusterID: rainmaker.clusterId,
                                     commandID: rainmaker.commands.sendNodeId.commandId,
                                     commandFields: data,
                                     timedInvokeTimeout: nil,
                                     queue: self.matterQueue) { value, error in
				guard let _ = error else {
					completion(true)
					return
				}
				completion(false)
			}
		} else {
			completion(false)
		}
	}
}
```
	- Send matter command method: This is the method of MTRBaseDevice class that can be used to send command for a given endpoint id, cluster id & command id.
```
/**
 * Invoke a command with a designated command path
 *
 * @param commandFields   command fields object. The object must be a data-value NSDictionary object
 *                      as described in the MTRDeviceResponseHandler.
 *                      The attribute must be a Structure, i.e.,
 *                      the NSDictionary MTRTypeKey key must have the value MTRStructureValueType.
 *
 * @param timeoutMs   timeout in milliseconds for timed invoke, or nil.
 *
 * @param completion  response handler will receive either values or error.
 */
- (void)invokeCommandWithEndpointID:(NSNumber *)endpointID
                          clusterID:(NSNumber *)clusterID
                          commandID:(NSNumber *)commandID
                      commandFields:(id)commandFields
                 timedInvokeTimeout:(NSNumber * _Nullable)timeoutMs
                              queue:(dispatch_queue_t)queue
                         completion:(MTRDeviceResponseHandler)completion
    API_AVAILABLE(ios(16.4), macos(13.3), watchos(9.4), tvos(16.4));
```