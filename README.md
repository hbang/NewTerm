# ![NewTerm](https://github.com/hbang/NewTerm/raw/main/assets/banner.jpg)

<p align="center">
	<strong><a href="https://chariz.com/get/newterm-beta">Download NewTerm 3 (Beta) on Chariz</a></strong>
	<br>
	or
	<br>
	<strong><a href="https://chariz.com/get/newterm">Download NewTerm 2 (Stable) on Chariz</a></strong>
</p>

---

Introducing **NewTerm 3**, a significant rewrite of the popular NewTerm 2 terminal emulator app for iOS.

NewTerm 3 delivers improved performance and more accurate emulation. The user interface has been rebuilt, making it easier to use and more visually appealing. Supporting iOS 14 and newer, NewTerm 3 aims to be the best terminal emulator available for iOS. Whether you’re an advanced user looking to get some work done on the command line of your iOS device, or just want to try out some new commands and scripts, NewTerm 3 has you covered.

One of the key features of NewTerm 3 is its support for [iTerm2 Shell Integration](https://chariz.com/get/iterm2-shell-integration). This brings tighter integration between the terminal app and the programs you use. For instance, NewTerm is aware of the current working directory of each terminal, so when you open a new tab, it’s already running in that same directory. You can also directly upload and download files within an SSH session using the `it2ul` and `it2dl` commands.

Another standout feature of NewTerm 3 is its ability to create split-screen panes on iPads. This allows you to run multiple terminal sessions simultaneously, making it easier to multitask and work with multiple command-line tools simultaneously. You can have unlimited panes and resize them to fit whatever task you need.

Performance is a top concern when it comes to terminal emulation. NewTerm 3 is designed to achieve 120 frames-per-second performance on iPhones and iPads with ProMotion, making for a smooth and responsive experience. However, if you’re concerned about battery life, you can tune the performance down to 60, 30, or 15 fps. NewTerm is aware of Low Power Mode, and by default, automatically reduces performance to 15 fps when it’s enabled.

NewTerm 3 also includes a host of other enhancements designed to make it the best terminal app available for iOS. Whether you’re a seasoned command-line user or just getting started, NewTerm 3 has something to offer everyone.

NewTerm 3 is a work in progress, and is not yet considered stable. While we’ve made every effort to ensure its quality, please be aware that there may still be some bugs or unfinished features. If you’re not comfortable using beta software, we recommend using [NewTerm 2](https://chariz.com/get/newterm) until NewTerm 3 is ready for release.

This is only an early preview of what we’ve got planned for NewTerm. Stay tuned for further updates!

## Building
The Xcode project builds with the latest release of Xcode, once Swift Package Manager dependencies have been downloaded.

The most convenient way to test the app is by building for the “My Mac” target. For debugging iOS-specific functionality, a mostly-functional terminal does work in the Simulator. It will spawn with a weird prompt that says “I have no name!”, as Simulator seems to block access to macOS’s Open Directory user database. However, you should still be able to do everything your logged-in macOS user can do.

To install on a jailbroken device, first [set up Theos](https://git.io/theosinstall). Then, you can run `make do` in the root of the repo.

## License
Licensed under the Apache License, version 2.0. Refer to [LICENSE.md](LICENSE.md).
