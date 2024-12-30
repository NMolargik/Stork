//
//  HospitalDetailView.swift
//  
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation
import SwiftUI
import StorkModel

struct HospitalDetailView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State var location: Location? = nil
    
    let hospital: Hospital
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ZStack {
                if let location = location {
                    MapView(latitude: location.latitude, longitude: location.longitude)
                } else {
                    Rectangle()
                }
                
                VStack (alignment: .leading) {
                    HStack (alignment: .top) {
                        Text(hospital.facility_name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.black)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .opacity(0.9)
                            }
                        
                        Spacer()

                        Button(action: {
                            withAnimation {
                                managePrimaryHospital()
                            }
                        }, label: {
                            Image(systemName: profileViewModel.profile.primaryHospitalId == hospital.id ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .font(.title2)
                                .padding(10)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(.black)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                        .opacity(0.9)
                                }
                        })
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .frame(height: 250)

            VStack (alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.red)
                        .frame(width: 30)
                    
                    Text("\(hospital.address) \(hospital.citytown), \(hospital.state) \(hospital.zip_code) - \(hospital.countyparish)")
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                }

                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.green)
                        .frame(width: 30)

                    
                    Text("\(hospital.telephone_number)")
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Image(systemName: "info.square.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 30)

                    
                    Text(hospital.hospital_type)
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Image(systemName: "dollarsign.square.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 30)

                    Text("Owned by: \(hospital.hospital_ownership)")
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                }
                
                if(hospital.meets_criteria_for_birthing_friendly_designation) {
                    HStack {
                        Image(systemName: "figure.child")
                            .foregroundStyle(.indigo)
                            .frame(width: 30)

                        Text("Birthing Center")
                            .foregroundStyle(.black)
                            .fontWeight(.semibold)
                    }
                }
                
                if(hospital.emergency_services) {
                    HStack {
                        Image(systemName: "cross.fill")
                            .foregroundStyle(.red)
                            .frame(width: 30)

                        Text("Emergency Services")
                            .foregroundStyle(.black)
                            .fontWeight(.semibold)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background {
                Rectangle()
                    .cornerRadius(10)
                    .foregroundStyle(.white)
                    .shadow(radius: 5)
                    .opacity(0.9)
            }
            .padding(.horizontal)
            
            HStack {
                // TODO: replace with a stork!
                Image(systemName: "figure.child")
                    .foregroundStyle(.indigo)
                    .frame(width: 30)

                // Text for delivery count
                Text("\(hospital.deliveryCount) reported deliver\(hospital.deliveryCount == 1 ? "y" : "ies")")
                    .foregroundStyle(.black)
                    .fontWeight(.semibold)

            }
            .padding()
            .background {
                Rectangle()
                    .cornerRadius(10)
                    .foregroundStyle(.white)
                    .shadow(radius: 5)
                    .opacity(0.9)
            }
            .padding(.horizontal)

            HStack {
                ZStack {
                    Image(systemName: "figure.child")
                        .foregroundStyle(.purple)
                    
                    Image(systemName: "figure.child")
                        .foregroundStyle(.pink)
                        .shadow(radius: 2)
                        .offset(x: 8)

                    Image(systemName: "figure.child")
                        .foregroundStyle(.blue)
                        .shadow(radius: 2)
                        .offset(x: 15)
                }
                .offset(x: -5)
                .frame(width: 30)

                // Text for baby count
                Text("\(hospital.babyCount) reported bab\(hospital.babyCount == 1 ? "y" : "ies")")
                    .foregroundStyle(.black)
                    .fontWeight(.semibold)

            }
            .padding()
            .background {
                Rectangle()
                    .cornerRadius(10)
                    .foregroundStyle(.white)
                    .shadow(radius: 5)
                    .opacity(0.9)
            }
            .padding(.horizontal)

            Spacer()
            
            HStack {
                CustomButtonView(text: "Back", width: 100, height: 40, color: Color.orange, icon: Image(systemName: "arrow.left"), isEnabled: true, onTapAction: {
                    withAnimation {
                        dismiss()
                    }
                })
                
                Spacer()
                
                CustomButtonView(text: (profileViewModel.profile.primaryHospitalId == hospital.id) ? "Remove From Default" : "Set As Default", width: 200, height: 40, color: Color.indigo, isEnabled: true, onTapAction: {
                    withAnimation {
                        managePrimaryHospital()
                    }
                })
            }
            .padding()
        }
        .toolbar(.hidden)
        .onAppear {
            Task {
                let address = makeAddress()
                let location = try await hospitalViewModel.locationProvider.geocodeAddress(address)
                self.location = Location(latitude: location.latitude, longitude: location.longitude)
                
            }
        }
    }
    
    func makeAddress() -> String {
        return "\(hospital.address) \(hospital.citytown), \(hospital.state), \(hospital.zip_code)"
    }
    
    func managePrimaryHospital() {
        if (profileViewModel.profile.primaryHospitalId == hospital.id) {
            profileViewModel.profile.primaryHospitalId = ""
        } else {
            profileViewModel.profile.primaryHospitalId = hospital.id
        }
        
        profileViewModel.tempProfile = profileViewModel.profile
        profileViewModel.tempProfile.primaryHospitalId = hospital.id
        
        Task {
            do {
                try await profileViewModel.updateProfile()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    HospitalDetailView(hospital: Hospital(id: "1234523423542342342342342342342", facility_name: "Parkview Hospital", address: "1116 South Hamsher Street", citytown: "Garrett", state: "IN", zip_code: "46738", countyparish: "Dekalb", telephone_number: "260-357-6625", hospital_type: "Normal Type", hospital_ownership: "Molargik", emergency_services: true, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 10, babyCount: 12))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider() ))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
