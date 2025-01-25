//
//  HospitalListView.swift
//  Stork
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct HospitalListView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var navigationPath: [String] = []
    @State var selectionMode: Bool = false
    var onSelection: (Hospital) -> Void

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                SearchBarView()
                
                if hospitalViewModel.hospitals.isEmpty && !hospitalViewModel.isWorking {
                    NoHospitalsFoundView()
                }
                
                hospitalListView
            }
            .navigationTitle("Hospitals")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if hospitalViewModel.usingLocation {
                        locationSearchIndicator
                    } else {
                        useLocationButton
                    }
                }
                
                ToolbarItem {
                    missingHospitalButton
                }
            }
        }
        .onAppear(perform: fetchHospitalsIfNeeded)
        .sheet(isPresented: $hospitalViewModel.isMissingHospitalSheetPresented) {
            MissingHospitalSheetView { hospitalName in
                onSelection(try await hospitalViewModel.createMissingHospital(name: hospitalName))
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }
}

// MARK: - Views
private extension HospitalListView {
    var hospitalListView: some View {
        List(hospitalViewModel.hospitals, id: \.id) { hospital in
            if selectionMode {
                Button(action: {
                    withAnimation {
                        print("Selecting \(hospital.facility_name)")
                        onSelection(hospital)
                    }
                }) {
                    HospitalRowView(selectionMode: $selectionMode, hospital: hospital)
                }
            } else {
                NavigationLink(destination: HospitalDetailView(hospital: hospital)) {
                    HospitalRowView(selectionMode: $selectionMode, hospital: hospital)
                }
            }
        }
    }
    
    var locationSearchIndicator: some View {
        HStack {
            Spacer()
            
            Text("Searching by location")
                .fontWeight(.bold)
            
            Image("location.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .foregroundColor(.blue)
        .padding(.trailing)
    }

    var useLocationButton: some View {
        Button(action: {
            triggerHaptic()
            withAnimation {
                hospitalViewModel.searchQuery = ""
                fetchNearbyHospitals()
            }
        }) {
            Text("Use Location")
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }

    var missingHospitalButton: some View {
        Button(action: {
            triggerHaptic()
            withAnimation {
                hospitalViewModel.isMissingHospitalSheetPresented = true
            }
        }) {
            Text("Missing?")
                .foregroundColor(Color("storkOrange"))
                .fontWeight(.bold)
        }
    }
}

// MARK: - Helper Methods
private extension HospitalListView {
    func fetchHospitalsIfNeeded() {
        if hospitalViewModel.hospitals.isEmpty {
            fetchNearbyHospitals()
        }
    }

    func fetchNearbyHospitals() {
        Task {
            await hospitalViewModel.fetchHospitalsNearby()
        }
    }
}

// MARK: - Preview
#Preview {
    HospitalListView(selectionMode: true, onSelection: { _ in })
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
