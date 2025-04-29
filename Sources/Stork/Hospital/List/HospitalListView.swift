//
//  HospitalListView.swift
//  Stork
//
//  Created by Nick Molargik on 11/29/24.
//

import SkipFoundation
import SwiftUI
import StorkModel

#if !SKIP
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#else
import SkipFirebaseCore
import SkipFirebaseFirestore
import SkipFirebaseAuth
#endif

struct HospitalListView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @State var selectionMode: Bool = false
    
    var onSelection: (Hospital) -> Void

    var body: some View {
        NavigationStack(path: $appStateManager.navigationPath) {
            VStack {
                SearchBarView(hospitalViewModel: hospitalViewModel)
                    .onAppear(perform: fetchHospitalsIfNeeded)
                
                if hospitalViewModel.hospitals.isEmpty && !hospitalViewModel.isWorking {
                    NoHospitalsFoundView()
                }
                                
                List(hospitalViewModel.hospitals, id: \.id) { hospital in
                    if selectionMode {
                        Button(action: {
                            withAnimation {
                                print("Selecting \(hospital.facility_name)")
                                onSelection(hospital)
                            }
                        }) {
                            HospitalRowView(profileViewModel: profileViewModel, selectionMode: $selectionMode, hospital: hospital)
                        }
                    } else {
                        NavigationLink(destination: HospitalDetailView(
                            hospitalViewModel: hospitalViewModel,
                            profileViewModel: profileViewModel,
                            hospital: hospital
                        )
                        ) {
                            HospitalRowView(profileViewModel: profileViewModel, selectionMode: $selectionMode, hospital: hospital)
                        }
                    }
                }
            }
            .navigationTitle("Hospitals")
            .toolbar {
                #if !SKIP // No location searching on Android
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if hospitalViewModel.usingLocation {
                        locationSearchIndicator
                    } else {
                        useLocationButton
                    }
                }
                #endif
                
                ToolbarItem {
                    missingHospitalButton
                }
            }
        }
        .sheet(isPresented: $hospitalViewModel.isMissingHospitalSheetPresented) {
            MissingHospitalSheetView { hospitalName in
                onSelection(try await hospitalViewModel.createMissingHospital(name: hospitalName))
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }
    
    var locationSearchIndicator: some View {
        HStack {
            Spacer()
            
            Text("Searching by State")
                .fontWeight(.bold)
            
            Image("location.fill", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .foregroundStyle(.blue)
        .padding(.trailing)
    }

    var useLocationButton: some View {
        Button(action: {
            HapticFeedback.trigger(style: .medium)
            withAnimation {
                hospitalViewModel.searchQuery = ""
                fetchNearbyHospitals()
            }
        }) {
            Text("Use Location")
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
    }

    var missingHospitalButton: some View {
        Button(action: {
            HapticFeedback.trigger(style: .medium)
            withAnimation {
                hospitalViewModel.isMissingHospitalSheetPresented = true
            }
        }) {
            Text("Missing?")
                .foregroundStyle(Color("storkOrange"))
                .fontWeight(.bold)
        }
    }
    
    func fetchHospitalsIfNeeded() {
        if hospitalViewModel.hospitals.isEmpty && Auth.auth().currentUser != nil {
            fetchNearbyHospitals()
        }
    }

    func fetchNearbyHospitals() {
        print("Fetching nearby hospitals")
        
        Task {
            await hospitalViewModel.fetchHospitalsNearby()
        }
    }
}

#Preview {
    HospitalListView(
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()),
        onSelection: { _ in }
    )
    .environmentObject(AppStateManager.shared)
}
