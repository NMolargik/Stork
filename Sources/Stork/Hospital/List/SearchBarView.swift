//
//  SearchBarView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct SearchBarView: View {
    @ObservedObject var hospitalViewModel: HospitalViewModel

    var body: some View {
        HStack {
            CustomTextfieldView(
                text: $hospitalViewModel.searchQuery,
                hintText: "Search by name",
                icon: Image(hospitalViewModel.usingLocation ? "location.fill" : "magnifyingglass"),
                isSecure: false,
                iconColor: hospitalViewModel.usingLocation ? .blue : Color("storkOrange")
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
                    color: Color("storkIndigo"),
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
    SearchBarView(
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider())
    )
}
