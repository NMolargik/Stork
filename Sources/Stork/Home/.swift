//
//  HomeCarouselView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI

struct HomeCarouselView: View {
    var body: some View {
        TabView {
            // Tab 1
                #if !SKIP
                DeliveriesPerDay()
                .tag(0)
                #endif

            
            // Tab 2
            Color.black
                .tag(1)
            
            // Tab 3
            Color.blue
                .tag(2)
        }
        #if !SKIP
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: PageTabViewStyle.IndexDisplayMode.always))
        #endif
        .frame(height: 200) // Adjust the height as needed
        .padding()
    }
}

#Preview {
    HomeCarouselView()
}
