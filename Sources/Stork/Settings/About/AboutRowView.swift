//
//  AboutRowView.swift
//
//
//  Created by Nick Molargik on 3/16/25.
//

import SwiftUI

struct AboutRowView<Content: View>: View {
    let title: String
    let content: Content

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            content
        }
    }
}

#Preview {
    AboutRowView(title: "Title", content: Text("Content"))
}
