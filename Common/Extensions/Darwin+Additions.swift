//
//  Darwin+Additions.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 19/7/2022.
//

import Foundation

// Macros copied from <sys/wait.h>
@inline(__always)
fileprivate func _WSTATUS(_ value: Int32) -> Int32 {
	return value & 0177
}

@inline(__always)
func WIFEXITED(_ value: Int32) -> Bool {
	return _WSTATUS(value) == 0
}

@inline(__always)
func WEXITSTATUS(_ value: Int32) -> Int32 {
	return (value >> 8) & 0xff
}
