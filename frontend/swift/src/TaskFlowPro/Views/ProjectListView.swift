import SwiftUI

// MARK: - Project List ViewModel
@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingCreateProject = false
    
    private let projectService: ProjectServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(projectService: ProjectServiceProtocol = ProjectService()) {
        self.projectService = projectService
        loadProjects()
    }
    
    func loadProjects() {
        isLoading = true
        errorMessage = nil
        
        projectService.getAllProjects()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] projects in
                    self?.projects = projects
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshProjects() {
        loadProjects()
    }
}

// MARK: - Project List View
struct ProjectListView: View {
    @EnvironmentObject var viewModel: ProjectViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Ładowanie projektów...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.projects.isEmpty {
                    EmptyProjectsView()
                } else {
                    List {
                        ForEach(viewModel.projects, id: \.id) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectRowView(project: project)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Projekty")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingCreateProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                viewModel.refreshProjects()
            }
            .sheet(isPresented: $viewModel.showingCreateProject) {
                CreateProjectView()
            }
        }
    }
}

// MARK: - Project Detail View
struct ProjectDetailView: View {
    let project: Project
    @StateObject private var taskListViewModel = TaskListViewModel()
    @State private var showingCreateTask = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Project Header
                ProjectHeaderView(project: project)
                
                // Project Statistics
                ProjectStatsView(project: project)
                
                // Tasks Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Zadania")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Nowe zadanie") {
                            showingCreateTask = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if taskListViewModel.tasks.isEmpty {
                        EmptyStateView(
                            icon: "checklist",
                            title: "Brak zadań",
                            subtitle: "Dodaj pierwsze zadanie do tego projektu"
                        )
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(taskListViewModel.tasks.filter { $0.project?.id == project.id }, id: \.id) { task in
                                TaskRowView(task: task)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskView()
        }
    }
}

// MARK: - Project Header View
struct ProjectHeaderView: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 60, height: 60)
                
                Image(systemName: project.icon)
                    .foregroundColor(.white)
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(project.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Utworzono \(formatDate(project.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Project Stats View
struct ProjectStatsView: View {
    let project: Project
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Zadania",
                value: "\(project.taskCount)",
                icon: "checklist",
                color: .blue
            )
            
            StatCard(
                title: "Ukończone",
                value: "\(project.completedTaskCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Postęp",
                value: "\(Int(project.progressPercentage))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
        }
    }
}

// MARK: - Empty Projects View
struct EmptyProjectsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Brak projektów")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Utwórz swój pierwszy projekt, aby rozpocząć organizację zadań")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
