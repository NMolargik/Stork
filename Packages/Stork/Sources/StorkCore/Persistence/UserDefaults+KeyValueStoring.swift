//
//  UserDefaults+KeyValueStoring.swift
//  StorkCore
//
//  The production `KeyValueStoring` conformance. Lives in Core (Foundation-only) alongside
//  the protocol so any layer — features, data, composition — can default to
//  `UserDefaults.standard` without importing the data layer.
//

import Foundation

extension UserDefaults: KeyValueStoring {}
