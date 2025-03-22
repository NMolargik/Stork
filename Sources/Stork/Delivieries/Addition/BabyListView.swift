//
//  BabyListView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct BabyListView: View {
    @Binding var babies: [Baby]

    var body: some View {
        ForEach($babies) { $baby in
            let babyIndex = babies.firstIndex(where: { $0.id == baby.id }) ?? 0
            let babyNumber = babyIndex + 1

            BabyEditorView(
                baby: $baby,
                babyNumber: babyNumber,
                removeBaby: { babyId in
                    withAnimation(.spring()) {
                        babies.removeAll { $0.id == babyId }
                    }
                }
            )
            .id(baby.id)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    BabyListView(babies: .constant([]))
}
