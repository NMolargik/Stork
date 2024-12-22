//
//  MusterViewModel.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import Foundation
import SwiftUI
import StorkModel

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
    
    // Creation
    @Published var newMuster: Muster = Muster(
        id: UUID().uuidString,
        profileIds: [],
        primaryHospitalId: "",
        administratorProfileIds: [],
        name: "",
        primaryColor: ""
    )
    @Published var showHospitalSelection: Bool = false
    @Published var creationFormValid: Bool = false
    @Published var nameError: String? = nil
    @Published var musterMembers: [Profile] = []
    
    // Invitation
    @Published var invite: MusterInvite? = nil
    
    // Predefined Colors
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    // MARK: - Dependencies
    
    private let musterRepository: MusterRepositoryInterface
    
    // MARK: - Initializer
    
    public init(musterRepository: MusterRepositoryInterface) {
        self.musterRepository = musterRepository
    }
    
    // MARK: - Creation Methods
    
    /// Validates the creation form and updates the form's validity state.
    func validateCreationForm() {
        if newMuster.name.count > 25 {
            nameError = "Muster name cannot exceed 25 characters"
        } else {
            nameError = nil
        }
        
        creationFormValid = !newMuster.name.isEmpty &&
                            newMuster.name.count <= 25 &&
                            !newMuster.primaryHospitalId.isEmpty
    }
    
    /// Creates a new muster with the provided profile ID.
    @MainActor
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
        newMuster.primaryColor = currentMuster?.primaryColor ?? "red"
        
        do {
            try await musterRepository.createMuster(muster: newMuster)
            print("New muster successfully created")
            currentMuster = newMuster
            resetNewMuster()
        } catch {
            throw MusterError.creationFailed(error.localizedDescription)
        }
    }
    
    /// Resets the `newMuster` to its default state.
    private func resetNewMuster() {
        newMuster = Muster(
            id: UUID().uuidString,
            profileIds: [],
            primaryHospitalId: "",
            administratorProfileIds: [],
            name: "",
            primaryColor: "red" // Assuming primaryColor is a String
        )
    }
    
    // MARK: - Muster Management
    
    /// Loads the current muster based on the provided `ProfileViewModel`.
    func loadCurrentMuster(profileViewModel: ProfileViewModel) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
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
            musterMembers = try await profileViewModel.searchProfilesByMuster(musterId: muster.id)
        } catch {
            throw error
        }
    }
    
    /// Clears the current muster data.
    func clearCurrentMuster() {
        currentMuster = Muster(
            id: UUID().uuidString,
            profileIds: [""],
            primaryHospitalId: "",
            administratorProfileIds: [""],
            name: "",
            primaryColor: "red" // Assuming primaryColor is a String
        )
    }
    
    /// Allows a user to leave the current muster.
    func leaveMuster(profileViewModel: ProfileViewModel) async throws {
        try await loadCurrentMuster(profileViewModel: profileViewModel)
        
        guard var muster = currentMuster else {
            throw MusterError.deletionFailed("No muster to delete")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        muster.profileIds.removeAll { $0 == profileViewModel.profile.id }
        muster.administratorProfileIds.removeAll { $0 == profileViewModel.profile.id }
        
        // Reassign admin if necessary
        if muster.administratorProfileIds.isEmpty && !muster.profileIds.isEmpty {
            muster.administratorProfileIds.append(muster.profileIds.first!)
        }
        
        if muster.profileIds.isEmpty {
            try await deleteMuster(muster: muster)
        } else {
            try await updateMuster(muster: muster)
        }
    }
    
    /// Deletes the muster if no members are left.
    private func deleteMuster(muster: Muster) async throws {
        do {
            try await musterRepository.deleteMuster(muster: muster)
            currentMuster = nil
            
            try await musterRepository.deleteMusterInvites(musterId: muster.id)
            
            print("Muster deleted successfully")
        } catch {
            throw error
        }
    }
    
    /// Updates the muster with the provided changes.
    private func updateMuster(muster: Muster) async throws {
        do {
            try await musterRepository.updateMuster(muster: muster)
            currentMuster = muster
            print("Muster updated successfully")
        } catch {
            throw error
        }
    }
    
    // MARK: - Invitation Handling
    
    /// Fetches user invitations based on the provided profile ID.
    func fetchUserInvitations(profileId: String) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            let fetchedInvites = try await musterRepository.collectUserMusterInvites(userId: profileId)
            await MainActor.run {
                invites = fetchedInvites
            }
        } catch {
            throw error
        }
    }
    
    /// Responds to a user's muster invite.
    func respondToUserInvite(profile: Profile, invite: MusterInvite, accepted: Bool) async throws {
        isWorking = true
        defer { isWorking = false }
        
        if accepted {
            try await acceptInvite(profile: profile, invite: invite)
        } else {
            try await declineInvite(invite: invite)
        }
    }
    
    /// Accepts a muster invite.
    private func acceptInvite(profile: Profile, invite: MusterInvite) async throws {
        startNewMusterInvite()
        
        do {
            currentMuster = try await musterRepository.getMuster(byId: invite.musterId)
        } catch {
            throw error
        }
        
        guard var muster = currentMuster else {
            throw MusterError.invitationResponseFailed("Failed to load muster after accepting invite.")
        }
        
        muster.profileIds.append(profile.id)
        
        do {
            try await musterRepository.updateMuster(muster: muster)
            currentMuster = muster
        } catch {
            throw error
        }
        
        do {
            try await musterRepository.cancelMusterInvite(invitationId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            throw error
        }
    }
    
    /// Declines a muster invite.
    private func declineInvite(invite: MusterInvite) async throws {
        do {
            try await musterRepository.cancelMusterInvite(invitationId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            throw error
        }
    }
    
    // MARK: - Admin Functions
    
    /// Invites a user to the current muster.
    func inviteUserToMuster(profile: Profile, currentUser: Profile) async throws {
        guard let muster = currentMuster else {
            throw MusterError.invitationFailed("You can't invite. You aren't in a muster.")
        }
        
        startNewMusterInvite()
        configureInvite(for: profile, currentUser: currentUser, muster: muster)
        
        guard let invitation = invite else {
            throw MusterError.invitationFailed("Invitation is invalid. Please try again.")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        do {
            try await musterRepository.sendMusterInvite(invite: invitation, userId: profile.id)
            print("Invitation sent to \(profile.firstName) \(profile.lastName)")
            invites.append(invitation)
            startNewMusterInvite()
        } catch {
            throw error
        }
    }
    
    /// Checks if the user is an admin within the muster.
    func isUserAdmin(profile: Profile) -> Bool {
        return musterMembers.contains(where: { $0.id == profile.id && $0.isAdmin }) && profile.isAdmin
    }
    
    /// Retrieves muster invitations for the specified muster.
    func getMusterInvitations(muster: Muster) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            invites = try await musterRepository.collectInvitesForMuster(musterId: muster.id)
        } catch {
            throw error
        }
    }
    
    /// Assigns admin privileges to a user within the muster.
    func assignAdmin(userId: String) async throws {
        guard let muster = currentMuster, !muster.administratorProfileIds.contains(userId) else {
            throw MusterError.invitationFailed("User is already an admin")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        var updatedMuster = muster
        updatedMuster.administratorProfileIds.append(userId)
        
        do {
            try await musterRepository.updateMuster(muster: updatedMuster)
            currentMuster = updatedMuster
            print("Admin assigned to user ID: \(userId)")
        } catch {
            throw error
        }
    }
    
    /// Kicks a member out of the muster.
    func kickMember(userId: String) async throws {
        guard var muster = currentMuster else {
            throw MusterError.creationFailed("No muster found")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        muster.profileIds.removeAll { $0 == userId }
        muster.administratorProfileIds.removeAll { $0 == userId }
        
        do {
            try await musterRepository.updateMuster(muster: muster)
            currentMuster = muster
            print("Member with user ID \(userId) has been kicked out.")
        } catch {
            throw error
        }
    }
    
    /// Changes the primary color of the muster.
    func changeMusterColor(newColor: String) async throws {
        guard var muster = currentMuster else {
            throw MusterError.updateFailed("No muster to update")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        muster.primaryColor = newColor
        
        do {
            try await musterRepository.updateMuster(muster: muster)
            currentMuster = muster
            print("Muster color changed to \(newColor)")
        } catch {
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Configures the muster invite with necessary details.
    private func configureInvite(for profile: Profile, currentUser: Profile, muster: Muster) {
        invite?.musterId = muster.id
        invite?.recipientId = profile.id
        invite?.musterName = muster.name
        invite?.senderName = currentUser.firstName
        invite?.primaryColor = muster.primaryColor
        invite?.recipientName = profile.firstName
    }
    
    /// Starts a new muster invite by resetting the invite state.
    private func startNewMusterInvite() {
        invite = MusterInvite(
            id: UUID().uuidString,
            recipientId: "",
            recipientName: "",
            senderName: "",
            musterName: "",
            musterId: "",
            primaryColor: ""
        )
    }
}
