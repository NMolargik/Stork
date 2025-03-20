//
//  HospitalMapView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

#if !SKIP
import MapKit
#else
// skip.yml: implementation("com.google.maps.android:maps-compose:4.3.3")
import com.google.maps.android.compose.__
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
#endif

struct HospitalMapView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @Binding var location: Location?
    
    let hospital: Hospital
    
    var body: some View {
        ZStack {
            if let location = location {
                #if !SKIP
                // on Darwin platforms, we use the new SwiftUI Map type
                if #available(iOS 17.0, macOS 14.0, *) {
                    Map(initialPosition: .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))))
                } else {
                    Text("Map requires iOS 17")
                        .font(.title)
                }
                #else
                // on Android platforms, we use com.google.maps.android.compose.GoogleMap within in a ComposeView
                ComposeView { ctx in
                    GoogleMap(cameraPositionState: rememberCameraPositionState {
                        position = CameraPosition.fromLatLngZoom(LatLng(location.latitude, location.longitude), Float(12.0))
                    })
                }
                #endif
            } else {
                Rectangle()
                
                if (hospital.state.isEmpty) {
                    Text("No address listed yet.")
                        .foregroundStyle(.white)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .padding(.top)
                }
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(hospital.facility_name)
                        .hospitalTitleStyle(colorScheme: colorScheme)
                    
                    Spacer()

                    Button(action: togglePrimaryHospital) {
                        Image(systemName: profileViewModel.profile.primaryHospitalId == hospital.id ? "star.fill" : "star")
                            .resizable()
                            .hospitalStarStyle(colorScheme: colorScheme)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 50)
        }
        .frame(height: 250)
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
                print("Failed to update profile")
            }
        }
    }
}

#Preview {
    HospitalMapView(profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()), location: .constant(Location(latitude: 0.0, longitude: 0.0)), hospital: Hospital.sampleHospital())
}
