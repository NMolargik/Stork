//
//  StorkMark.swift
//  StorkDesignSystem
//
//  The Stork mark, drawn in code: a marble jar with an orange lid. Geometry is the app
//  icon's, on a 1024 grid (no background), so the mark scales cleanly at any size and is
//  usable in the app, widgets and watch. The colours are fixed and look the same in light
//  and dark mode.
//

import SwiftUI

public struct StorkMark: View {
    /// Draws the jar as a single-colour silhouette (outline, lid, separate marbles) in the
    /// current foreground style. Lock Screen and tinted widgets recolour everything to one
    /// tint, where the full-colour mark would melt into a solid blob.
    let isMonochrome: Bool

    public init(monochrome: Bool = false) {
        isMonochrome = monochrome
    }

    // MARK: Colours

    /// The jar's glass body. The one colour of the mark that may still change.
    public static let jarBody = Color(red: 0xDC / 255, green: 0xD5 / 255, blue: 0xF4 / 255)
    public static let lid = Color(red: 0xF0 / 255, green: 0x7A / 255, blue: 0x3C / 255)

    /// The six marbles on the 1024 grid, bottom row first: centre and colour (radius 92).
    public static let marbles: [(x: CGFloat, y: CGFloat, color: Color)] = [
        (346, 790, Color(red: 0x6C / 255, green: 0xB8 / 255, blue: 0xF4 / 255)),
        (512, 800, Color(red: 0xEE / 255, green: 0x8A / 255, blue: 0xF5 / 255)),
        (678, 790, Color(red: 0x75 / 255, green: 0x59 / 255, blue: 0xFF / 255)),
        (430, 638, Color(red: 0xF0 / 255, green: 0x7A / 255, blue: 0x3C / 255)),
        (594, 638, Color(red: 0x6C / 255, green: 0xB8 / 255, blue: 0xF4 / 255)),
        (512, 488, Color(red: 0xEE / 255, green: 0x8A / 255, blue: 0xF5 / 255)),
    ]

    public static let marbleRadius: CGFloat = 92

    // MARK: Body

    // Built from plain shapes (not a Canvas) so it renders in widgets and on the watch too.
    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let k = side / 1024
            ZStack(alignment: .topLeading) {
                if isMonochrome {
                    monochromeJar(k: k)
                } else {
                    fullColorJar(k: k)
                }
            }
            .frame(width: side, height: side, alignment: .topLeading)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func monochromeJar(k: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 44 * k, style: .circular)
            .frame(width: 300 * k, height: 110 * k)
            .offset(x: 362 * k, y: 160 * k)
        RoundedRectangle(cornerRadius: 170 * k, style: .circular)
            .strokeBorder(lineWidth: 52 * k)
            .frame(width: 580 * k, height: 670 * k)
            .offset(x: 222 * k, y: 250 * k)
        ForEach(Array(Self.marbles.enumerated()), id: \.offset) { _, marble in
            // Smaller than the full-colour marbles so neighbours stay separate.
            Circle()
                .frame(width: 2 * 68 * k, height: 2 * 68 * k)
                .offset(x: (marble.x - 68) * k, y: (marble.y - 68) * k)
        }
    }

    @ViewBuilder
    private func fullColorJar(k: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 44 * k, style: .circular)
            .fill(Self.lid)
            .frame(width: 300 * k, height: 110 * k)
            .offset(x: 362 * k, y: 160 * k)
        RoundedRectangle(cornerRadius: 170 * k, style: .circular)
            .fill(Self.jarBody)
            .frame(width: 580 * k, height: 670 * k)
            .offset(x: 222 * k, y: 250 * k)
        ForEach(Array(Self.marbles.enumerated()), id: \.offset) { _, marble in
            Circle()
                .fill(marble.color)
                .frame(width: 2 * Self.marbleRadius * k, height: 2 * Self.marbleRadius * k)
                .offset(x: (marble.x - Self.marbleRadius) * k, y: (marble.y - Self.marbleRadius) * k)
        }
    }
}

#if DEBUG
#Preview("Stork mark") {
    HStack(spacing: 24) {
        StorkMark().frame(width: 240, height: 240)
        StorkMark(monochrome: true).foregroundStyle(.white).frame(width: 240, height: 240)
    }
    .padding()
    .background(Color(white: 0.5))
}
#endif
