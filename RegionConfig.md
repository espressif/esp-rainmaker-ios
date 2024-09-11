# iOS China Configuration Guide

This guide provides detailed instructions on configuring your iOS app using the `Configuration.plist` file to ensure proper functionality based on region-specific settings and to enable certain features such as JPushService and WeChat login.

## 1. CN Configuration

- **Fields Required:**
  - **App Client ID** (String)
  - **Authentication URL** (String)
  - **Base URL** (String)
  - **Claim URL** (String)

These fields must be set for users running the app from Xcode when their iOS device's region is set to "China mainland." Without these configurations, the app will crash.

## 2. JPushService Configuration

- **Fields Required:**
  - **App Key** (String)
  - **APS For Production** (BOOL, default set to true)

To enable JPushService for notifications:

- Provide a valid App Key in the `Configuration.plist` under **JPushService Configuration/App Key**.
- If the App Key is not set, the app will revert to the default notification implementation.
- **Important Note:**
  - When uploading the app for distribution, set **APS For Production** to **True**.
  - When running the app from Xcode, set **APS For Production** to **False** to receive notifications during development.

### How to Get the JPushService App Key

To obtain a JPushService App Key:

1. Go to the [JPush Official Website](https://www.jiguang.cn/).
2. If you don't have an account, complete the registration process.
3. Once registered, log in and follow the steps to create a new application.
4. Their iOS-specific documentation can be found [here](https://docs.jiguang.cn/jpush/client/iOS).

## 3. WeChat Configuration

- **Fields Required:**
  - **App Id** (String)
  - **Universal Link** (String)
  - **Scope** (String)

To enable WeChat login on the sign-in page (when the region is set to "China mainland"):

- Provide a valid WeChat App Id in the `Configuration.plist` under **WeChat Configuration/App Id**.
- Add the same App Id in the Project Info section under URL Types for the identifier **weixin**.
- If the App Id is not provided, the WeChat login option will not be displayed, and only Sign in with Apple will be supported.

### How to Get the WeChat App Id

To obtain a WeChat App Id:

1. Visit the [WeChat Open Platform](https://open.weixin.qq.com/cgi-bin/index?t=home/index&lang=en_US).
2. Register to create an account if you don't have one.
3. Follow the steps provided on the platform to obtain your App Id.
4. Their iOS-specific documentation can be found [here](https://developers.weixin.qq.com/doc/oplatform/en/Mobile_App/Access_Guide/iOS.html).

## Region-Specific Configuration Behavior

- If the app is run on a device where the region is set to "China mainland," it will use the configurations under **CN Configuration** for:
  - **Auth URL**
  - **Base URL**
  - **Claim URL**
  - **App Id**
- If the region is set to anything other than "China mainland," the app will default to using values defined under **AWS Configuration**.

## Summary of Required Setup

### WeChat Login Setup

1. Add a valid WeChat App Id in:
   - **Configuration.plist/WeChat Configuration/App Id**
2. Add the same App Id in:
   - **Project Info section > URL Types** for the identifier **weixin**.

### JPushService Setup

1. Add a valid JPushService App Key in:
   - **Configuration.plist/JPushService Configuration/App Key**
2. Set **APS For Production** based on the deployment:
   - **True** for distribution.
   - **False** when running from Xcode for testing.

Ensure that all required fields are correctly set in your `Configuration.plist` to ensure smooth functionality across different regions and features in your app.