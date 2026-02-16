//
//  TransparentSpriteView.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

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
