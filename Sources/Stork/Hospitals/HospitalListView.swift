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
    @Binding var navigationPath: [String]
    
    var selectionMode: Bool = false
    var onSelection: ((Hospital) -> Void)?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            if (hospitalViewModel.usingLocation) {
                HStack {
                    Text("Currently searching by location")
                    Image(systemName: "location.circle.fill")
                }
                .foregroundStyle(.blue)
                .font(.footnote)
            }
            
            HStack {
                CustomTextfieldView(text: $hospitalViewModel.searchQuery, hintText: "Search by name", icon: Image(systemName: "magnifyingglass"), isSecure: false)
                
                CustomButtonView(text: "Search", width: 80, height: 40, color: Color.indigo, isEnabled: $hospitalViewModel.searchEnabled, onTapAction: {
                    hospitalViewModel.searchHospitals()
                })
                .onChange(of: hospitalViewModel.searchQuery) { query in
                    hospitalViewModel.searchEnabled = query.count > 0
                }
                .onAppear {
                    hospitalViewModel.searchEnabled = hospitalViewModel.searchQuery.count > 0
                }
                
            }
            .padding(.horizontal)
            
            List(hospitalViewModel.hospitals, id: \.id) { hospital in
                if (selectionMode) {
                    Button(action: {
                        withAnimation {
                            print("Selecting \(hospital.facility_name)")
                            onSelection!(hospital)
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
                    hospitalViewModel.fetchHospitalsNearby()
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
                if hospitalViewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                
                //TODO: this button is broken for some reason
                if (!hospitalViewModel.usingLocation) {
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
            AddHospitalSheetView(onSubmit: { hospitalName in
                try await hospitalViewModel.hospitalRepository.createHospital(hospitalName)
                
                hospitalViewModel.searchHospitals()
            })
        })
    }
}

#Preview {
    HospitalListView(navigationPath: .constant([]), selectionMode: true)
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}

struct AddHospitalSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hospitalName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    var onSubmit: (String) async throws -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Sorry we are missing your hospital. Please provide its name and we will take it from there!")
                    .font(.headline)
                    .padding(.bottom, 16)
                
                CustomTextfieldView(text: $hospitalName, hintText: "Missing hospital name...", icon: Image(systemName: "building"), isSecure: false, iconColor: Color.orange)
                    .padding()

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }

                Button(action: {
                    Task {
                        isSubmitting = true
                        errorMessage = nil
                        do {
                            try await onSubmit(hospitalName)
                            dismiss()
                        } catch {
                            errorMessage = "Failed to add hospital: \(error.localizedDescription)"
                        }
                        isSubmitting = false
                    }
                    // TODO: alert admins somehow
                }) {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hospitalName.isEmpty ? Color.gray : Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(hospitalName.isEmpty || isSubmitting)
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Missing Hospital")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}
