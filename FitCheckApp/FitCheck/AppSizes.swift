//
//  AppSizes.swift
//  FitCheck
//
//  All the sizes of the app in one place, like AppColors does for colors.
//  Every value is a multiple of `unit` (1% of the screen width),
//  so use it like this:  AppSizes.Text.body * unit
//
//  The scale follows the Gestalt principles:
//  - Similarity: same role = same size, everywhere in the app.
//  - Proximity: little space inside a group, more space between groups.
//  - Hierarchy: each text step is clearly different from the next one.
//  - Common region: cards share only a few corner radii.
//  To change a size for the whole app, change it here.

import SwiftUI

enum AppSizes {

    // MARK: Text (7 steps, from the smallest to the biggest)
    enum Text {
        static let caption: CGFloat = 2.8      // tiny labels, units, hints
        static let small: CGFloat = 3.2        // secondary text, captions of cards
        static let body: CGFloat = 3.8         // normal text, rows, buttons
        static let bodyLarge: CGFloat = 4.4    // emphasized text, card titles
        static let title: CGFloat = 6          // screen section titles
        static let display: CGFloat = 8        // big numbers
        static let hero: CGFloat = 10          // the biggest number on a screen
    }

    // MARK: Corner radius (the shape of a container tells what it is)
    enum Radius {
        static let small: CGFloat = 3          // chips, small buttons, thumbnails
        static let card: CGFloat = 5           // cards and rows
        static let large: CGFloat = 6          // sheets and hero cards
    }

    // MARK: Spacing (proximity: closer = more related)
    enum Space {
        static let tight: CGFloat = 1          // lines of the same text block
        static let related: CGFloat = 2        // elements of the same group
        static let group: CGFloat = 3          // different groups in a card
        static let section: CGFloat = 4        // blocks of a screen
        static let screen: CGFloat = 6         // big separations
    }
}
