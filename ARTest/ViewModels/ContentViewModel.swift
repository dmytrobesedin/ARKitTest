//
//  ContentViewModel.swift
//  ARTest
//
//  Created by Dmytro Besedin on 03.07.2025.
//

import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published var combinedDebugText = ""
    @Published var showDebugUI = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        ActionManager.shared
            .debugText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] debugText in
                guard let self else { return }
                if self.combinedDebugText.isEmpty {
                    self.combinedDebugText = debugText
                } else {
                    self.combinedDebugText += "\n" + debugText
                }
            }
            .store(in: &cancellables)
    }
}
