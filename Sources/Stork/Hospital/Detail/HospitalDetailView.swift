//
//  HospitalDetailView.swift
//  Stork
//
//  Created by Nick Molargik on 11/30/24.
//

import SkipFoundation
import SwiftUI
import StorkModel

struct HospitalDetailView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @State private var location: Location?
    
    let hospital: Hospital

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HospitalMapView(profileViewModel: profileViewModel, location: $location, hospital: hospital)
                
                HospitalActionButtonsView(profileViewModel: profileViewModel, hospital: hospital)
                
                HospitalInfoView(hospital: hospital)

                Spacer()
            }
            .toolbar(.hidden)
            .onAppear(perform: fetchLocation)
        }
        .ignoresSafeArea()
    }
    
    private var makeAddress: String {
        "\(hospital.address) \(hospital.citytown), \(hospital.state), \(hospital.zip_code)"
    }

    private func fetchLocation() {
        Task {
            do {
                let geocodedLocation = try await hospitalViewModel.locationProvider.geocodeAddress(makeAddress)
                self.location = Location(latitude: geocodedLocation.latitude, longitude: geocodedLocation.longitude)
            } catch {
                withAnimation {
                    appStateManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func togglePrimaryHospital() {
        withAnimation {
            profileViewModel.profile.primaryHospitalId = (profileViewModel.profile.primaryHospitalId == hospital.id) ? "" : hospital.id
        }
        
        profileViewModel.tempProfile = profileViewModel.profile
        
        Task {
            do {
                try await profileViewModel.updateProfile()
            } catch {
                withAnimation {
                    appStateManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    HospitalDetailView(hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()), profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()), hospital: Hospital.sampleHospital())
    .environmentObject(AppStateManager.shared)
}
