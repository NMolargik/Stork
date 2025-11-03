// HospitalManager.swift
// Stork
//
// Created by Nick Molargik on 10/26/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class HospitalManager {
    static var shared: HospitalManager? = nil
    
    private(set) var hospitals: [Hospital] = []
    
    init() {
        HospitalManager.shared = self
        Task { await loadHospitalsFromJSON() }
    }
    
    // MARK: - Parse hospitals.json
    func loadHospitalsFromJSON(fileName: String = "hospitals") async {
        do {
            // Locate hospitals.json in the main bundle
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                print("hospitals.json not found in bundle")
                return
            }
            
            // Read and decode JSON directly into [Hospital]
            let data = try Data(contentsOf: url)
            let hospitals = try JSONDecoder().decode([Hospital].self, from: data)
            
            // Update in-memory hospitals array
            self.hospitals = hospitals.sorted(by: { $0.facilityName < $1.facilityName })
            print("Successfully loaded \(hospitals.count) hospitals from \(fileName).json")
        } catch {
            print("Error loading hospitals from JSON: \(error.localizedDescription)")
            self.hospitals = []
        }
    }
}
