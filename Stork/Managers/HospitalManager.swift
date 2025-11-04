// HospitalManager.swift
// Stork
//
// Created by Nick Molargik on 10/26/25.
//

import Foundation
import SwiftUI
import class UIKit.NSDataAsset


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
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Error: \(fileName).json not found in app bundle")
            self.hospitals = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let hospitals = try JSONDecoder().decode([Hospital].self, from: data)
            self.hospitals = hospitals.sorted { $0.facilityName < $1.facilityName }
            print("Loaded \(hospitals.count) hospitals from bundle")
        } catch {
            print("Failed to load or decode hospitals.json: \(error)")
            self.hospitals = []
        }
    }
}
