//
//  ContentView.swift
//  ARTest
//
//  Created by Dmytro Besedin on 16.06.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CustomARViewContainer()
            
            HStack {
                Button(action: {
                    ActionManager.shared.actionStream.send(.place3DModel)
                }, label: {
                    Text("Place 3D Model")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                })
                
                if !viewModel.combinedDebugText.isEmpty {
                    Button {
                        viewModel.showDebugUI.toggle()
                    } label: {
                        Text("Show Debug")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $viewModel.showDebugUI, onDismiss: {
            ActionManager.shared.isDebugLoggingEnabled.toggle()
        }) {
            VStack {
                HStack {
                    Spacer()
                    
                    Button("Close") {
                        viewModel.showDebugUI.toggle()
                    }
                    .padding(.trailing)
                }
                
                ScrollView {
                    Text(viewModel.combinedDebugText)
                        .font(.callout)
                        .foregroundColor(.black)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .presentationDetents(.init(([.medium, .large])))
            .onAppear {
                ActionManager.shared.isDebugLoggingEnabled.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}
