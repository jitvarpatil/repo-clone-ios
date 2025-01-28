<p align="center">
  <img alt="CometChat" src="https://assets.cometchat.io/website/images/logos/banner.png">
</p>

# iOS Sample App by CometChat

This is a reference application showcasing the integration of [CometChat's iOS UI Kit](https://www.cometchat.com/docs/ui-kit/ios/5.0/overview) in a native iOS application. It demonstrates how to implement real-time messaging and voice/video calling features with ease.

<div style="
    display: flex;
    align-items: center;
    justify-content: center;">
   <img src="../screenshots/overview_cometchat_screen.png" />
</div>


## Pre-requisite

1. Login to the [CometChat Dashboard](https://app.cometchat.com/).
2. Select an existing app or create a new one and note the _`APP_ID`_, _`REGION`_ and _`AUTH_KEY`_.

## Run the Sample App

1. Clone this repository.
2. Install the dependencies.

```
pod install
```

3. Update the app credentials `APP_ID`, `REGION` and `AUTH_KEY` in the [AppConstants.swift](AppConstants.swift) file. file:https://github.com/cometchat/cometchat-uikit-ios/blob/dff19ab3a1a398ff44a0dc0394972af4b3d04e3f/SampleApp/AppConstants.swift#L11-L15

4. Run the sample app.


## Help and Support

For issues running the project or integrating with our UI Kits, consult our [documentation](https://www.cometchat.com/docs/ui-kit/ios/5.0/overview) or create a [support ticket](https://help.cometchat.com/hc/en-us) or seek real-time support via the [CometChat Dashboard](https://app.cometchat.com/).
