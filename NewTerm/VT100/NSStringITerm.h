// $Id: NSStringITerm.h,v 1.2 2006-11-13 06:57:47 yfabian Exp $
//
//  NSStringJTerminal.h
//
//  Additional function to NSString Class by Category
//  2001.11.13 by Y.Hanahara
//  2002.05.18 by Kiichi Kusama
/*
 **  NSStringIterm.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian
 **      Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: Implements NSString extensions.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

@import Foundation;

// This is the standard unicode replacement character for when input couldn't
// be parsed properly but we need to render something there.
#define UNICODE_REPLACEMENT_CHAR 0xfffd

@interface NSString (iTerm)

+ (BOOL)isDoubleWidthCharacter:(int)unicode
        ambiguousIsDoubleWidth:(BOOL)ambiguousIsDoubleWidth
                unicodeVersion:(NSInteger)version;

// Call |block| for each composed character in the string. If it is a single base character or a
// high surrogate, then |simple| will be valid and |complex| will be nil. Otherwise, |complex| will
// be non-nil.
- (void)enumerateComposedCharacters:(void (^)(NSRange range,
                                              unichar simple,
                                              NSString *complexString,
                                              BOOL *stop))block;

@end
