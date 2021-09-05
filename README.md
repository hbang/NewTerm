# ![NewTerm](https://github.com/hbang/NewTerm/raw/main/assets/banner.jpg)

NewTerm is a full terminal emulator app for iOS and macOS. It features first-class iPhone, iPad, and Mac support, a tab-based interface, and multi-window support on iPad, as well as support for modern terminal features such as extensions created by the iTerm2 project, and more.

It’s the perfect companion for running quick commands directly on your iPhone, or working on projects on your iPad side-by-side with other apps, or SSHing to a server that crashed while you’re on vacation.

**[Download on Chariz](https://chariz.com/get/newterm)**

## Building
The Xcode project builds with the latest release of Xcode 12, once Swift Package Manager dependencies have been downloaded.

The most convenient way to test the app is by building for the “My Mac” target. For debugging iOS-specific functionality, a mostly-functional terminal does work in the Simulator. It will spawn with a weird prompt that says “I have no name!”, as Simulator seems to block access to macOS’s Open Directory user database. However, you should still be able to do everything your logged-in macOS user can do.

To install on a jailbroken device, first [set up Theos](https://git.io/theosinstall). Then, you can run `make do` in the root of the repo. Xcode 11 is *not* required as NewTerm does not need to be built for arm64e, and in fact won’t work as a number of iOS 14 APIs are in use.

## License
Licensed under the Apache License, version 2.0. Refer to [LICENSE.md](LICENSE.md).
