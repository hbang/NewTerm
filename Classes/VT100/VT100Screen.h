// -*- mode:objc -*-
/*
 **  VT100Screen.h
 **
 **  Copyright (c) 2002, 2003, 2007
 **
 **  Author: Fabian, Ujwal S. Setlur
 **          Initial code by Kiichi Kusama
 **          Ported to MobileTerminal (from iTerm) by Allen Porter
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import "VT100Terminal.h"
#import "VT100Types.h"

//_______________________________________________________________________________
//_______________________________________________________________________________

#define TABWINDOW 300

@interface VT100Screen : NSObject
{
    int WIDTH; // width of screen
    int HEIGHT; // height of screen
    int CURSOR_X;
    int CURSOR_Y;
    int SAVE_CURSOR_X;
    int SAVE_CURSOR_Y;
    int SCROLL_TOP;
    int SCROLL_BOTTOM;
    BOOL tabStop[TABWINDOW];

    VT100Terminal *TERMINAL;
    int charset[4], saveCharset[4];
    BOOL blinkShow;
    BOOL PLAYBELL;
    BOOL SHOWBELL;

    BOOL blinkingCursor;

    // single buffer that holds both scrollback and screen contents
    screen_char_t *buffer_lines;
    // buffer holding flags for each char on whether it needs to be redrawn
    char *dirty;
    // a single default line
    screen_char_t *default_line;
    // temporary buffer to store main buffer in SAVE_BUFFER/RESET_BUFFER mode
    screen_char_t *temp_buffer;

    // pointer to last line in buffer
    screen_char_t *last_buffer_line;
    // pointer to first screen line
    screen_char_t *screen_top;
    //pointer to first scrollback line
    screen_char_t *scrollback_top;

    // default line stuff
    char default_bg_code;
    char default_fg_code;
    int default_line_width;

    //scroll back stuff
    BOOL dynamic_scrollback_size;
    // max size of scrollback buffer
    unsigned int max_scrollback_lines;
    // current number of lines in scrollback buffer
    unsigned int current_scrollback_lines;


    // print to ansi...
    BOOL printToAnsi; // YES=ON, NO=OFF, default=NO;
    NSMutableString *printToAnsiString;

    NSLock *screenLock;


    // UI related
    int newWidth, newHeight;
    NSString *newWinTitle;
    NSString *newIconTitle;
    BOOL soundBell;
    int scrollUpLines;
    BOOL printPending;
  
    id <ScreenBufferRefreshDelegate> refreshDelegate;
}

@property (nonatomic, retain) id <ScreenBufferRefreshDelegate> refreshDelegate;

- (id)init;
- (void)dealloc;

- (void)initScreenWithWidth:(int)width Height:(int)height;

- (void)resizeWidth:(int)width height:(int)height;
- (void)reset;
- (void)setWidth:(int)width height:(int)height;
- (int)width;
- (int)height;
- (unsigned int)scrollbackLines;
- (void)setScrollback:(unsigned int)lineCount;
- (void)setTerminal:(VT100Terminal *)terminal;
- (VT100Terminal *)terminal;

- (BOOL)blinkingCursor;
- (void)setBlinkingCursor:(BOOL)flag;
- (void)showCursor:(BOOL)show;
- (void)setPlayBellFlag:(BOOL)flag;
- (void)setShowBellFlag:(BOOL)flag;

// line access
- (screen_char_t *)getLineAtIndex:(int)theIndex;
- (screen_char_t *)getLineAtScreenIndex:(int)theIndex;
- (char *)dirty;

// lock
- (void)acquireLock;
- (void)releaseLock;
- (BOOL)tryLock;

// edit screen buffer
- (void)putToken:(VT100TCC)token;
- (void)clearBuffer;
- (void)clearScrollbackBuffer;
- (void)saveBuffer;
- (void)restoreBuffer;

// internal
- (void)setString:(NSString *)s ascii:(BOOL)ascii;
- (void)setNewLine;
- (void)deleteCharacters:(int)n;
- (void)backSpace;
- (void)setTab;
- (void)clearTabStop;
- (void)clearScreen;
- (void)eraseInDisplay:(VT100TCC)token;
- (void)eraseInLine:(VT100TCC)token;
- (void)selectGraphicRendition:(VT100TCC)token;
- (void)cursorLeft:(int)n;
- (void)cursorRight:(int)n;
- (void)cursorUp:(int)n;
- (void)cursorDown:(int)n;
- (void)cursorToX:(int)x;
- (void)cursorToX:(int)x Y:(int)y;
- (void)saveCursorPosition;
- (void)restoreCursorPosition;
- (void)setTopBottom:(VT100TCC)token;
- (void)scrollUp;
- (void)scrollDown;
- (void)activateBell;
- (void)insertBlank:(int)n;
- (void)insertLines:(int)n;
- (void)deleteLines:(int)n;
- (int)cursorX;
- (int)cursorY;

- (void)resetDirty;
- (void)setDirty;

- (int)numberOfLines;

// print to ansi...
- (BOOL)printToAnsi;
- (void)setPrintToAnsi:(BOOL)aFlag;
- (void)printStringToAnsi:(NSString *)aString;

// UI stuff
- (int)newWidth;
- (int)newHeight;
- (void)updateBell;
- (void)setBell;
- (int)scrollUpLines;
- (void)resetScrollUpLines;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
