//
//  CrossPlatformUI.h
//  NewTerm
//
//  Created by Adam Demasi on 20/6/19.
//

// This is required to get availability headers working
@import Foundation;

#if TARGET_OS_IPHONE
@import UIKit;

#define Color UIColor
#define Font  UIFont
#else
@import AppKit;

#define Color NSColor
#define Font  NSFont

#define NSStringFromCGPoint NSStringFromPoint
#define NSStringFromCGSize  NSStringFromSize
#define NSStringFromCGRect  NSStringFromRect
#endif
