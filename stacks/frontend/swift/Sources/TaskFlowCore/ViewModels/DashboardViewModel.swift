import Foundation
import Combine
import SwiftUI

// MARK: - Dashboard ViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var recentTasks: [Task] = []
    @Published var overdueTasks: [Task] = []
    @Published var tasksDueToday: [Task] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Statistics
    @Published var totalProjects: Int = 0
    @Published var totalTasks: Int = 0
    @Published var completedTasks: Int = 0
    @Published var completionRate: Double = 0
    
    private let projectService: ProjectServiceProtocol
    private let taskService: TaskServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        projectService: ProjectServiceProtocol = ProjectService(),
        taskService: TaskServiceProtocol = TaskService()
    ) {
        self.projectService = projectService
        self.taskService = taskService
        
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    func refreshData() {
        loadDashboardData()
    }
    
    func createProject(name: String, description: String, color: String) {
        let project = Project()
        project.name = name
        project.description = description
        project.color = color
        
        isLoading = true
        
        projectService.createProject(project)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadProjects()
                }
            )
            .store(in: &cancellables)
    }
    
    func createTask(title: String, projectId: String?, priority: TaskPriority, dueDate: Date?) {
        let task = Task()
        task.title = title
        task.priority = priority
        task.dueDate = dueDate
        
        if let projectId = projectId {
            let project = projects.first { $0.id == projectId }
            task.project = project
        }
        
        isLoading = true
        
        taskService.createTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadTasks()
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        // Load projects
        loadProjects()
        
        // Load tasks
        loadTasks()
    }
    
    private func loadProjects() {
        projectService.getAllProjects()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] projects in
                    self?.projects = projects
                    self?.totalProjects = projects.count
                    self?.updateStatistics()
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadTasks() {
        // Load recent tasks
        taskService.getAllTasks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] tasks in
                    self?.recentTasks = Array(tasks.prefix(5))
                    self?.totalTasks = tasks.count
                    self?.completedTasks = tasks.filter { $0.isCompleted }.count
                    self?.updateStatistics()
                }
            )
            .store(in: &cancellables)
        
        // Load overdue tasks
        taskService.getOverdueTasks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] tasks in
                    self?.overdueTasks = tasks
                }
            )
            .store(in: &cancellables)
        
        // Load tasks due today
        taskService.getTasksDueToday()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] tasks in
                    self?.tasksDueToday = tasks
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
    }
}

// MARK: - Dashboard Data Extensions
extension DashboardViewModel {
    var urgentTasksCount: Int {
        return recentTasks.filter { $0.priority == .urgent }.count
    }
    
    var highPriorityTasksCount: Int {
        return recentTasks.filter { $0.priority == .high }.count
    }
    
    var projectsWithProgress: [Project] {
        return projects.filter { $0.taskCount > 0 }
    }
    
    var topPerformingProjects: [Project] {
        return projects.sorted { $0.progressPercentage > $1.progressPercentage }.prefix(3).map { $0 }
    }
    
    var tasksByPriority: [TaskPriority: Int] {
        var counts: [TaskPriority: Int] = [:]
        for priority in TaskPriority.allCases {
            counts[priority] = recentTasks.filter { $0.priority == priority }.count
        }
        return counts
    }
    
    var tasksByStatus: [TaskStatus: Int] {
        var counts: [TaskStatus: Int] = [:]
        for status in TaskStatus.allCases {
            counts[status] = recentTasks.filter { $0.status == status }.count
        }
        return counts
    }
}
