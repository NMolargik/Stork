//
//  DeliveryDetailView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    // MARK: - AppStorage
    @AppStorage("useMetric") private var useMetric: Bool = false
    
    // MARK: - Environment Objects
    @EnvironmentObject var musterViewModel: MusterViewModel

    // MARK: - Binding
    @Binding var delivery: Delivery

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // MARK: - Delivery Date
                    Text(delivery.date.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .padding(.leading)
                        .accessibilityLabel("Delivery Date: \(delivery.date.formatted(date: .omitted, time: .shortened))")
                    
                    // MARK: - Hospital Information
                    HStack {
                        Image(systemName: "building.fill")
                            .foregroundStyle(.orange)
                            .font(.title)
                            .frame(width: 30)
                            .shadow(radius: 1)
                            .accessibilityHidden(true)
                        
                        Text(delivery.hospitalName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .accessibilityLabel("Hospital Name: \(delivery.hospitalName)")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(radius: 2)
                            .opacity(0.9)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Delivery Details
                    VStack(alignment: .leading, spacing: 10) {
                        if delivery.epiduralUsed {
                            HStack {
                                Image(systemName: "syringe.fill")
                                    .foregroundStyle(.red)
                                    .font(.title2)
                                    .frame(width: 30)
                                    .accessibilityHidden(true)
                                
                                Text("Epidural Used")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .accessibilityLabel("Epidural Used")
                            }
                        }
                        
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(.indigo)
                                .font(.title2)
                                .frame(width: 30)
                                .accessibilityHidden(true)
                            
                            Text("\(delivery.deliveryMethod.description) Delivery")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .accessibilityLabel("Delivery Method: \(delivery.deliveryMethod.description)")
                        }
                        
                        if !delivery.musterId.isEmpty {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(.blue)
                                    .font(.body)
                                    .frame(width: 30)
                                    .accessibilityHidden(true)
                                
                                Text("Added to your muster")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .accessibilityLabel("Added to your muster")
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(radius: 2)
                            .opacity(0.9)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Babies Information
                    ForEach(delivery.babies, id: \.id) { baby in
                        HStack {
                            Image(systemName: "figure.child")
                                .foregroundStyle(baby.sex.color)
                                .font(.title)
                                .frame(width: 30)
                                .shadow(radius: 1)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "scalemass.fill")
                                        .foregroundStyle(.orange)
                                        .frame(width: 30)
                                        .accessibilityHidden(true)
                                    
                                    Text(weightText(for: baby.weight))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .accessibilityLabel("Weight: \(weightText(for: baby.weight))")
                                }
                                
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .foregroundStyle(.green)
                                        .frame(width: 30)
                                        .accessibilityHidden(true)
                                    
                                    Text(heightText(for: baby.height))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .accessibilityLabel("Height: \(heightText(for: baby.height))")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if baby.nurseCatch {
                                Text("Nurse Catch")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .accessibilityLabel("Nurse Catch")
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 2)
                                .opacity(0.9)
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut, value: delivery.babies)
                    }
                }
                .padding()
            }
                
            Spacer()
            
            // MARK: - Delivery ID
            HStack {
                Spacer()
                
                Text("ID: \(delivery.id)")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                    .accessibilityLabel("Delivery ID: \(delivery.id)")
            }
            .padding([.trailing, .bottom])
        }
        .navigationTitle(delivery.date.formatted(date: .long, time: .omitted))
        .onAppear {
            triggerHaptic()
        }
        .onDisappear {
            triggerHaptic()
        }
    }
    
    // MARK: - Haptic Feedback
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    // MARK: - Weight Formatting
    private func weightText(for weightInOunces: Double) -> String {
        if useMetric {
            let weightInKilograms = weightInOunces * 0.0283495 // 1 ounce = 0.0283495 kg
            return "\(String(format: "%.2f", weightInKilograms)) kg"
        } else {
            let pounds = Int(weightInOunces) / 16
            let ounces = Int(weightInOunces) % 16
            return "\(pounds) lbs \(ounces) oz"
        }
    }
    
    // MARK: - Height Formatting
    private func heightText(for heightInInches: Double) -> String {
        if useMetric {
            let heightInCentimeters = heightInInches * 2.54 // 1 inch = 2.54 cm
            return "\(String(format: "%.1f", heightInCentimeters)) cm"
        } else {
            return "\(String(format: "%.1f", heightInInches)) inches"
        }
    }
}

struct DeliveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryDetailView(delivery: .constant(Delivery(sample: true)))
            .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
    }
}
