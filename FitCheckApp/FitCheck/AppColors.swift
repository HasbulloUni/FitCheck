//
//  AppColors.swift
//  FitCheck
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

// Colori dell'app. Ogni colore ha la versione chiara e quella scura:
// si adatta da solo al tema di sistema.
// Per cambiare un colore basta modificare l'esadecimale qui sotto.

enum AppColors {

    // MARK: Sfondi
    static let background = Color(light: 0xF5F3EE, dark: 0x111111)
    static let card = Color(light: 0xFFFFFF, dark: 0x232321)
    static let cardAlt = Color(light: 0xE9E5DB, dark: 0x2E2D2A)
    static let divider = Color(light: 0xD9D5CA, dark: 0x3A3834)

    // MARK: Testi
    static let textPrimary = Color(light: 0x111111, dark: 0xF5F3EE)
    static let textSecondary = Color(light: 0x5F5D58, dark: 0xA8A59C)

    // MARK: Accenti
    static let green = Color(light: 0x2F7A1F, dark: 0x86CF69)
    static let greenSoft = Color(light: 0x6CBF4D, dark: 0x6CBF4D)
    static let yellow = Color(light: 0xF2C230, dark: 0xF6D25C)
    static let red = Color(light: 0xE5524A, dark: 0xF06B63)

    // MARK: Famiglie dei gruppi muscolari
    static let muscleBlue = Color(light: 0x4A9BD8, dark: 0x6CB4EA)
    static let musclePurple = Color(light: 0x7B4FD1, dark: 0xA287EA)
    static let muscleOrange = Color(light: 0xE8923A, dark: 0xF2A65E)
    static let muscleGreen = Color(light: 0x2F7A1F, dark: 0x86CF69)
    static let muscleYellow = Color(light: 0xF2C230, dark: 0xF6D25C)
    static let muscleRed = Color(light: 0xE5524A, dark: 0xF06B63)
}

extension Color {
    /// Colore con versione chiara e scura, scelta in automatico dal tema di sistema.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat((hex >> 0) & 0xFF) / 255,
            alpha: 1
        )
    }
}
