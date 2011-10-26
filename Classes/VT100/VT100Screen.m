// -*- mode:objc -*-
/*
 **  VT100Screen.m
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

// Debug option
#define DEBUG_ALLOC 0
#define DEBUG_METHOD_TRACE 0

#import "VT100Screen.h"

#import "charmaps.h"
#include <string.h>
#include <unistd.h>

#define MAX_SCROLLBACK_LINES 100000
#define DEFAULT_TERMINAL_WIDTH 80
#define DEFAULT_TERMINAL_HEIGHT 24

// we add a character at the end of line to indiacte wrapping
#define REAL_WIDTH (WIDTH+1)

/* translates normal char into graphics char */
void translate(screen_char_t *s, int len)
{
    int i;
    for (i = 0; i < len ; i++) {
        s[i].ch = charmap[(int)(s[i].ch)];
    }
}

/* pad the source string whenever double width character appears */
void padString(NSString *s, screen_char_t *buf, int fg, int bg, int *len,
        NSStringEncoding encoding)
{
    int l=*len;
    int i,j;
    for(i=j=0;i<l;i++,j++) {
        buf[j].ch = [s characterAtIndex:i];
        buf[j].fg_color = fg;
        buf[j].bg_color = bg;
        if (buf[j].ch == 0xfeff || buf[j].ch == 0x200b ||
            buf[j].ch == 0x200c || buf[j].ch == 0x200d) { //zero width space
            j--;
        }
    }
    *len=j;
}

// increments line pointer accounting for buffer wrap-around
static __inline__ screen_char_t *incrementLinePointer(
        screen_char_t *buf_start, screen_char_t *current_line,
        int max_lines, int line_width, BOOL *wrap)
{
    screen_char_t *next_line;

    //include the wrapping indicator
    line_width++;

    next_line = current_line + line_width;
    if (next_line >= (buf_start + line_width *max_lines)) {
        next_line = buf_start;
        if (wrap) {
            *wrap = YES;
        }
    } else if (wrap) {
        *wrap = NO;
    }
    return (next_line);
}

@interface VT100Screen (Private)

- (screen_char_t *)_getLineAtIndex:(int)anIndex
                          fromLine:(screen_char_t *)aLine;
- (screen_char_t *)_getDefaultLineWithWidth:(int)width;
- (BOOL)_addLineToScrollback;

@end

@implementation VT100Screen

#define DEFAULT_SCROLLBACK 1000

#define MIN_WIDTH 10
#define MIN_HEIGHT 3

#define TABSIZE 8

@synthesize refreshDelegate;

- (id)init
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    if ((self = [super init]) == nil)
        return nil;

    WIDTH = DEFAULT_TERMINAL_WIDTH;
    HEIGHT = DEFAULT_TERMINAL_HEIGHT;

    CURSOR_X = CURSOR_Y = 0;
    SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
    SCROLL_TOP = 0;
    SCROLL_BOTTOM = HEIGHT - 1;

    TERMINAL = nil;

    buffer_lines = NULL;
    dirty = NULL;
    last_buffer_line = NULL;
    screen_top = NULL;
    scrollback_top = NULL;

    temp_buffer=NULL;

    max_scrollback_lines = DEFAULT_SCROLLBACK;
    dynamic_scrollback_size = NO;
    [self clearTabStop];

    // set initial tabs
    int i;
    for(i = TABSIZE; i < TABWINDOW; i += TABSIZE) {
        tabStop[i] = YES;
    }

    for(i = 0; i < 4; i++) saveCharset[i] = charset[i] = 0;

    screenLock = [[NSLock alloc] init];

    newWinTitle = nil;
    newIconTitle = nil;
    soundBell =  NO;
    scrollUpLines = 0;
    [self initScreenWithWidth:DEFAULT_TERMINAL_WIDTH Height:DEFAULT_TERMINAL_HEIGHT];
    return self;
}

- (void)dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif

    // free our character buffer
    if (buffer_lines) {
        free(buffer_lines);
    }

    // free our "dirty flags" buffer
    if (dirty) {
        free(dirty);
    }
    // free our default line
    if (default_line) {
        free(default_line);
    }

    if (temp_buffer) {
        free(temp_buffer);
    }

    [printToAnsiString release];

    [super dealloc];
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x, done", __PRETTY_FUNCTION__, self);
#endif
}

- (void)initScreenWithWidth:(int)width Height:(int)height
{
    int total_height;
    screen_char_t *aDefaultLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen initScreenWithWidth:%d Height:%d]", __FILE__, __LINE__, width, height );
#endif

    WIDTH = width;
    HEIGHT = height;
    CURSOR_X = CURSOR_Y = 0;
    SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
    SCROLL_TOP = 0;
    SCROLL_BOTTOM = HEIGHT - 1;
    blinkShow=YES;

    // allocate our buffer to hold both scrollback and screen contents
    total_height = HEIGHT + max_scrollback_lines;
    buffer_lines = (screen_char_t *)malloc(
            total_height *REAL_WIDTH *sizeof(screen_char_t));

    // set up our pointers
    last_buffer_line = buffer_lines + (total_height - 1)*REAL_WIDTH;
    screen_top = buffer_lines;
    scrollback_top = buffer_lines;

    // set all lines in buffer to default
    default_fg_code = [TERMINAL foregroundColorCode];
    default_bg_code = [TERMINAL backgroundColorCode];
    default_line_width = WIDTH;
    aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
    for(int i = 0; i < HEIGHT; i++)
        memcpy([self _getLineAtIndex:i fromLine:buffer_lines], aDefaultLine,
                REAL_WIDTH *sizeof(screen_char_t));

    // set current lines in scrollback
    current_scrollback_lines = 0;

    // set up our dirty flags buffer
    dirty = (char *)malloc(HEIGHT *WIDTH *sizeof(char));

    // force a redraw
    [self setDirty];
}


- (void)acquireLock
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [screenLock lock];
}

- (void)releaseLock
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    [screenLock unlock];
}

- (BOOL)tryLock
{
    return [screenLock tryLock];
}

// gets line at specified index starting from scrollback_top
- (screen_char_t *)getLineAtIndex:(int)theIndex
{
    NSParameterAssert(theIndex >= 0);
    screen_char_t *theLinePointer;

    if (max_scrollback_lines == 0)
        theLinePointer = screen_top;
    else
        theLinePointer = scrollback_top;

    return ([self _getLineAtIndex:theIndex fromLine:theLinePointer]);
}

// gets line at specified index starting from screen_top
- (screen_char_t *)getLineAtScreenIndex:(int)theIndex
{
    return ([self _getLineAtIndex:theIndex fromLine:screen_top]);
}

- (void)setWidth:(int)width height:(int)height
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setWidth:%d height:%d]",
            __FILE__, __LINE__, width, height);
#endif

    if (width >= MIN_WIDTH && height >= MIN_HEIGHT) {
        WIDTH = width;
        HEIGHT = height;
        CURSOR_X = CURSOR_Y = 0;
        SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
        SCROLL_TOP = 0;
        SCROLL_BOTTOM = HEIGHT - 1;
    }
}

- (void)resizeWidth:(int)width height:(int)height
{
    int i, new_total_height;
    screen_char_t *bl, *aLine, *c1, *c2, *new_scrollback_top;

    if (WIDTH == 0 || HEIGHT == 0 || (width==WIDTH && height==HEIGHT)) {
        return;
    }

    [self acquireLock];

    // Try to determine how many empty trailing lines there are on screen
    for(;HEIGHT>CURSOR_Y+1;HEIGHT--) {
        aLine = [self getLineAtScreenIndex: HEIGHT-1];
        for (i=0;i<WIDTH;i++)
            if (aLine[i].ch) break;
        if (i<WIDTH) break;
    }

    // create a new buffer
    new_total_height = max_scrollback_lines + height;
    new_scrollback_top = bl = (screen_char_t *)malloc(new_total_height *(width+1)*sizeof(screen_char_t));

    //copy over the content
    int y1, y2, x1, x2, x3;
    BOOL wrapped = NO, _wrap;
    screen_char_t *defaultLine = [self _getDefaultLineWithWidth: width];

    c2 = bl;
    for(y2=y1=0; y1<current_scrollback_lines+HEIGHT; y1++) {
        c1 = [self getLineAtIndex:y1];
        if (WIDTH == width) {
            memcpy(c2, c1, REAL_WIDTH *sizeof(screen_char_t));
        } else if (WIDTH < width) {
            memcpy(c2, c1, WIDTH *sizeof(screen_char_t));
            c2[width].ch = 0; // no wrapping by default
            x2 = WIDTH;
            while (c1[WIDTH].ch) { //wrapping?
                c1 = [self getLineAtIndex:++y1];
                for(x1=0;x1<WIDTH;x1++,x2++) {
                    for(x3=x1; x3<=WIDTH && !c1[x3].ch; x3++);
                    if (x3>WIDTH) break;
                    if (x2>=width) {
                        c2[width].ch = 1;
                        x2 = 0;
                        if (wrapped) {
                            new_scrollback_top = incrementLinePointer(bl, new_scrollback_top, new_total_height, width, &_wrap);
                        }
                        c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
                        wrapped = wrapped || _wrap;
                        if (_wrap) y2 = 0; else y2++;
                        c2[width].ch = 0;
                    }
                    c2[x2]=c1[x1];
                }
            }
            if (x2<width) memcpy(c2+x2, defaultLine, (width-x2)*sizeof(screen_char_t));
        } else {
            memcpy(c2, c1, width *sizeof(screen_char_t));
            c2[width].ch = 0; // no wrapping by default
            x1 = x2 = width;
            do {
                for(;x1<WIDTH;x1++,x2++) {
                    for(x3=x1; x3<WIDTH && !c1[x3].ch; x3++);
                    if (x3>=WIDTH && !c1[WIDTH].ch) break;
                    if (x2>=width) {
                        c2[width].ch = 1;
                        x2 = 0;
                        if (wrapped) {
                            new_scrollback_top = incrementLinePointer(bl, new_scrollback_top, new_total_height, width, &_wrap);
                        }
                        c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
                        wrapped = wrapped || _wrap;
                        if (_wrap) y2 = 0; else y2++;
                        c2[width].ch = 0;
                    }
                    c2[x2]=c1[x1];
                }
                if (c1[WIDTH].ch) {
                    c1 = [self getLineAtIndex:++y1];
                    x1 = 0;
                } else
                    break;
            } while (1);
            if (x2<width) memcpy(c2+x2, defaultLine, (width-x2)*sizeof(screen_char_t));
        }

        if (wrapped) {
            new_scrollback_top = incrementLinePointer(bl, new_scrollback_top, new_total_height, width, &_wrap);
        }
        c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
        wrapped = wrapped || _wrap;
        if (_wrap) y2 = 0; else y2++;
    }

    // reassign our pointers
    if(buffer_lines)
        free(buffer_lines);
    buffer_lines = bl;
    scrollback_top = new_scrollback_top;
    last_buffer_line = bl + (new_total_height - 1)*(width+1);
    if (max_scrollback_lines > 0) {
        if (wrapped) {
            current_scrollback_lines = max_scrollback_lines;
            CURSOR_Y = height - 1;
        } else {
            if (y2 <= height) {
                current_scrollback_lines = 0;
                CURSOR_Y = y2 - 1;
            } else {
                current_scrollback_lines = y2 - height ;
                CURSOR_Y = height - 1;
            }
        }
    } else {
        current_scrollback_lines = 0;
        CURSOR_Y = wrapped ? height - 1 : y2 - 1;
    }

    screen_top = scrollback_top + current_scrollback_lines *(width+1);
    if (screen_top > last_buffer_line)
        screen_top = bl + (screen_top - last_buffer_line) - width - 1;

    // set the rest of new buffer (if any) to default line
    if (!wrapped) {
        for(;y2 < new_total_height; y2++) {
            memcpy(c2, defaultLine, (width+1)*sizeof(screen_char_t));
            c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
        }
    }

    // new height and width
    WIDTH = width;
    HEIGHT = height;

    // reset terminal scroll top and bottom
    SCROLL_TOP = 0;
    SCROLL_BOTTOM = HEIGHT - 1;

    // adjust X coordinate of cursor
    if (CURSOR_X >= width)
        CURSOR_X = width-1;
    if (SAVE_CURSOR_X >= width)
        SAVE_CURSOR_X = width-1;
    if (CURSOR_Y >= height)
        CURSOR_Y = height-1;
    if (SAVE_CURSOR_Y >= height)
        SAVE_CURSOR_Y = height-1;

    // if we did the resize in SAVE_BUFFER mode, too bad, get rid of it
    if (temp_buffer) {
        free(temp_buffer);
        temp_buffer=NULL;
    }

    // force a redraw
    if(dirty)
        free(dirty);
    dirty=(char *)malloc(height *width *sizeof(char));
    [self setDirty];
    // release lock
    [self releaseLock];

    // An immediate refresh is needed so that the size of TEXTVIEW can be
    // adjusted to fit the new size
    [refreshDelegate refresh];
}

- (void)reset
{
    // reset terminal scroll top and bottom
    SCROLL_TOP = 0;
    SCROLL_BOTTOM = HEIGHT - 1;

    [self clearScreen];
    [self clearTabStop];
    SAVE_CURSOR_X = 0;
    CURSOR_Y = 0;
    SAVE_CURSOR_Y = 0;

    // set initial tabs
    int i;
    for(i = TABSIZE; i < TABWINDOW; i += TABSIZE)
        tabStop[i] = YES;

    for(i=0;i<4;i++) saveCharset[i]=charset[i]=0;

    [self showCursor: YES];
    newWinTitle = nil;
    newIconTitle = nil;
    soundBell = NO;
}

- (int)width
{
    return WIDTH;
}

- (int)height
{
    return HEIGHT;
}

- (unsigned int)scrollbackLines
{
    return max_scrollback_lines;
}

// sets scrollback lines.
- (void)setScrollback:(unsigned int)lineCount;
{
    // if we already have a buffer, don't allow this
    if(buffer_lines != NULL)
        return;

    if (lineCount > MAX_SCROLLBACK_LINES) {
        dynamic_scrollback_size = YES;
        max_scrollback_lines = DEFAULT_SCROLLBACK;
    } else {
        dynamic_scrollback_size = NO;
        max_scrollback_lines = lineCount;
    }
}

- (void)setTerminal:(VT100Terminal *)terminal
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTerminal:%@]",
            __FILE__, __LINE__, terminal);
#endif
    TERMINAL = terminal;
}

- (VT100Terminal *)terminal
{
    return TERMINAL;
}

- (BOOL)blinkingCursor
{
    return (blinkingCursor);
}

- (void)setBlinkingCursor:(BOOL)flag
{
    blinkingCursor = flag;
}

- (void)putToken:(VT100TCC)token
{

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen putToken:%d (%d)]",__FILE__, __LINE__, token,
            token.type);
#endif
    int i,j,k;
    screen_char_t *aLine;

    [self acquireLock];

    // Keep track of the old cursor location so that we can mark it dirty of the
    // screen is redrawn.
    int oldCursorX = CURSOR_X;
    int oldCursorY = CURSOR_Y;

    switch (token.type) {
        // our special code
        case VT100_STRING:
   case VT100_ASCIISTRING:
            // check if we are in print mode
            if ([self printToAnsi] == YES)
                [self printStringToAnsi: token.u.string];
            // else display string on screen
            else
                [self setString:token.u.string ascii: token.type == VT100_ASCIISTRING];
            break;
   case VT100_UNKNOWNCHAR: break;
   case VT100_NOTSUPPORT: break;

                          // VT100 CC
   case VT100CC_ENQ: break;
   case VT100CC_BEL: soundBell = YES; break;
   case VT100CC_BS: [self backSpace]; break;
   case VT100CC_HT: [self setTab]; break;
   case VT100CC_LF:
   case VT100CC_VT:
   case VT100CC_FF:
                     if ([self printToAnsi] == YES) {
                         [self printStringToAnsi: @"\n"];
                     } else {
                         [self setNewLine];
                     }
                     break;
   case VT100CC_CR: CURSOR_X = 0; break;
   case VT100CC_SO: break;
   case VT100CC_SI: break;
   case VT100CC_DC1: break;
   case VT100CC_DC3: break;
   case VT100CC_CAN:
   case VT100CC_SUB: break;
   case VT100CC_DEL:
                      [self deleteCharacters:1];
                      break;

                      // VT100 CSI
   case VT100CSI_CPR: break;
   case VT100CSI_CUB: [self cursorLeft:token.u.csi.p[0]]; break;
   case VT100CSI_CUD: [self cursorDown:token.u.csi.p[0]]; break;
   case VT100CSI_CUF: [self cursorRight:token.u.csi.p[0]]; break;
   case VT100CSI_CUP:
     [self cursorToX:token.u.csi.p[1] Y:token.u.csi.p[0]];
     break;
   case VT100CSI_CUU: [self cursorUp:token.u.csi.p[0]]; break;
   case VT100CSI_DA:
                      NSLog(@"Not implemented DA");
                      break;
                      // case VT100CSI_DA: [self deviceAttribute:token]; break;
   case VT100CSI_DECALN:
                      for (i = 0; i < HEIGHT; i++) {
                          aLine = [self getLineAtScreenIndex: i];
                          for(j = 0; j < WIDTH; j++) {
                              aLine[j].ch ='E';
                              aLine[j].fg_color = [TERMINAL foregroundColorCode];
                              aLine[j].bg_color = [TERMINAL backgroundColorCode];
                          }
                          aLine[WIDTH].ch = 0;
                      }
                      [self setDirty];
                      break;
   case VT100CSI_DECDHL: break;
   case VT100CSI_DECDWL: break;
   case VT100CSI_DECID: break;
   case VT100CSI_DECKPAM: break;
   case VT100CSI_DECKPNM: break;
   case VT100CSI_DECLL: break;
   case VT100CSI_DECRC: [self restoreCursorPosition]; break;
   case VT100CSI_DECREPTPARM: break;
   case VT100CSI_DECREQTPARM: break;
   case VT100CSI_DECSC: [self saveCursorPosition]; break;
   case VT100CSI_DECSTBM: [self setTopBottom:token]; break;
   case VT100CSI_DECSWL: break;
   case VT100CSI_DECTST: break;
   case VT100CSI_DSR:
                         NSLog(@"Not implemented DSR");
                         break;
                         // case VT100CSI_DSR: [self deviceReport:token]; break;
   case VT100CSI_ED: [self eraseInDisplay:token]; break;
   case VT100CSI_EL: [self eraseInLine:token]; break;
   case VT100CSI_HTS: if (CURSOR_X<WIDTH) tabStop[CURSOR_X]=YES; break;
   case VT100CSI_HVP:
     [self cursorToX:token.u.csi.p[1] Y:token.u.csi.p[0]];
     break;
   case VT100CSI_NEL:
     CURSOR_X=0;
   case VT100CSI_IND:
     if (CURSOR_Y == SCROLL_BOTTOM) {
         [self scrollUp];
     } else {
         CURSOR_Y++;
         if (CURSOR_Y>=HEIGHT) {
             CURSOR_Y=HEIGHT-1;
         }
     }
     break;
   case VT100CSI_RI:
     if(CURSOR_Y == SCROLL_TOP) {
         [self scrollDown];
     } else {
         CURSOR_Y--;
         if (CURSOR_Y<0) {
             CURSOR_Y=0;
         }
     }
     break;
   case VT100CSI_RIS: break;
   case VT100CSI_RM: break;
   case VT100CSI_SCS0: charset[0]=(token.u.code=='0'); break;
   case VT100CSI_SCS1: charset[1]=(token.u.code=='0'); break;
   case VT100CSI_SCS2: charset[2]=(token.u.code=='0'); break;
   case VT100CSI_SCS3: charset[3]=(token.u.code=='0'); break;
   case VT100CSI_SGR: [self selectGraphicRendition:token]; break;
   case VT100CSI_SM: break;
   case VT100CSI_TBC:
                     switch (token.u.csi.p[0]) {
                         case 3: [self clearTabStop]; break;
                         case 0: if (CURSOR_X<WIDTH) tabStop[CURSOR_X]=NO;
                     }
                     break;

   case VT100CSI_DECSET:
   case VT100CSI_DECRST:
                     if (token.u.csi.p[0]==3 && [TERMINAL allowColumnMode] == YES) {
                         // set the column
                         newWidth = [TERMINAL columnMode]?132:80;
                         newHeight = HEIGHT;
                     }
                     break;
                     // ANSI CSI
   case ANSICSI_CHA:
    [self cursorToX: token.u.csi.p[0]];
    break;
   case ANSICSI_VPA:
    [self cursorToX: CURSOR_X+1 Y: token.u.csi.p[0]];
    break;
   case ANSICSI_VPR:
    [self cursorToX: CURSOR_X+1 Y: token.u.csi.p[0]+CURSOR_Y+1];
    break;
   case ANSICSI_ECH:
    if (CURSOR_X<WIDTH) {
        i=WIDTH *CURSOR_Y+CURSOR_X;
        j=token.u.csi.p[0];
        if (j + CURSOR_X > WIDTH)
            j = WIDTH - CURSOR_X;
        aLine = [self getLineAtScreenIndex: CURSOR_Y];
        for(k = 0; k < j; k++) {
            aLine[CURSOR_X+k].ch = 0;
            aLine[CURSOR_X+k].fg_color = [TERMINAL foregroundColorCode];
            aLine[CURSOR_X+k].bg_color = [TERMINAL backgroundColorCode];
        }
        memset(dirty+i,1,j);
    }
    break;

   case STRICT_ANSI_MODE:
                      [TERMINAL setStrictAnsiMode: ![TERMINAL strictAnsiMode]];
                      break;

   case ANSICSI_PRINT:
                      switch (token.u.csi.p[0]) {
                          case 4:
                              // print our stuff!!
                              printPending = YES;
                              break;
                          case 5:
                              // allocate a string for the stuff to be printed
                              if (printToAnsiString != nil)
                                  [printToAnsiString release];
                              printToAnsiString = [[NSMutableString alloc] init];
                              [self setPrintToAnsi: YES];
                              break;
                          default:
                              //print out the whole screen
                              if (printToAnsiString != nil)
                                  [printToAnsiString release];
                              printToAnsiString = nil;
                              [self setPrintToAnsi: NO];
                              printPending = YES;
                      }
                      break;
   case XTERMCC_INSBLNK: [self insertBlank:token.u.csi.p[0]]; break;
   case XTERMCC_INSLN: [self insertLines:token.u.csi.p[0]]; break;
   case XTERMCC_DELCH: [self deleteCharacters:token.u.csi.p[0]]; break;
   case XTERMCC_DELLN: [self deleteLines:token.u.csi.p[0]]; break;
   case XTERMCC_SU:
                       for (i=0; i<token.u.csi.p[0]; i++) [self scrollUp];
                       break;
   case XTERMCC_SD:
                       for (i=0; i<token.u.csi.p[0]; i++) [self scrollDown];
                       break;


   default:
                        NSLog(@"%s(%d): Unexpected token.type = %d",
                                __FILE__, __LINE__, token.type);
                        break;
    }
    if (oldCursorX != CURSOR_X || oldCursorY != CURSOR_Y) {
        dirty[oldCursorY *WIDTH+oldCursorX] = 1;
    }
    [self releaseLock];
}

- (void)clearBuffer
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearBuffer]", __FILE__, __LINE__ );
#endif

    [self clearScreen];
    [self clearScrollbackBuffer];
}

- (void)clearScrollbackBuffer
{
    int i;
    screen_char_t *aLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearScrollbackBuffer]", __FILE__, __LINE__ );
#endif

    [self acquireLock];

    if (max_scrollback_lines) {
        aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
        for(i = 0; i < current_scrollback_lines; i++) {
            aLine = [self getLineAtIndex:i];
            memcpy(aLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
        }

        current_scrollback_lines = 0;
        scrollback_top = screen_top;

    }

    [self releaseLock];
    [self setDirty];
    [refreshDelegate refresh];
}

- (void)saveBuffer
{
    int size=REAL_WIDTH *HEIGHT;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif

    [self acquireLock];

    if (temp_buffer)
        free(temp_buffer);

    int n = (screen_top - buffer_lines)/REAL_WIDTH - max_scrollback_lines;

    temp_buffer=(screen_char_t *)malloc(size *(sizeof(screen_char_t)));
    if (n <= 0)
        memcpy(temp_buffer, screen_top, size *sizeof(screen_char_t));
    else {
        memcpy(temp_buffer, screen_top, (HEIGHT-n)*REAL_WIDTH *sizeof(screen_char_t));
        memcpy(temp_buffer+(HEIGHT-n)*REAL_WIDTH, buffer_lines, n *REAL_WIDTH *sizeof(screen_char_t));
    }

    [self releaseLock];
}

- (void)restoreBuffer
{

#if DEBUG_METHOD_TRACE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif

    if (!temp_buffer)
        return;

    [self acquireLock];

    int n = (screen_top - buffer_lines)/REAL_WIDTH - max_scrollback_lines;

    if (n<=0)
        memcpy(screen_top, temp_buffer, REAL_WIDTH *HEIGHT *sizeof(screen_char_t));
    else {
        memcpy(screen_top, temp_buffer, (HEIGHT-n)*REAL_WIDTH *sizeof(screen_char_t));
        memcpy(buffer_lines, temp_buffer+(HEIGHT-n)*REAL_WIDTH, n *REAL_WIDTH *sizeof(screen_char_t));
    }


    [self setDirty];

    free(temp_buffer);
    temp_buffer = NULL;
    [self releaseLock];

}

- (BOOL)printToAnsi
{
    return (printToAnsi);
}

- (void)setPrintToAnsi:(BOOL)aFlag
{
    printToAnsi = aFlag;
}

- (void)printStringToAnsi:(NSString *)aString
{
    if([aString length] > 0)
        [printToAnsiString appendString: aString];
}

- (void)setString:(NSString *)string ascii:(BOOL)ascii
{
    screen_char_t *buffer;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setString:%@ at %d]",
            __FILE__, __LINE__, string, CURSOR_X);
#endif

    int len;
    if ((len=[string length]) < 1 || !string) {
        NSLog(@"%s: invalid string '%@'", __PRETTY_FUNCTION__, string);
        return;
    }
    if (ascii) {
        unichar *sc = (unichar *) malloc(len *sizeof(unichar));
        int fg=[TERMINAL foregroundColorCode], bg=[TERMINAL backgroundColorCode];

        buffer = (screen_char_t *) malloc([string length] * sizeof(screen_char_t));
        if (!buffer) {
            NSLog(@"%s: Out of memory", __PRETTY_FUNCTION__);
            return;
        }

        [string getCharacters: sc];
        int i;
        for (i = 0; i < len; i++) {
            buffer[i].ch = sc[i];
            buffer[i].fg_color = fg;
            buffer[i].bg_color = bg;
        }

        // check for graphical characters
        if (charset[[TERMINAL charset]]) {
            translate(buffer,len);
        }
        // NSLog(@"%d(%d):%@",[TERMINAL charset],charset[[TERMINAL charset]],string);
        free(sc);
    } else {
        string = [string precomposedStringWithCanonicalMapping];
        len=[string length];
        buffer = (screen_char_t *) malloc( 2 * len *sizeof(screen_char_t) );
        if (!buffer) {
            NSLog(@"%s: Out of memory", __PRETTY_FUNCTION__);
            return;
        }
        padString(string, buffer, [TERMINAL foregroundColorCode],
                [TERMINAL backgroundColorCode], &len, [TERMINAL encoding]);
    }

    if (len < 1)
        return;

    // TODO(allen): Implement insert mode
    for (int idx = 0; idx < len; idx++) {
        // cut off in the middle of double width characters
        if (buffer[idx].ch == 0xffff) {
            buffer[idx].ch = '#';
        }
        screen_char_t *aLine = [self getLineAtScreenIndex: CURSOR_Y];
        aLine[CURSOR_X] = buffer[idx];
        dirty[CURSOR_Y * WIDTH + CURSOR_X] = 1;
      
        // Dirty the new cursor position
        CURSOR_X++;
        dirty[CURSOR_Y * WIDTH + CURSOR_X] = 1;
      
        // Wrap
        if (CURSOR_X >= WIDTH) {
            CURSOR_X = 0;
            [self getLineAtScreenIndex: CURSOR_Y][WIDTH].ch = 1;
            [self setNewLine]; 
        }
    }
  
    free(buffer);

#if DEBUG_METHOD_TRACE
    NSLog(@"setString done at %d", CURSOR_X);
#endif
}

- (void)setNewLine
{
    screen_char_t *aLine;
    BOOL wrap = NO;
    int total_height;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setNewLine](%d,%d)-[%d,%d]", __FILE__, __LINE__, CURSOR_X, CURSOR_Y, SCROLL_TOP, SCROLL_BOTTOM);
#endif

    if (CURSOR_Y < SCROLL_BOTTOM || (CURSOR_Y < (HEIGHT - 1) && CURSOR_Y > SCROLL_BOTTOM)) {
        CURSOR_Y++;
        if (CURSOR_X < WIDTH) {
            dirty[CURSOR_Y * WIDTH + CURSOR_X] = 1;
        }
    } else if (SCROLL_TOP == 0 && SCROLL_BOTTOM == HEIGHT - 1) {
        total_height = max_scrollback_lines + HEIGHT;

        // try to add top line to scroll area
        if (max_scrollback_lines > 0) {
            if ([self _addLineToScrollback]) {
                // TODO(allen): This could probably be a bit smarter
                // scroll buffer overflow, entire screen needs to be redrawn
                [self setDirty];
            } else{
                // top line can move into scroll area; we need to draw only bottom line
                //dirty[WIDTH *(CURSOR_Y-1)*sizeof(char)+CURSOR_X-1]=1;
                memmove(dirty, dirty+WIDTH *sizeof(char), WIDTH *(HEIGHT-1)*sizeof(char));
                memset(dirty+WIDTH *(HEIGHT-1)*sizeof(char),1,WIDTH *sizeof(char));
            };
        } else
            [self setDirty];

        // Increment screen_top pointer
        screen_top = incrementLinePointer(buffer_lines, screen_top, total_height, WIDTH, &wrap);

        // set last screen line default
        aLine = [self getLineAtScreenIndex: (HEIGHT - 1)];
        memcpy(aLine, [self _getDefaultLineWithWidth: WIDTH], REAL_WIDTH *sizeof(screen_char_t));

    } else {
        [self scrollUp];
    }
}

- (void)deleteCharacters:(int)n
{
    screen_char_t *aLine;
    int i;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deleteCharacter]: %d", __FILE__, __LINE__, n);
#endif

    if (CURSOR_X >= 0 && CURSOR_X < WIDTH &&
            CURSOR_Y >= 0 && CURSOR_Y < HEIGHT) {
        int idx;

        idx=CURSOR_Y *WIDTH;
        if (n+CURSOR_X>WIDTH) n=WIDTH-CURSOR_X;

        // get the appropriate screen line
        aLine = [self getLineAtScreenIndex: CURSOR_Y];

        if (n<WIDTH) {
            memmove(aLine + CURSOR_X, aLine + CURSOR_X + n, (WIDTH-CURSOR_X-n)*sizeof(screen_char_t));
        }
        for(i = 0; i < n; i++) {
            aLine[WIDTH-n+i].ch = 0;
            aLine[WIDTH-n+i].fg_color = [TERMINAL foregroundColorCode];
            aLine[WIDTH-n+i].bg_color = [TERMINAL backgroundColorCode];
        }
        memset(dirty+idx+CURSOR_X,1,WIDTH-CURSOR_X);
    }
}

- (void)backSpace
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen backSpace]", __FILE__, __LINE__);
#endif
    if (CURSOR_X > 0)
        CURSOR_X--;
}

- (void)setTab
{

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTab]", __FILE__, __LINE__);
#endif

    CURSOR_X++; // ensure we go to the next tab in case we are already on one
    for(;!tabStop[CURSOR_X]&&CURSOR_X<WIDTH; CURSOR_X++);
    if (CURSOR_X >= WIDTH)
        CURSOR_X =  WIDTH - 1;
}

- (void)clearScreen
{
    screen_char_t *aLine, *aDefaultLine;
    int i;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearScreen]; CURSOR_Y = %d", __FILE__, __LINE__, CURSOR_Y);
#endif
    [self acquireLock];
    // Clear the screen by overwriting everything with the default (blank) line
    aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
    for (i = 0; i < HEIGHT; ++i) {
        aLine = [self getLineAtScreenIndex:i];
        memcpy(aLine, aDefaultLine, REAL_WIDTH * sizeof(screen_char_t));
    }
    CURSOR_X = 0;
    CURSOR_Y = 0;
    // all the screen is dirty
    [self setDirty];
    [self releaseLock];
}

- (void)eraseInDisplay:(VT100TCC)token
{
    int x1, y1, x2, y2;
    int i, total_height;
    screen_char_t *aScreenChar;
    //BOOL wrap;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen eraseInDisplay:(param=%d); X = %d; Y = %d]",
            __FILE__, __LINE__, token.u.csi.p[0], CURSOR_X, CURSOR_Y);
#endif
    switch (token.u.csi.p[0]) {
        case 1:
            x1 = 0;
            y1 = 0;
            x2 = CURSOR_X<WIDTH?CURSOR_X+1:WIDTH;
            y2 = CURSOR_Y;
            break;

        case 2:
            x1 = 0;
            y1 = 0;
            x2 = 0;
            y2 = HEIGHT;

            break;

        case 0:
       default:
            x1 = CURSOR_X;
            y1 = CURSOR_Y;
            x2 = 0;
            y2 = HEIGHT;
            break;
    }


    int idx1, idx2;

    idx1=y1 *REAL_WIDTH+x1;
    idx2=y2 *REAL_WIDTH+x2;

    total_height = max_scrollback_lines + HEIGHT;

    // clear the contents between idx1 and idx2
    for(i = idx1, aScreenChar = screen_top + idx1; i < idx2; i++, aScreenChar++) {
        if(aScreenChar >= (buffer_lines + total_height *REAL_WIDTH))
            aScreenChar = buffer_lines; // wrap around to top of buffer
        aScreenChar->ch = 0;
        aScreenChar->fg_color = [TERMINAL foregroundColorCode];
        aScreenChar->bg_color = [TERMINAL backgroundColorCode];
    }

    memset(dirty+y1 *WIDTH+x1,1,((y2-y1)*WIDTH+(x2-x1))*sizeof(char));
}

- (void)eraseInLine:(VT100TCC)token
{
    screen_char_t *aLine;
    int i;
    int idx, x1 ,x2;
    int fgCode, bgCode;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen eraseInLine:(param=%d); X = %d; Y = %d]",
            __FILE__, __LINE__, token.u.csi.p[0], CURSOR_X, CURSOR_Y);
#endif


    x1 = x2 = 0;
    switch (token.u.csi.p[0]) {
        case 1:
            x1=0;
            x2=CURSOR_X<WIDTH?CURSOR_X+1:WIDTH;
            break;
        case 2:
            x1 = 0;
            x2 = WIDTH;
            break;
        case 0:
            x1=CURSOR_X;
            x2=WIDTH;
            break;
    }
    aLine = [self getLineAtScreenIndex: CURSOR_Y];

    // I'm commenting out the following code. I'm not sure about OpenVMS, but this code produces wrong result
    // when I use vttest program for testing the color features. --fabian

    // if we erasing entire lines, set to default foreground and background colors. Some systems (like OpenVMS)
    // do not send explicit video information
    //if(x1 == 0 && x2 == WIDTH)
    //{
    // fgCode = FG_COLOR_CODE;
    // bgCode = BG_COLOR_CODE;
    //}
    //else
    //{
    fgCode = [TERMINAL foregroundColorCode];
    bgCode = [TERMINAL backgroundColorCode];
    //}


    for(i = x1; i < x2; i++) {
        aLine[i].ch = 0;
        aLine[i].fg_color = fgCode;
        aLine[i].bg_color = bgCode;
    }

    idx=CURSOR_Y *WIDTH+x1;
    memset(dirty+idx,1,(x2-x1)*sizeof(char));
}

- (void)selectGraphicRendition:(VT100TCC)token
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen selectGraphicRendition:...]",
            __FILE__, __LINE__);
#endif
}

- (void)cursorLeft:(int)n
{
    int x = CURSOR_X - (n>0?n:1);

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorLeft:%d]",
            __FILE__, __LINE__, n);
#endif
    if (x < 0)
        x = 0;
    if (x >= 0 && x < WIDTH)
        CURSOR_X = x;

    dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;
}

- (void)cursorRight:(int)n
{
    int x = CURSOR_X + (n>0?n:1);

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorRight:%d]",
            __FILE__, __LINE__, n);
#endif
    if (x >= WIDTH)
        x =  WIDTH - 1;
    if (x >= 0 && x < WIDTH)
        CURSOR_X = x;

    dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;
}

- (void)cursorUp:(int)n
{
    int y = CURSOR_Y - (n>0?n:1);

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorUp:%d]",
            __FILE__, __LINE__, n);
#endif
    if(CURSOR_Y >= SCROLL_TOP)
        CURSOR_Y=y<SCROLL_TOP?SCROLL_TOP:y;
    else
        CURSOR_Y = y;

    if (CURSOR_X<WIDTH) dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;
}

- (void)cursorDown:(int)n
{
    int y = CURSOR_Y + (n>0?n:1);

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorDown:%d, Y = %d; SCROLL_BOTTOM = %d]",
            __FILE__, __LINE__, n, CURSOR_Y, SCROLL_BOTTOM);
#endif
    if(CURSOR_Y <= SCROLL_BOTTOM)
        CURSOR_Y=y>SCROLL_BOTTOM?SCROLL_BOTTOM:y;
    else
        CURSOR_Y = y;

    if (CURSOR_X<WIDTH) dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;
}

- (void)cursorToX:(int)x
{
    int x_pos;


#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorToX:%d]",
            __FILE__, __LINE__, x);
#endif
    x_pos = (x-1);

    if(x_pos < 0)
        x_pos = 0;
    else if(x_pos >= WIDTH)
        x_pos = WIDTH - 1;

    CURSOR_X = x_pos;

    dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;
}

- (void)cursorToX:(int)x Y:(int)y
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorToX:%d Y:%d]",
            __FILE__, __LINE__, x, y);
#endif
    int x_pos, y_pos;


    x_pos = x - 1;
    y_pos = y - 1;

    if ([TERMINAL originMode]) y_pos += SCROLL_TOP;

    if (x_pos < 0)
        x_pos = 0;
    else if (x_pos >= WIDTH)
        x_pos = WIDTH - 1;
    if (y_pos < 0)
        y_pos = 0;
    else if (y_pos >= HEIGHT)
        y_pos = HEIGHT - 1;

    CURSOR_X = x_pos;
    CURSOR_Y = y_pos;

    dirty[CURSOR_Y *WIDTH+CURSOR_X] = 1;

    // NSParameterAssert(CURSOR_X >= 0 && CURSOR_X < WIDTH);

}

- (void)saveCursorPosition
{
    int i;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen saveCursorPosition]",
            __FILE__, __LINE__);
#endif

    if(CURSOR_X < 0)
        CURSOR_X = 0;
    if(CURSOR_X >= WIDTH)
        CURSOR_X = WIDTH-1;
    if(CURSOR_Y < 0)
        CURSOR_Y = 0;
    if(CURSOR_Y >= HEIGHT)
        CURSOR_Y = HEIGHT;

    SAVE_CURSOR_X = CURSOR_X;
    SAVE_CURSOR_Y = CURSOR_Y;

    for(i=0;i<4;i++) saveCharset[i]=charset[i];

}

- (void)restoreCursorPosition
{
    int i;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen restoreCursorPosition]",
            __FILE__, __LINE__);
#endif
    CURSOR_X = SAVE_CURSOR_X;
    CURSOR_Y = SAVE_CURSOR_Y;

    for(i=0;i<4;i++) charset[i]=saveCharset[i];

    NSParameterAssert(CURSOR_X >= 0 && CURSOR_X < WIDTH);
    NSParameterAssert(CURSOR_Y >= 0 && CURSOR_Y < HEIGHT);
}

- (void)setTopBottom:(VT100TCC)token
{
    int top, bottom;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTopBottom:(%d,%d)]",
            __FILE__, __LINE__, token.u.csi.p[0], token.u.csi.p[1]);
#endif

    top = token.u.csi.p[0] == 0 ? 0 : token.u.csi.p[0] - 1;
    bottom = token.u.csi.p[1] == 0 ? HEIGHT - 1 : token.u.csi.p[1] - 1;
    if (top >= 0 && top < HEIGHT &&
            bottom >= 0 && bottom < HEIGHT &&
            bottom >= top) {
        SCROLL_TOP = top;
        SCROLL_BOTTOM = bottom;

        if ([TERMINAL originMode]) {
            CURSOR_X = 0;
            CURSOR_Y = SCROLL_TOP;
        } else {
            CURSOR_X = 0;
            CURSOR_Y = 0;
        }
    }
}

- (void)scrollUp
{
    int i;
    screen_char_t *sourceLine, *targetLine;

    //#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen scrollUp]", __FILE__, __LINE__);
    //#endif

    NSParameterAssert(SCROLL_TOP >= 0 && SCROLL_TOP < HEIGHT);
    NSParameterAssert(SCROLL_BOTTOM >= 0 && SCROLL_BOTTOM < HEIGHT);
    NSParameterAssert(SCROLL_TOP <= SCROLL_BOTTOM );

    if (SCROLL_TOP == 0 && SCROLL_BOTTOM == HEIGHT -1) {
        [self setNewLine];
    } else if (SCROLL_TOP<SCROLL_BOTTOM) {
        // SCROLL_TOP is not top of screen; move all lines between SCROLL_TOP and SCROLL_BOTTOM one line up
        // check if the screen area is wrapped
        sourceLine = [self getLineAtScreenIndex: SCROLL_TOP];
        targetLine = [self getLineAtScreenIndex: SCROLL_BOTTOM];
        if(sourceLine < targetLine) {
            // screen area is not wrapped; direct memmove
            memmove(screen_top+SCROLL_TOP *REAL_WIDTH, screen_top+(SCROLL_TOP+1)*REAL_WIDTH, (SCROLL_BOTTOM-SCROLL_TOP)*REAL_WIDTH *sizeof(screen_char_t));
        } else {
            // screen area is wrapped; copy line by line
            for(i = SCROLL_TOP; i < SCROLL_BOTTOM; i++) {
                sourceLine = [self getLineAtScreenIndex:i+1];
                targetLine = [self getLineAtScreenIndex: i];
                memmove(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
            }
        }
        // new line at SCROLL_BOTTOM with default settings
        targetLine = [self getLineAtScreenIndex:SCROLL_BOTTOM];
        memcpy(targetLine, [self _getDefaultLineWithWidth: WIDTH], REAL_WIDTH *sizeof(screen_char_t));

        // everything between SCROLL_TOP and SCROLL_BOTTOM is dirty
        memset(dirty+SCROLL_TOP *WIDTH,1,(SCROLL_BOTTOM-SCROLL_TOP+1)*WIDTH *sizeof(char));
    }
}

- (void)scrollDown
{
    int i;
    screen_char_t *sourceLine, *targetLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen scrollDown]", __FILE__, __LINE__);
#endif

    NSParameterAssert(SCROLL_TOP >= 0 && SCROLL_TOP < HEIGHT);
    NSParameterAssert(SCROLL_BOTTOM >= 0 && SCROLL_BOTTOM < HEIGHT);
    NSParameterAssert(SCROLL_TOP <= SCROLL_BOTTOM );

    if (SCROLL_TOP<SCROLL_BOTTOM) {
        // move all lines between SCROLL_TOP and SCROLL_BOTTOM one line down
        // check if screen is wrapped
        sourceLine = [self getLineAtScreenIndex:SCROLL_TOP];
        targetLine = [self getLineAtScreenIndex:SCROLL_BOTTOM];
        if(sourceLine < targetLine) {
            // screen area is not wrapped; direct memmove
            memmove(screen_top+(SCROLL_TOP+1)*REAL_WIDTH, screen_top+SCROLL_TOP *REAL_WIDTH, (SCROLL_BOTTOM-SCROLL_TOP)*REAL_WIDTH *sizeof(screen_char_t));
        } else {
            // screen area is wrapped; move line by line
            for(i = SCROLL_BOTTOM - 1; i >= SCROLL_TOP; i--) {
                sourceLine = [self getLineAtScreenIndex:i];
                targetLine = [self getLineAtScreenIndex:i+1];
                memmove(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
            }
        }
    }
    // new line at SCROLL_TOP with default settings
    targetLine = [self getLineAtScreenIndex:SCROLL_TOP];
    memcpy(targetLine, [self _getDefaultLineWithWidth: WIDTH], REAL_WIDTH *sizeof(screen_char_t));

    // everything between SCROLL_TOP and SCROLL_BOTTOM is dirty
    memset(dirty+SCROLL_TOP *WIDTH,1,(SCROLL_BOTTOM-SCROLL_TOP+1)*WIDTH *sizeof(char));
}

- (void)insertBlank:(int)n
{
    screen_char_t *aLine;
    int i;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen insertBlank; %d]", __FILE__, __LINE__, n);
#endif

    // NSLog(@"insertBlank[%d@(%d,%d)]",n,CURSOR_X,CURSOR_Y);

    if (CURSOR_X>=WIDTH) return;

    if (n + CURSOR_X > WIDTH) n = WIDTH - CURSOR_X;

    // get the appropriate line
    aLine = [self getLineAtScreenIndex:CURSOR_Y];

    memmove(aLine + CURSOR_X + n,aLine + CURSOR_X,(WIDTH-CURSOR_X-n)*sizeof(screen_char_t));

    for(i = 0; i < n; i++) {
        aLine[CURSOR_X+i].ch = 0;
        aLine[CURSOR_X+i].fg_color = [TERMINAL foregroundColorCode];
        aLine[CURSOR_X+i].bg_color = [TERMINAL backgroundColorCode];
    }

    // everything from CURSOR_X to end of line is dirty
    int screenIdx=CURSOR_Y *WIDTH+CURSOR_X;
    memset(dirty+screenIdx,1,WIDTH-CURSOR_X);

}

- (void)insertLines:(int)n
{
    int i, num_lines_moved;
    screen_char_t *sourceLine, *targetLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen insertLines; %d]", __FILE__, __LINE__, n);
#endif
    // NSLog(@"insertLines %d[%d,%d]",n, CURSOR_X,CURSOR_Y);
    if (n+CURSOR_Y<=SCROLL_BOTTOM) {

        // number of lines we can move down by n before we hit SCROLL_BOTTOM
        num_lines_moved = SCROLL_BOTTOM - (CURSOR_Y + n);
        // start from lower end
        for(i = num_lines_moved ; i >= 0; i--) {
            sourceLine = [self getLineAtScreenIndex: CURSOR_Y + i];
            targetLine = [self getLineAtScreenIndex:CURSOR_Y + i + n];
            memcpy(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
        }

    }
    if (n+CURSOR_Y>SCROLL_BOTTOM)
        n=SCROLL_BOTTOM-CURSOR_Y+1;

    // clear the n lines
    aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
    for(i = 0; i < n; i++) {
        sourceLine = [self getLineAtScreenIndex:CURSOR_Y+i];
        memcpy(sourceLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
    }

    // everything between CURSOR_Y and SCROLL_BOTTOM is dirty
    memset(dirty+CURSOR_Y *WIDTH,1,(SCROLL_BOTTOM-CURSOR_Y+1)*WIDTH);
}

- (void)deleteLines:(int)n
{
    int i, num_lines_moved;
    screen_char_t *sourceLine, *targetLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deleteLines; %d]", __FILE__, __LINE__, n);
#endif

    // NSLog(@"insertLines %d[%d,%d]",n, CURSOR_X,CURSOR_Y);
    if (n+CURSOR_Y<=SCROLL_BOTTOM) {
        // number of lines we can move down by n before we hit SCROLL_BOTTOM
        num_lines_moved = SCROLL_BOTTOM - (CURSOR_Y + n);

        for (i = 0; i <= num_lines_moved; i++) {
            sourceLine = [self getLineAtScreenIndex:CURSOR_Y + i + n];
            targetLine = [self getLineAtScreenIndex: CURSOR_Y + i];
            memcpy(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
        }

    }
    if (n+CURSOR_Y>SCROLL_BOTTOM)
        n=SCROLL_BOTTOM-CURSOR_Y+1;
    // clear the n lines
    aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
    for(i = 0; i < n; i++) {
        sourceLine = [self getLineAtScreenIndex:SCROLL_BOTTOM-n+1+i];
        memcpy(sourceLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
    }

    // everything between CURSOR_Y and SCROLL_BOTTOM is dirty
    memset(dirty+CURSOR_Y *WIDTH,1,(SCROLL_BOTTOM-CURSOR_Y+1)*WIDTH);

}

- (void)setPlayBellFlag:(BOOL)flag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):+[VT100Screen setPlayBellFlag:%s]",
      __FILE__, __LINE__, flag == YES ? "YES" : "NO");
#endif
    PLAYBELL = flag;
}

- (void)setShowBellFlag:(BOOL)flag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):+[VT100Screen setShowBellFlag:%s]",
      __FILE__, __LINE__, flag == YES ? "YES" : "NO");
#endif
    SHOWBELL = flag;
}

- (void)activateBell
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen playBell]", __FILE__, __LINE__);
#endif
    if (PLAYBELL) {
        // TODO(allen): Implement! :)
        NSLog(@"Bell not implemented");
        //NSBeep();
    }
    if (SHOWBELL) {
        // TODO(allen): Implement! :)
        NSLog(@"Visual bell not implemented");
        //[SESSION setBell: YES];
    }
}

- (void)showCursor:(BOOL)show
{
    /*
    // TODO: Support this
    if (show)
    [display showCursor];
    else
    [display hideCursor];
    */
}

- (int)cursorX
{
    return CURSOR_X;
}

- (int)cursorY
{
    return CURSOR_Y;
}

- (void)clearTabStop
{
    int i;
    for(i=0;i<300;i++) tabStop[i]=NO;
}

- (int)numberOfLines
{
  int num_lines_in_scrollback =
    (current_scrollback_lines > max_scrollback_lines)
      ? max_scrollback_lines
      : current_scrollback_lines;
  return (num_lines_in_scrollback + HEIGHT);
}

- (char *)dirty
{
    return dirty;
}

- (void)resetDirty
{
    memset(dirty,0,WIDTH *HEIGHT *sizeof(char));
}

- (void)setDirty
{
    memset(dirty, 1, WIDTH *HEIGHT *sizeof(char));
    [refreshDelegate refresh];
}

- (int)newWidth
{
    return newWidth;
}

- (int)newHeight
{
    return newHeight;
}

- (void)updateBell
{
    if (soundBell)
        [self activateBell];
    soundBell = NO;
}

- (void)setBell
{
    soundBell = YES;
}

- (int)scrollUpLines
{
    return scrollUpLines;
}

- (void)resetScrollUpLines
{
    scrollUpLines = 0;
}

@end

@implementation VT100Screen (Private)

    // gets line offset by specified index from specified line poiner; accounts for buffer wrap
- (screen_char_t *)_getLineAtIndex:(int)anIndex fromLine:(screen_char_t *)aLine
{
    screen_char_t *the_line = NULL;
    NSParameterAssert(anIndex >= 0);
    // get the line offset from the specified line
    the_line = aLine + anIndex *REAL_WIDTH;
    // check if we have gone beyond our buffer; if so, we need to wrap around to the top of buffer
    if(the_line > last_buffer_line) {
        the_line = buffer_lines + (the_line - last_buffer_line - REAL_WIDTH);
    }
    return (the_line);
}

// returns a line set to default character and attributes
// released when session is closed
- (screen_char_t *)_getDefaultLineWithWidth:(int)width
{
    int i;

    // check if we have to generate a new line
    if(default_line && default_fg_code == [TERMINAL foregroundColorCode] &&
            default_bg_code == [TERMINAL backgroundColorCode] && default_line_width >= width) {
        return (default_line);
    }

    if(default_line)
        free(default_line);

    default_line = (screen_char_t *)malloc((width+1)*sizeof(screen_char_t));

    for(i = 0; i < width; i++) {
        default_line[i].ch = 0;
        default_line[i].fg_color = [TERMINAL foregroundColorCode];
        default_line[i].bg_color = [TERMINAL backgroundColorCode];
    }
    //Not wrapped by default
    default_line[width].ch = 0;

    default_fg_code = [TERMINAL foregroundColorCode];
    default_bg_code = [TERMINAL backgroundColorCode];
    default_line_width = width;
    return (default_line);
}


// adds a line to scrollback area. Returns YES if oldest line is lost, NO otherwise
- (BOOL)_addLineToScrollback
{
    BOOL lost_oldest_line = NO;
    BOOL wrap;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif

    if(max_scrollback_lines>0) {
        if (dynamic_scrollback_size && max_scrollback_lines < MAX_SCROLLBACK_LINES ) {
            if (++current_scrollback_lines > max_scrollback_lines) {
                // scrollback area is full; add more
                screen_char_t *bl = buffer_lines;
                int total_height = max_scrollback_lines + DEFAULT_SCROLLBACK + HEIGHT;
                bl = realloc (bl, total_height *REAL_WIDTH *sizeof(screen_char_t));
                if (!bl) {
                    scrollback_top = incrementLinePointer(buffer_lines, scrollback_top, max_scrollback_lines+HEIGHT, WIDTH, &wrap);
                    current_scrollback_lines = max_scrollback_lines;
                    lost_oldest_line = YES;
                } else {
                    /*screen_char_t *aLine = [self _getDefaultLineWithWidth: WIDTH];
                      int i;

                      for(i = max_scrollback_lines+HEIGHT; i < total_height; i++)
                      memcpy(bl+WIDTH *i, aLine, width *sizeof(screen_char_t));*/

                    max_scrollback_lines += DEFAULT_SCROLLBACK;

                    buffer_lines = scrollback_top = bl;
                    last_buffer_line = bl + (total_height - 1)*REAL_WIDTH;
                    screen_top = bl + (current_scrollback_lines-1)*REAL_WIDTH;

                    lost_oldest_line = NO;
                }
            }
        } else {
            if (++current_scrollback_lines > max_scrollback_lines) {
                // scrollback area is full; lose oldest line
                scrollback_top = incrementLinePointer(buffer_lines, scrollback_top, max_scrollback_lines+HEIGHT, WIDTH, &wrap);
                current_scrollback_lines = max_scrollback_lines;
                lost_oldest_line = YES;
            }
        }
    }

    return (lost_oldest_line);
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
