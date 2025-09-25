import Foundation
import RealmSwift

// MARK: - Project Model
@objcMembers
class Project: Object, Codable {
    dynamic var id: String = UUID().uuidString
    dynamic var name: String = ""
    dynamic var description: String = ""
    dynamic var color: String = "#007AFF"
    dynamic var icon: String = "folder"
    dynamic var isArchived: Bool = false
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    
    // Relationships
    dynamic var owner: User?
    let tasks = LinkingObjects(fromType: Task.self, property: "project")
    let teamMembers = List<User>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, color, icon
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case owner, teamMembers = "team_members"
    }
}

// MARK: - Project Extensions
extension Project {
    var taskCount: Int {
        return tasks.count
    }
    
    var completedTaskCount: Int {
        return tasks.filter { $0.isCompleted }.count
    }
    
    var progressPercentage: Double {
        guard taskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(taskCount) * 100
    }
    
    var priority: TaskPriority {
        let highPriorityTasks = tasks.filter { $0.priority == .high }
        if highPriorityTasks.count > 0 {
            return .high
        } else if tasks.filter({ $0.priority == .medium }).count > 0 {
            return .medium
        } else {
            return .low
        }
    }
}
