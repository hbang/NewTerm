//
//  CrossPlatformUI.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

#if os(macOS)
import AppKit

public typealias UIColor = NSColor
public typealias Font    = NSFont
public typealias UIFont  = NSFont
public typealias UIFontDescriptor = NSFontDescriptor
#else
import UIKit

public typealias Font  = UIFont
#endif
