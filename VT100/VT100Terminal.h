// VT100Terminal.h
// MobileTeterminal
//
// This header file originally came from the iTerm project, but has been
// modified heavily for use in MobileTerminal.	See the original copyright
// below.
//
// VT100Terminal contains the logic for parsing streams of character data and
// modifying the current state of the VT100Screen.	This low-level component
// should have no direct dependencies on other parts of the VT100 system.
//
// The VT100Terminal is wrapped by the VT100 class which provides a simpler
// interface to use by the higher level text drawing components.
/*`
 **	 VT100Terminal.h
 **
 **	 Copyright (c) 2002, 2003, 2007
 **
 **	 Author: Fabian, Ujwal S. Setlur
 **					 Initial code by Kiichi Kusama
 **
 **	 This program is free software; you can redistribute it and/or modify
 **	 it under the terms of the GNU General Public License as published by
 **	 the Free Software Foundation; either version 2 of the License, or
 **	 (at your option) any later version.
 **
 **	 This program is distributed in the hope that it will be useful,
 **	 but WITHOUT ANY WARRANTY; without even the implied warranty of
 **	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 **	 GNU General Public License for more details.
 **
 **	 You should have received a copy of the GNU General Public License
 **	 along with this program; if not, write to the Free Software
 **	 Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import "VT100Types.h"
#import "VT100Token.h"

#define VT100CSIPARAM_MAX 16

@class VT100Screen;

// character attributes
#define VT100CHARATTR_ALLOFF 0
#define VT100CHARATTR_BOLD 1
#define VT100CHARATTR_UNDER 4
#define VT100CHARATTR_BLINK 5
#define VT100CHARATTR_REVERSE 7

// xterm additions
#define VT100CHARATTR_NORMAL 22
#define VT100CHARATTR_NOT_UNDER 24
#define VT100CHARATTR_STEADY 25
#define VT100CHARATTR_POSITIVE 27

typedef enum {
	COLORCODE_BLACK=0,
	COLORCODE_RED=1,
	COLORCODE_GREEN=2,
	COLORCODE_YELLOW=3,
	COLORCODE_BLUE=4,
	COLORCODE_PURPLE=5,
	COLORCODE_WATER=6,
	COLORCODE_WHITE=7,
	COLORCODE_256=8,
	COLORS
} colorCode;

// 8 color support
#define VT100CHARATTR_FG_BASE 30
#define VT100CHARATTR_BG_BASE 40

#define VT100CHARATTR_FG_BLACK (VT100CHARATTR_FG_BASE + COLORCODE_BLACK)
#define VT100CHARATTR_FG_RED (VT100CHARATTR_FG_BASE + COLORCODE_RED)
#define VT100CHARATTR_FG_GREEN (VT100CHARATTR_FG_BASE + COLORCODE_GREEN)
#define VT100CHARATTR_FG_YELLOW (VT100CHARATTR_FG_BASE + COLORCODE_YELLOW)
#define VT100CHARATTR_FG_BLUE (VT100CHARATTR_FG_BASE + COLORCODE_BLUE)
#define VT100CHARATTR_FG_PURPLE (VT100CHARATTR_FG_BASE + COLORCODE_PURPLE)
#define VT100CHARATTR_FG_WATER (VT100CHARATTR_FG_BASE + COLORCODE_WATER)
#define VT100CHARATTR_FG_WHITE (VT100CHARATTR_FG_BASE + COLORCODE_WHITE)
#define VT100CHARATTR_FG_256 (VT100CHARATTR_FG_BASE + COLORCODE_256)
#define VT100CHARATTR_FG_DEFAULT (VT100CHARATTR_FG_BASE + 9)

#define VT100CHARATTR_BG_BLACK (VT100CHARATTR_BG_BASE + COLORCODE_BLACK)
#define VT100CHARATTR_BG_RED (VT100CHARATTR_BG_BASE + COLORCODE_RED)
#define VT100CHARATTR_BG_GREEN (VT100CHARATTR_BG_BASE + COLORCODE_GREEN)
#define VT100CHARATTR_BG_YELLOW (VT100CHARATTR_BG_BASE + COLORCODE_YELLOW)
#define VT100CHARATTR_BG_BLUE (VT100CHARATTR_BG_BASE + COLORCODE_BLUE)
#define VT100CHARATTR_BG_PURPLE (VT100CHARATTR_BG_BASE + COLORCODE_PURPLE)
#define VT100CHARATTR_BG_WATER (VT100CHARATTR_BG_BASE + COLORCODE_WATER)
#define VT100CHARATTR_BG_WHITE (VT100CHARATTR_BG_BASE + COLORCODE_WHITE)
#define VT100CHARATTR_BG_256 (VT100CHARATTR_BG_BASE + COLORCODE_256)
#define VT100CHARATTR_BG_DEFAULT (VT100CHARATTR_BG_BASE + 9)

// 16 color support
#define VT100CHARATTR_FG_HI_BASE 90
#define VT100CHARATTR_BG_HI_BASE 100

#define VT100CHARATTR_FG_HI_BLACK (VT100CHARATTR_FG_HI_BASE + COLORCODE_BLACK)
#define VT100CHARATTR_FG_HI_RED (VT100CHARATTR_FG_HI_BASE + COLORCODE_RED)
#define VT100CHARATTR_FG_HI_GREEN (VT100CHARATTR_FG_HI_BASE + COLORCODE_GREEN)
#define VT100CHARATTR_FG_HI_YELLOW (VT100CHARATTR_FG_HI_BASE + COLORCODE_YELLOW)
#define VT100CHARATTR_FG_HI_BLUE (VT100CHARATTR_FG_HI_BASE + COLORCODE_BLUE)
#define VT100CHARATTR_FG_HI_PURPLE (VT100CHARATTR_FG_HI_BASE + COLORCODE_PURPLE)
#define VT100CHARATTR_FG_HI_WATER (VT100CHARATTR_FG_HI_BASE + COLORCODE_WATER)
#define VT100CHARATTR_FG_HI_WHITE (VT100CHARATTR_FG_HI_BASE + COLORCODE_WHITE)

#define VT100CHARATTR_BG_HI_BLACK (VT100CHARATTR_BG_HI_BASE + COLORCODE_BLACK)
#define VT100CHARATTR_BG_HI_RED (VT100CHARATTR_BG_HI_BASE + COLORCODE_RED)
#define VT100CHARATTR_BG_HI_GREEN (VT100CHARATTR_BG_HI_BASE + COLORCODE_GREEN)
#define VT100CHARATTR_BG_HI_YELLOW (VT100CHARATTR_BG_HI_BASE + COLORCODE_YELLOW)
#define VT100CHARATTR_BG_HI_BLUE (VT100CHARATTR_BG_HI_BASE + COLORCODE_BLUE)
#define VT100CHARATTR_BG_HI_PURPLE (VT100CHARATTR_BG_HI_BASE + COLORCODE_PURPLE)
#define VT100CHARATTR_BG_HI_WATER (VT100CHARATTR_BG_HI_BASE + COLORCODE_WATER)
#define VT100CHARATTR_BG_HI_WHITE (VT100CHARATTR_BG_HI_BASE + COLORCODE_WHITE)

// color codes & masks
#define FG_COLOR_CODE 0x100
#define BG_COLOR_CODE 0x101
#define SELECTED_TEXT 0x102
#define CURSOR_TEXT 0x103
#define CURSOR_BG 0x104

#define COLOR_CODE_MASK 0x100
#define SELECTION_MASK 0x200
#define BOLD_MASK 0x200
#define BLINK_MASK 0x400
#define UNDER_MASK 0x800

// terminfo stuff
enum {
	TERMINFO_KEY_LEFT, TERMINFO_KEY_RIGHT, TERMINFO_KEY_UP, TERMINFO_KEY_DOWN,
	TERMINFO_KEY_HOME, TERMINFO_KEY_END, TERMINFO_KEY_PAGEDOWN, TERMINFO_KEY_PAGEUP,
	TERMINFO_KEY_F0, TERMINFO_KEY_F1, TERMINFO_KEY_F2, TERMINFO_KEY_F3, TERMINFO_KEY_F4,
	TERMINFO_KEY_F5, TERMINFO_KEY_F6, TERMINFO_KEY_F7, TERMINFO_KEY_F8, TERMINFO_KEY_F9,
	TERMINFO_KEY_F10, TERMINFO_KEY_F11, TERMINFO_KEY_F12, TERMINFO_KEY_F13, TERMINFO_KEY_F14,
	TERMINFO_KEY_F15, TERMINFO_KEY_F16, TERMINFO_KEY_F17, TERMINFO_KEY_F18, TERMINFO_KEY_F19,
	TERMINFO_KEY_F20, TERMINFO_KEY_F21, TERMINFO_KEY_F22, TERMINFO_KEY_F23, TERMINFO_KEY_F24,
	TERMINFO_KEY_F25, TERMINFO_KEY_F26, TERMINFO_KEY_F27, TERMINFO_KEY_F28, TERMINFO_KEY_F29,
	TERMINFO_KEY_F30, TERMINFO_KEY_F31, TERMINFO_KEY_F32, TERMINFO_KEY_F33, TERMINFO_KEY_F34,
	TERMINFO_KEY_F35,
	TERMINFO_KEY_BACKSPACE, TERMINFO_KEY_BACK_TAB,
	TERMINFO_KEY_TAB,
	TERMINFO_KEY_DEL, TERMINFO_KEY_INS,
	TERMINFO_KEY_HELP,
	TERMINFO_KEYS
};

typedef enum {
	MOUSE_REPORTING_NONE = -1,
	MOUSE_REPORTING_NORMAL = 0,
	MOUSE_REPORTING_HILITE,
	MOUSE_REPORTING_BUTTON_MOTION,
	MOUSE_REPORTING_ALL_MOTION,
} mouseMode;

@interface VT100Terminal : NSObject

- (instancetype)init;

@property (nonatomic, strong) NSString *termType;
@property (nonatomic) BOOL trace;
@property (nonatomic) BOOL strictAnsiMode;
@property (nonatomic) BOOL allowColumnMode;
@property (nonatomic) NSStringEncoding encoding;

@property (nonatomic, weak) VT100Screen *currentScreen;
@property (nonatomic, strong) VT100Screen *primaryScreen;
@property (nonatomic, strong) VT100Screen *alternateScreen;

- (void)setMode:(VT100Token *)token;
- (void)setCharAttr:(VT100Token *)token;

- (void)cleanStream;
- (void)putStreamData:(NSData *)data;
- (VT100Token *)getNextToken;

- (void)reset;

- (NSData *)keyArrowUp:(unsigned int)modflag;
- (NSData *)keyArrowDown:(unsigned int)modflag;
- (NSData *)keyArrowLeft:(unsigned int)modflag;
- (NSData *)keyArrowRight:(unsigned int)modflag;
- (NSData *)keyHome:(unsigned int)modflag;
- (NSData *)keyEnd:(unsigned int)modflag;
- (NSData *)keyInsert;
- (NSData *)keyDelete;
- (NSData *)keyBackspace;
- (NSData *)keyPageUp;
- (NSData *)keyPageDown;
- (NSData *)keyFunction:(int)no;
- (NSData *)keyPFn:(int)n;
- (NSData *)keypadData:(unichar)unicode keystr:(NSString *)keystr;

@property (nonatomic, readonly) BOOL lineMode; // YES=Newline, NO=Line feed
@property (nonatomic, readonly) BOOL cursorMode; // YES=Application, NO=Cursor
@property (nonatomic, readonly) BOOL ansiMode; // YES=ANSI, NO=VT52
@property (nonatomic, readonly) BOOL columnMode; // YES=132 Column, NO=80 Column
@property (nonatomic, readonly) BOOL scrollMode; // YES=Smooth, NO=Jump
@property (nonatomic, readonly) BOOL screenMode; // YES=Reverse, NO=Normal
@property (nonatomic, readonly) BOOL originMode; // YES=Relative, NO=Absolute
@property (nonatomic, readonly) BOOL wraparoundMode; // YES=On, NO=Off
@property (nonatomic, readonly) BOOL autorepeatMode; // YES=On, NO=Off
@property (nonatomic, readonly) BOOL interlaceMode; // YES=On, NO=Off
@property (nonatomic, readonly) BOOL keypadMode; // YES=Application, NO=Numeric
@property (nonatomic, readonly) BOOL insertMode; // YES=Insert, NO=Replace
@property (nonatomic, readonly) int charset; // G0...G3
@property (nonatomic, readonly) BOOL xon; // YES=_xon, NO=XOFF
@property (nonatomic, readonly) mouseMode mouseMode;

- (int)foregroundColorCode;
- (int)backgroundColorCode;

- (NSData *)reportActivePositionWithX:(int)x Y:(int)y;
- (NSData *)reportStatus;
- (NSData *)reportDeviceAttribute;
- (NSData *)reportSecondaryDeviceAttribute;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
