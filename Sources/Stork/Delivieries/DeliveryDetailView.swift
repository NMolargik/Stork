//
//  DeliveryDetailView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    @AppStorage("useMetric") private var useMetric: Bool = false
    
    @EnvironmentObject var musterViewModel: MusterViewModel

    @Binding var delivery: Delivery

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(delivery.date.formatted(date: .omitted, time: .shortened))
                        .padding(.leading)
                    
                    HStack {
                        Image(systemName: "building.fill")
                            .foregroundStyle(.orange)
                            .font(.title)
                            .frame(width: 30)
                            .shadow(radius: 1)
                        
                        Text(delivery.hospitalName)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .font(.subheadline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .cornerRadius(10)
                            .foregroundStyle(.white)
                            .shadow(radius: 5)
                            .opacity(0.9)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            if delivery.epiduralUsed {
                                HStack {
                                    Image(systemName: "syringe.fill")
                                        .foregroundStyle(.red)
                                        .frame(width: 30)
                                        .font(.title)
                                    
                                    Text("Epidural Used")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundStyle(.indigo)
                                    .frame(width: 30)
                                    .font(.title)
                                
                                Text("\(delivery.deliveryMethod.description) Delivery")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .fontWeight(.semibold)
                            }
                            
                            if !delivery.musterId.isEmpty {
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 30)
                                        .font(.body)
                                    
                                    Text("Added to your muster")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                    
                                }
                            }
                        }
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .cornerRadius(10)
                            .foregroundStyle(.white)
                            .shadow(radius: 5)
                            .opacity(0.9)
                    }
                    .padding(.horizontal)
                    
                    ForEach(delivery.babies, id: \.self) { baby in
                        HStack {
                            Image(systemName: "figure.child")
                                .foregroundStyle(baby.sex.color)
                                .font(.title)
                                .frame(width: 30)
                                .shadow(radius: 1)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: "scalemass.fill")
                                        .frame(width: 30)
                                        .foregroundStyle(.orange)
                                    
                                    // Display weight with units
                                    Text(weightText(for: baby.weight))
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .foregroundStyle(.green)
                                        .frame(width: 30)
                                    
                                    // Display height with units
                                    Text(heightText(for: baby.height))
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.trailing)
                            .frame(width: 150)
                            
                            if baby.nurseCatch {
                                Text("Nurse Catch")
                                    .foregroundStyle(.black)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background {
                            Rectangle()
                                .cornerRadius(10)
                                .foregroundStyle(.white)
                                .shadow(radius: 5)
                                .opacity(0.9)
                        }
                        .padding(.horizontal)
                    }
                }
            }
                
            Spacer()
            
            HStack {
                Spacer()
                
                Text("ID: \(delivery.id)")
                    .foregroundStyle(.gray)
            }
            .padding([.trailing, .bottom])
            .font(.system(size: 10))
        }
        .navigationTitle(delivery.date.formatted(date: .long, time: .omitted))
        .onAppear {
            triggerHaptic()
        }
        .onDisappear {
            triggerHaptic()
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    // Computed property to format weight based on useMetric
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
    
    // Computed property to format height based on useMetric
    private func heightText(for heightInInches: Double) -> String {
        if useMetric {
            let heightInCentimeters = heightInInches * 2.54 // 1 inch = 2.54 cm
            return "\(String(format: "%.1f", heightInCentimeters)) cm"
        } else {
            return "\(String(format: "%.1f", heightInInches)) inches"
        }
    }
}

#Preview {
    // Preview with a constant binding
    DeliveryDetailView(delivery: .constant(Delivery(sample: true)))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
