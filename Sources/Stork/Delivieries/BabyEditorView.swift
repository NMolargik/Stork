//
//  BabyEditorView.swift
//
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI
import StorkModel

struct BabyEditorView: View {
    @Binding var baby: Baby
    var babyIndex: Int
    var removeBaby: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Baby #\(babyIndex + 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            removeBaby(babyIndex)
                        }
                    }
                }, label: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.black)
                        .padding(5)
                        .background {
                            Circle()
                                .foregroundStyle(.white)
                        }
                })
            }
            
            Picker("Sex", selection: $baby.sex) {
                Text("Male").tag(Sex.male)
                Text("Female").tag(Sex.female)
                Text("Loss").tag(Sex.loss)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("\(baby.weight, specifier: "%.1f") lbs")
                    .foregroundStyle(.black)
                    .fontWeight(.bold)
                    .frame(width: 100)

                Slider(value: $baby.weight, in: 2.0...15.0, step: 0.1)
                    .tint(.indigo)
            }
            
            //TODO: dynamic units, better ranges
            
            HStack {
                Text("\(baby.height, specifier: "%.1f") inches")
                    .foregroundStyle(.black)
                    .fontWeight(.bold)
                    .frame(width: 100)

                Slider(value: $baby.height, in: 10.0...30.0, step: 0.1)
                    .tint(.indigo)

            }
            //TODO: dynamic units, better ranges


            Toggle("Nurse Catch", isOn: $baby.nurseCatch)
                .foregroundStyle(.black)
                .fontWeight(.bold)

        }
        .padding()
        .background {
            ZStack {
                Color.white
                
                baby.sex.color
                    .opacity(0.4)
            }
        }
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

#Preview {
    BabyEditorView(baby: .constant(Baby(deliveryId: "", nurseCatch: true, sex: Sex.male)), babyIndex: 0, removeBaby: {_ in })
}
