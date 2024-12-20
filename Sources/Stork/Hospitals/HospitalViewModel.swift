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
    @AppStorage("errorMessage") var errorMessage: String = ""

    @Published var hospitals: [Hospital] = []
    @Published var isWorking: Bool = false
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
        
        Task { @MainActor in
            try await self.fetchHospitalsNearby()
        }
    }
    
    /// Fetches hospitals near the user's current location.
    @MainActor
    func fetchHospitalsNearby() async throws {
        Task {
            searchQuery = ""
            isWorking = true
            usingLocation = true
            
            var location = (latitude: 0.0, longitude: 0.0)
            let cityState: (city: String?, state: String?) = (city: nil, state: nil)
            
            do {
                location = try await locationProvider.fetchCurrentLocation()
                print("Got location: \(location)")
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
                
            do {
                let cityState = try await locationProvider.fetchCityAndState(from: Location(latitude: location.latitude, longitude: location.longitude))
                print(cityState)
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
            
            do {
                self.hospitals = []
                self.hospitals = try await hospitalRepository.getHospitals(byCity: cityState.city ?? "San Francisco", andState: cityState.state ?? "CA")
                print("Got \(hospitals.count) hospitals!")
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }

            isWorking = false
        }
    }

    /// Searches hospitals by partial name.
    /// - Parameter name: The partial name to search for.
    func searchHospitals() async throws {
        Task { @MainActor in
            isWorking = true
            usingLocation = false
            
            do {
                self.hospitals = []
                let results = try await hospitalRepository.searchHospitals(byPartialName: searchQuery)
                self.hospitals = results
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
            
            isWorking = false
        }
    }
    
    func updateHospitalWithNewDelivery(hospital: Hospital, babyCount: Int) async throws {
        Task {
            isWorking = true
            do {
                let updatedHospital = try await hospitalRepository.updateAfterDelivery(hospital: hospital, babyCount: babyCount)
                
                if let index = self.hospitals.firstIndex(where: { $0.id == hospital.id }) {
                    // Replace the hospital at the found index
                    self.hospitals[index] = updatedHospital
                }
            } catch {
                isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
}
