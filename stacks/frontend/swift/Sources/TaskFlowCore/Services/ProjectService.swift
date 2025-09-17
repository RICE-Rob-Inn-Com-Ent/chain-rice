import Foundation
import RealmSwift
import Combine

// MARK: - Project Service Protocol
protocol ProjectServiceProtocol {
    func getAllProjects() -> AnyPublisher<[Project], Error>
    func createProject(_ project: Project) -> AnyPublisher<Project, Error>
    func updateProject(_ project: Project) -> AnyPublisher<Project, Error>
    func deleteProject(id: String) -> AnyPublisher<Void, Error>
    func getProjectStats(id: String) -> AnyPublisher<ProjectStats, Error>
}

// MARK: - Project Stats Model
struct ProjectStats: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let inProgressTasks: Int
    let overdueTasks: Int
    let completionRate: Double
    let averageCompletionTime: Double
    let teamMembersCount: Int
}

// MARK: - Project Service Implementation
class ProjectService: ProjectServiceProtocol {
    private let apiClient: APIClient
    private let realm: Realm
    private let taskService: TaskServiceProtocol
    
    init(
        apiClient: APIClient = APIClient.shared,
        realm: Realm = try! Realm(),
        taskService: TaskServiceProtocol = TaskService()
    ) {
        self.apiClient = apiClient
        self.realm = realm
        self.taskService = taskService
    }
    
    // MARK: - Public Methods
    func getAllProjects() -> AnyPublisher<[Project], Error> {
        return Future<[Project], Error> { [weak self] promise in
            Task {
                do {
                    let projects = try await self?.apiClient.getProjects() ?? []
                    self?.saveProjectsToLocal(projects)
                    promise(.success(projects))
                } catch {
                    // Fallback to local data
                    let localProjects = self?.getLocalProjects() ?? []
                    promise(.success(localProjects))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createProject(_ project: Project) -> AnyPublisher<Project, Error> {
        return Future<Project, Error> { [weak self] promise in
            Task {
                do {
                    let createdProject = try await self?.apiClient.createProject(project) ?? project
                    self?.saveProjectToLocal(createdProject)
                    promise(.success(createdProject))
                } catch {
                    // Save locally even if API fails
                    self?.saveProjectToLocal(project)
                    promise(.success(project))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateProject(_ project: Project) -> AnyPublisher<Project, Error> {
        return Future<Project, Error> { [weak self] promise in
            Task {
                do {
                    let updatedProject = try await self?.apiClient.updateProject(project) ?? project
                    self?.saveProjectToLocal(updatedProject)
                    promise(.success(updatedProject))
                } catch {
                    // Update locally even if API fails
                    self?.saveProjectToLocal(project)
                    promise(.success(project))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteProject(id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            Task {
                do {
                    try await self?.apiClient.deleteProject(id: id)
                    self?.deleteProjectFromLocal(id: id)
                    promise(.success(()))
                } catch {
                    // Delete locally even if API fails
                    self?.deleteProjectFromLocal(id: id)
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getProjectStats(id: String) -> AnyPublisher<ProjectStats, Error> {
        return Future<ProjectStats, Error> { [weak self] promise in
            let stats = self?.calculateProjectStats(for: id) ?? ProjectStats(
                totalTasks: 0,
                completedTasks: 0,
                inProgressTasks: 0,
                overdueTasks: 0,
                completionRate: 0,
                averageCompletionTime: 0,
                teamMembersCount: 0
            )
            promise(.success(stats))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func saveProjectsToLocal(_ projects: [Project]) {
        try? realm.write {
            for project in projects {
                realm.add(project, update: .modified)
            }
        }
    }
    
    private func saveProjectToLocal(_ project: Project) {
        try? realm.write {
            realm.add(project, update: .modified)
        }
    }
    
    private func deleteProjectFromLocal(id: String) {
        if let project = realm.object(ofType: Project.self, forPrimaryKey: id) {
            try? realm.write {
                realm.delete(project)
            }
        }
    }
    
    private func getLocalProjects() -> [Project] {
        return Array(realm.objects(Project.self)
            .filter("isArchived == false")
            .sorted(byKeyPath: "updatedAt", ascending: false))
    }
    
    private func calculateProjectStats(for projectId: String) -> ProjectStats {
        let tasks = realm.objects(Task.self).filter("project.id == %@", projectId)
        let project = realm.object(ofType: Project.self, forPrimaryKey: projectId)
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter("statusRaw == %@", TaskStatus.completed.rawValue).count
        let inProgressTasks = tasks.filter("statusRaw == %@", TaskStatus.inProgress.rawValue).count
        
        let today = Date()
        let overdueTasks = tasks.filter("dueDate < %@ AND statusRaw != %@", today, TaskStatus.completed.rawValue).count
        
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        
        // Calculate average completion time
        let completedTasksWithTimes = tasks.filter("statusRaw == %@ AND completedAt != nil", TaskStatus.completed.rawValue)
        var totalCompletionTime: TimeInterval = 0
        for task in completedTasksWithTimes {
            if let createdAt = task.createdAt, let completedAt = task.completedAt {
                totalCompletionTime += completedAt.timeIntervalSince(createdAt)
            }
        }
        let averageCompletionTime = completedTasksWithTimes.count > 0 ? totalCompletionTime / Double(completedTasksWithTimes.count) : 0
        
        let teamMembersCount = project?.teamMembers.count ?? 0
        
        return ProjectStats(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            inProgressTasks: inProgressTasks,
            overdueTasks: overdueTasks,
            completionRate: completionRate,
            averageCompletionTime: averageCompletionTime,
            teamMembersCount: teamMembersCount
        )
    }
}
