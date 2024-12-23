import SwiftUI
import StorkModel

struct ProfileView: View {
    // MARK: - Environment Objects
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Variables
    
    @State private var showingEditSheet = false
    @State private var joinDateFormatted: String = ""
    
    // MARK: - Date Formatter
    
    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
            VStack(spacing: 20) {
                // Profile Image
                InitialsAvatarView(
                    firstName: profileViewModel.profile.firstName,
                    lastName: profileViewModel.profile.lastName,
                    size: 100
                )
                .accessibilityLabel(Text("Profile image"))
                
                // Name and Role
                VStack(alignment: .center, spacing: 5) {
                    Text("\(profileViewModel.profile.firstName) \(profileViewModel.profile.lastName)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(profileViewModel.profile.role.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Birthday
                VStack(alignment: .leading, spacing: 5) {
                    Text("Birthday:")
                        .font(.headline)
                    Text(displayDateFormatter.string(from: profileViewModel.profile.birthday))
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
                
                // Member of Muster
                
                if let muster = musterViewModel.currentMuster {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Member of Muster:")
                            .font(.headline)
                        Text(muster.name)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
                
                // Member Since
                VStack(alignment: .leading, spacing: 5) {
                    Text("Member since:")
                        .font(.headline)
                    Text(formatJoinDate(joinDateString: profileViewModel.profile.joinDate))
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal)
                
                // Primary Hospital
                if let hospital = hospitalViewModel.primaryHospital {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Primary Hospital:")
                            .font(.headline)
                        Text(hospital.facility_name)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Edit Profile Button
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView()
                    .environmentObject(profileViewModel)
                    .environmentObject(musterViewModel)
                    .environmentObject(hospitalViewModel)
            }
            .onAppear {
                joinDateFormatted = formatJoinDate(joinDateString: profileViewModel.profile.joinDate)
            }
    }
    
    // MARK: - Helper Functions
    
    /// Formats the join date string to "dd/MM/yyyy". If parsing fails, returns the original string.
    /// - Parameter joinDateString: The join date as a string.
    /// - Returns: Formatted join date string.
    private func formatJoinDate(joinDateString: String) -> String {
        let inputFormatter = Profile.dateFormatter
        if let date = inputFormatter.date(from: joinDateString) {
            return displayDateFormatter.string(from: date)
        } else {
            return joinDateString
        }
    }
}
