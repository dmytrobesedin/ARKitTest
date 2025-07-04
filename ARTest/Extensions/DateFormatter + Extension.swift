//
//  DateFormatter + Extension.swift
//  ARTest
//
//  Created by Dmytro Besedin on 03.07.2025.
//

import Foundation

extension DateFormatter {
    static let debugTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
