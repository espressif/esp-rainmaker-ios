
## ESP RainMaker iOS App

  

This is the official iOS app for [ESP RainMaker](https://github.com/espressif/esp-rainmaker), an end-to-end solution offered by Espressif to enable remote control and monitoring for ESP32-S2 and ESP32 based products without any configuration required in the Cloud.

  

For more details :

- Please check the ESP RainMaker documentation [here](http://rainmaker.espressif.com/docs/get-started.html) to get started.

- Try out this app in [App Store](https://apps.apple.com/app/esp-rainmaker/id1497491540).

  

## Features

  

### User Management

  

- Signup/Signin using email id.

- Third party login includes Apple login, GitHub and Google.

- Forgot/reset password support.

- Signing out.

  

### Provisioning

  

- Uses [ESPProvision](https://github.com/espressif/esp-idf-provisioning-ios/) library for provisioning.

- Automatically connects to device using QR code.

- Can choose manual flow if QR code is not present.

- Shows list of available Wi-Fi networks.

- Supports SoftAP based Wi-Fi Provisioning.

- Performs the User-Node association workflow.

  

### Manage

  

- List all devices associated with a user.

- Shows node and device details.

- Capability to remove node of a user.

- Shows online/offline status of nodes.

  

### Control

  

- Shows all static and configurable parameters of a device.

- Adapt UI according to the parameter type like toggle for power, slider for brightness.

- Allow user to change and monitor parameters of devices.


### Local Control


- This feature allows discovering devices on local Wi-Fi network using Bonjour (mDNS) and controlling them using HTTP as per the [ESP Local Control](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/esp_local_ctrl.html) specifications.

- Local Control ensures your devices are reachable even when your internet connection is poor or there is no internet over connected Wi-Fi.

- Supports both secure and unsecure communication with device over local network.

Local Control feature is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Local Control` key from `App Configuration` to `NO`.


### Personalisation

  

- Change theme colour of App at runtime.

- Change app background during runtime.

### Scheduling

 Schedules allow you to automate a device by setting it to trigger an action at the same time on a specified day or days of the week.  List of operations that are supported for scheduling :
 
 - Add.
 - Edit.
 - Remove.
 - Enable/disable.

Schedule feature is optional but enabled by default. Schedule can be disabled from the `Configuration.plist` by setting `Enable Schedule` key from `App Configuration` to `NO`.

### Scenes

 Scene is a group of parameters with specific values, for one or more devices (optionally) spanning across multiple nodes. As an example, an "Evening" scene may turn on all the lights and set them to a warm colour. A "Night" scene may turn off all the lights, turn on a bedside lamp set to minimal brightness and turn on the fan/ac. 
 List of operations that are supported for scene :
 
 - Add.
 - Edit.
 - Remove.
 - Activate.

Scene feature is optional but enabled by default. Scenes can be disabled from the `Configuration.plist` by setting `Enable Scene` key from `App Configuration` to `NO`.

### Node Grouping

Node Grouping allows you to create abstract or logical groups of devices like lights, switches, fans etc. List of operations that are supported in node grouping :

 - Create groups.
 - Edit groups (rename or add/remove device).
 - Remove groups.
 - List groups.

Node Grouping is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Grouping` key from `App Configuration` to `NO`.
  
  ### Node Sharing

  Node Sharing allows a user to share nodes with other registered users and allow them to monitor and control these nodes.
  List of operations that are supported in node sharing :

  For primary users:

  - Register requests to share nodes.
  - View pending requests.
  - Cancel a pending request, if required.
  - Remove node sharing.

  For secondary users:

  - View pending requests.
  - Accept/decline pending requests.

Node Sharing is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Sharing` key from `App Configuration` to `NO`.


### Device Automation

Device Automation is a set of actions that will be triggered based on the completion of certain events. For example, the user can set an event as the Temperature sensor equals 35 degrees celsius. Then based on this event user can trigger different actions like Switching on AC or Setting the AC temperature to 20 degrees celsius or a combination of both.

Users will be allowed to perform different automation operations in the app as mentioned below:

1. Adding new automation.
2. Updating existing automation.
3. Enabling/disabling automation triggers.
4. Deleting automation.
5. Receiving notifications related to triggered automation.

Device automation is optional but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Device Automation` key from `App Configuration` to `NO`.

### Push Notifications

ESPRainMaker app supports remote notifiations in order to notify app in realtime for any updates. Types of notification enabled in the app :

1. Alert notification: User will be updated by sending alert notification in case of below events:
   - A new node is added to the user.
   - Existing node is removed from the user account.
   - Node sharing request is accepted/declined by secondary user.
   - Alerts triggered from the node.
 
2. Actionable notification: In case a node sharing request is received, user will be be alerted with an actionable notification. This will enable the user to accept or decline the sharing request from the notification center.

3. Silent notifications: This notification is triggered at the time when any of the user device param changes. It will update the app with latest param value in case when app is in foreground.

### Alexa App to App Linking

  This account linking flow enables users to link their Alexa user identity with their Rainmaker identity
  by starting from Rainmaker app. When they start the account linking flow from the app, users can:
  - Discover their Alexa skill through the app.
  - Initiate skill enablement and account linking from within the app.
  - Link their account without entering Alexa account credentials if already logged into Alexa app. They will have to login to Rainmaker once, when trying to link accounts.
  - Link their account from your Rainmaker using [Login with Amazon (LWA)](https://developer.amazon.com/docs/login-with-amazon/documentation-overview.html), when the Alexa app isn&#39;t installed on their device.

### Time Series

- Time series allows a user to see historical values of parameters plotted as a bar or line chart.
- Users can select different time durations to see reported parameter values like 1 day, 7 days, 4 weeks and 1 year.
- Users can see graph for raw data and can also select from different aggregate types like avg, min, max, count and latest.

Note : Time series feature requires support in firmware. It will be available only for the parameters that have "time_series" property.

### System service

System service allows a primary user of the node to perform node operations like:
- Reboot
- Wi-Fi reset
- Factory reset

Note : System service feature requires support in firmware. It will be available for nodes that has "esp.service.system" configured.

### OTA Update

- Checks if firmware update is available for nodes that requires user approval.
- Push firmware update to nodes remotely when user provide approval using the app.

OTA update is optional and disabled by default. It can be enabled from the `Configuration.plist` by setting `Enable OTA Update` key from `App Configuration` to `YES`.

### Continuous Parameter Update

- App now supports continuous update feature that allows users to move a slider continuously and see the changes reflect on the device in real-time as the slider is moved.
- Continuous update are supported only for sliders and hue circle type of UI.
- This feautre is configurable but enabled by default. It can be disabled from the `Configuration.plist` by setting `Enable Continuous Updates` key from `App Configuration` to `NO`.
- Minimum gap between two updates can be managed by setting `Continuous Update Interval` under `App Configuration` in `Configuration.plist`. This value is considered in milliseconds and acceptable value is in range 400 - 1000.


## Custom Matter Fabric

### What is Matter?
Matter is a unifying standard that provides reliable, secure connectivity across smart home devices. It is being developed by Matter Working Group within the Connectivity Standards Alliance (CSA) as a new, royalty-free connectivity standard to increase compatibility among smart home products, with security as a fundamental design tenet.
The project is built around a shared belief that smart home devices should be secure, reliable, and seamless to use. By building upon Internet Protocol (IP), the project aims to enable communication across smart home devices, mobile apps, and cloud services and to define a specific set of IP-based networking technologies for device certification.

### Capabilities
- Commission matter only and matter+rainmaker devices to custom fabric.
- Control matter & matter+rainmaker devices locally using Matter clusters.
- Control matter+rainmaker devices remotely using the Rainmaker cloud.
- Bind switch to light device.

### Build app for Matter fabric
To support Custom Matter Fabric on the app do the following:
- Open Xcode go to Scheme selection dropdown.
- Select ESPRainmakerMatter scheme.
- Build/Run/Archive the app and it will be built with Matter support.
```
Note: This app with ESPRainmakerMatter configuration cannot be run on iOS simulators.
```

To build app for Rainmaker only devcies:
- Open Xcode go to Scheme selection dropdown.
- Select ESPRainmaker scheme.
- Build/Run/Archive the app and it will be built without Matter support.

```
In order to build the Rainmaker only app for simulator user needs to do the following:
- On Xcode select ESPRainmaker project from navigator.
- Select General tab.
- Scroll down to Frameworks, Libraries and Embedded Content
- Delete Matter.farmework from the list.
- User will be able to run the app on simulator.

If user wants to rerun the app for Matter: 
- On Xcode go to Scheme selection dropdown.
- Select ESPRainmakerMatter scheme.
- Go to General tab under main project.
- Go to Frameworks section.
- Select + button at the bottom.
- Go to ESPRainMaker/Matter/ESPMTRCommissioner/Framework and select Matter.framework and click Open.
- Under embed section select Embed and Sign from dropdown for the Matter framework.
- Run the app.
```


## Supports


- iOS 13.0 or greater.

- Xcode 13.0

- Swift 5+

  

## Installation

- Run `pod install` from  ESPRainMaker folder in the terminal.

- After pod installation open ESPRainMaker.xcworkspace project.

- Build and run the project.


## Additional Settings

Settings associated with provisioning a device can be modified in the `Configuration.plist` file under `Provision Settings` dictionary. Description of each key can be found below.

| Key      | Type |   Description |
| ----------- | ----------- | --- |
| ESP Transport | String | Possible values: <br>**Both**(Default) : Supports both BLE and SoftAP device provisioning.<br>**SoftAP** : supports only SoftAP device provisioning.<br>**BLE** : supports only BLE device provisioning. |
| BLE Device Prefix | String | Search for BLE devices with this prefix in name. |
| ESP Allow Prefix Search | Bool | Prefix search allows you to filter available BLE device list based on prefix value.  |
| ESP Security Mode | String | Possible values: <br>**Secure**(Default) : for secure/encrypted communication between device and app.<br>**Unsecure** : for unsecure/unencrypted communication between device and app.|

## License

  

Licensed under Apache License Version 2.0.
