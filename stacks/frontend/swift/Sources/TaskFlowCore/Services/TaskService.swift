import Foundation
import RealmSwift
import Combine

// MARK: - Task Service Protocol
protocol TaskServiceProtocol {
    func getAllTasks() -> AnyPublisher<[Task], Error>
    func getTasks(for projectId: String) -> AnyPublisher<[Task], Error>
    func createTask(_ task: Task) -> AnyPublisher<Task, Error>
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error>
    func deleteTask(id: String) -> AnyPublisher<Void, Error>
    func getTasksByStatus(_ status: TaskStatus) -> AnyPublisher<[Task], Error>
    func getTasksByPriority(_ priority: TaskPriority) -> AnyPublisher<[Task], Error>
    func getOverdueTasks() -> AnyPublisher<[Task], Error>
    func getTasksDueToday() -> AnyPublisher<[Task], Error>
}

// MARK: - Task Service Implementation
class TaskService: TaskServiceProtocol {
    private let apiClient: APIClient
    private let realm: Realm
    
    init(apiClient: APIClient = APIClient.shared, realm: Realm = try! Realm()) {
        self.apiClient = apiClient
        self.realm = realm
    }
    
    // MARK: - Public Methods
    func getAllTasks() -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            Task {
                do {
                    let tasks = try await self?.apiClient.getTasks() ?? []
                    self?.saveTasksToLocal(tasks)
                    promise(.success(tasks))
                } catch {
                    // Fallback to local data
                    let localTasks = self?.getLocalTasks() ?? []
                    promise(.success(localTasks))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTasks(for projectId: String) -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            Task {
                do {
                    let tasks = try await self?.apiClient.getTasks(projectId: projectId) ?? []
                    self?.saveTasksToLocal(tasks)
                    promise(.success(tasks))
                } catch {
                    // Fallback to local data
                    let localTasks = self?.getLocalTasks(for: projectId) ?? []
                    promise(.success(localTasks))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createTask(_ task: Task) -> AnyPublisher<Task, Error> {
        return Future<Task, Error> { [weak self] promise in
            Task {
                do {
                    let createdTask = try await self?.apiClient.createTask(task) ?? task
                    self?.saveTaskToLocal(createdTask)
                    promise(.success(createdTask))
                } catch {
                    // Save locally even if API fails
                    self?.saveTaskToLocal(task)
                    promise(.success(task))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error> {
        return Future<Task, Error> { [weak self] promise in
            Task {
                do {
                    let updatedTask = try await self?.apiClient.updateTask(task) ?? task
                    self?.saveTaskToLocal(updatedTask)
                    promise(.success(updatedTask))
                } catch {
                    // Update locally even if API fails
                    self?.saveTaskToLocal(task)
                    promise(.success(task))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteTask(id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            Task {
                do {
                    try await self?.apiClient.deleteTask(id: id)
                    self?.deleteTaskFromLocal(id: id)
                    promise(.success(()))
                } catch {
                    // Delete locally even if API fails
                    self?.deleteTaskFromLocal(id: id)
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTasksByStatus(_ status: TaskStatus) -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            let tasks = self?.getLocalTasksByStatus(status) ?? []
            promise(.success(tasks))
        }
        .eraseToAnyPublisher()
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            let tasks = self?.getLocalTasksByPriority(priority) ?? []
            promise(.success(tasks))
        }
        .eraseToAnyPublisher()
    }
    
    func getOverdueTasks() -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            let tasks = self?.getLocalOverdueTasks() ?? []
            promise(.success(tasks))
        }
        .eraseToAnyPublisher()
    }
    
    func getTasksDueToday() -> AnyPublisher<[Task], Error> {
        return Future<[Task], Error> { [weak self] promise in
            let tasks = self?.getLocalTasksDueToday() ?? []
            promise(.success(tasks))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func saveTasksToLocal(_ tasks: [Task]) {
        try? realm.write {
            for task in tasks {
                realm.add(task, update: .modified)
            }
        }
    }
    
    private func saveTaskToLocal(_ task: Task) {
        try? realm.write {
            realm.add(task, update: .modified)
        }
    }
    
    private func deleteTaskFromLocal(id: String) {
        if let task = realm.object(ofType: Task.self, forPrimaryKey: id) {
            try? realm.write {
                realm.delete(task)
            }
        }
    }
    
    private func getLocalTasks() -> [Task] {
        return Array(realm.objects(Task.self).sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    private func getLocalTasks(for projectId: String) -> [Task] {
        return Array(realm.objects(Task.self)
            .filter("project.id == %@", projectId)
            .sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    private func getLocalTasksByStatus(_ status: TaskStatus) -> [Task] {
        return Array(realm.objects(Task.self)
            .filter("statusRaw == %@", status.rawValue)
            .sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    private func getLocalTasksByPriority(_ priority: TaskPriority) -> [Task] {
        return Array(realm.objects(Task.self)
            .filter("priorityRaw == %@", priority.rawValue)
            .sorted(byKeyPath: "createdAt", ascending: false))
    }
    
    private func getLocalOverdueTasks() -> [Task] {
        let today = Date()
        return Array(realm.objects(Task.self)
            .filter("dueDate < %@ AND statusRaw != %@", today, TaskStatus.completed.rawValue)
            .sorted(byKeyPath: "dueDate", ascending: true))
    }
    
    private func getLocalTasksDueToday() -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return Array(realm.objects(Task.self)
            .filter("dueDate >= %@ AND dueDate < %@", startOfDay, endOfDay)
            .sorted(byKeyPath: "dueDate", ascending: true))
    }
}
