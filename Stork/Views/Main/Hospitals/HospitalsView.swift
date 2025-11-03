// HospitalsView.swift
// Stork
//
// Created by Nick Molargik on 10/5/25.
//

import SwiftUI
import SwiftData
import CoreLocation

struct HospitalsView: View {
    @Environment(HospitalManager.self) private var hospitalManager: HospitalManager
    @Environment(LocationManager.self) private var locationManager: LocationManager
    @Environment(UserManager.self) private var userManager: UserManager
    @State private var viewModel = ViewModel()

    // Selection-mode configuration
    var selectionMode: Bool = false
    var preselectedHospitalId: String? = nil
    var onSelect: ((Hospital) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedHospital: Hospital?
    
    var body: some View {
        NavigationStack {
            Group {
                let filtered = viewModel.filteredHospitals(
                    hospitals: hospitalManager.hospitals,
                    primaryId: userManager.currentUser?.primaryHospitalId
                )
                if filtered.isEmpty {
                    ScrollView {
                        ContentUnavailableView(
                            viewModel.searchText.isEmpty ? "No Hospitals Found" : "No Matching Hospitals",
                            systemImage: "building.2",
                            description: Text(viewModel.searchText.isEmpty ? "No hospitals have been loaded for your state (\(viewModel.userState ?? "Unknown"))." : "No hospitals match your search.")
                        )
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                        )
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filtered) { hospital in
                            Button {
                                if selectionMode {
                                    Haptics.success()
                                    onSelect?(hospital)
                                    dismiss()
                                } else {
                                    Haptics.lightImpact()
                                    selectedHospital = hospital
                                }
                            } label: {
                                HospitalRowView(
                                    hospital: hospital,
                                    isPrimary: hospital.remoteId == userManager.currentUser?.primaryHospitalId
                                )
                                    .overlay(alignment: .topTrailing) {
                                        if selectionMode, let preId = preselectedHospitalId, preId == hospital.remoteId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .imageScale(.medium)
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                    .contentShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                            .if(!selectionMode) { view in
                                view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        Haptics.success()
                                        userManager.currentUser?.primaryHospitalId = hospital.remoteId
                                    } label: {
                                        Label("Set Primary", systemImage: "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationTitle(selectionMode ? "Select Hospital" : "Hospitals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.searchText.isEmpty, let state = viewModel.userState {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                            Text("\(state) Hospitals")
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if selectionMode {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.storkOrange)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.automatic)
            .navigationDestination(item: $selectedHospital) { hospital in
                HospitalDetailView(hospital: hospital)
            }
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search by name, city, state, or zip code"
            )
            .onChange(of: viewModel.searchText) { _, _ in
                Haptics.lightImpact()
            }
        }
        .task {
            await viewModel.startUserStateLookup(locationManager: locationManager)
        }
    }
}

#Preview("HospitalsView") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    HospitalsView()
        .environment(HospitalManager())
        .environment(LocationManager())
        .environment(UserManager(context: context))
}
