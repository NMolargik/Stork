//
//  HospitalListView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct HospitalListView: View {
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var navigationPath: [String] = []
    
    var selectionMode: Bool = false
    var onSelection: ((Hospital) -> Void)

    var body: some View {
        //TODO: post release, show default hospital at top
        
        NavigationStack(path: $navigationPath) {
            HStack {
                CustomTextfieldView(text: $hospitalViewModel.searchQuery, hintText: "Search by name", icon: Image(systemName: hospitalViewModel.usingLocation ? "location.fill" : "magnifyingglass"), isSecure: false, iconColor: hospitalViewModel.usingLocation ? Color.blue : Color.orange)
                
                CustomButtonView(text: "Search", width: 80, height: 55, color: Color.indigo, isEnabled: $hospitalViewModel.searchEnabled, onTapAction: {
                    Task {
                        try await hospitalViewModel.searchHospitals()
                    }
                })
                .onChange(of: hospitalViewModel.searchQuery) { query in
                    hospitalViewModel.searchEnabled = query.count > 0
                }
                .onAppear {
                    hospitalViewModel.searchEnabled = hospitalViewModel.searchQuery.count > 0
                }
                
            }
            .padding(.horizontal)
            
            if (hospitalViewModel.hospitals.count == 0 && !hospitalViewModel.isWorking) {
                Text("No hospitals found. Either Stork services are down, or you should change your search criteria.\n\nIf you feel your hospital is missing, report it using the button above.")
                    .padding()
                    .multilineTextAlignment(.center)
                    .background {
                        Color.white
                            .cornerRadius(10)
                            .shadow(radius: 5)
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
                        HospitalRowView(hospital: hospital)
                    })
                } else {
                    NavigationLink(destination: HospitalDetailView(hospital: hospital)) {
                        HospitalRowView(hospital: hospital)
                    }
                }
            }
            .refreshable {
                withAnimation {
                    Task {
                        hospitalViewModel.fetchHospitalsNearby()
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
            .overlay {
                if hospitalViewModel.isWorking {
                    ProgressView()
                }
            }
            .toolbar {
                if (hospitalViewModel.usingLocation) {
                    ToolbarItem {
                        HStack {
                            Spacer()
                            
                            Text("Currently searching by location")
                            Image(systemName: "location.circle.fill")
                        }
                        .foregroundStyle(.blue)
                        .font(.footnote)
                        .padding(.trailing)
                    }
                } else {
                    ToolbarItem {
                        Button(action: {
                            withAnimation {
                                hospitalViewModel.searchQuery = ""
                                hospitalViewModel.fetchHospitalsNearby()
                            }
                        }, label: {
                            Text("Use Location")
                                .foregroundStyle(.indigo)
                        })
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            hospitalViewModel.isMissingHospitalSheetPresented = true
                        }
                    }, label: {
                        Text("Missing?")
                            .foregroundStyle(.red)

                    })
                }
            }
        }
        .onAppear {
            if (hospitalViewModel.hospitals.count == 0) {
                hospitalViewModel.fetchHospitalsNearby()
            }
        }
        .sheet(isPresented: $hospitalViewModel.isMissingHospitalSheetPresented, content: {
            MissingHospitalSheetView(onSubmit: { hospitalName in
                onSelection(try await hospitalViewModel.hospitalRepository.createHospital(name: hospitalName))

            })
        })
    }
}

#Preview {
    HospitalListView(selectionMode: true, onSelection: { _ in })
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
