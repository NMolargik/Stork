//
//  HospitalInfoRow.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct HospitalInfoRow: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(icon, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(color)

            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .lineLimit(nil) // Allow unlimited lines
                .multilineTextAlignment(.leading) // Ensure text aligns properly
            #if !SKIP
                .fixedSize(horizontal: false, vertical: true) // Prevent horizontal shrinking, force vertical expansion
            #endif
        }
    }
}

#Preview {
    HospitalInfoRow(icon: "figure.child", text: "Child Info", color: Color("storkIndigo"))
        .environmentObject(AppStorageManager())
}
