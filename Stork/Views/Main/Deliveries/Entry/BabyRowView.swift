//
//  BabyRowView.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI

struct BabyRowView: View {
    let baby: Baby
    let useMetricUnits: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isDeleting: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(baby.sex.color)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(baby.sex.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(weightHeightSummary(for: baby))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        if baby.nicuStay {
                            Image(systemName: "cross.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.storkOrange)
                        }
                        if baby.nurseCatch {
                            Image(systemName: "person.2.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent unintended tap propagation
                    .disabled(isDeleting)
                    
                    Button(action: {
                        guard !isDeleting else { return }
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isDeleting = true
                        }
                        // Call the parent delete after the exit animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .padding(8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent unintended tap propagation
                    .disabled(isDeleting)
                }
            }
            .padding()
        }
        .opacity(isDeleting ? 0 : 1)
        .offset(x: isDeleting ? 20 : 0)
        .scaleEffect(isDeleting ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.18), value: isDeleting)
    }
    
    private func weightHeightSummary(for baby: Baby) -> String {
        let weightString: String
        let heightString: String
        
        if useMetricUnits {
            let weightKg = baby.weight / 35.27396
            weightString = String(format: "%.1f kg", weightKg)
            let heightCm = baby.height / 0.393701
            heightString = String(format: "%.1f cm", heightCm)
        } else {
            let totalOunces = baby.weight
            let lbs = Int(totalOunces / 16)
            let oz = Int(totalOunces.truncatingRemainder(dividingBy: 16))
            weightString = "\(lbs) lb \(oz) oz"
            
            let totalInches = baby.height
            let ft = Int(totalInches / 12)
            let inch = Int(totalInches.truncatingRemainder(dividingBy: 12))
            heightString = ft > 0 ? "\(ft) ft \(inch) in" : "\(inch) in"
        }
        
        return "\(weightString), \(heightString)"
    }
}

#Preview("Imperial Units") {
    BabyRowView(
        baby: Baby.sample,
        useMetricUnits: false,
        onEdit: {},
        onDelete: {}
    )
}
