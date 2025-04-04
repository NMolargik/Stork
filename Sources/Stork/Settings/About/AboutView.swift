//
//  AboutView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct AboutView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    let appInfo: (name: String, version: String)

    var body: some View {
        Group {
            AboutRowView(title: "Version", content: Text(appInfo.version)
                .foregroundStyle(useDarkMode ? Color.white : Color.black))
                .foregroundStyle(useDarkMode ? Color.white : Color.black)
            
            
            AboutRowView(title: "Developer", content:
                Link("Nick Molargik", destination: URL(string: "https://www.nickmolargik.tech")!)
                    .foregroundStyle(Color("storkBlue"))
            )
            .foregroundStyle(useDarkMode ? Color.white : Color.black)
            
            AboutRowView(title: "Multiplatform Technology", content:
                Link("Skip", destination: URL(string: "https://skip.tools")!)
                    .foregroundStyle(Color("storkBlue"))
            )
            .foregroundStyle(useDarkMode ? Color.white : Color.black)
        }
    }
}

#Preview {
    AboutView(appInfo: ("Stork", "1.0.0"))
}
