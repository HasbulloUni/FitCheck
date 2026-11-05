//
//  ReadyMadeCatalog.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// Reads ReadyMadePrograms.json from the app and finds the program the user asked for.
enum ReadyMadeCatalog {

    // The programs have plans for 2 to 5 days
    static let minDays = 2
    static let maxDays = 5

    // Read once, the first time it is needed
    static let programs: [ReadyMadeProgram] = {
        guard let url = Bundle.main.url(forResource: "ReadyMadePrograms", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ReadyMadeFile.self, from: data) else {
            print("ReadyMadeCatalog: ReadyMadePrograms.json not found or not readable")
            return []
        }
        return file.programs
    }()

    // The program for this level, style and number of training days.
    // Less than 2 days uses the 2-day program, more than 5 the 5-day one.
    static func program(level: ReadyMadeLevel, style: ReadyMadeStyle, days: Int) -> ReadyMadeProgram? {
        let clampedDays = min(max(days, minDays), maxDays)
        return programs.first {
            $0.level == level && $0.style == style.rawValue && $0.days == clampedDays
        }
    }
}
