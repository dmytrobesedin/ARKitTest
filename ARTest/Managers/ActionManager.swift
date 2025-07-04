//
//  ActionManager.swift
//  ARTest
//
//  Created by Dmytro Besedin on 17.06.2025.
//

import Foundation
import Combine

enum Actions {
    case place3DModel
    case remove3DModel
}

class ActionManager {
    static let shared = ActionManager()
    var actionStream = PassthroughSubject<Actions, Never>()
    var debugText = PassthroughSubject<String, Never>()
    var isDebugLoggingEnabled = true
    
    private init() { }
    
    func sendDebug(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        debugText.send(message)
    }
}
