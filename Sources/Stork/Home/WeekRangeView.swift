//
//  WeekRangeView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct WeekRangeView: View {
    let weekRange: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            if !weekRange.isEmpty {
                Text(weekRange)
                    .padding(8)
                    .foregroundStyle(.gray)
                    .font(.headline)
                    .fontWeight(.bold)
                    .background {
                        Rectangle()
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .cornerRadius(20)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                    }
                    .padding(.top, 20)
            }
            Spacer()
        }
    }
}

#Preview {
    WeekRangeView(weekRange: "Sample Week", colorScheme: ColorScheme.dark)
}
