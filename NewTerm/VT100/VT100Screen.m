// -*- mode:objc -*-
/*
 **	 VT100Screen.m
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
#define REAL_WIDTH (_width+1)

/* translates normal char into graphics char */
void translate(screen_char_t *s, int len)
{
		int i;
		for (i = 0; i < len ; i++) {
				s[i].code = charmap[(int)(s[i].code)];
		}
}

/* pad the source string whenever double width character appears */
void padString(NSString *s, screen_char_t *buf, int fg, int bg, int *len,
				NSStringEncoding encoding)
{
		int l=*len;
		int i,j;
		for(i=j=0;i<l;i++,j++) {
				buf[j].code = [s characterAtIndex:i];
				buf[j].foregroundColor = fg;
				buf[j].backgroundColor = bg;
				if (buf[j].code == 0xfeff || buf[j].code == 0x200b ||
						buf[j].code == 0x200c || buf[j].code == 0x200d) { //zero width space
						j--;
				}
		}
		*len=j;
}

// increments line pointer accounting for buffer wrap-around
static __inline__ screen_char_t *incrementLinePointer(
				screen_char_t *buf_start, screen_char_t *current_line,
				int max_lines, int line_width, BOOL *wrap) {
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

@implementation VT100Screen {
		int _cursorX;
		int _cursorY;
		int _saveCursorX;
		int _saveCursorY;
		int _scrollTop;
		int _scrollBottom;
		BOOL _tabStop[TABWINDOW];

		int _charset[4], _saveCharset[4];
		BOOL _blinkShow;
		BOOL _blinkingCursor;

		// single buffer that holds both scrollback and screen contents
		screen_char_t *_bufferLines;
		// buffer holding flags for each char on whether it needs to be redrawn
		char *_dirty;
		// a single default line
		screen_char_t *_defaultLine;

		// pointer to last line in buffer
		screen_char_t *_lastBufferLine;
		// pointer to first screen line
		screen_char_t *_screenTop;
		//pointer to first scrollback line
		screen_char_t *_scrollbackTop;

		// default line stuff
		char _defaultBgCode;
		char _defaultFgCode;
		int _defaultLineWidth;

		//scroll back stuff
		BOOL _dynamicScrollbackSize;
		// max size of scrollback buffer
		unsigned int _maxScrollbackLines;
		// current number of lines in scrollback buffer
		unsigned int _currentScrollbackLines;


		// print to ansi...
		NSMutableString *_printToAnsiString;

		NSLock *_screenLock;


		// UI related
		NSString *_newWinTitle;
		NSString *_newIconTitle;
		BOOL _printPending;
}

#define DEFAULT_SCROLLBACK 1000

#define MIN_WIDTH 10
#define MIN_HEIGHT 3

#define TABSIZE 8

- (instancetype)init {
#if DEBUG_ALLOC
		NSLog(@"%s: %p", __PRETTY_FUNCTION__, self);
#endif
		self = [super init];

		if (!self) {
			return nil;
		}

		_width = DEFAULT_TERMINAL_WIDTH;
		_height = DEFAULT_TERMINAL_HEIGHT;

		_cursorX = _cursorY = 0;
		_saveCursorX = _saveCursorY = 0;
		_scrollTop = 0;
		_scrollBottom = _height - 1;

		_maxScrollbackLines = DEFAULT_SCROLLBACK;
		_dynamicScrollbackSize = NO;
		[self clearTabStop];

		// set initial tabs
		int i;
		for(i = TABSIZE; i < TABWINDOW; i += TABSIZE) {
				_tabStop[i] = YES;
		}

		for(i = 0; i < 4; i++) _saveCharset[i] = _charset[i] = 0;

		_screenLock = [[NSLock alloc] init];

		[self initScreenWithWidth:DEFAULT_TERMINAL_WIDTH Height:DEFAULT_TERMINAL_HEIGHT];
		return self;
}

- (void)dealloc {
#if DEBUG_ALLOC
		NSLog(@"%s: %p", __PRETTY_FUNCTION__, self);
#endif

		// free our character buffer
		if (_bufferLines) {
				free(_bufferLines);
		}

		// free our "dirty flags" buffer
		if (_dirty) {
				free(_dirty);
		}
		// free our default line
		if (_defaultLine) {
				free(_defaultLine);
		}
		
#if DEBUG_ALLOC
		NSLog(@"%s: %p, done", __PRETTY_FUNCTION__, self);
#endif
}

- (void)initScreenWithWidth:(int)width Height:(int)height {
		int total_height;
		screen_char_t *aDefaultLine;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen initScreenWithWidth:%d Height:%d]", width, height );
#endif

		_width = width;
		_height = height;
		_cursorX = _cursorY = 0;
		_saveCursorX = _saveCursorY = 0;
		_scrollTop = 0;
		_scrollBottom = _height - 1;
		_blinkShow=YES;

		// allocate our buffer to hold both scrollback and screen contents
		total_height = _height + _maxScrollbackLines;
		_bufferLines = (screen_char_t *)malloc(
						total_height *REAL_WIDTH *sizeof(screen_char_t));

		// set up our pointers
		_lastBufferLine = _bufferLines + (total_height - 1)*REAL_WIDTH;
		_screenTop = _bufferLines;
		_scrollbackTop = _bufferLines;

		// set all lines in buffer to default
		_defaultFgCode = [_terminal foregroundColorCode];
		_defaultBgCode = [_terminal backgroundColorCode];
		_defaultLineWidth = _width;
		aDefaultLine = [self _getDefaultLineWithWidth: _width];
		for(int i = 0; i < _height; i++)
				memcpy([self _getLineAtIndex:i fromLine:_bufferLines], aDefaultLine,
								REAL_WIDTH *sizeof(screen_char_t));

		// set current lines in scrollback
		_currentScrollbackLines = 0;

		// set up our dirty flags buffer
		_dirty = (char *)malloc(_height * _width * sizeof(char));

		// force a redraw
		[self setDirty];
}


- (void)acquireLock {
		//NSLog(@"%s", __PRETTY_FUNCTION__);
		[_screenLock lock];
}

- (void)releaseLock {
		//NSLog(@"%s", __PRETTY_FUNCTION__);
		[_screenLock unlock];
}

- (BOOL)tryLock {
		return [_screenLock tryLock];
}

// gets line at specified index starting from _scrollbackTop
- (screen_char_t *)getLineAtIndex:(int)theIndex {
		NSParameterAssert(theIndex >= 0);
		screen_char_t *theLinePointer;

		if (_maxScrollbackLines == 0)
				theLinePointer = _screenTop;
		else
				theLinePointer = _scrollbackTop;

		return ([self _getLineAtIndex:theIndex fromLine:theLinePointer]);
}

// gets line at specified index starting from _screenTop
- (screen_char_t *)getLineAtScreenIndex:(int)theIndex {
		return ([self _getLineAtIndex:theIndex fromLine:_screenTop]);
}

- (void)setWidth:(int)width height:(int)height
{
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen setWidth:%d height:%d]",
						width, height);
#endif

		if (width >= MIN_WIDTH && height >= MIN_HEIGHT) {
				_width = width;
				_height = height;
				_cursorX = _cursorY = 0;
				_saveCursorX = _saveCursorY = 0;
				_scrollTop = 0;
				_scrollBottom = _height - 1;
		}
}

- (void)resizeWidth:(int)width height:(int)height {
#if DEBUG_METHOD_TRACE
	NSLog(@"-[VT100Screen resizeWidth:%d height:%d]",
		  width, height);
#endif

		int i, new_total_height;
		screen_char_t *bl, *aLine, *c1, *c2, *new_scrollback_top;

		if (_width == 0 || _height == 0 || (width==_width && height==_height)) {
				return;
		}

		[self acquireLock];

		// Try to determine how many empty trailing lines there are on screen
		for(;_height>_cursorY+1;_height--) {
				aLine = [self getLineAtScreenIndex: _height-1];
				for (i=0;i<_width;i++)
						if (aLine[i].code) break;
				if (i<_width) break;
		}

		// create a new buffer
		new_total_height = _maxScrollbackLines + height;
		new_scrollback_top = bl = (screen_char_t *)malloc(new_total_height *(width+1)*sizeof(screen_char_t));

		//copy over the content
		int y1, y2, x1, x2, x3;
		BOOL wrapped = NO, _wrap;
		screen_char_t *defaultLine = [self _getDefaultLineWithWidth: width];

		c2 = bl;
		for(y2=y1=0; y1<_currentScrollbackLines+_height; y1++) {
				c1 = [self getLineAtIndex:y1];
				if (_width == width) {
						memcpy(c2, c1, REAL_WIDTH *sizeof(screen_char_t));
				} else if (_width < width) {
						memcpy(c2, c1, _width *sizeof(screen_char_t));
						c2[width].code = 0; // no wrapping by default
						x2 = _width;
						while (c1[_width].code) { //wrapping?
								c1 = [self getLineAtIndex:++y1];
								for(x1=0;x1<_width;x1++,x2++) {
										for(x3=x1; x3<=_width && !c1[x3].code; x3++);
										if (x3>_width) break;
										if (x2>=width) {
												c2[width].code = 1;
												x2 = 0;
												if (wrapped) {
														new_scrollback_top = incrementLinePointer(bl, new_scrollback_top, new_total_height, width, &_wrap);
												}
												c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
												wrapped = wrapped || _wrap;
												if (_wrap) y2 = 0; else y2++;
												c2[width].code = 0;
										}
										c2[x2]=c1[x1];
								}
						}
						if (x2<width) memcpy(c2+x2, defaultLine, (width-x2)*sizeof(screen_char_t));
				} else {
						memcpy(c2, c1, width *sizeof(screen_char_t));
						c2[width].code = 0; // no wrapping by default
						x1 = x2 = width;
						do {
								for(;x1<_width;x1++,x2++) {
										for(x3=x1; x3<_width && !c1[x3].code; x3++);
										if (x3>=_width && !c1[_width].code) break;
										if (x2>=width) {
												c2[width].code = 1;
												x2 = 0;
												if (wrapped) {
														new_scrollback_top = incrementLinePointer(bl, new_scrollback_top, new_total_height, width, &_wrap);
												}
												c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
												wrapped = wrapped || _wrap;
												if (_wrap) y2 = 0; else y2++;
												c2[width].code = 0;
										}
										c2[x2]=c1[x1];
								}
								if (c1[_width].code) {
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
		if(_bufferLines){NSLog(@"aaaa");
				free(_bufferLines);NSLog(@"bbbb");}
		_bufferLines = bl;
		_scrollbackTop = new_scrollback_top;
		_lastBufferLine = bl + (new_total_height - 1)*(width+1);
		if (_maxScrollbackLines > 0) {
				if (wrapped) {
						_currentScrollbackLines = _maxScrollbackLines;
						_cursorY = height - 1;
				} else {
						if (y2 <= height) {
								_currentScrollbackLines = 0;
								_cursorY = y2 - 1;
						} else {
								_currentScrollbackLines = y2 - height ;
								_cursorY = height - 1;
						}
				}
		} else {
				_currentScrollbackLines = 0;
				_cursorY = wrapped ? height - 1 : y2 - 1;
		}

		_screenTop = _scrollbackTop + _currentScrollbackLines *(width+1);
		if (_screenTop > _lastBufferLine)
				_screenTop = bl + (_screenTop - _lastBufferLine) - width - 1;

		// set the rest of new buffer (if any) to default line
		if (!wrapped) {
				for(;y2 < new_total_height; y2++) {
						memcpy(c2, defaultLine, (width+1)*sizeof(screen_char_t));
						c2 = incrementLinePointer(bl, c2, new_total_height, width, &_wrap);
				}
		}

		// new height and width
		_width = width;
		_height = height;

		// reset terminal scroll top and bottom
		_scrollTop = 0;
		_scrollBottom = _height - 1;

		// adjust X coordinate of cursor
		if (_cursorX >= width)
				_cursorX = width-1;
		if (_saveCursorX >= width)
				_saveCursorX = width-1;
		if (_cursorY >= height)
				_cursorY = height-1;
		if (_saveCursorY >= height)
				_saveCursorY = height-1;

		// force a redraw
		if(_dirty){NSLog(@"cccc");
				free(_dirty);NSLog(@"dddd");}
		_dirty=(char *)malloc(height *width *sizeof(char));
		[self setDirty];
		// release lock
		[self releaseLock];

		// An immediate refresh is needed so that the size of TEXTVIEW can be
		// adjusted to fit the new size
		[_refreshDelegate refresh];
}

- (void)reset {
		// reset terminal scroll top and bottom
		_scrollTop = 0;
		_scrollBottom = _height - 1;

		[self clearScreen];
		[self clearTabStop];
		_saveCursorX = 0;
		_cursorY = 0;
		_saveCursorY = 0;

		// set initial tabs
		int i;
		for(i = TABSIZE; i < TABWINDOW; i += TABSIZE)
				_tabStop[i] = YES;

		for(i=0;i<4;i++) _saveCharset[i]=_charset[i]=0;

		[self showCursor: YES];
		_newWinTitle = nil;
		_newIconTitle = nil;
}

- (unsigned int)maxScrollbackLines {
		return _maxScrollbackLines;
}

// sets scrollback lines.
- (void)setMaxScrollbackLines:(unsigned int)lineCount {
		// if we already have a buffer, don't allow this
		if(_bufferLines != NULL)
				return;

		if (lineCount > MAX_SCROLLBACK_LINES) {
				_dynamicScrollbackSize = YES;
				_maxScrollbackLines = DEFAULT_SCROLLBACK;
		} else {
				_dynamicScrollbackSize = NO;
				_maxScrollbackLines = lineCount;
		}
}

- (void)putToken:(VT100Token *)token {

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen putToken: (%d)]",
						token.type);
#endif
		int i,j,k;
		screen_char_t *aLine;

		[self acquireLock];

		// Keep track of the old cursor location so that we can mark it dirty of the
		// screen is redrawn.
		int oldCursorX = _cursorX;
		int oldCursorY = _cursorY;

		switch (token.type) {
				// our special code
				case VT100_STRING:
	 case VT100_ASCIISTRING:
						// check if we are in print mode
						if ([self printToAnsi] == YES)
								[self printStringToAnsi: token.string];
						// else display string on screen
						else
								[self setString:token.string ascii: token.type == VT100_ASCIISTRING];
						break;
	 case VT100_UNKNOWNCHAR: break;
	 case VT100_NOTSUPPORT: break;

													// VT100 CC
	 case VT100CC_ENQ: break;
	 case VT100CC_BEL: [self activateBell]; break;
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
	 case VT100CC_CR: _cursorX = 0; break;
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
	 case VT100CSI_CUB: [self cursorLeft:token.csi->p[0]]; break;
	 case VT100CSI_CUD: [self cursorDown:token.csi->p[0]]; break;
	 case VT100CSI_CUF: [self cursorRight:token.csi->p[0]]; break;
	 case VT100CSI_CUP:
		 [self cursorToX:token.csi->p[1] Y:token.csi->p[0]];
		 break;
	 case VT100CSI_CUU: [self cursorUp:token.csi->p[0]]; break;
	 case VT100CSI_DA:
											NSLog(@"Not implemented DA");
											break;
											// case VT100CSI_DA: [self deviceAttribute:token]; break;
	 case VT100CSI_DECALN:
											for (i = 0; i < _height; i++) {
													aLine = [self getLineAtScreenIndex: i];
													for(j = 0; j < _width; j++) {
															aLine[j].code ='E';
															aLine[j].foregroundColor = [_terminal foregroundColorCode];
															aLine[j].backgroundColor = [_terminal backgroundColorCode];
													}
													aLine[_width].code = 0;
											}
											[self setDirty];
											break;
	 case VT100CSI_DECDHL: break;
	 case VT100CSI_DECDWL: break;
	 case VT100CSI_DECID: break;
	 case VT100CSI_DECKPAM: break;
	 case VT100CSI_DECKPNM: break;
	 case VT100CSI_DECRC: [self restoreCursorPosition]; break;
	 case VT100CSI_DECSC: [self saveCursorPosition]; break;
	 case VT100CSI_DECSTBM: [self setTopBottom:token]; break;
	 case VT100CSI_DSR:
												 NSLog(@"Not implemented DSR");
												 break;
												 // case VT100CSI_DSR: [self deviceReport:token]; break;
	 case VT100CSI_ED: [self eraseInDisplay:token]; break;
	 case VT100CSI_EL: [self eraseInLine:token]; break;
	 case VT100CSI_HTS: if (_cursorX<_width) _tabStop[_cursorX]=YES; break;
	 case VT100CSI_HVP:
		 [self cursorToX:token.csi->p[1] Y:token.csi->p[0]];
		 break;
	 case VT100CSI_NEL:
		 _cursorX=0;
	 case VT100CSI_IND:
		 if (_cursorY == _scrollBottom) {
				 [self scrollUp];
		 } else {
				 _cursorY++;
				 if (_cursorY>=_height) {
						 _cursorY=_height-1;
				 }
		 }
		 break;
	 case VT100CSI_RI:
		 if(_cursorY == _scrollTop) {
				 [self scrollDown];
		 } else {
				 _cursorY--;
				 if (_cursorY<0) {
						 _cursorY=0;
				 }
		 }
		 break;
	 case VT100CSI_RIS: break;
	 case VT100CSI_RM: break;
	 case VT100CSI_SCS0: _charset[0]=(token.code=='0'); break;
	 case VT100CSI_SCS1: _charset[1]=(token.code=='0'); break;
	 case VT100CSI_SCS2: _charset[2]=(token.code=='0'); break;
	 case VT100CSI_SCS3: _charset[3]=(token.code=='0'); break;
	 case VT100CSI_SGR: [self selectGraphicRendition:token]; break;
	 case VT100CSI_SM: break;
	 case VT100CSI_TBC:
										 switch (token.csi->p[0]) {
												 case 3: [self clearTabStop]; break;
												 case 0: if (_cursorX<_width) _tabStop[_cursorX]=NO;
										 }
										 break;

	 case VT100CSI_DECSET:
	 case VT100CSI_DECRST:
										 if (token.csi->p[0]==3 && [_terminal allowColumnMode] == YES) {
												 // set the column
												 _newWidth = [_terminal columnMode]?132:80;
												 _newHeight = _height;
										 }
										 break;
										 // ANSI CSI
	 case ANSICSI_CHA:
		[self cursorToX: token.csi->p[0]];
		break;
	 case ANSICSI_VPA:
		[self cursorToX: _cursorX+1 Y: token.csi->p[0]];
		break;
	 case ANSICSI_VPR:
		[self cursorToX: _cursorX+1 Y: token.csi->p[0]+_cursorY+1];
		break;
	 case ANSICSI_ECH:
		if (_cursorX<_width) {
				i=_width *_cursorY+_cursorX;
				j=token.csi->p[0];
				if (j + _cursorX > _width)
						j = _width - _cursorX;
				aLine = [self getLineAtScreenIndex: _cursorY];
				for(k = 0; k < j; k++) {
						aLine[_cursorX+k].code = 0;
						aLine[_cursorX+k].foregroundColor = [_terminal foregroundColorCode];
						aLine[_cursorX+k].backgroundColor = [_terminal backgroundColorCode];
				}
				memset(_dirty+i,1,j);
		}
		break;

	 case STRICT_ANSI_MODE:
											[_terminal setStrictAnsiMode: ![_terminal strictAnsiMode]];
											break;

	 case ANSICSI_PRINT:
											switch (token.csi->p[0]) {
													case 4:
															// print our stuff!!
															_printPending = YES;
															break;
													case 5:
															// allocate a string for the stuff to be printed
															_printToAnsiString = [[NSMutableString alloc] init];
															[self setPrintToAnsi: YES];
															break;
													default:
															//print out the whole screen
															_printToAnsiString = nil;
															[self setPrintToAnsi: NO];
															_printPending = YES;
											}
											break;
	 case VT100CSI_ICH: [self insertBlank:token.csi->p[0]]; break;
	 case XTERMCC_INSLN: [self insertLines:token.csi->p[0]]; break;
	 case XTERMCC_DELCH: [self deleteCharacters:token.csi->p[0]]; break;
	 case XTERMCC_DELLN: [self deleteLines:token.csi->p[0]]; break;
	 case XTERMCC_SU:
											 for (i=0; i<token.csi->p[0]; i++) [self scrollUp];
											 break;
	 case XTERMCC_SD:
											 for (i=0; i<token.csi->p[0]; i++) [self scrollDown];
											 break;


	 default:
												NSLog(@" Unexpected token.type = %d",
																token.type);
												break;
		}
		if (oldCursorX != _cursorX || oldCursorY != _cursorY) {
				_dirty[oldCursorY *_width+oldCursorX] = 1;
		}
		[self releaseLock];
}

- (void)clearBuffer {
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen clearBuffer]" );
#endif

		[self clearScreen];
		[self clearScrollbackBuffer];
}

- (void)clearScrollbackBuffer {
		int i;
		screen_char_t *aLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen clearScrollbackBuffer]" );
#endif

		[self acquireLock];

		if (_maxScrollbackLines) {
				aDefaultLine = [self _getDefaultLineWithWidth: _width];
				for(i = 0; i < _currentScrollbackLines; i++) {
						aLine = [self getLineAtIndex:i];
						memcpy(aLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
				}

				_currentScrollbackLines = 0;
				_scrollbackTop = _screenTop;

		}

		[self releaseLock];
		[self setDirty];
}

- (void)printStringToAnsi:(NSString *)aString {
		if([aString length] > 0)
				[_printToAnsiString appendString: aString];
}

- (void)setString:(NSString *)string ascii:(BOOL)ascii {
		screen_char_t *buffer;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen setString:%@ at %d]",
						string, _cursorX);
#endif

		int len;
		if ((len=[string length]) < 1 || !string) {
				NSLog(@"%s: invalid string '%@'", __PRETTY_FUNCTION__, string);
				return;
		}
		if (ascii) {
				unichar *sc = (unichar *) malloc(len *sizeof(unichar));
				int fg=[_terminal foregroundColorCode], bg=[_terminal backgroundColorCode];

				buffer = (screen_char_t *) malloc([string length] * sizeof(screen_char_t));
				if (!buffer) {
						NSLog(@"%s: Out of memory", __PRETTY_FUNCTION__);
			free(sc);
						return;
				}

				[string getCharacters: sc];
				int i;
				for (i = 0; i < len; i++) {
						buffer[i].code = sc[i];
						buffer[i].foregroundColor = fg;
						buffer[i].backgroundColor = bg;
				}

				// check for graphical characters
				if (_charset[[_terminal charset]]) {
						translate(buffer,len);
				}
				// NSLog(@"%d(%d):%@",[_terminal charset],_charset[[_terminal charset]],string);
				free(sc);
		} else {
				string = [string precomposedStringWithCanonicalMapping];
				len=[string length];
				buffer = (screen_char_t *) malloc( 2 * len *sizeof(screen_char_t) );
				if (!buffer) {
						NSLog(@"%s: Out of memory", __PRETTY_FUNCTION__);
						return;
				}
				padString(string, buffer, [_terminal foregroundColorCode],
								[_terminal backgroundColorCode], &len, [_terminal encoding]);
		}

		if (len < 1) {
		free(buffer);
				return;
	}

		// TODO(allen): Implement insert mode
		for (int idx = 0; idx < len; idx++) {
				// cut off in the middle of double width characters
				if (buffer[idx].code == 0xffff) {
						buffer[idx].code = '#';
				}
				screen_char_t *aLine = [self getLineAtScreenIndex: _cursorY];
				aLine[_cursorX] = buffer[idx];
				_dirty[_cursorY * _width + _cursorX] = 1;

				// Dirty the new cursor position
				_cursorX++;
				_dirty[_cursorY * _width + _cursorX] = 1;

				// Wrap
				if (_cursorX >= _width) {
						_cursorX = 0;
						[self getLineAtScreenIndex: _cursorY][_width].code = 1;
						[self setNewLine];
				}
		}

		free(buffer);

#if DEBUG_METHOD_TRACE
		NSLog(@"setString done at %d", _cursorX);
#endif
}

- (void)setNewLine {
		screen_char_t *aLine;
		BOOL wrap = NO;
		int total_height;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen setNewLine](%d,%d)-[%d,%d]", _cursorX, _cursorY, _scrollTop, _scrollBottom);
#endif

		if (_cursorY < _scrollBottom || (_cursorY < (_height - 1) && _cursorY > _scrollBottom)) {
				_cursorY++;
				if (_cursorX < _width) {
						_dirty[_cursorY * _width + _cursorX] = 1;
				}
		} else if (_scrollTop == 0 && _scrollBottom == _height - 1) {
				total_height = _maxScrollbackLines + _height;

				// try to add top line to scroll area
				if (_maxScrollbackLines > 0) {
						if ([self _addLineToScrollback]) {
								// TODO(allen): This could probably be a bit smarter
								// scroll buffer overflow, entire screen needs to be redrawn
								[self setDirty];
						} else{
								// top line can move into scroll area; we need to draw only bottom line
								//_dirty[_width *(_cursorY-1)*sizeof(char)+_cursorX-1]=1;
								memmove(_dirty, _dirty+_width *sizeof(char), _width *(_height-1)*sizeof(char));
								memset(_dirty+_width *(_height-1)*sizeof(char),1, _width *sizeof(char));
						};
				} else
						[self setDirty];

				// Increment _screenTop pointer
				_screenTop = incrementLinePointer(_bufferLines, _screenTop, total_height, _width, &wrap);

				// set last screen line default
				aLine = [self getLineAtScreenIndex: (_height - 1)];
				memcpy(aLine, [self _getDefaultLineWithWidth: _width], REAL_WIDTH *sizeof(screen_char_t));

		} else {
				[self scrollUp];
		}
}

- (void)deleteCharacters:(int)n {
		screen_char_t *aLine;
		int i;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen deleteCharacter]: %d", n);
#endif

		if (_cursorX >= 0 && _cursorX < _width &&
						_cursorY >= 0 && _cursorY < _height) {
				int idx;

				idx=_cursorY *_width;
				if (n+_cursorX>_width) n=_width-_cursorX;

				// get the appropriate screen line
				aLine = [self getLineAtScreenIndex: _cursorY];

				if (n<_width) {
						memmove(aLine + _cursorX, aLine + _cursorX + n, (_width-_cursorX-n)*sizeof(screen_char_t));
				}
				for(i = 0; i < n; i++) {
						aLine[_width-n+i].code = 0;
						aLine[_width-n+i].foregroundColor = [_terminal foregroundColorCode];
						aLine[_width-n+i].backgroundColor = [_terminal backgroundColorCode];
				}
				memset(_dirty+idx+_cursorX,1, _width-_cursorX);
		}
}

- (void)backSpace
{
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen backSpace]");
#endif
		if (_cursorX > 0)
				_cursorX--;
}

- (void)setTab {

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen setTab]");
#endif

		_cursorX++; // ensure we go to the next tab in case we are already on one
		for(;!_tabStop[_cursorX]&&_cursorX<_width; _cursorX++);
		if (_cursorX >= _width)
				_cursorX =	_width - 1;
}

- (void)clearScreen {
		screen_char_t *aLine, *aDefaultLine;
		int i;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen clearScreen]; _cursorY = %d", _cursorY);
#endif
		[self acquireLock];
		// Clear the screen by overwriting everything with the default (blank) line
		aDefaultLine = [self _getDefaultLineWithWidth: _width];
		for (i = 0; i < _height; ++i) {
				aLine = [self getLineAtScreenIndex:i];
				memcpy(aLine, aDefaultLine, REAL_WIDTH * sizeof(screen_char_t));
		}
		_cursorX = 0;
		_cursorY = 0;
		// all the screen is dirty
		[self setDirty];
		[self releaseLock];
}

- (void)eraseInDisplay:(VT100Token *)token {
		int x1, y1, x2, y2;
		int i, total_height;
		screen_char_t *aScreenChar;
		//BOOL wrap;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen eraseInDisplay:(param=%d); X = %d; Y = %d]",
						token.csi->p[0], _cursorX, _cursorY);
#endif
		switch (token.csi->p[0]) {
				case 1:
						x1 = 0;
						y1 = 0;
						x2 = _cursorX<_width?_cursorX+1:_width;
						y2 = _cursorY;
						break;

				case 2:
						x1 = 0;
						y1 = 0;
						x2 = 0;
						y2 = _height;

						break;

				case 0:
			 default:
						x1 = _cursorX;
						y1 = _cursorY;
						x2 = 0;
						y2 = _height;
						break;
		}


		int idx1, idx2;

		idx1=y1 *REAL_WIDTH+x1;
		idx2=y2 *REAL_WIDTH+x2;

		total_height = _maxScrollbackLines + _height;

		// clear the contents between idx1 and idx2
		for(i = idx1, aScreenChar = _screenTop + idx1; i < idx2; i++, aScreenChar++) {
				if(aScreenChar >= (_bufferLines + total_height *REAL_WIDTH))
						aScreenChar = _bufferLines; // wrap around to top of buffer
				aScreenChar->code = 0;
				aScreenChar->foregroundColor = [_terminal foregroundColorCode];
				aScreenChar->backgroundColor = [_terminal backgroundColorCode];
		}

		memset(_dirty+y1 *_width+x1,1,((y2-y1)*_width+(x2-x1))*sizeof(char));
}

- (void)eraseInLine:(VT100Token *)token {
		screen_char_t *aLine;
		int i;
		int idx, x1 ,x2;
		int fgCode, bgCode;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen eraseInLine:(param=%d); X = %d; Y = %d]",
						token.csi->p[0], _cursorX, _cursorY);
#endif


		x1 = x2 = 0;
		switch (token.csi->p[0]) {
				case 1:
						x1=0;
						x2=_cursorX<_width?_cursorX+1:_width;
						break;
				case 2:
						x1 = 0;
						x2 = _width;
						break;
				case 0:
						x1=_cursorX;
						x2=_width;
						break;
		}
		aLine = [self getLineAtScreenIndex: _cursorY];

		// I'm commenting out the following code. I'm not sure about OpenVMS, but this code produces wrong result
		// when I use vttest program for testing the color features. --fabian

		// if we erasing entire lines, set to default foreground and background colors. Some systems (like OpenVMS)
		// do not send explicit video information
		//if(x1 == 0 && x2 == _width)
		//{
		// fgCode = FG_COLOR_CODE;
		// bgCode = BG_COLOR_CODE;
		//}
		//else
		//{
		fgCode = [_terminal foregroundColorCode];
		bgCode = [_terminal backgroundColorCode];
		//}


		for(i = x1; i < x2; i++) {
				aLine[i].code = 0;
				aLine[i].foregroundColor = fgCode;
				aLine[i].backgroundColor = bgCode;
		}

		idx=_cursorY *_width+x1;
		memset(_dirty+idx,1,(x2-x1)*sizeof(char));
}

- (void)selectGraphicRendition:(VT100Token *)token {
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen selectGraphicRendition:...]");
#endif
}

- (void)cursorLeft:(int)n {
		int x = _cursorX - (n>0?n:1);

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorLeft:%d]",
						n);
#endif
		if (x < 0)
				x = 0;
		if (x >= 0 && x < _width)
				_cursorX = x;

		_dirty[_cursorY *_width+_cursorX] = 1;
}

- (void)cursorRight:(int)n {
		int x = _cursorX + (n>0?n:1);

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorRight:%d]",
						n);
#endif
		if (x >= _width)
				x =	 _width - 1;
		if (x >= 0 && x < _width)
				_cursorX = x;

		_dirty[_cursorY *_width+_cursorX] = 1;
}

- (void)cursorUp:(int)n {
		int y = _cursorY - (n>0?n:1);

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorUp:%d]",
						n);
#endif
		if(_cursorY >= _scrollTop)
				_cursorY=y<_scrollTop?_scrollTop:y;
		else
				_cursorY = y;

		if (_cursorX<_width) _dirty[_cursorY *_width+_cursorX] = 1;
}

- (void)cursorDown:(int)n {
		int y = _cursorY + (n>0?n:1);

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorDown:%d, Y = %d; _scrollBottom = %d]",
						n, _cursorY, _scrollBottom);
#endif
		if(_cursorY <= _scrollBottom)
				_cursorY=y>_scrollBottom?_scrollBottom:y;
		else
				_cursorY = y;

		if (_cursorX<_width) _dirty[_cursorY *_width+_cursorX] = 1;
}

- (void)cursorToX:(int)x {
		int x_pos;


#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorToX:%d]",
						x);
#endif
		x_pos = (x-1);

		if(x_pos < 0)
				x_pos = 0;
		else if(x_pos >= _width)
				x_pos = _width - 1;

		_cursorX = x_pos;

		_dirty[_cursorY *_width+_cursorX] = 1;
}

- (void)cursorToX:(int)x Y:(int)y {
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen cursorToX:%d Y:%d]",
						x, y);
#endif
		int x_pos, y_pos;


		x_pos = x - 1;
		y_pos = y - 1;

		if ([_terminal originMode]) y_pos += _scrollTop;

		if (x_pos < 0)
				x_pos = 0;
		else if (x_pos >= _width)
				x_pos = _width - 1;
		if (y_pos < 0)
				y_pos = 0;
		else if (y_pos >= _height)
				y_pos = _height - 1;

		_cursorX = x_pos;
		_cursorY = y_pos;

		_dirty[_cursorY *_width+_cursorX] = 1;

		// NSParameterAssert(_cursorX >= 0 && _cursorX < _width);

}

- (void)saveCursorPosition {
		int i;
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen saveCursorPosition]");
#endif

		if(_cursorX < 0)
				_cursorX = 0;
		if(_cursorX >= _width)
				_cursorX = _width-1;
		if(_cursorY < 0)
				_cursorY = 0;
		if(_cursorY >= _height)
				_cursorY = _height;

		_saveCursorX = _cursorX;
		_saveCursorY = _cursorY;

		for(i=0;i<4;i++) _saveCharset[i]=_charset[i];

}

- (void)restoreCursorPosition {
		int i;
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen restoreCursorPosition]");
#endif
		_cursorX = _saveCursorX;
		_cursorY = _saveCursorY;

		for(i=0;i<4;i++) _charset[i]=_saveCharset[i];

		NSParameterAssert(_cursorX >= 0 && _cursorX < _width);
		NSParameterAssert(_cursorY >= 0 && _cursorY < _height);
}

- (void)setTopBottom:(VT100Token *)token {
		int top, bottom;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen setTopBottom:(%d,%d)]",
						token.csi->p[0], token.csi->p[1]);
#endif

		top = token.csi->p[0] == 0 ? 0 : token.csi->p[0] - 1;
		bottom = token.csi->p[1] == 0 ? _height - 1 : token.csi->p[1] - 1;
		if (top >= 0 && top < _height &&
						bottom >= 0 && bottom < _height &&
						bottom >= top) {
				_scrollTop = top;
				_scrollBottom = bottom;

				if ([_terminal originMode]) {
						_cursorX = 0;
						_cursorY = _scrollTop;
				} else {
						_cursorX = 0;
						_cursorY = 0;
				}
		}
}

- (void)scrollUp {
		int i;
		screen_char_t *sourceLine, *targetLine;

		#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen scrollUp]");
		#endif

		NSParameterAssert(_scrollTop >= 0 && _scrollTop < _height);
		NSParameterAssert(_scrollBottom >= 0 && _scrollBottom < _height);
		NSParameterAssert(_scrollTop <= _scrollBottom );

		if (_scrollTop == 0 && _scrollBottom == _height -1) {
				[self setNewLine];
		} else if (_scrollTop<_scrollBottom) {
				// _scrollTop is not top of screen; move all lines between _scrollTop and _scrollBottom one line up
				// check if the screen area is wrapped
				sourceLine = [self getLineAtScreenIndex: _scrollTop];
				targetLine = [self getLineAtScreenIndex: _scrollBottom];
				if(sourceLine < targetLine) {
						// screen area is not wrapped; direct memmove
						memmove(_screenTop+_scrollTop *REAL_WIDTH, _screenTop+(_scrollTop+1)*REAL_WIDTH, (_scrollBottom-_scrollTop)*REAL_WIDTH *sizeof(screen_char_t));
				} else {
						// screen area is wrapped; copy line by line
						for(i = _scrollTop; i < _scrollBottom; i++) {
								sourceLine = [self getLineAtScreenIndex:i+1];
								targetLine = [self getLineAtScreenIndex: i];
								memmove(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
						}
				}
				// new line at _scrollBottom with default settings
				targetLine = [self getLineAtScreenIndex:_scrollBottom];
				memcpy(targetLine, [self _getDefaultLineWithWidth: _width], REAL_WIDTH *sizeof(screen_char_t));

				// everything between _scrollTop and _scrollBottom is dirty
				memset(_dirty+_scrollTop *_width,1,(_scrollBottom-_scrollTop+1)*_width *sizeof(char));
		}
}

- (void)scrollDown {
		int i;
		screen_char_t *sourceLine, *targetLine;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen scrollDown]");
#endif

		NSParameterAssert(_scrollTop >= 0 && _scrollTop < _height);
		NSParameterAssert(_scrollBottom >= 0 && _scrollBottom < _height);
		NSParameterAssert(_scrollTop <= _scrollBottom );

		if (_scrollTop<_scrollBottom) {
				// move all lines between _scrollTop and _scrollBottom one line down
				// check if screen is wrapped
				sourceLine = [self getLineAtScreenIndex:_scrollTop];
				targetLine = [self getLineAtScreenIndex:_scrollBottom];
				if(sourceLine < targetLine) {
						// screen area is not wrapped; direct memmove
						memmove(_screenTop+(_scrollTop+1)*REAL_WIDTH, _screenTop+_scrollTop *REAL_WIDTH, (_scrollBottom-_scrollTop)*REAL_WIDTH *sizeof(screen_char_t));
				} else {
						// screen area is wrapped; move line by line
						for(i = _scrollBottom - 1; i >= _scrollTop; i--) {
								sourceLine = [self getLineAtScreenIndex:i];
								targetLine = [self getLineAtScreenIndex:i+1];
								memmove(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
						}
				}
		}
		// new line at _scrollTop with default settings
		targetLine = [self getLineAtScreenIndex:_scrollTop];
		memcpy(targetLine, [self _getDefaultLineWithWidth: _width], REAL_WIDTH *sizeof(screen_char_t));

		// everything between _scrollTop and _scrollBottom is dirty
		memset(_dirty+_scrollTop *_width,1,(_scrollBottom-_scrollTop+1)*_width *sizeof(char));
}

- (void)insertBlank:(int)n {
		screen_char_t *aLine;
		int i;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen insertBlank; %d]", n);
#endif

		// NSLog(@"insertBlank[%d@(%d,%d)]",n,_cursorX,_cursorY);

		if (_cursorX>=_width) return;

		if (n + _cursorX > _width) n = _width - _cursorX;

		// get the appropriate line
		aLine = [self getLineAtScreenIndex:_cursorY];

		memmove(aLine + _cursorX + n,aLine + _cursorX,(_width-_cursorX-n)*sizeof(screen_char_t));

		for(i = 0; i < n; i++) {
				aLine[_cursorX+i].code = 0;
				aLine[_cursorX+i].foregroundColor = [_terminal foregroundColorCode];
				aLine[_cursorX+i].backgroundColor = [_terminal backgroundColorCode];
		}

		// everything from _cursorX to end of line is dirty
		int screenIdx=_cursorY *_width+_cursorX;
		memset(_dirty+screenIdx,1, _width-_cursorX);

}

- (void)insertLines:(int)n {
		int i, num_lines_moved;
		screen_char_t *sourceLine, *targetLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen insertLines; %d]", n);
#endif
		// NSLog(@"insertLines %d[%d,%d]",n, _cursorX,_cursorY);
		if (n+_cursorY<=_scrollBottom) {

				// number of lines we can move down by n before we hit _scrollBottom
				num_lines_moved = _scrollBottom - (_cursorY + n);
				// start from lower end
				for(i = num_lines_moved ; i >= 0; i--) {
						sourceLine = [self getLineAtScreenIndex: _cursorY + i];
						targetLine = [self getLineAtScreenIndex:_cursorY + i + n];
						memcpy(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
				}

		}
		if (n+_cursorY>_scrollBottom)
				n=_scrollBottom-_cursorY+1;

		// clear the n lines
		aDefaultLine = [self _getDefaultLineWithWidth: _width];
		for(i = 0; i < n; i++) {
				sourceLine = [self getLineAtScreenIndex:_cursorY+i];
				memcpy(sourceLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
		}

		// everything between _cursorY and _scrollBottom is dirty
		memset(_dirty+_cursorY *_width,1,(_scrollBottom-_cursorY+1)*_width);
}

- (void)deleteLines:(int)n {
		int i, num_lines_moved;
		screen_char_t *sourceLine, *targetLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen deleteLines; %d]", n);
#endif

		// NSLog(@"insertLines %d[%d,%d]",n, _cursorX,_cursorY);
		if (n+_cursorY<=_scrollBottom) {
				// number of lines we can move down by n before we hit _scrollBottom
				num_lines_moved = _scrollBottom - (_cursorY + n);

				for (i = 0; i <= num_lines_moved; i++) {
						sourceLine = [self getLineAtScreenIndex:_cursorY + i + n];
						targetLine = [self getLineAtScreenIndex: _cursorY + i];
						memcpy(targetLine, sourceLine, REAL_WIDTH *sizeof(screen_char_t));
				}

		}
		if (n+_cursorY>_scrollBottom)
				n=_scrollBottom-_cursorY+1;
		// clear the n lines
		aDefaultLine = [self _getDefaultLineWithWidth: _width];
		for(i = 0; i < n; i++) {
				sourceLine = [self getLineAtScreenIndex:_scrollBottom-n+1+i];
				memcpy(sourceLine, aDefaultLine, REAL_WIDTH *sizeof(screen_char_t));
		}

		// everything between _cursorY and _scrollBottom is dirty
		memset(_dirty+_cursorY *_width,1,(_scrollBottom-_cursorY+1)*_width);

}

- (void)activateBell {
#if DEBUG_METHOD_TRACE
		NSLog(@"-[VT100Screen activateBell]");
#endif

		[_refreshDelegate activateBell];
}

- (void)showCursor:(BOOL)show {
		/*
		// TODO: Support this
		if (show)
		[display showCursor];
		else
		[display hideCursor];
		*/
}

- (int)cursorX {
		return _cursorX;
}

- (int)cursorY
{
		return _cursorY;
}

- (void)clearTabStop {
		int i;
		for(i=0;i<300;i++) _tabStop[i]=NO;
}

- (int)numberOfLines {
	return ([self numberOfScrollbackLines] + _height);
}

- (unsigned)numberOfScrollbackLines {
	int num_lines_in_scrollback =
		(_currentScrollbackLines > _maxScrollbackLines)
			? _maxScrollbackLines
			: _currentScrollbackLines;
	return num_lines_in_scrollback;
}

- (void)resetDirty {
		if (_dirty) {
			memset(_dirty,0, _width *_height *sizeof(char));
		}
}

- (void)setDirty {
		if (_dirty) {
			memset(_dirty, 1, _width *_height *sizeof(char));
		}

		[_refreshDelegate refresh];
}

- (void)resetScrollUpLines {
		_scrollUpLines = 0;
}

@end

@implementation VT100Screen (Private)

		// gets line offset by specified index from specified line poiner; accounts for buffer wrap
- (screen_char_t *)_getLineAtIndex:(int)anIndex fromLine:(screen_char_t *)aLine {
		screen_char_t *the_line = NULL;
		NSParameterAssert(anIndex >= 0);
		// get the line offset from the specified line
		the_line = aLine + anIndex *REAL_WIDTH;
		// check if we have gone beyond our buffer; if so, we need to wrap around to the top of buffer
		if(the_line > _lastBufferLine) {
				the_line = _bufferLines + (the_line - _lastBufferLine - REAL_WIDTH);
		}
		return (the_line);
}

// returns a line set to default character and attributes
// released when session is closed
- (screen_char_t *)_getDefaultLineWithWidth:(int)width {
		int i;

		// check if we have to generate a new line
		if(_defaultLine && _defaultFgCode == [_terminal foregroundColorCode] &&
						_defaultBgCode == [_terminal backgroundColorCode] && _defaultLineWidth >= width) {
				return (_defaultLine);
		}

		if(_defaultLine)
				free(_defaultLine);

		_defaultLine = (screen_char_t *)malloc((width+1)*sizeof(screen_char_t));

		for(i = 0; i < width; i++) {
				_defaultLine[i].code = 0;
				_defaultLine[i].foregroundColor = [_terminal foregroundColorCode];
				_defaultLine[i].backgroundColor = [_terminal backgroundColorCode];
		}
		//Not wrapped by default
		_defaultLine[width].code = 0;

		_defaultFgCode = [_terminal foregroundColorCode];
		_defaultBgCode = [_terminal backgroundColorCode];
		_defaultLineWidth = width;
		return (_defaultLine);
}


// adds a line to scrollback area. Returns YES if oldest line is lost, NO otherwise
- (BOOL)_addLineToScrollback {
		BOOL lost_oldest_line = NO;
		BOOL wrap;

#if DEBUG_METHOD_TRACE
		NSLog(@"%s", __PRETTY_FUNCTION__);
#endif

		if(_maxScrollbackLines>0) {
				if (_dynamicScrollbackSize && _maxScrollbackLines < MAX_SCROLLBACK_LINES ) {
						if (++_currentScrollbackLines > _maxScrollbackLines) {
								// scrollback area is full; add more
								screen_char_t *bl = _bufferLines;
								int total_height = _maxScrollbackLines + DEFAULT_SCROLLBACK + _height;
								bl = realloc (bl, total_height *REAL_WIDTH *sizeof(screen_char_t));
								if (!bl) {
										_scrollbackTop = incrementLinePointer(_bufferLines, _scrollbackTop, _maxScrollbackLines+_height, _width, &wrap);
										_currentScrollbackLines = _maxScrollbackLines;
										lost_oldest_line = YES;
								} else {
										/*screen_char_t *aLine = [self _getDefaultLineWithWidth: _width];
											int i;

											for(i = _maxScrollbackLines+_height; i < total_height; i++)
											memcpy(bl+_width *i, aLine, width *sizeof(screen_char_t));*/

										_maxScrollbackLines += DEFAULT_SCROLLBACK;

										_bufferLines = _scrollbackTop = bl;
										_lastBufferLine = bl + (total_height - 1)*REAL_WIDTH;
										_screenTop = bl + (_currentScrollbackLines-1)*REAL_WIDTH;

										lost_oldest_line = NO;
								}
						}
				} else {
						if (++_currentScrollbackLines > _maxScrollbackLines) {
								// scrollback area is full; lose oldest line
								_scrollbackTop = incrementLinePointer(_bufferLines, _scrollbackTop, _maxScrollbackLines+_height, _width, &wrap);
								_currentScrollbackLines = _maxScrollbackLines;
								lost_oldest_line = YES;
						}
				}
		}

		return (lost_oldest_line);
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
