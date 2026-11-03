//
//  Fnv1aHash.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - A hash that gives the same number on every run
// Swift's own hashValue changes at every launch. This one does not, so the same input
// always gives the same plan (the generator uses it to break ties between equal exercises).
enum Fnv1aHash {
    static func hash(_ text: String) -> UInt32 {
        var result: UInt32 = 2166136261
        for byte in text.utf8 {
            result = result ^ UInt32(byte)
            result = result &* 16777619     // &* = multiply without crashing on overflow
        }
        return result
    }
}
