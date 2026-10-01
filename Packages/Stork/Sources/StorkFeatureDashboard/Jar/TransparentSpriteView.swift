//
//  TransparentSpriteView.swift
//  StorkFeatureDashboard
//
//  Hosts an `SKScene` with a transparent background so the jar floats over Liquid Glass.
//

#if os(iOS)
import SwiftUI
import SpriteKit

struct TransparentSpriteView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsTransparency = true
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        uiView.presentScene(scene)
    }
}
#endif
