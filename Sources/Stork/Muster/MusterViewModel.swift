//
//  MusterViewModel.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import Foundation
import SwiftUI
import StorkModel

public class MusterViewModel: ObservableObject {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @Published var currentMuster: Muster?
    @Published var invites: [MusterInvite] = []
    @Published var showInvitationsFullScreen = false
    @Published var showCreateMusterSheet = false
    @Published var showLeaveConfirmation = false
    @Published var isWorking = false
    
    // Admin sheets
    @Published var showInviteUserSheet = false
    @Published var showAssignAdminSheet = false
    @Published var showKickMemberSheet = false
    @Published var showChangeColorSheet = false
    
    // Creation
    @Published var newMusterName = ""
    @Published var newMusterPrimaryHospitalId = ""
    @Published var showHospitalSelection: Bool = false
    @Published var newMusterSelectedHospital: Hospital?
    @Published var newMusterSelectedColor: Color = Color.purple
    @Published var creationFormValid: Bool = false
    
    // Predefined colors
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    // MARK: - Dependencies
    var musterRepository: MusterRepositoryInterface

    // MARK: - Initializer
    public init(musterRepository: MusterRepositoryInterface) {
        self.musterRepository = musterRepository
    }
    
    
    
    //TODO: update a bunch of these functions to properly throw
    
    
    
    
    
    func validateCreationForm() {
        self.creationFormValid = self.newMusterName != "" && self.newMusterSelectedHospital != nil
    }
    
    /// Handles the creation of a new Muster
    func createMuster(profileId: String) async throws {
        self.isWorking = true

        guard !newMusterName.isEmpty else {
            throw MusterError.creationFailed("Muster must have a name!")
        }
        
        guard (newMusterSelectedHospital != nil) else {
            throw MusterError.creationFailed("Muster must have a primary hospital!")
        }
        
        do {
            let newMuster = Muster(
                id: UUID().uuidString,
                profileIds: [profileId],
                primaryHospitalId: newMusterSelectedHospital!.id,
                administratorProfileIds: [profileId],
                name: newMusterName,
                primaryColor: newMusterSelectedColor.description
            )
            
            currentMuster = try await musterRepository.createMuster(newMuster)
            print("Muster creation succeeded: \(currentMuster!.name)")
            
            
        } catch {
            throw MusterError.creationFailed(error.localizedDescription)
        }
    }
    
    func loadCurrentMuster(profileId: String) async {
        // Fetch the muster associated with the current user if any
        // This is just a placeholder. Actual logic would depend on how you map a user to a muster.
        do {
            let musters = try await musterRepository.listMusters(
                profileIds: [profileId],
                primaryHospitalId: nil,
                administratorProfileIds: nil,
                name: nil,
                primaryColor: nil
            )
            self.currentMuster = musters.first
        } catch {
            // Handle error (e.g. user not in any muster)
            self.currentMuster = nil
        }
    }
    
    func fetchInvitations(profileId: String) async {
        do {
            invites = try await musterRepository.collectUserMusterInvites(userId: profileId)
        } catch {
            print("Failed to fetch invites: \(error)")
        }
    }
    
    func respondToInvite(invite: MusterInvite, accepted: Bool, profileId: String) async {
        self.isWorking = true
        
        do {
            try await musterRepository.respondToMusterInvite(invite, response: accepted)
        } catch {
            errorMessage = "Failed to respond to invitaiton. Please try again later."
            self.isWorking = false
        }
    }
    
    func leaveMuster(profileId: String) async {
        guard let muster = currentMuster else { return }
        // Remove user from muster
        var updatedMuster = muster
        updatedMuster.profileIds.removeAll { $0 == profileId }
        updatedMuster.administratorProfileIds.removeAll { $0 == profileId }
        
        if (updatedMuster.administratorProfileIds.count == 0 && updatedMuster.profileIds.count > 0) {
            do {
                updatedMuster.administratorProfileIds.append(updatedMuster.profileIds.first!)
            }
        }
        
        do {
            if updatedMuster.profileIds.isEmpty {
                // If no one is left, we might delete the muster
                try await musterRepository.deleteMuster(muster)
            } else {
                try await musterRepository.updateMuster(updatedMuster)
            }
            currentMuster = nil
        } catch {
            print("Failed to leave muster: \(error)")
        }
    }
    
    func isUserAdmin(of muster: Muster, profileId: String) -> Bool {
        return muster.administratorProfileIds.contains(profileId)
    }
    
    // Admin functions
    func inviteUserToMuster(userId: String) async {
        guard let muster = currentMuster else { return }
        let invite = MusterInvite(
            id: UUID().uuidString,
            recipientId: userId,
            recipientName: "User \(userId)", // You'd fetch this in reality
            senderName: "Current User",
            musterName: muster.name,
            musterId: muster.id,
            primaryHospitalName: muster.primaryHospitalId,
            message: "Join our muster!",
            primaryColor: muster.primaryColor,
            status: InvitationStatus.pending
        )
        do {
            try await musterRepository.sendMusterInvite(invite, userId: userId)
        } catch {
            print("Failed to send invite: \(error)")
        }
    }
    
    func assignAdmin(userId: String) async {
        guard var muster = currentMuster, !muster.administratorProfileIds.contains(userId) else { return }
        muster.administratorProfileIds.append(userId)
        do {
            try await musterRepository.updateMuster(muster)
            currentMuster = muster
        } catch {
            print("Failed to assign admin: \(error)")
        }
    }
    
    func kickMember(userId: String) async {
        guard var muster = currentMuster else { return }
        muster.profileIds.removeAll { $0 == userId }
        muster.administratorProfileIds.removeAll { $0 == userId }
        do {
            try await musterRepository.updateMuster(muster)
            currentMuster = muster
        } catch {
            print("Failed to kick member: \(error)")
        }
    }
    
    func changeMusterColor(newColor: String) async {
        guard var muster = currentMuster else { return }
        muster.primaryColor = newColor
        do {
            try await musterRepository.updateMuster(muster)
            currentMuster = muster
        } catch {
            print("Failed to change muster color: \(error)")
        }
    }
}
