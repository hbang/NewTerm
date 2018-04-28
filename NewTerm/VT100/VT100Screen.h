// -*- mode:objc -*-
/*
 **	 VT100Screen.h
 **
 **	 Copyright (c) 2002, 2003, 2007
 **
 **	 Author: Fabian, Ujwal S. Setlur
 **					 Initial code by Kiichi Kusama
 **					 Ported to MobileTerminal (from iTerm) by Allen Porter
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

#import "VT100Terminal.h"
#import "VT100Types.h"

//_______________________________________________________________________________
//_______________________________________________________________________________

#define TABWINDOW 300

@interface VT100Screen : NSObject

@property (nonatomic, strong) VT100Terminal *terminal;
@property (nonatomic, weak) id <ScreenBufferRefreshDelegate> refreshDelegate;

@property (nonatomic) int width, height;

- (void)resizeWidth:(int)width height:(int)height;
- (void)reset;
- (void)setWidth:(int)width height:(int)height;

@property (nonatomic) unsigned int maxScrollbackLines;

@property (nonatomic) BOOL cursorVisible;
@property (nonatomic) BOOL blinkingCursor;

// line access
- (screen_char_t *)getLineAtIndex:(int)theIndex;
- (screen_char_t *)getLineAtScreenIndex:(int)theIndex;

// edit screen buffer
- (void)putToken:(VT100Token *)token;
- (void)clearBuffer;
- (void)clearScrollbackBuffer;

// internal
- (void)setString:(NSString *)s ascii:(BOOL)ascii;
- (void)setNewLine;
- (void)deleteCharacters:(int)n;
- (void)backSpace;
- (void)setTab;
- (void)clearTabStop;
- (void)clearScreen;
- (void)eraseInDisplay:(VT100Token *)token;
- (void)eraseInLine:(VT100Token *)token;
- (void)selectGraphicRendition:(VT100Token *)token;
- (void)cursorLeft:(int)n;
- (void)cursorRight:(int)n;
- (void)cursorUp:(int)n;
- (void)cursorDown:(int)n;
- (void)cursorToX:(int)x;
- (void)cursorToX:(int)x Y:(int)y;
- (void)saveCursorPosition;
- (void)restoreCursorPosition;
- (void)setTopBottom:(VT100Token *)token;
- (void)scrollUp;
- (void)scrollDown;
- (void)activateBell;
- (void)insertBlank:(int)n;
- (void)insertLines:(int)n;
- (void)deleteLines:(int)n;

@property (nonatomic, readonly) int cursorX, cursorY;

- (void)resetDirty;
- (void)setDirty;

- (int)numberOfLines;
- (unsigned int)numberOfScrollbackLines;

// print to ansi...
@property (nonatomic) BOOL printToAnsi;

- (void)printStringToAnsi:(NSString *)aString;

// UI stuff
@property (nonatomic, readonly) int newWidth, newHeight;
@property (nonatomic, readonly) int scrollUpLines;

- (void)resetScrollUpLines;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
