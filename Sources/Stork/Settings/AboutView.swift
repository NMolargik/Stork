//
//  AboutView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct AboutView: View {
    let appInfo: (name: String, version: String)

    var body: some View {
        Section(header: Text("Stork")) {
            HStack {
                Text("Version")
                Spacer()
                Text(appInfo.version)
            }

            HStack {
                Text("Developer")
                Spacer()
                Link("Nick Molargik", destination: URL(string: "https://www.nickmolargik.tech")!)
                    .foregroundColor(.blue)
                    .underline(false)
            }

            HStack {
                Text("Multiplatform Technology")
                Spacer()
                Link("Skip", destination: URL(string: "https://skip.tools")!)
                    .foregroundColor(.blue)
            }
        }
    }
}
#Preview {
    AboutView(appInfo: ("Stork", "1.0.0"))
}
