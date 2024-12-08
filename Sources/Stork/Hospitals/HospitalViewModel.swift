//
//  HospitalViewModel.swift
//
//
//  Created by Nick Molargik on 11/21/24.
//

import Foundation
import SwiftUI
import StorkModel

class HospitalViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var searchEnabled: Bool = true
    @Published var usingLocation: Bool = true
    @Published var selectedHospital: Hospital?
    @Published var isMissingHospitalSheetPresented: Bool = false

    var hospitalRepository: HospitalRepositoryInterface
    var locationProvider: LocationProviderInterface

    // MARK: - Initializer
    @MainActor
    public init(hospitalRepository: HospitalRepositoryInterface, locationProvider: LocationProviderInterface) {
        self.hospitalRepository = hospitalRepository
        self.locationProvider = locationProvider
        
        self.fetchHospitalsNearby()
    }
    
    /// Fetches hospitals near the user's current location.
    @MainActor
    func fetchHospitalsNearby() {
        Task {
            searchQuery = ""
            isLoading = true
            errorMessage = nil
            usingLocation = true
            
            do {
                let location = try await locationProvider.fetchCurrentLocation()
                print(location)
                let cityState = try await locationProvider.fetchCityAndState(from: Location(latitude: location.latitude, longitude: location.longitude))
                print(cityState)
                self.hospitals = []
                self.hospitals = try await hospitalRepository.getHospitals(byCity: cityState.city ?? "San Francisco", andState: cityState.state ?? "CA")
                isLoading = false
                print("got \(hospitals.count) hospitals!")
            } catch {
                errorMessage = "Failed to fetch nearby hospitals: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    /// Searches hospitals by partial name.
    /// - Parameter name: The partial name to search for.
    func searchHospitals() {
        Task {
            @MainActor in // Ensure the entire Task runs on the main thread
            isLoading = true
            errorMessage = nil
            usingLocation = false
            do {
                self.hospitals = []
                let results = try await hospitalRepository.searchHospitals(byPartialName: searchQuery)
                self.hospitals = results
                isLoading = false
            } catch {
                print("FAILURE")
                errorMessage = "Failed to search hospitals: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func updateHospitalWithNewDelivery(hospital: Hospital, babyCount: Int) {
        Task {
            var updatedHospital = hospital
            updatedHospital = try await hospitalRepository.updateAfterDelivery(updatedHospital, babyCount: babyCount)
            
            if let index = self.hospitals.firstIndex(where: { $0.id == hospital.id }) {
                // Replace the hospital at the found index
                self.hospitals[index] = updatedHospital
            }
        }
    }
}
