//
//  DateSelectionView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct DateSelectionView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    
    @Binding var selectedDate: Date
    @Binding var selectedTime: Date
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Delivery Date & Time")
                .foregroundStyle(.gray)
                .font(.footnote)
                .padding(.leading)

            HStack {
                Spacer()

                Button(action: {
                    HapticFeedback.trigger(style: .medium)
                    withAnimation {
                        showingDatePicker = !showingDatePicker
                    }
                }) {
                    HStack {
                        Image("calendar", bundle: .module)
                            .foregroundStyle(.red)

                        Text("\(formattedDate(selectedDate))")
                            .foregroundStyle(.blue)
                            .padding(.trailing)
                    }
                }
                .padding(.horizontal)

                Spacer()
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: selectedTime) { _ in updateDeliveryDate() }
                
                Spacer()
            }

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
                        .frame(height: 50)
                        .padding()

                    Button("Done") {
                        withAnimation {
                            showingDatePicker = false
                        }
                    }
                    .foregroundStyle(Color("storkBlue"))
                    .padding()
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                .transition(.opacity.combined(with: .scale))
                .padding(.horizontal, 5)
                .padding(.top)
            }
        }
        .padding(5)
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
    }
    
    private func updateDeliveryDate() {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0

        if let combinedDateTime = Calendar.current.date(from: dateComponents) {
            deliveryViewModel.newDelivery.date = combinedDateTime
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    DateSelectionView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        selectedDate: .constant(Date()), selectedTime: .constant(Date()), showingDatePicker: .constant(true)
    )
}
