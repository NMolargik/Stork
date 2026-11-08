//
//  PrivacyTrustView.swift
//  StorkFeatureSettings
//
//  "Why This Is Safe to Keep": what Stork stores, where it lives, and why identifiers
//  do not belong in it. Reached from the Privacy section of Settings.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

struct PrivacyTrustView: View {
    var body: some View {
        List {
            Section {
                Text("Stork is a private log of the births you have been part of. It is built so that it never needs to know who anyone is.", bundle: .module)
                    .font(.callout)
            }

            Section {
                point("tray.full.fill", "What Stork stores", "Dates and times, delivery method, whether an epidural was used, each baby's sex, weight and length, your role, and any short note or tag you choose to add.")
                point("person.crop.circle.badge.xmark", "What it never asks for", "No patient or baby names, medical record numbers, dates of birth, hospital or unit, and no account or sign-in.")
            }

            Section {
                point("iphone", "Stays on your device", "Your log lives on your iPhone, iPad and Apple Watch. There are no Stork servers, no analytics about your births and no advertising.")
                point("icloud.fill", "Private iCloud only", "If iCloud is on, your log syncs through your own private iCloud database. Molargik Software cannot see it, and neither can anyone else.")
                point("faceid", "Optional lock", "Turn on Require Face ID in Privacy to ask for Face ID or your passcode when Stork opens.")
            } header: {
                Text("Where it lives", bundle: .module)
            }

            Section {
                point("exclamationmark.bubble.fill", "Keep notes free of identifiers", "Write \"twins on Christmas Eve\", not a name or a date of birth. Stork warns you if a note looks like it has an identifier, and it never imports them from a CSV.")
                point("checkmark.shield.fill", "Why that matters", "A log with no identifiers is just your own career memories, which is why it is safe to keep for years. Follow your employer's policies too: they come first.")
            } header: {
                Text("What to avoid", bundle: .module)
            }
        }
        .navigationTitle(Text("Why This Is Safe to Keep", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func point(_ symbol: String, _ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3).foregroundStyle(.storkPurple).frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title, bundle: .module).font(.headline)
                Text(body, bundle: .module).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
#endif
