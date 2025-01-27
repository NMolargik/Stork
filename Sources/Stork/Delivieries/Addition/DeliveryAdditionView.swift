//
//  DeliveryAdditionView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryAdditionView: View {
    @Environment(\.colorScheme) var colorScheme

    // MARK: - AppStorage
    @AppStorage("errorMessage") var errorMessage: String = ""

    // MARK: - Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var dailyResetManager: DailyResetManager

    // MARK: - Binding
    @Binding var showingDeliveryAddition: Bool

    // MARK: - Date Selection State
    @State private var selectedDate: Date
    @State private var selectedTime: Date

    private let calendar = Calendar.current

    init(showingDeliveryAddition: Binding<Bool>) {
        self._showingDeliveryAddition = showingDeliveryAddition

        let now = Date()
        self._selectedDate = State(initialValue: now)
        self._selectedTime = State(initialValue: now)
    }

    var body: some View {
        VStack {
            // MARK: - Date & Time Selection
            HStack {
                Text("Select Delivery Time")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                
                Spacer()
            }
            .padding(.leading)
            
            HStack {
                // Horizontal ScrollView for Date Selection (Last 5 Days)
                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { offset in
                        let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
                        let isSelected = calendar.isDate(selectedDate, inSameDayAs: date)

                        Text("\(calendar.component(.day, from: date))")
                            .fontWeight(.bold)
                            .frame(width: 40, height: 35)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.red : Color.gray.opacity(0.3)))
                            .foregroundColor(isSelected ? .white : .black)
                            .onTapGesture {
                                triggerHaptic()
                                selectedDate = date
                                updateDeliveryDate()
                            }
                    }
                }
                .padding(.horizontal, 10)

                // Native Time Picker (Limited to Past)
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: selectedTime) { _ in updateDeliveryDate() }
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Baby Editor Views with Enhanced Transitions
                    ForEach($deliveryViewModel.newDelivery.babies) { $baby in
                        let babyIndex = deliveryViewModel.newDelivery.babies.firstIndex(where: { $0.id == baby.id }) ?? 0
                        let babyNumber = babyIndex + 1

                        BabyEditorView(
                            baby: $baby,
                            babyNumber: babyNumber,
                            removeBaby: { babyId in
                                withAnimation(.spring()) {
                                    deliveryViewModel.newDelivery.babies.removeAll { $0.id == babyId }
                                }
                            }
                        )
                        .id(baby.id)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // MARK: - Add A Baby Button Positioned Below ScrollView
                    CustomButtonView(
                        text: "Add A Baby",
                        width: 250,
                        height: 50,
                        color: Color("storkIndigo"),
                        icon: nil,
                        isEnabled: true,
                        onTapAction: {
                            withAnimation(.spring()) {
                                deliveryViewModel.addBaby()
                            }
                        }
                    )
                    .padding(.bottom)

                    Divider()

                    // MARK: - Epidural Used Toggle
                    Toggle("Epidural Used", isOn: $deliveryViewModel.newDelivery.epiduralUsed)
                        .padding()
                        .fontWeight(.bold)
                        .backgroundCard(colorScheme: colorScheme)
                        .tint(.green)

                    // MARK: - Add To Muster Toggle (Conditional)
                    if !profileViewModel.profile.musterId.isEmpty {
                        Toggle("Add To Muster", isOn: $deliveryViewModel.addToMuster)
                            .padding()
                            .fontWeight(.bold)
                            .backgroundCard(colorScheme: colorScheme)
                            .tint(.green)
                    }

                    // MARK: - Delivery Method Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Delivery Method")
                            .font(.headline)

                        Picker("Delivery Method", selection: $deliveryViewModel.newDelivery.deliveryMethod) {
                            ForEach(DeliveryMethod.allCases, id: \.self) { method in
                                Text(method.description).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: deliveryViewModel.newDelivery.deliveryMethod) { _ in
                            triggerHaptic()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .backgroundCard(colorScheme: colorScheme)

                    // MARK: - Select Hospital Section
                    VStack(alignment: .center, spacing: 10) {
                        Text(deliveryViewModel.selectedHospital?.facility_name ?? "No Hospital Selected")
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        CustomButtonView(
                            text: "Change Hospital",
                            width: 250,
                            height: 50,
                            color: Color.red,
                            icon: Image("building.fill"),
                            isEnabled: true,
                            onTapAction: {
                                withAnimation {
                                    deliveryViewModel.isSelectingHospital = !deliveryViewModel.isSelectingHospital
                                }
                            }
                        )
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .backgroundCard(colorScheme: colorScheme)

                    Spacer(minLength: 10)

                    // MARK: - Submit Delivery Button or ProgressView
                    if deliveryViewModel.isWorking {
                        ProgressView()
                            .frame(height: 50)
                    } else {
                        CustomButtonView(
                            text: "Submit Delivery",
                            width: 250,
                            height: 50,
                            color: Color.green,
                            isEnabled: deliveryViewModel.canSubmitDelivery,
                            onTapAction: {
                                Task {
                                    await submitDelivery()
                                    deliveryViewModel.startNewDelivery()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $deliveryViewModel.isSelectingHospital) {
            HospitalListView(
                selectionMode: true,
                onSelection: { selectedHospital in
                    print("selectedHospital: \(selectedHospital.facility_name)")
                    deliveryViewModel.selectedHospital = selectedHospital
                    deliveryViewModel.newDelivery.hospitalId = selectedHospital.id
                    deliveryViewModel.newDelivery.hospitalName = selectedHospital.facility_name
                    deliveryViewModel.isSelectingHospital = false
                }
            )
            .interactiveDismissDisabled()
            .environmentObject(hospitalViewModel)
            .environmentObject(profileViewModel)
        }
        .onAppear { initializeHospital() }
        .onChange(of: deliveryViewModel.newDelivery.babies) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
        .onChange(of: deliveryViewModel.selectedHospital) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
        .onChange(of: deliveryViewModel.isSelectingHospital) { isSelecting in
            if isSelecting {
                Task {
                    await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
                    if let selectedHospital = hospitalViewModel.primaryHospital {
                        deliveryViewModel.selectedHospital = selectedHospital
                        print("🏥 Hospital updated: \(selectedHospital.facility_name)")
                    } else {
                        print("❌ No hospital selected")
                    }
                }
            }
        }    }

    // MARK: - Helper Functions

    private func updateDeliveryDate() {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        // Manually set hour and minute to the selected time
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0 // Ensure consistency

        // Create the final date
        if let combinedDateTime = calendar.date(from: dateComponents) {
            deliveryViewModel.newDelivery.date = combinedDateTime
            print("📅 Updated Delivery Date: \(combinedDateTime) → Epoch: \(combinedDateTime.timeIntervalSince1970)")
        } else {
            print("❌ Failed to create a valid delivery date")
        }
    }
    
    /// Initializes the selected hospital when the view appears.
    private func initializeHospital() {
        Task {
            if hospitalViewModel.primaryHospital == nil {
                await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
            }
            
            deliveryViewModel.selectedHospital = hospitalViewModel.primaryHospital
        }
    }
    
    /// Updates the selected hospital when the user changes the selection.
    private func updateHospitalSelection() {
        if let selectedHospital = hospitalViewModel.primaryHospital {
            deliveryViewModel.selectedHospital = selectedHospital
            print("🏥 Hospital updated: \(selectedHospital.facility_name)")
        } else {
            print("❌ No hospital selected")
        }
    }
    
    // MARK: - Submit Delivery Function
    
    @MainActor
    private func submitDelivery() async {
        deliveryViewModel.isWorking = true
        defer { deliveryViewModel.isWorking = false }
        
        guard let hospital = deliveryViewModel.selectedHospital else {
            errorMessage = "No hospital selected"
            return
        }
        deliveryViewModel.newDelivery.hospitalName = hospital.facility_name
        deliveryViewModel.newDelivery.hospitalId = hospital.id
        
        let babyCount = deliveryViewModel.newDelivery.babies.count
        
        do {
            try await deliveryViewModel.submitDelivery(profile: profileViewModel.profile, dailyResetManager: dailyResetManager)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        await hospitalViewModel.updateHospitalWithNewDelivery(hospital: hospital, babyCount: babyCount)
        
        showingDeliveryAddition = false
    }
}

#Preview {
    DeliveryAdditionView(showingDeliveryAddition: .constant(true))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(DailyResetManager())
}
