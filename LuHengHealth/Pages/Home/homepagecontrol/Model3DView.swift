//
//  Model3DView.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/8.
//


//
//  Model3DView.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/17.
//

import SwiftUI
import SceneKit
import Foundation


struct Model3DView: View {
    @Binding var ModelColor : Color
    @Binding var brightness: Double
    @State private var scene: SCNScene = SceneKitCache.shared.makeSceneInstance()
    
    var body: some View {
        TransparentSceneView(scene: scene, allowsCameraControl: true, rendersContinuously: true)
            .background(Color.clear)
            .onAppear {
                SceneKitCache.shared.applyColor(ModelColor, to: scene, nodeName: "jade", brightness: brightness)
            }
            .onChange(of: ModelColor) { newColor in
                SceneKitCache.shared.applyColor(newColor, to: scene, nodeName: "jade", brightness: brightness)
            }
            .onChange(of: brightness) { newValue in
                SceneKitCache.shared.applyColor(ModelColor, to: scene, nodeName: "jade", brightness: newValue)
            }
    }
}

#Preview {
    Model3DView(ModelColor: .constant(.white), brightness: .constant(1.0))
        .frame(height: 200)
    
}

struct TransparentSceneView: UIViewRepresentable {
    var scene: SCNScene
    var allowsCameraControl: Bool = false
    var preferredFramesPerSecond: Int = 60
    var antialiasingMode: SCNAntialiasingMode = .multisampling4X
    var rendersContinuously: Bool = false

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = allowsCameraControl
        scnView.antialiasingMode = antialiasingMode
        scnView.preferredFramesPerSecond = preferredFramesPerSecond
        scnView.rendersContinuously = rendersContinuously
        scnView.contentScaleFactor = UIScreen.main.scale
        scnView.isPlaying = true
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene !== scene {
            uiView.scene = scene
        }
        uiView.allowsCameraControl = allowsCameraControl
        uiView.antialiasingMode = antialiasingMode
        uiView.preferredFramesPerSecond = preferredFramesPerSecond
        uiView.rendersContinuously = rendersContinuously
        uiView.setNeedsDisplay()
    }
}


final class SceneKitCache {
    static let shared = SceneKitCache()

    private var baseScene: SCNScene?

    private init() {}

    private func loadBaseSceneIfNeeded() -> SCNScene {
        if let scene = baseScene {
            return scene
        }
        let scene = SCNScene(named: "light.usdz") ?? SCNScene()
        scene.background.contents = UIColor.clear
        baseScene = scene
        return scene
    }

    func makeSceneInstance() -> SCNScene {
        let base = loadBaseSceneIfNeeded()

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // 克隆基础场景中的所有子节点
        for child in base.rootNode.childNodes {
            scene.rootNode.addChildNode(child.clone())
        }

        // 确保存在相机
        let hasCamera = scene.rootNode.childNodes.contains(where: { $0.camera != nil })
        if !hasCamera {
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(x: 0, y: 24, z: 45)
            scene.rootNode.addChildNode(cameraNode)
        }

        return scene
    }

    func applyColor(_ color: Color, to scene: SCNScene, nodeName: String? = "jade", brightness: Double = 1.0) {
        let ui = UIColor(color)
        let intensity = max(0.0, min(brightness, 1.0))
        DispatchQueue.main.async {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0
            if let name = nodeName, let target = scene.rootNode.childNode(withName: name, recursively: true) {
                self.traverseAndModify(node: target, color: ui, brightness: CGFloat(intensity))
            } else {
                self.traverseAndModify(node: scene.rootNode, color: ui, brightness: CGFloat(intensity))
            }
            SCNTransaction.commit()
        }
    }

    private func traverseAndModify(node: SCNNode, color: UIColor, brightness: CGFloat) {
        if let geometry = node.geometry {
            for material in geometry.materials {
                // 当brightness接近0时，混合到白色；当brightness为1时，显示原始颜色
                let targetColor = blendColorWithWhite(color: color, brightness: brightness)
                
                // 使用diffuse应用混合后的颜色，intensity始终为1以确保可见
                material.diffuse.contents = targetColor
                material.diffuse.intensity = 1.0
                
                // 保持原有的其他材质设置
                material.specular.contents = UIColor.white
                material.shininess = 0
                material.metalness.contents = 0
                material.roughness.contents = 0.3
                material.lightingModel = .physicallyBased
                
                // 清除multiply以避免干扰
                material.multiply.contents = UIColor.white
                material.multiply.intensity = 1.0
            }
        }
        for child in node.childNodes {
            traverseAndModify(node: child, color: color, brightness: brightness)
        }
    }
    
    // 混合颜色和白色的辅助函数
    private func blendColorWithWhite(color: UIColor, brightness: CGFloat) -> UIColor {
        // 获取原始颜色的RGB值
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // brightness为0时显示白色，brightness为1时显示原始颜色
        // 使用线性插值在白色和原始颜色之间混合
        let blendedRed = (1.0 - brightness) * 1.0 + brightness * red
        let blendedGreen = (1.0 - brightness) * 1.0 + brightness * green
        let blendedBlue = (1.0 - brightness) * 1.0 + brightness * blue
        
        return UIColor(red: blendedRed, green: blendedGreen, blue: blendedBlue, alpha: alpha)
    }
}


