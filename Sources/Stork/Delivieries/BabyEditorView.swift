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
    var babyNumber: Int
    var removeBaby: (String) -> Void // Accepts baby.id
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Baby \(babyNumber + 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        removeBaby(baby.id)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.black)
                        .padding(5)
                        .background(Circle().foregroundStyle(.white))
                }
            }
            
            Picker("Sex", selection: $baby.sex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.rawValue.capitalized).tag(sex)
                }
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
        .background(
            ZStack {
                Color.white
                baby.sex.color.opacity(0.4)
            }
        )
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
}

#Preview {
    BabyEditorView(
        baby: .constant(Baby(deliveryId: "", nurseCatch: true, sex: Sex.male)),
        babyNumber: 1,
        removeBaby: { _ in }
    )
}
