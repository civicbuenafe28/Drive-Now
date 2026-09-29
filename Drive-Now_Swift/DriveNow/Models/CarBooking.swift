//
//  UserProfile.swift
//  DriveNow
//
//  Created by STUDENT on 10/15/25.
//

import Foundation

struct UserProfile: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var phoneNumber: String?
    var licenseInfo: String?
    var joinedDate: String?

    init(id: UUID = UUID(), fullName: String = "", email: String = "", phoneNumber: String? = nil, licenseInfo: String? = nil, joinedDate: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.licenseInfo = licenseInfo
        self.joinedDate = joinedDate
    }
}
