import SwiftUI
import Charts

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var showingCreateProject = false
    @State private var showingCreateTask = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Statistics Cards
                    StatisticsCardsView()
                    
                    // Quick Actions
                    QuickActionsView(
                        onCreateProject: { showingCreateProject = true },
                        onCreateTask: { showingCreateTask = true }
                    )
                    
                    // Recent Tasks
                    RecentTasksSection()
                    
                    // Projects Overview
                    ProjectsOverviewSection()
                    
                    // Overdue Tasks Alert
                    if !viewModel.overdueTasks.isEmpty {
                        OverdueTasksAlert()
                    }
                    
                    // Tasks Due Today
                    if !viewModel.tasksDueToday.isEmpty {
                        TasksDueTodaySection()
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refreshData()
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView()
            }
        }
    }
}

// MARK: - Statistics Cards View
struct StatisticsCardsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Projekty",
                value: "\(viewModel.totalProjects)",
                icon: "folder.fill",
                color: .blue
            )
            
            StatCard(
                title: "Zadania",
                value: "\(viewModel.totalTasks)",
                icon: "checklist",
                color: .green
            )
            
            StatCard(
                title: "Ukończone",
                value: "\(viewModel.completedTasks)",
                icon: "checkmark.circle.fill",
                color: .orange
            )
            
            StatCard(
                title: "Postęp",
                value: "\(Int(viewModel.completionRate))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Quick Actions View
struct QuickActionsView: View {
    let onCreateProject: () -> Void
    let onCreateTask: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Szybkie akcje")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Nowy projekt",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: onCreateProject
                )
                
                QuickActionButton(
                    title: "Nowe zadanie",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: onCreateTask
                )
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Tasks Section
struct RecentTasksSection: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ostatnie zadania")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("Zobacz wszystkie", destination: TaskListView())
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if viewModel.recentTasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "Brak zadań",
                    subtitle: "Utwórz swoje pierwsze zadanie"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentTasks, id: \.id) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
    }
}

// MARK: - Projects Overview Section
struct ProjectsOverviewSection: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Projekty")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("Zobacz wszystkie", destination: ProjectListView())
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if viewModel.projects.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "Brak projektów",
                    subtitle: "Utwórz swój pierwszy projekt"
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.projects.prefix(3), id: \.id) { project in
                        ProjectRowView(project: project)
                    }
                }
            }
        }
    }
}

// MARK: - Overdue Tasks Alert
struct OverdueTasksAlert: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Zaległe zadania")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(viewModel.overdueTasks.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.overdueTasks.prefix(3), id: \.id) { task in
                    TaskRowView(task: task, showOverdueIndicator: true)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Tasks Due Today Section
struct TasksDueTodaySection: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                
                Text("Zadania na dziś")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.tasksDueToday.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.tasksDueToday, id: \.id) { task in
                    TaskRowView(task: task, showDueDate: true)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
