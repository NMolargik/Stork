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
    @Published var newMuster: Muster?
    @Published var showHospitalSelection: Bool = false
    @Published var creationFormValid: Bool = false
    
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
        guard let newMuster else {
            self.creationFormValid = false
            return
        }
        self.creationFormValid = newMuster.name != "" && newMuster.primaryHospitalId != ""
    }
    
    func isUserAdmin(of muster: Muster, profileId: String) -> Bool {
        return muster.administratorProfileIds.contains(profileId)
    }
    
    /// Handles the creation of a new Muster
    func createMuster(profileId: String) async throws {
        guard let newMuster else {
            throw MusterError.creationFailed("Critical: There was an issue, please exit and try again.")

        }
        
        guard !newMuster.name.isEmpty else {
            throw MusterError.creationFailed("Muster must have a name!")
        }
        
        guard (newMuster.primaryHospitalId != "") else {
            throw MusterError.creationFailed("Muster must have a primary hospital!")
        }
        
        self.isWorking = true
        
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
    
    func fetchUserInvitations(profileId: String) async throws {
        self.isWorking = true
        
        do {
            invites = try await musterRepository.collectUserMusterInvites(userId: profileId)
            self.isWorking = false
        } catch {
            self.isWorking = false
            throw error
        }
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
    
    // Admin functions
    func inviteUserToMuster(profile: Profile) async throws {
        guard let musterId = invite?.musterId else {
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
    
    func assignAdmin(userId: String) async throws {
        guard var muster = currentMuster, !muster.administratorProfileIds.contains(userId) else {
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
        guard var muster = currentMuster else {
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
        guard var muster = currentMuster else {
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
