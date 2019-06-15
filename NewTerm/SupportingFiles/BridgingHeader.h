//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import UIKit;

#import "Extensions/NSArray+Additions.h"
#import "UI/Keyboard/TextInputBase.h"
#import "UI/Preferences/PreferencesRootController.h"
#import <CompactConstraint/CompactConstraint.h>
#import <VT100/FontMetrics.h>
#import <VT100/VT100.h>
#import <VT100/VT100StringSupplier.h>
#import <VT100/VT100Types.h>
#import <VT100/VT100ColorMap.h>

#if LINK_CEPHEI
#import <Cephei/HBPreferences.h>
#endif

// “The UIKit module currently doesn’t import the newly added NSToolbar and NSTouchBar headers,
// NSToolbar+UIKitAdditions.h and NSTouchBar+UIKitAdditions.h. You can import these headers directly
// in Objective-C, or you can create a bridging header to import them for Swift. Be sure to import
// Foundation before importing these headers.”
// https://developer.apple.com/documentation/macos_release_notes/macos_catalina_10_15_beta_release_notes#3318214
#if TARGET_OS_UIKITFORMAC
#import <UIKit/NSToolbar+UIKitAdditions.h>
#import <UIKit/NSTouchBar+UIKitAdditions.h>
#endif
