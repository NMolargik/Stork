//
//  AuthFlowViewModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI


class AuthFlowViewModel: ObservableObject {
    @Published var showRegistration: Bool = false
    @Published var authError: String?
    
}
