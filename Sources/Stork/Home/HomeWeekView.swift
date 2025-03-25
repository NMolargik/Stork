//
//  HomeTimeView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI

struct HomeTimeView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        HStack {
            Text("\(appStateManager.dateFormatterMMMdhmmssa)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .onAppear(perform: appStateManager.startTimer)
            Spacer()
        }
        .offset(y: -4)
    }
}

#Preview {
    HomeTimeView()
        .environmentObject(AppStateManager.shared)
}
