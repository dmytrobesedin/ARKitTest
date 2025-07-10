//
//  CustomARView.swift
//  ARTest
//
//  Created by Dmytro Besedin on 17.06.2025.
//

import SwiftUI
import ARKit
import RealityKit
import FocusEntity
import Combine

struct CustomARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomARView {
        return CustomARView()
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}

class CustomARView: ARView {
    var focusEntity: FocusEntity?
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        super.init(frame: .zero)
        self.session.delegate = self
        
        // ActionStrean
        subscribeToActionStream()
        
        self.setUpFocusEntity()
        self.setUpARView()
    }
    
    deinit {
        ActionManager.shared.actionStream.send(.remove3DModel)
        ActionManager.shared.actionStream.send(completion: .finished)
        ActionManager.shared.debugText.send(completion: .finished)
    }
    
    @MainActor @preconcurrency required dynamic init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor @preconcurrency required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    private func subscribeToActionStream() {
        ActionManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                case .place3DModel:
                    self?.place3DModel()
                case .remove3DModel:
                    self?.focusEntity = nil
                    print("Removeing 3D model: has not been implemented")
                }
            }
            .store(in: &cancellables)
    }
    
    private func place3DModel() {
        guard let focusEntity = self.focusEntity else { return }
        
        let modelEntity = try! ModelEntity.load(named: "frame_000_cylinders.usdz")
        modelEntity.transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        modelEntity.setScale(.init(x: 0.5, y: 0.5, z: 0.5), relativeTo: nil)
        let anchorEntity = AnchorEntity(world: focusEntity.position)
        anchorEntity.addChild(modelEntity)
        self.scene.addAnchor(anchorEntity)
    }
    
    private func setUpFocusEntity() {
        self.focusEntity = FocusEntity(on: self, style: .classic(color: .yellow))
    }
    
    private func setUpARView() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        
        self.session.run(config)
    }
}

//MARK: ARSessionDelegate
extension CustomARView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        let printMessage = "[\(timestamp)] 🔹 didAdd triggered with \(anchors.count) anchors"
        sendDebugInfo(printMessage)
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor,
               let currentFrame = session.currentFrame {
                let cameraTransform = currentFrame.camera.transform
                let params = getPlaneEquationParameters(transform: planeAnchor.transform,
                                                    cameraTransform: cameraTransform)
                let message = "[\(timestamp)] 📐 Plane equation (didAdd): a = \(params.a), b = \(params.b), c = \(params.c), d = \(params.d)"
                sendDebugInfo(message)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let timestamp = DateFormatter.debugTimestamp.string(from: Date())
        let printMessage = "[\(timestamp)] 🔄 didUpdate triggered with \(anchors.count) anchors"
        sendDebugInfo(printMessage)
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor,
                let currentFrame = session.currentFrame {
                let cameraTransform = currentFrame.camera.transform
                let params = getPlaneEquationParameters(transform: planeAnchor.transform,
                                                    cameraTransform: cameraTransform)
                let message = "[\(timestamp)] 📐 Plane equation (didUpdate): a = \(params.a), b = \(params.b), c = \(params.c), d = \(params.d)"
            sendDebugInfo(message)
            }
        }
    }
    
    private func handlePlaneAnchor(_ anchor: ARAnchor, prefix: String) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeExtent = planeAnchor.planeExtent
        let geometry = planeAnchor.geometry
        print("\(prefix) Plane updated:")
        print("Center: \(planeAnchor.center)")
        print("PlaneExtent: width: \(planeExtent.width), height: \(planeExtent.height), rotationOnYAxis: \(planeExtent.rotationOnYAxis)")
        print("Alignment: \(planeAnchor.alignment)")
        print("Geometry: vertices=\(geometry.vertices.count), triangles=\(geometry.triangleCount)")
    }
    
    private func getPlaneEquationParameters(transform: simd_float4x4, cameraTransform: simd_float4x4) -> (a: Float, b: Float, c: Float, d: Float) {
        let planeNormalWorld = SIMD3<Float>(
            transform.columns.1.x,
            transform.columns.1.y,
            transform.columns.1.z
        )
        
        let planeOriginWorld = SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        
        let worldToCamera = simd_inverse(cameraTransform)
        
        // Convert point to camera coordinates
        let pointInCamera = worldToCamera * SIMD4<Float>(planeOriginWorld, 1)
        let planeOriginCamera = SIMD3<Float>(pointInCamera.x, pointInCamera.y, pointInCamera.z)
        
        // Convert normal to camera coordinates (only rotate, don't translate)\
        let rotationOnly = simd_float3x3(
            columns:
                (SIMD3<Float>(worldToCamera.columns.0.x, worldToCamera.columns.0.y, worldToCamera.columns.0.z),
                 SIMD3<Float>(worldToCamera.columns.1.x, worldToCamera.columns.1.y, worldToCamera.columns.1.z),
                 SIMD3<Float>(worldToCamera.columns.2.x, worldToCamera.columns.2.y, worldToCamera.columns.2.z)
                )
        )
        let planeNormalCamera = simd_normalize(rotationOnly * planeNormalWorld)
        
        let a = planeNormalCamera.x
        let b = planeNormalCamera.y
        let c = planeNormalCamera.z
        let d = -simd_dot(planeNormalCamera, planeOriginCamera)
        
        return (a, b, c, d)
    }
    
    private func sendDebugInfo(_ message: String) {
        print(message)
        ActionManager.shared.sendDebug(message)
    }
}
