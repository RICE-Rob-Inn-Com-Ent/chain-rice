import Foundation
import RealmSwift

// MARK: - Task Priority Enum
enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Niski"
        case .medium: return "Średni"
        case .high: return "Wysoki"
        case .urgent: return "Pilny"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#34C759"
        case .medium: return "#FF9500"
        case .high: return "#FF3B30"
        case .urgent: return "#8E44AD"
        }
    }
}

// MARK: - Task Status Enum
enum TaskStatus: String, CaseIterable, Codable {
    case todo = "todo"
    case inProgress = "in_progress"
    case review = "review"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .todo: return "Do zrobienia"
        case .inProgress: return "W trakcie"
        case .review: return "Do sprawdzenia"
        case .completed: return "Zakończone"
        }
    }
}

// MARK: - Task Model
@objcMembers
class Task: Object, Codable {
    dynamic var id: String = UUID().uuidString
    dynamic var title: String = ""
    dynamic var taskDescription: String = ""
    dynamic var priorityRaw: String = TaskPriority.medium.rawValue
    dynamic var statusRaw: String = TaskStatus.todo.rawValue
    dynamic var dueDate: Date?
    dynamic var createdAt: Date = Date()
    dynamic var updatedAt: Date = Date()
    dynamic var completedAt: Date?
    dynamic var estimatedHours: Double = 0
    dynamic var actualHours: Double = 0
    
    // Relationships
    dynamic var project: Project?
    dynamic var assignee: User?
    let subtasks = List<Task>()
    dynamic var parentTask: Task?
    let comments = List<TaskComment>()
    let attachments = List<TaskAttachment>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case taskDescription = "description"
        case priorityRaw = "priority"
        case statusRaw = "status"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
        case estimatedHours = "estimated_hours"
        case actualHours = "actual_hours"
        case project, assignee, subtasks, parentTask, comments, attachments
    }
}

// MARK: - Task Extensions
extension Task {
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set { 
            statusRaw = newValue.rawValue
            if newValue == .completed && completedAt == nil {
                completedAt = Date()
            } else if newValue != .completed {
                completedAt = nil
            }
        }
    }
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: today, to: due).day
    }
    
    var progressPercentage: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 100 : 0 }
        let completedSubtasks = subtasks.filter { $0.isCompleted }.count
        return Double(completedSubtasks) / Double(subtasks.count) * 100
    }
}

// MARK: - Task Comment Model
@objcMembers
class TaskComment: Object, Codable {
    dynamic var id: String = UUID().uuidString
    dynamic var content: String = ""
    dynamic var createdAt: Date = Date()
    dynamic var author: User?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - Task Attachment Model
@objcMembers
class TaskAttachment: Object, Codable {
    dynamic var id: String = UUID().uuidString
    dynamic var fileName: String = ""
    dynamic var fileURL: String = ""
    dynamic var fileSize: Int = 0
    dynamic var mimeType: String = ""
    dynamic var uploadedAt: Date = Date()
    dynamic var uploadedBy: User?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
