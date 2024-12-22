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
    @Published var currentMuster: Muster?
    @Published var invites: [MusterInvite] = []
    @Published var musterInvites: [MusterInvite] = []
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
    @Published var newMuster: Muster = Muster(id: UUID().uuidString, profileIds: [], primaryHospitalId: "", administratorProfileIds: [], name: "", primaryColor: "")
    @Published var showHospitalSelection: Bool = false
    @Published var creationFormValid: Bool = false
    @Published var nameError: String? = nil
    
    // Invitation
    @Published var invite: MusterInvite? = nil
    
    // Predefined colors
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    
    // MARK: - Dependencies
    var musterRepository: MusterRepositoryInterface

    // MARK: - Initializer
    public init(musterRepository: MusterRepositoryInterface) {
        self.musterRepository = musterRepository
    }
    
    func validateCreationForm() {
        if newMuster.name.count > 20 {
            nameError = "Muster name cannot exceed 25 characters"
        } else {
            nameError = nil
        }
        
        self.creationFormValid = !newMuster.name.isEmpty && newMuster.name.count <= 25 && !newMuster.primaryHospitalId.isEmpty
    }
    
    func isUserAdmin(of muster: Muster, profileId: String) -> Bool {
        return muster.administratorProfileIds.contains(profileId)
    }
    
    /// Handles the creation of a new Muster
    @MainActor
    func createMuster(profileId: String) async throws {
        guard !newMuster.name.isEmpty else {
            throw MusterError.creationFailed("Muster must have a name!")
        }
        
        guard (newMuster.primaryHospitalId != "") else {
            throw MusterError.creationFailed("Muster must have a primary hospital!")
        }
        
        self.isWorking = true
        
        self.newMuster.profileIds.append(profileId)
        self.newMuster.administratorProfileIds.append(profileId)
        
        do {
            try await musterRepository.createMuster(muster: newMuster)
            print("New muster successfully created")
            self.currentMuster = newMuster
            self.startNewMuster()
            self.isWorking = false
        } catch {
            self.isWorking = false
            throw MusterError.creationFailed(error.localizedDescription)
        }
    }
    
    func startNewMuster() {
        self.newMuster = Muster(
            id: UUID().uuidString,
            profileIds: [""],
            primaryHospitalId: "",
            administratorProfileIds: [""],
            name: "",
            primaryColor: Color.red.description
        )
    }
    
    func loadCurrentMuster(profile: Profile) async throws {
        do {
            self.isWorking = true
            self.currentMuster = try await musterRepository.getMuster(byId: profile.musterId)
            self.isWorking = false
        } catch {
            print("Records indicate user is not currently in a muster")
            self.currentMuster = nil
        }
    }
    
    func clearCurrentMuster() {
        self.currentMuster = Muster(
            id: UUID().uuidString,
            profileIds: [""],
            primaryHospitalId: "",
            administratorProfileIds: [""],
            name: "",
            primaryColor: Color.red.description
        )
    }

    func leaveMuster(profileId: String) async throws {
        guard let muster = currentMuster else { throw MusterError.deletionFailed("No muster to delete") }
        isWorking = true
        
        var tempMuster = muster
        tempMuster.profileIds.removeAll { $0 == profileId }
        tempMuster.administratorProfileIds.removeAll { $0 == profileId }

    
        if (tempMuster.administratorProfileIds.count == 0 && tempMuster.profileIds.count > 0) {
            tempMuster.administratorProfileIds.append(tempMuster.profileIds.first!)
        }
        
        if tempMuster.profileIds.isEmpty {
            do {
                try await musterRepository.deleteMuster(muster: tempMuster)
                currentMuster = nil
                isWorking = false
            } catch {
                isWorking = false
                throw error
            }
        } else {
            do {
                try await musterRepository.updateMuster(muster: tempMuster)
                self.currentMuster = tempMuster
                print("Updated muster")
                self.isWorking = false
            } catch {
                self.isWorking = false
                throw error
            }
        }
    }
    
    // Invites - Recipient
    func fetchUserInvitations(profileId: String) async throws {
        self.isWorking = true
        
        do {
            let fetchedInvites = try await musterRepository.collectUserMusterInvites(userId: profileId)
            await MainActor.run {
                self.invites = fetchedInvites
                self.isWorking = false
            }
        } catch {
            await MainActor.run {
                self.isWorking = false
            }
            throw error
        }
    }
    
    func startNewMusterInvite() {
        self.invite = MusterInvite(
            id: UUID().uuidString,
            recipientId: "",
            recipientName: "",
            senderName: "",
            musterName: "",
            musterId: "",
            primaryHospitalName: "",
            message: "",
            primaryColor: ""
        )
    }
    
    func respondToUserInvite(profile: Profile, invite: MusterInvite, accepted: Bool) async throws {
        isWorking = true
        
        if (accepted) {
            startNewMuster()
            
            do {
                currentMuster = try await musterRepository.getMuster(byId: invite.musterId)
            } catch {
                isWorking = false
                throw error
            }
            
            var tempMuster = currentMuster
            tempMuster?.profileIds.append(profile.id)
            
            guard let updatedMuster = tempMuster else {
                isWorking = false
                throw MusterError.invitationResponseFailed("Failed to respond to invite. Please try again.")
            }
            
            do {
                try await musterRepository.updateMuster(muster: updatedMuster)
                currentMuster = updatedMuster
                
            } catch {
                isWorking = false
                throw error
            }
                
            do {
                try await musterRepository.cancelMusterInvite(invitationId: invite.id)
                invites.removeAll(where: { $0.id == invite.id })
            } catch {
                isWorking = false
                throw error
            }
        }
    }
    
    // Admin functions
    func inviteUserToMuster(profile: Profile) async throws {
        guard (invite?.musterId) != nil else {
            throw MusterError.invitationFailed("No muster to invite to")
        }
        
        guard let invitation = invite else {
            throw MusterError.invitationFailed("Invitation is invalid. Please try again.")
        }
        
        isWorking = true
        
        do {
            try await musterRepository.sendMusterInvite(invite: invitation, userId: profile.id)
            print("Invitation sent to \(profile.firstName) \(profile.lastName)")
            isWorking = false
        } catch {
            isWorking = false
            throw error
        }
    }
    
    func getMusterInvitations(muster: Muster) async throws {
        isWorking = true
        
        do {
            musterInvites = try await musterRepository.collectInvitesForMuster(musterId: muster.id)
            isWorking = false
        } catch {
            isWorking = false
            throw error
        }
    }
    
    func assignAdmin(userId: String) async throws {
        guard let muster = currentMuster, !muster.administratorProfileIds.contains(userId) else {
            throw MusterError.invitationFailed("User is already an admin")
        }
        
        isWorking = true
        
        var tempMuster = muster
        tempMuster.administratorProfileIds.append(userId)
        
        do {
            try await musterRepository.updateMuster(muster: tempMuster)
            currentMuster = tempMuster
            isWorking = false
        } catch {
            print("Failed to assign admin: \(error)")
            isWorking = false
            throw error
        }
    }
    
    func kickMember(userId: String) async throws {
        guard let muster = currentMuster else {
            throw MusterError.creationFailed("No muster found")
        }
        
        isWorking = true
        
        var tempMuster = muster
        tempMuster.profileIds.removeAll { $0 == userId }
        tempMuster.administratorProfileIds.removeAll { $0 == userId }
        
        do {
            try await musterRepository.updateMuster(muster: tempMuster)
            currentMuster = tempMuster
            isWorking = false
        } catch {
            isWorking = false
            throw error
        }
    }
    
    func changeMusterColor(newColor: String) async throws {
        guard let muster = currentMuster else {
            throw MusterError.updateFailed("No muster to update")
        }
        
        isWorking = true
        
        var tempMuster = muster
        tempMuster.primaryColor = newColor
        
        do {
            try await musterRepository.updateMuster(muster: tempMuster)
            currentMuster = muster
            isWorking = false
        } catch {
            isWorking = false
            throw error
        }
    }
}
