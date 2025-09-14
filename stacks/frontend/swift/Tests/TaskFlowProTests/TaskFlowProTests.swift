import XCTest
@testable import TaskFlowPro
@testable import TaskFlowCore

// MARK: - TaskFlow Pro Tests
final class TaskFlowProTests: XCTestCase {
    
    // MARK: - Model Tests
    func testTaskModel() {
        let task = Task()
        task.title = "Test Task"
        task.taskDescription = "Test Description"
        task.priority = .high
        task.status = .inProgress
        
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.taskDescription, "Test Description")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.status, .inProgress)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testProjectModel() {
        let project = Project()
        project.name = "Test Project"
        project.description = "Test Description"
        project.color = "#FF0000"
        
        XCTAssertEqual(project.name, "Test Project")
        XCTAssertEqual(project.description, "Test Description")
        XCTAssertEqual(project.color, "#FF0000")
        XCTAssertEqual(project.taskCount, 0)
        XCTAssertEqual(project.progressPercentage, 0)
    }
    
    func testUserModel() {
        let user = User()
        user.name = "Jan Kowalski"
        user.email = "jan@example.com"
        
        XCTAssertEqual(user.displayName, "Jan Kowalski")
        XCTAssertEqual(user.initials, "JK")
    }
    
    // MARK: - Priority Tests
    func testTaskPriority() {
        XCTAssertEqual(TaskPriority.low.displayName, "Niski")
        XCTAssertEqual(TaskPriority.medium.displayName, "Średni")
        XCTAssertEqual(TaskPriority.high.displayName, "Wysoki")
        XCTAssertEqual(TaskPriority.urgent.displayName, "Pilny")
        
        XCTAssertEqual(TaskPriority.low.color, "#34C759")
        XCTAssertEqual(TaskPriority.medium.color, "#FF9500")
        XCTAssertEqual(TaskPriority.high.color, "#FF3B30")
        XCTAssertEqual(TaskPriority.urgent.color, "#8E44AD")
    }
    
    // MARK: - Status Tests
    func testTaskStatus() {
        XCTAssertEqual(TaskStatus.todo.displayName, "Do zrobienia")
        XCTAssertEqual(TaskStatus.inProgress.displayName, "W trakcie")
        XCTAssertEqual(TaskStatus.review.displayName, "Do sprawdzenia")
        XCTAssertEqual(TaskStatus.completed.displayName, "Zakończone")
    }
    
    // MARK: - Task Extensions Tests
    func testTaskExtensions() {
        let task = Task()
        task.title = "Test Task"
        
        // Test completion
        XCTAssertFalse(task.isCompleted)
        task.status = .completed
        XCTAssertTrue(task.isCompleted)
        
        // Test overdue
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        task.dueDate = yesterday
        task.status = .todo
        XCTAssertTrue(task.isOverdue)
        
        // Test days until due
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        task.dueDate = tomorrow
        XCTAssertEqual(task.daysUntilDue, 1)
    }
    
    // MARK: - Project Extensions Tests
    func testProjectExtensions() {
        let project = Project()
        project.name = "Test Project"
        
        // Test priority calculation
        XCTAssertEqual(project.priority, .low)
        
        // Test progress calculation
        XCTAssertEqual(project.progressPercentage, 0)
    }
    
    // MARK: - User Extensions Tests
    func testUserExtensions() {
        let user = User()
        user.name = "Jan Kowalski"
        user.email = "jan@example.com"
        
        XCTAssertEqual(user.displayName, "Jan Kowalski")
        XCTAssertEqual(user.initials, "JK")
        
        // Test with empty name
        user.name = ""
        XCTAssertEqual(user.displayName, "jan@example.com")
        XCTAssertEqual(user.initials, "J")
    }
    
    // MARK: - API Error Tests
    func testAPIError() {
        let error = APIError.invalidURL
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Nieprawidłowy"))
        
        let networkError = APIError.networkError(NSError(domain: "test", code: 0))
        XCTAssertNotNil(networkError.errorDescription)
    }
    
    // MARK: - Performance Tests
    func testTaskCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let task = Task()
                task.title = "Performance Test Task"
                task.priority = .medium
                task.status = .todo
            }
        }
    }
    
    func testProjectCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let project = Project()
                project.name = "Performance Test Project"
                project.description = "Performance Test Description"
                project.color = "#007AFF"
            }
        }
    }
    
    // MARK: - Mock Data Tests
    func testMockDataCreation() {
        let mockUser = createMockUser()
        XCTAssertNotNil(mockUser)
        XCTAssertEqual(mockUser.name, "Jan Kowalski")
        XCTAssertEqual(mockUser.email, "jan.kowalski@example.com")
    }
    
    // MARK: - Helper Methods
    private func createMockUser() -> User {
        let user = User()
        user.name = "Jan Kowalski"
        user.email = "jan.kowalski@example.com"
        user.avatarURL = ""
        return user
    }
}

// MARK: - Integration Tests
class TaskFlowProIntegrationTests: XCTestCase {
    
    func testTaskProjectRelationship() {
        let project = Project()
        project.name = "Test Project"
        
        let task = Task()
        task.title = "Test Task"
        task.project = project
        
        XCTAssertEqual(task.project?.name, "Test Project")
        XCTAssertTrue(project.tasks.contains(task))
    }
    
    func testUserTaskAssignment() {
        let user = User()
        user.name = "Test User"
        
        let task = Task()
        task.title = "Test Task"
        task.assignee = user
        
        XCTAssertEqual(task.assignee?.name, "Test User")
        XCTAssertTrue(user.tasks.contains(task))
    }
}

// MARK: - UI Tests (Preview Tests)
#if canImport(SwiftUI)
import SwiftUI

class TaskFlowProUITests: XCTestCase {
    
    func testDashboardViewPreview() {
        // Test that DashboardView can be instantiated
        let view = DashboardView()
        XCTAssertNotNil(view)
    }
    
    func testTaskListViewPreview() {
        // Test that TaskListView can be instantiated
        let view = TaskListView()
        XCTAssertNotNil(view)
    }
    
    func testProjectListViewPreview() {
        // Test that ProjectListView can be instantiated
        let view = ProjectListView()
        XCTAssertNotNil(view)
    }
}
#endif
