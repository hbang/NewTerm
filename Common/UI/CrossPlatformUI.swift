//
//  CrossPlatformUI.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 20/6/19.
//

#if os(macOS)
import AppKit

public typealias Color = NSColor
public typealias Font  = NSFont
#else
import UIKit

public typealias Color = UIColor
public typealias Font  = UIFont
#endif
