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
    @State private var showingDatePicker = false

    private let calendar = Calendar.current

    init(showingDeliveryAddition: Binding<Bool>) {
        self._showingDeliveryAddition = showingDeliveryAddition
        let now = Date()
        self._selectedDate = State(initialValue: now)
        self._selectedTime = State(initialValue: now)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Delivery Date & Time")
                            .foregroundStyle(.gray)
                            .font(.footnote)
                            .padding(.leading)
                        
                        HStack {
                            Spacer()
                            
                            // Date Selection Button (Expands Picker)
                            Button(action: {
                                triggerHaptic()
                                withAnimation {
                                    showingDatePicker = !showingDatePicker
                                }
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("\(formattedDate(selectedDate))")
                                        .foregroundStyle(Color("storkIndigo"))
                                        .padding(.trailing)
                                }
                                
                                // Native Time Picker (Limited to Past)
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .onChange(of: selectedTime) { _ in updateDeliveryDate() }
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                            
                        // Inline Date Picker (Expands & Collapses)
                        if showingDatePicker {
                            VStack {
                                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                                    .onChange(of: selectedDate) { _ in updateDeliveryDate() } // ✅ Ensure date updates properly
                                    .tint(Color("storkIndigo"))
        #if !SKIP
                                    .datePickerStyle(.wheel)
        #endif
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "en_US"))
                                    .padding(.top, -15)
                                
                                // Done Button to Collapse Picker
                                Button("Done") {
                                    withAnimation {
                                        showingDatePicker = false
                                    }
                                }
                                .padding(.bottom)
                            }
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                            .transition(.opacity.combined(with: .scale)) // Smooth expand/collapse animation
                            .padding(.horizontal, 5)
                        }
                    }
                    .padding(5)
                    .backgroundCard(colorScheme: colorScheme)
                    
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

                    // MARK: - Add A Baby Button
                    CustomButtonView(
                        text: "Add A Baby",
                        width: 250,
                        height: 50,
                        color: Color("storkIndigo"),
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

                    // MARK: - Submit Delivery Button
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
        .onAppear {
            initializeHospital()
            deliveryViewModel.addBaby()
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
        .onChange(of: deliveryViewModel.newDelivery.babies) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
        .onChange(of: deliveryViewModel.selectedHospital) { _ in
            deliveryViewModel.additionPropertiesChanged()
        }
    }

    // MARK: - Helper Functions
    
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

    private func updateDeliveryDate() {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0

        if let combinedDateTime = calendar.date(from: dateComponents) {
            deliveryViewModel.newDelivery.date = combinedDateTime
            print("📅 Updated Delivery Date: \(combinedDateTime) → Epoch: \(combinedDateTime.timeIntervalSince1970)")
        } else {
            print("❌ Failed to create a valid delivery date")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func initializeHospital() {
        Task {
            if hospitalViewModel.primaryHospital == nil {
                await hospitalViewModel.getUserPrimaryHospital(profile: profileViewModel.profile)
            }
            deliveryViewModel.selectedHospital = hospitalViewModel.primaryHospital
        }
    }
}
