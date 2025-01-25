//
//  HospitalDetailView.swift
//  Stork
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation
import SwiftUI
import StorkModel

struct HospitalDetailView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State private var location: Location?
    
    let hospital: Hospital
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            hospitalMapView
            
            actionButtons
            
            hospitalDetailsView
            
            HStack {
                HospitalStatView(
                    text: "\(hospital.deliveryCount) deliver\(hospital.deliveryCount == 1 ? "y" : "ies"), \(hospital.babyCount) bab\(hospital.babyCount == 1 ? "y" : "ies")"
                )
                
                Spacer()
            }
            
            Spacer()
        }
        .toolbar(.hidden)
        .onAppear(perform: fetchLocation)
    }
}

// MARK: - Subviews
private extension HospitalDetailView {
    var hospitalMapView: some View {
        ZStack {
            if let location = location {
                MapView(latitude: location.latitude, longitude: location.longitude)
            } else {
                Rectangle()
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(hospital.facility_name)
                        .hospitalTitleStyle(colorScheme: colorScheme)
                    
                    Spacer()

                    Button(action: togglePrimaryHospital) {
                        Image(systemName: profileViewModel.profile.primaryHospitalId == hospital.id ? "star.fill" : "star")
                            .hospitalStarStyle(colorScheme: colorScheme)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)

        }
        .frame(height: 250)
    }
    
    var hospitalDetailsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HospitalInfoRow(icon: "pin.fill", text: "\(hospital.address) \(hospital.citytown), \(hospital.state) \(hospital.zip_code) - \(hospital.countyparish)", color: Color.red)
            
            HospitalInfoRow(icon: "phone.fill", text: hospital.telephone_number, color: Color.green)
            
            HospitalInfoRow(icon: "info.square.fill", text: hospital.hospital_type, color: Color.blue)
            
            if hospital.meets_criteria_for_birthing_friendly_designation {
                HospitalInfoRow(icon: "figure.child", text: "Birthing Center", color: Color.indigo)
            }
            
            if hospital.emergency_services {
                HospitalInfoRow(icon: "cross.fill", text: "Emergency Services", color: Color.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .backgroundCard(colorScheme: colorScheme)
        .padding(.horizontal)
    }
    
    var actionButtons: some View {
        HStack {
            CustomButtonView(
                text: "Back",
                width: 100,
                height: 40,
                color: .orange,
                icon: Image(systemName: "arrow.left"),
                isEnabled: true,
                onTapAction: { withAnimation { dismiss() } }
            )
            
            Spacer()
            
            CustomButtonView(
                text: profileViewModel.profile.primaryHospitalId == hospital.id ? "Remove From Default" : "Set As Default",
                width: 200,
                height: 40,
                color: .indigo,
                isEnabled: true,
                onTapAction: { withAnimation { togglePrimaryHospital() } }
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Methods
private extension HospitalDetailView {
    var makeAddress: String {
        "\(hospital.address) \(hospital.citytown), \(hospital.state), \(hospital.zip_code)"
    }
    
    func fetchLocation() {
        Task {
            do {
                let geocodedLocation = try await hospitalViewModel.locationProvider.geocodeAddress(makeAddress)
                self.location = Location(latitude: geocodedLocation.latitude, longitude: geocodedLocation.longitude)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func togglePrimaryHospital() {
        withAnimation {
            profileViewModel.profile.primaryHospitalId = (profileViewModel.profile.primaryHospitalId == hospital.id) ? "" : hospital.id
        }
        
        profileViewModel.tempProfile = profileViewModel.profile
        
        Task {
            do {
                try await profileViewModel.updateProfile()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
