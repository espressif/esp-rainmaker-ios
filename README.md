
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

  

### Personalisation

  

- Change theme colour of App at runtime.

- Change app background during runtime.

### Scheduling

 Schedules allow you to automate a device by setting it to trigger an action at the same time on a specified day or days of the week.  List of operations that are supported for scheduling :
 
 - Add.
 - Edit.
 - Remove.
 - Enable/disable.

Schedule feature is optional but enabled by default. Schedule can be disabled from the build settings by removing `Schedule` keyword from `Active Compilation Condition` under `Swift Compiler - Custom Flags`.
  

## Supports

  

- iOS 11.0 or greater.

- Xcode 12.0

- Swift 5+

  

## Installation

  

- Run `pod install` from  ESPRainMaker folder in the terminal.

- Terminal will prompt to set AWS credentials which are managed using  [Cocopods-Keys](https://github.com/orta/cocoapods-keys) in the project.

- `UserPoolId` and `UserPoolAppClientId` are keys for Release build configuration.

-  `Staging_UserPoolId` and `Staging_UserPoolAppClientId` are keys for Debug builds.

- Set keys and after pod installation open ESPRainMaker.xcworkspace project.

- Enter your bundle id and run the project.

  

## License

  

Licensed under Apache License Version 2.0.
