//
//  HospitalListView.swift
//
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
    var onSelection: ((Hospital) -> Void)

    var body: some View {
        //TODO: post release, show default hospital at top
        
        NavigationStack(path: $navigationPath) {
            HStack {
                CustomTextfieldView(text: $hospitalViewModel.searchQuery, hintText: "Search by name", icon: Image(systemName: hospitalViewModel.usingLocation ? "location.fill" : "magnifyingglass"), isSecure: false, iconColor: hospitalViewModel.usingLocation ? Color.blue : Color.orange)
                    .onChange(of: hospitalViewModel.searchQuery) { query in
                        withAnimation {
                            hospitalViewModel.searchEnabled = query.count > 0
                        }
                    }
                    .onAppear {
                        hospitalViewModel.searchEnabled = hospitalViewModel.searchQuery.count > 0
                    }
                
                if (hospitalViewModel.searchEnabled) {
                    CustomButtonView(text: "Search", width: 80, height: 55, color: Color.indigo, isEnabled: hospitalViewModel.searchEnabled, onTapAction: {
                        Task {
                            try await hospitalViewModel.searchHospitals()
                        }
                    })
                }
            }
            .padding(.horizontal)
            
            if (hospitalViewModel.hospitals.count == 0 && !hospitalViewModel.isWorking) {
                Text("No hospitals found. Either Stork services are down, or you should change your search criteria.\n\nIf you feel your hospital is missing, report it using the button above.")
                    .padding()
                    .multilineTextAlignment(.center)
                    .background {
                        Color.white
                            .cornerRadius(20)
                            .shadow(radius: 2)
                    }
                    .padding()
            }
            
            List(hospitalViewModel.hospitals, id: \.id) { hospital in
                if (selectionMode) {
                    Button(action: {
                        withAnimation {
                            print("Selecting \(hospital.facility_name)")
                            onSelection(hospital)
                        }
                    }, label: {
                        HospitalRowView(selectionMode: $selectionMode, hospital: hospital)
                    })
                } else {
                    NavigationLink(destination: HospitalDetailView(hospital: hospital)) {
                        HospitalRowView(selectionMode: $selectionMode, hospital: hospital)
                    }
                }
            }
            .navigationTitle("Hospitals")
            .navigationDestination(for: String.self) { value in
                if value == "ProfileView" {
                    Text("Shared Profile View")
                } else {
                    Text("Other View: \(value)")
                }
            }
            .toolbar {
                if (hospitalViewModel.usingLocation) {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack {
                            Spacer()
                            
                            Text("Searching by location")
                                .fontWeight(.bold)
                            Image(systemName: "location.circle.fill")
                        }
                        .foregroundStyle(.blue)
                        .padding(.trailing)
                    }
                } else {
                    ToolbarItem {
                        Button(action: {
                            triggerHaptic()
                            
                            withAnimation {
                                hospitalViewModel.searchQuery = ""
                                self.getNearbyHospitals()
                            }
                        }, label: {
                            Text("Use Location")
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        })
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        triggerHaptic()
                        
                        withAnimation {
                            hospitalViewModel.isMissingHospitalSheetPresented = true
                        }
                    }, label: {
                        Text("Missing?")
                            .foregroundStyle(.orange)
                            .fontWeight(.bold)
                    })
                }
            }
        }
        .onAppear {
            if (hospitalViewModel.hospitals.count == 0) {
                getNearbyHospitals()
            }
        }
        .sheet(isPresented: $hospitalViewModel.isMissingHospitalSheetPresented, content: {
            MissingHospitalSheetView(onSubmit: { hospitalName in
                onSelection(try await hospitalViewModel.createMissingHospital(name: hospitalName))
            })
            .presentationDetents([PresentationDetent.medium])
        })
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    private func getNearbyHospitals() {
        Task {
            do {
                try await hospitalViewModel.fetchHospitalsNearby()

            } catch {
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
}

#Preview {
    HospitalListView(selectionMode: true, onSelection: { _ in })
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
