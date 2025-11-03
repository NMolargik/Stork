//
//  OnboardingCompletePage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI

struct OnboardingCompletePage: View {
    @State private var shownRows: [Bool] = [false, false, false, false]
    @State private var showButton: Bool = false
    
    var onFinish: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 12)
                
                Text("Here's what you've got to look forward to.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Feature cards
                VStack(spacing: 14) {
                    DetailRowView(
                        style: .feature,
                        systemImage: "stethoscope",
                        title: "Track your deliveries.",
                        tint: .storkPink
                    )
                    .opacity(shownRows[0] ? 1 : 0)
                    .offset(x: shownRows[0] ? 0 : -32)
                    .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[0])
                    .symbolEffect(.bounce, value: shownRows[0])
                    
                    DetailRowView(
                        style: .feature,
                        systemImage: "cloud",
                        title: "Effortless syncing between Apple devices",
                        tint: .storkBlue
                    )
                    .opacity(shownRows[1] ? 1 : 0)
                    .offset(x: shownRows[1] ? 0 : 32)
                    .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[1])
                    .symbolEffect(.bounce, value: shownRows[1])
                    
                    DetailRowView(
                        style: .feature,
                        systemImage: "chart.xyaxis.line",
                        title: "View trends and statistics over time",
                        tint: .storkPurple
                    )
                    .opacity(shownRows[2] ? 1 : 0)
                    .offset(x: shownRows[2] ? 0 : -32)
                    .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[2])
                    .symbolEffect(.bounce, value: shownRows[2])
                    
                    DetailRowView(
                        style: .feature,
                        systemImage: "circle.hexagongrid",
                        title: "Start adding to your Delivery Jar",
                        tint: .secondary
                    )
                    .opacity(shownRows[3] ? 1 : 0)
                    .offset(x: shownRows[3] ? 0 : 32)
                    .animation(.spring(response: 1.2, dampingFraction: 0.85), value: shownRows[3])
                    .symbolEffect(.bounce, value: shownRows[3])
                }
                .padding(.horizontal)
                
                Spacer(minLength: 12)
                
                Button(action: onFinish) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                            .symbolEffect(.bounce, value: showButton)
                        Text("Enter Stork")
                            .font(.title3).bold()
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                .adaptiveGlass(tint: .storkPurple)
                .shadow(radius: 6, y: 3)
                .padding(.horizontal)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 12)
                .animation(.spring(response: 1.2, dampingFraction: 0.85), value: showButton)
            }
            .navigationTitle("All Set!")
            .task {
                for i in 0..<shownRows.count {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    withAnimation(.spring(response: 1.2, dampingFraction: 0.85)) {
                        shownRows[i] = true
                    }
                }
                try? await Task.sleep(nanoseconds: 800_000_000)
                withAnimation(.spring(response: 1.2, dampingFraction: 0.85)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingCompletePage(onFinish: {})
    }
}
