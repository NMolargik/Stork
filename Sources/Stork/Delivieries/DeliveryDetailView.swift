//
//  DeliveryDetailView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    @Binding var delivery: Delivery
    
    var body: some View {
        // No extra NavigationStack here
        VStack(alignment: .leading, spacing: 10) {
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
                        Image(systemName: "figure.fall")
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
                                .font(.title)
                            
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
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "scalemass.fill")
                                .frame(width: 15)
                                .foregroundStyle(.green)

                            
                            Text(baby.weight.description)
                                .foregroundStyle(.black)
                                .font(.subheadline)
                                .lineLimit(1)
                                .fontWeight(.semibold)
                            // TODO: fix units
                        }
                        
                        HStack {
                            Spacer()
                            Image(systemName: "ruler.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 15)
                            
                            // NOTE: This uses baby.weight twice – might be a bug
                            Text(baby.weight.description)
                                .foregroundStyle(.black)
                                .font(.subheadline)
                                .lineLimit(1)
                                .fontWeight(.semibold)
                            // TODO: fix units
                        }
                    }
                    .frame(width: 70)
                    .padding(.trailing)
                    
                    if baby.nurseCatch {
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundStyle(.indigo)
                                .font(.title)
                                .frame(width: 50)
                                .shadow(radius: 1)
                            
                            Text("Nurse Catch")
                                .foregroundStyle(.black)
                                .font(.subheadline)
                                .lineLimit(1)
                                .fontWeight(.semibold)
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
    }
}

#Preview {
    // Preview with a constant binding
    DeliveryDetailView(delivery: .constant(Delivery(sample: true)))
}
