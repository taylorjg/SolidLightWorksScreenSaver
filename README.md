# Description

The idea of this repo is to make a macOS screensaver out of my [solid-light-works](https://github.com/taylorjg/solid-light-works) project
which is three.js/WebGL based. I intend to write the screensaver in Swift using Metal. 

# Basic Screensaver

The first step was to create a basic macOS screensaver in Swift using Metal. This has not been easy. I have not been able to find much in the way of examples. I did the following:

* Created a project using the `Screen Saver` template
* Removed the Objective-C files and added a Swift file (`SolidLightWorksView.swift`) as per [How to Make a Custom Screensaver for Mac OS X](https://medium.com/better-programming/how-to-make-a-custom-screensaver-for-mac-os-x-7e1650c13bd8)
* Added a new target based on the `Cross-platform` template choosing Swift and Metal
  * I would have used the `App` template but I am running XCode 11.3 on macOS 10.14.4 and I found that if I created an App with a User Interface of type SwiftUI, I could not run it because it required macOS 10.15.
* Hacked away at `SolidLightWorksView.swift` based on `GameViewController.swift`
* Started the process of debugging to figure out why the screensaver wasn't working and how to fix it

## Debugging the Screensaver

In order to debug my screensaver, I did something horrible but effective - I used `NSAlert` as a logging mechanism e.g.:

```
let alert = NSAlert()
alert.informativeText = "Unable to load texture. Error info: \(error)"
alert.addButton(withTitle: "OK")
alert.runModal()
```

This allowed me to pinpoint where the problem was occurring. The call to `device.makeDefaultLibrary()` was returning `nil`.
I figured out this was a bundling issue - the main bundle was for `/Applications/System Preferences.app` rather than my screensaver's bundle. I fixed this by explicltly loading my bundle using [`init(for:)`](https://developer.apple.com/documentation/foundation/bundle/1417717-init).

```
let bundle = Bundle(for: SolidLightWorksView.self)
```

# Links

* [solid-light-works](https://github.com/taylorjg/solid-light-works)
* [How to Make a Custom Screensaver for Mac OS X](https://medium.com/better-programming/how-to-make-a-custom-screensaver-for-mac-os-x-7e1650c13bd8)
* [ScreenSaverView](https://developer.apple.com/documentation/screensaver/screensaverview)
