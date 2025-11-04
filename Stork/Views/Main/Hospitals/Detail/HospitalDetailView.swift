// HospitalDetailView.swift
// Stork
//
// Created by Nick Molargik on 10/26/25.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct HospitalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(UserManager.self) private var userManager

    let hospital: Hospital

    @State private var coordinate: CLLocationCoordinate2D?
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // USA centroid fallback
        span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 5.0)
    )
    @State private var isGeocoding = false

    private var fullAddressString: String {
        "\(hospital.address), \(hospital.citytown), \(hospital.state) \(hospital.zipCode)"
    }

    private func geocodeAddressIfNeeded() {
        guard coordinate == nil, !isGeocoding else { return }
        isGeocoding = true
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(fullAddressString) { placemarks, error in
            defer { isGeocoding = false }
            guard error == nil, let location = placemarks?.first?.location else { return }
            let coord = location.coordinate
            coordinate = coord
            region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HospitalDetailHeaderView(hospital: hospital)
                
                // Map showing hospital location
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if let coordinate {
                            ZStack(alignment: .bottomTrailing) {
                                Map(initialPosition: .region(region)) {
                                    Marker(hospital.facilityName, coordinate: coordinate)
                                }
                                .mapStyle(.standard)

                                Button {
                                    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
                                    let item = MKMapItem(placemark: placemark)
                                    item.name = hospital.facilityName
                                    // Attempt to include address in the subtitle if available via userInfo
                                    item.openInMaps(launchOptions: [
                                        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                                        MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)
                                    ])
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map")
                                        Text("Open In Maps")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.footnote)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.thinMaterial, in: Capsule())
                                    .overlay(
                                        Capsule().stroke(Color(.separator), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(10)
                                .accessibilityLabel("Open location in Maps")
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                VStack(spacing: 8) {
                                    if isGeocoding {
                                        ProgressView()
                                        Text("Finding location...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Location unavailable")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
                .task {
                    geocodeAddressIfNeeded()
                }
                
                HospitalDetailPropertyView(hospital: hospital)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Hospital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hSizeClass == .regular {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Close")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    let isPrimary = userManager.currentUser?.primaryHospitalId == hospital.id
                    Button {
                        Haptics.lightImpact()
                        withAnimation(.snappy) {
                            userManager.currentUser?.primaryHospitalId = hospital.id
                        }
                    } label: {
                        Image(systemName: isPrimary ? "star.fill" : "star")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(isPrimary ? .yellow : .secondary)
                            .accessibilityLabel(isPrimary ? "Primary Hospital" : "Make Primary")
                    }
                }
            }
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    HospitalDetailView(hospital: Hospital.sample())
        .environment(UserManager(context: context))
}
