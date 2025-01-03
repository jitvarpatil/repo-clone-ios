<p align="center">
  <img alt="CometChat" src="https://assets.cometchat.io/website/images/logos/banner.png">
</p>

# iOS Sample App by CometChat

This reference application showcases the integration of [CometChat's iOS UI Kit](https://www.cometchat.com/docs/v5/ui-kit/ios/overview) within an iOS framework. It demonstrates how to implement real-time messaging and voice/video calling features with ease.

<div style="
    display: flex;
    align-items: center;
    justify-content: center;">
   <img src="../screenshots/overview_cometchat_screens.png" />
</div>

## Prerequisites

- Xcode 
- pod (CocoaPods)
- Sign up for a [CometChat](https://app.cometchat.com/) account to get your app credentials: _`App ID`_, _`Region`_, and _`Auth Key`_


## Installation
1. Clone the repository:
    ```
    git clone https://github.com/cometchat/cometchat-sample-app-ios.git
    ```

2. Navigate to the project directory:
    ```sh
      cd cometchat-sample-app-ios/CometChatSwift
    ```

3. Install dependencies:
    ```sh
      pod install
    ```

4. If you're facing any issues while installing pods then use the below command.
    ```sh
      pod install --repo-update
    ```

5. In Xcode, open the project by opening `cometchat-sample-app-ios/CometChatSwift.xcworkspace`

6. Enter your CometChat _`App ID`_, _`Region`_, and _`Auth Key`_ in the [CometChatSwift/AppConstants.swift](CometChatSwift/AppConstants.swift) file:
   https://github.com/cometchat/cometchat-sample-app-ios/blob/056b60f4b8092a6a24df64e371e56879bbb77915/CometChatSwift/AppConstants.swift#L9-L13

8. Run the app on a device or emulator.


## Help and Support
For issues running the project or integrating with our UI Kits, consult our [documentation](https://www.cometchat.com/docs/ios-uikit/integration) or create a [support ticket](https://help.cometchat.com/hc/en-us) or seek real-time support via the [CometChat Dashboard](http://app.cometchat.com/).
