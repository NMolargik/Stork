//
//  AboutView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    let appInfo: (name: String, version: String)

    var body: some View {
        Section(header: Text("Stork")) {
            AboutRowView(title: "Version", content: Text(appInfo.version)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black))
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
            
            
            AboutRowView(title: "Developer", content:
                Link("Nick Molargik", destination: URL(string: "https://www.nickmolargik.tech")!)
                    .foregroundStyle(Color("storkBlue"))
            )
            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
            
            AboutRowView(title: "Multiplatform Technology", content:
                Link("Skip", destination: URL(string: "https://skip.tools")!)
                    .foregroundStyle(Color("storkBlue"))
            )
            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
        }
    }
}

#Preview {
    AboutView(appInfo: ("Stork", "1.0.0"))
        .environmentObject(AppStorageManager())
}
