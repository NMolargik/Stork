//
//  MusterViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 12/11/24.
//

import SkipFoundation
import SwiftUI
import StorkModel

@MainActor
public class MusterViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentMuster: Muster?
    @Published var invites: [MusterInvite] = []
    @Published var showMusterInvitations = false
    @Published var showCreateMusterSheet = false
    @Published var showLeaveConfirmation = false
    @Published var isWorking = false
    
    // Admin Sheets
    @Published var showInviteUserSheet = false
    @Published var showAssignAdminSheet = false
    @Published var showRenameSheet = false
    
    // Creation
    @Published var newMuster: Muster = Muster(
        id: UUID().uuidString,
        profileIds: [],
        primaryHospitalId: "",
        administratorProfileIds: [],
        name: ""
    )
    @Published var nameError: String? = nil

    @Published var showHospitalSelection: Bool = false
    @Published var creationFormValid: Bool = false
    @Published var musterMembers: [Profile] = []
    
    // Invitation
    @Published var invite: MusterInvite? = nil
    
    // Predefined Colors
    let colors: [Color] = [.red, Color("storkOrange"), .yellow, .green, Color("storkBlue"), Color("storkPurple")]
    
    // MARK: - Dependencies
    
    private let musterRepository: MusterRepositoryInterface
    
    // MARK: - Initializer
    public init(musterRepository: MusterRepositoryInterface) {
        self.musterRepository = musterRepository
    }
    
    // MARK: - Reset
    
    func reset() {
        self.currentMuster = nil
        self.invites = []
        self.musterMembers = []
        self.invite = nil
    }
    
    // MARK: - Creation Methods
    
    /// Validates the creation form and updates the form's validity state.
    func validateCreationForm() {
        if newMuster.name.count > 30 {
            nameError = "Muster name cannot exceed 30 characters"
        } else {
            nameError = nil
        }
        
        creationFormValid =
            !newMuster.name.isEmpty &&
            newMuster.name.count <= 30 &&
            !newMuster.primaryHospitalId.isEmpty
    }
    
    /// Creates a new muster with the provided profile ID.
    func createMuster(profileId: String) async throws {
        guard !newMuster.name.isEmpty else {
            throw MusterError.creationFailed("Muster must have a name!")
        }
        guard !newMuster.primaryHospitalId.isEmpty else {
            throw MusterError.creationFailed("Muster must have a primary hospital!")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        newMuster.profileIds.append(profileId)
        newMuster.administratorProfileIds.append(profileId)
        
        newMuster = try await musterRepository.createMuster(muster: newMuster)
        print("New muster successfully created")
        
        currentMuster = newMuster
        resetNewMuster()
    }
    
    func updateMuster() async throws {
        guard let muster = currentMuster else {
            throw MusterError.updateFailed("No existing muster")
        }
        
        guard !muster.name.isEmpty else {
            throw MusterError.updateFailed("Muster must have a name!")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        do {
            let currentMuster = try await musterRepository.updateMuster(muster: muster)
            self.currentMuster = currentMuster
        } catch {
            throw MusterError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Resets the `newMuster` to its default state.
    private func resetNewMuster() {
        newMuster = Muster(
            id: UUID().uuidString,
            profileIds: [],
            primaryHospitalId: "",
            administratorProfileIds: [],
            name: ""
        )
    }
        
    /// Loads the current muster based on the provided `ProfileViewModel`.
    func loadCurrentMuster(profileViewModel: ProfileViewModel, deliveryViewModel: DeliveryViewModel) async throws {
        musterMembers = []
        isWorking = true
        defer { isWorking = false }
        
        if profileViewModel.profile.musterId.isEmpty {
            print("User is not in a muster")
            // The user is not in a muster
            return
        }
        
        do {
            print("Fetching muster: \(profileViewModel.profile.musterId)")
            currentMuster = try await musterRepository.getMuster(byId: profileViewModel.profile.musterId)
        } catch {
            print("Records indicate user is not currently in a muster")
            currentMuster = nil
            return
        }
        
        
        guard let muster = currentMuster else {
            throw MusterError.updateFailed("Could not load muster")
        }
        
        do {
            try await deliveryViewModel.fetchMusterDeliveries(muster: muster)
        } catch {
            throw DeliveryError.notFound("Could not collect muster deliveries. Please refresh.")
        }
        
        musterMembers = try await profileViewModel.listProfiles(musterId: muster.id)
    }
    
    /// Clears the current muster data.
    func clearCurrentMuster() {
        currentMuster = nil
    }
    
    /// Allows a user to leave the current muster.
    func leaveMuster(profileViewModel: ProfileViewModel, deliveryViewModel: DeliveryViewModel) async throws {
        isWorking = true
        defer { isWorking = false }
        
        try await loadCurrentMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
        
        var muster = try requireMuster()  // Unwrap or throw
        
        muster.profileIds.removeAll { $0 == profileViewModel.profile.id }
        muster.administratorProfileIds.removeAll { $0 == profileViewModel.profile.id }
        
        // If no admins remain, assign the first member as admin
        if muster.administratorProfileIds.isEmpty && !muster.profileIds.isEmpty {
            muster.administratorProfileIds.append(muster.profileIds.first!)
        }
        
        if muster.profileIds.isEmpty {
            // No members left, so delete the muster
            try await deleteMuster(muster: muster)
        } else {
            try await updateMuster(muster: muster)
        }
        
        clearCurrentMuster()
        musterMembers = []
        currentMuster = nil
    }
    
    /// Deletes the muster if no members are left.
    private func deleteMuster(muster: Muster) async throws {
        try await musterRepository.deleteMuster(muster: muster)
        currentMuster = nil
        
        try await musterRepository.deleteMusterInvites(musterId: muster.id)
        
        print("Muster deleted successfully")
    }
    
    /// Updates the muster with the provided changes and refreshes `currentMuster`.
    private func updateMuster(muster: Muster) async throws {
        let updated = try await musterRepository.updateMuster(muster: muster)
        currentMuster = updated
        print("Muster updated successfully")
    }
    
    // MARK: - Invitation Handling
    
    /// Fetches user invitations based on the provided profile ID.
    func fetchUserInvitations(profileId: String) async throws {
        isWorking = true
        defer { isWorking = false }
        
        invites = try await musterRepository.collectUserMusterInvites(userId: profileId)
    }
    
    /// Responds to a user's muster invite.
    func respondToUserInvite(
        profile: Profile,
        invite: MusterInvite,
        accepted: Bool,
        profileViewModel: ProfileViewModel
    ) async throws {
        isWorking = true
        defer { isWorking = false }
        
        if accepted {
            try await acceptInvite(profile: profile, invite: invite, profileViewModel: profileViewModel)
        } else {
            try await declineInvite(invite: invite)
        }
    }
    
    /// Accepts a muster invite.
    private func acceptInvite(profile: Profile, invite: MusterInvite, profileViewModel: ProfileViewModel) async throws {
        resetMusterInviteState()
        
        currentMuster = try await musterRepository.getMuster(byId: invite.musterId)
        var muster = try requireMuster()
        
        // Add this profile to muster membership
        muster.profileIds.append(profile.id)
        
        try await updateMuster(muster: muster)
        
        // Cancel the invite
        try await musterRepository.cancelMusterInvite(invitationId: invite.id)
        invites.removeAll { $0.id == invite.id }
        
        // Update local profile musterId
        profileViewModel.profile.musterId = muster.id
        print("Set profile's musterId to \(muster.id)")
    }
    
    /// Declines a muster invite.
    private func declineInvite(invite: MusterInvite) async throws {
        try await musterRepository.cancelMusterInvite(invitationId: invite.id)
        invites.removeAll { $0.id == invite.id }
    }
    
    // MARK: - Admin Functions
    
    /// Invites a user to the current muster.
    func inviteUserToMuster(profile: Profile, currentUser: Profile) async throws {
        let muster = try requireMuster()
        
        // Make sure we can invite
        guard muster.administratorProfileIds.contains(currentUser.id) else {
            throw MusterError.invitationFailed("Only muster admins can invite.")
        }
        
        resetMusterInviteState()
        configureInvite(for: profile, currentUser: currentUser, muster: muster)
        
        guard let invitation = invite else {
            throw MusterError.invitationFailed("Invitation is invalid. Please try again.")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        try await musterRepository.sendMusterInvite(invite: invitation, userId: profile.id)
        print("Invitation sent to \(profile.firstName) \(profile.lastName)")
        invites.append(invitation)
        
        resetMusterInviteState()
    }
    
    /// Checks if the user is an admin within the muster.
    func isUserAdmin(profile: Profile) -> Bool {
        guard let muster = currentMuster else { return false }
        return muster.administratorProfileIds.contains(profile.id)
    }
    
    /// Retrieves muster invitations for the specified muster.
    func getMusterInvitations(muster: Muster) async throws {
        isWorking = true
        defer { isWorking = false }
        
        invites = try await musterRepository.collectInvitesForMuster(musterId: muster.id)
    }
    
    /// Assigns admin privileges to a user within the muster.
    func assignAdmin(userId: String) async throws {
        var muster = try requireMuster()
        guard !muster.administratorProfileIds.contains(userId) else {
            throw MusterError.invitationFailed("User is already an admin.")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        muster.administratorProfileIds.append(userId)
        try await updateMuster(muster: muster)
        print("Admin assigned to user ID: \(userId)")
    }
    
    // MARK: - Helper Methods
    
    /// Configures the muster invite with necessary details.
    private func configureInvite(for profile: Profile, currentUser: Profile, muster: Muster) {
        invite?.musterId = muster.id
        invite?.recipientId = profile.id
        invite?.musterName = muster.name
        invite?.senderName = currentUser.firstName
        invite?.recipientName = profile.firstName
    }
    
    /// Prepares a new muster invite object in `invite`.
    private func resetMusterInviteState() {
        invite = MusterInvite(
            id: UUID().uuidString,
            recipientId: "",
            recipientName: "",
            senderName: "",
            musterName: "",
            musterId: ""
        )
    }
    
    /// Ensures `currentMuster` is non-nil, or throws an error.
    private func requireMuster() throws -> Muster {
        guard let muster = currentMuster else {
            throw MusterError.updateFailed("No muster loaded.")
        }
        return muster
    }
}
