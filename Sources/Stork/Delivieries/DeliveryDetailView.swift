//
//  DeliveryDetailView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    var delivery: Delivery
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(delivery.id)
                    Spacer()
                }
                .padding(.leading)
                .font(.system(size: 10))
                
                ForEach(delivery.babies, id: \.self) { baby in
                    HStack {
                        Image(systemName: "figure.child")
                            .foregroundStyle(baby.sex.color)
                            .font(.title)
                            .shadow(radius: 1)

                        VStack {
                            HStack {
                                Spacer()
                                
                                Image(systemName: "scalemass.fill")
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)

                                Text(baby.weight.description)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                
                                //TODO: fix units

                            }
                            
                            HStack {
                                Spacer()
                                
                                Image(systemName: "ruler.fill")
                                    .foregroundStyle(.orange)
                                
                                Text(baby.weight.description)
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                
                                //TODO: fix units
                            }
                        }
                        .frame(width: 100)
                        .padding(.trailing)
                        
                        if (baby.nurseCatch) {
                            HStack {
                                Image(systemName: "stethoscope")
                                    .foregroundStyle(.indigo)
                                
                                Text("Nurse Catch")
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .font(.subheadline)
                            }
                            .frame(width: 100)
                        } else {
                            Rectangle()
                                .frame(width: 100, height: 20)
                                .opacity(0)
                        }
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .cornerRadius(10)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .shadow(radius: 5)
                            .opacity(0.9)
                    }
                    .padding(.horizontal)
                        
                }
                
                Divider()
                
                HStack {
                    VStack (alignment: .leading, spacing: 10) {
                        if (delivery.epiduralUsed) {
                            HStack {
                                Image(systemName: "syringe.fill")
                                    .foregroundStyle(.red)
                                    .frame(width: 30)
                                
                                Text("Epidural Used")
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "figure.fall")
                                .foregroundStyle(.indigo)
                                .frame(width: 30)
                            
                            Text("\(delivery.deliveryMethod.description) Delivery")
                                .foregroundStyle(colorScheme == .dark ? .black : .white)
                                .fontWeight(.bold)


                        }
                        
                        if (delivery.musterId != "") {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                Text("Added to your muster!")
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background {
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .shadow(radius: 5)
                        .opacity(0.9)
                }
                .padding(.horizontal)
                    
                Spacer()

            }
            .navigationTitle("\(delivery.date.formatted(date: .long, time: .omitted))")
            
            //TODO: post-release, let user delete a delivery
            
            //TODO: post-release, let user modify delivery
        }
    }
}

#Preview {
    DeliveryDetailView(delivery: Delivery(sample: true))
}

