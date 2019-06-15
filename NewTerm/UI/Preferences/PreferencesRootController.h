//
//  PreferencesRootController.h
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#if LINK_CEPHEI
#import <Preferences/PSRootController.h>

@interface PreferencesRootController : PSRootController

@end
#else
@import UIKit;

@interface PreferencesRootController : UIViewController

@end
#endif
