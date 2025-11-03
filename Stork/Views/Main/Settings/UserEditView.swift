//
//  UserEditView.swift
//  Stork
//
//  Created by Assistant on 10/3/25.
//

import SwiftUI

struct UserEditView: View {
    @AppStorage(AppStorageKeys.useDayMonthYearDates) var useDayMonthYearDates: Bool = false
    
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var birthday: Date
    @Binding var role: UserRole
    var validationMessage: String

    var body: some View {
        Group {
            Section(header: Text("Your Info")) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.storkOrange)
                        .frame(width: 20)
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                }
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.storkOrange)
                        .frame(width: 20)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                }
                LabeledContent {
                    DatePicker("", selection: $birthday, displayedComponents: .date)
                        .labelsHidden()
                        .tint(.red)
                        .environment(\.locale, useDayMonthYearDates ? Locale(identifier: "en_GB") : Locale.current)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.red)
                            .frame(width: 20)
                        Text("Birthday")
                    }
                }
                LabeledContent {
                    Picker("", selection: $role) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.description).tag(role)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .foregroundStyle(.storkPurple)
                            .frame(width: 20)
                    }
                }
            }

            Section(footer: Text(validationMessage).foregroundStyle(.secondary)) { }
        }
    }
}

#Preview {
    @Previewable @State var firstName = "Nick"
    @Previewable @State var lastName = "Molargik"
    @Previewable @State var birthday = Date()
    @Previewable @State var role = UserRole.nurse
    
    Form {
        UserEditView(
            firstName: $firstName,
            lastName: $lastName,
            birthday: $birthday,
            role: $role,
            validationMessage: "All fields are required."
        )
    }
    .formStyle(.grouped)
}
