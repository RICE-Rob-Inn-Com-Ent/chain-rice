import Foundation
import Combine
import SwiftUI

// MARK: - Task List ViewModel
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Filters
    @Published var selectedProject: Project?
    @Published var selectedStatus: TaskStatus?
    @Published var selectedPriority: TaskPriority?
    @Published var searchText: String = ""
    @Published var sortOption: TaskSortOption = .dueDate
    
    // Statistics
    @Published var totalTasks: Int = 0
    @Published var completedTasks: Int = 0
    @Published var overdueTasks: Int = 0
    
    private let taskService: TaskServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(taskService: TaskServiceProtocol = TaskService()) {
        self.taskService = taskService
        
        // Observe filter changes
        Publishers.CombineLatest4(
            $selectedProject,
            $selectedStatus,
            $selectedPriority,
            $searchText
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
        
        loadTasks()
    }
    
    // MARK: - Public Methods
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
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
                    self?.tasks = tasks
                    self?.updateStatistics()
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshTasks() {
        loadTasks()
    }
    
    func createTask(title: String, description: String, priority: TaskPriority, dueDate: Date?, project: Project?) {
        let task = Task()
        task.title = title
        task.taskDescription = description
        task.priority = priority
        task.dueDate = dueDate
        task.project = project
        
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
    
    func updateTask(_ task: Task) {
        isLoading = true
        
        taskService.updateTask(task)
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
    
    func deleteTask(_ task: Task) {
        isLoading = true
        
        taskService.deleteTask(id: task.id)
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
    
    func toggleTaskCompletion(_ task: Task) {
        task.status = task.isCompleted ? .todo : .completed
        updateTask(task)
    }
    
    func setTaskStatus(_ task: Task, status: TaskStatus) {
        task.status = status
        updateTask(task)
    }
    
    func setTaskPriority(_ task: Task, priority: TaskPriority) {
        task.priority = priority
        updateTask(task)
    }
    
    func clearFilters() {
        selectedProject = nil
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
    }
    
    // MARK: - Private Methods
    private func applyFilters() {
        var filtered = tasks
        
        // Filter by project
        if let project = selectedProject {
            filtered = filtered.filter { $0.project?.id == project.id }
        }
        
        // Filter by status
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Filter by priority
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.taskDescription.localizedCaseInsensitiveContains(searchText) ||
                task.project?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Sort tasks
        filtered = sortTasks(filtered)
        
        filteredTasks = filtered
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdAt > task2.createdAt
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
        case .priority:
            return tasks.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .status:
            return tasks.sorted { $0.status.rawValue < $1.status.rawValue }
        case .createdDate:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return tasks.sorted { $0.title < $1.title }
        }
    }
    
    private func updateStatistics() {
        totalTasks = tasks.count
        completedTasks = tasks.filter { $0.isCompleted }.count
        overdueTasks = tasks.filter { $0.isOverdue }.count
    }
}

// MARK: - Task Sort Options
enum TaskSortOption: String, CaseIterable {
    case dueDate = "due_date"
    case priority = "priority"
    case status = "status"
    case createdDate = "created_date"
    case title = "title"
    
    var displayName: String {
        switch self {
        case .dueDate: return "Data wykonania"
        case .priority: return "Priorytet"
        case .status: return "Status"
        case .createdDate: return "Data utworzenia"
        case .title: return "Tytuł"
        }
    }
}

// MARK: - Task List Extensions
extension TaskListViewModel {
    var tasksByStatus: [TaskStatus: [Task]] {
        var grouped: [TaskStatus: [Task]] = [:]
        for status in TaskStatus.allCases {
            grouped[status] = filteredTasks.filter { $0.status == status }
        }
        return grouped
    }
    
    var tasksByPriority: [TaskPriority: [Task]] {
        var grouped: [TaskPriority: [Task]] = [:]
        for priority in TaskPriority.allCases {
            grouped[priority] = filteredTasks.filter { $0.priority == priority }
        }
        return grouped
    }
    
    var tasksByProject: [String: [Task]] {
        var grouped: [String: [Task]] = [:]
        for task in filteredTasks {
            let projectName = task.project?.name ?? "Bez projektu"
            if grouped[projectName] == nil {
                grouped[projectName] = []
            }
            grouped[projectName]?.append(task)
        }
        return grouped
    }
    
    var hasActiveFilters: Bool {
        return selectedProject != nil || selectedStatus != nil || selectedPriority != nil || !searchText.isEmpty
    }
}
