//
//  SearchBarView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject var hospitalViewModel: HospitalViewModel

    var body: some View {
        HStack {
            CustomTextfieldView(
                text: $hospitalViewModel.searchQuery,
                hintText: "Search by name",
                icon: Image(systemName: hospitalViewModel.usingLocation ? "location.fill" : "magnifyingglass"),
                isSecure: false,
                iconColor: hospitalViewModel.usingLocation ? Color.blue : Color.orange
            )
            .onChange(of: hospitalViewModel.searchQuery) { query in
                withAnimation {
                    hospitalViewModel.searchEnabled = !query.isEmpty
                }
            }
            .onAppear {
                hospitalViewModel.searchEnabled = !hospitalViewModel.searchQuery.isEmpty
            }
            
            if hospitalViewModel.searchEnabled {
                CustomButtonView(
                    text: "Search",
                    width: 80,
                    height: 55,
                    color: .indigo,
                    isEnabled: hospitalViewModel.searchEnabled,
                    onTapAction: {
                        Task {
                            await hospitalViewModel.searchHospitals()
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchBarView()
}
