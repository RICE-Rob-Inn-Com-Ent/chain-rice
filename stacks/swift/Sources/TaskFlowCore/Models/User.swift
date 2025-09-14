import Foundation
import RealmSwift

// MARK: - User Model
@objcMembers
class User: Object, Codable {
    dynamic var id: String = UUID().uuidString
    dynamic var email: String = ""
    dynamic var name: String = ""
    dynamic var avatarURL: String = ""
    dynamic var createdAt: Date = Date()
    dynamic var lastLoginAt: Date = Date()
    
    // Relationships
    let projects = LinkingObjects(fromType: Project.self, property: "owner")
    let tasks = LinkingObjects(fromType: Task.self, property: "assignee")
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
    }
}

// MARK: - User Extensions
extension User {
    var displayName: String {
        return name.isEmpty ? email : name
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first }.map { String($0) }.joined().uppercased()
    }
}
