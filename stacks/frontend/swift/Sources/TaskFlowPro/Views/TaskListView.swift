import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    @State private var showingCreateTask = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                // Filters
                if viewModel.hasActiveFilters {
                    FilterBar(viewModel: viewModel)
                }
                
                // Task List
                if viewModel.isLoading {
                    ProgressView("Ładowanie zadań...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredTasks.isEmpty {
                    EmptyTasksView()
                } else {
                    List {
                        ForEach(viewModel.filteredTasks, id: \.id) { task in
                            TaskDetailRowView(task: task)
                                .swipeActions(edge: .trailing) {
                                    Button("Usuń", role: .destructive) {
                                        viewModel.deleteTask(task)
                                    }
                                    
                                    Button("Edytuj") {
                                        // TODO: Show edit task view
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Zadania")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filtry") {
                        showingFilters = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                viewModel.refreshTasks()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView()
            }
            .sheet(isPresented: $showingFilters) {
                TaskFiltersView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Szukaj zadań...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Wyczyść") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let project = viewModel.selectedProject {
                    FilterChip(
                        title: project.name,
                        color: .blue,
                        action: { viewModel.selectedProject = nil }
                    )
                }
                
                if let status = viewModel.selectedStatus {
                    FilterChip(
                        title: status.displayName,
                        color: .green,
                        action: { viewModel.selectedStatus = nil }
                    )
                }
                
                if let priority = viewModel.selectedPriority {
                    FilterChip(
                        title: priority.displayName,
                        color: .orange,
                        action: { viewModel.selectedPriority = nil }
                    )
                }
                
                Button("Wyczyść wszystkie") {
                    viewModel.clearFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Image(systemName: "xmark")
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(12)
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Task Detail Row View
struct TaskDetailRowView: View {
    let task: Task
    @EnvironmentObject var viewModel: TaskListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Completion Button
                Button(action: {
                    viewModel.toggleTaskCompletion(task)
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                    
                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    PriorityIndicator(priority: task.priority)
                    
                    StatusIndicator(status: task.status)
                }
            }
            
            // Task Details
            HStack {
                // Project
                if let project = task.project {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(project.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Due Date
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                        
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                }
                
                // Assignee
                if let assignee = task.assignee {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(assignee.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Empty Tasks View
struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Brak zadań")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Utwórz swoje pierwsze zadanie lub zmień filtry")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Task Filters View
struct TaskFiltersView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Projekt") {
                    Picker("Projekt", selection: $viewModel.selectedProject) {
                        Text("Wszystkie").tag(nil as Project?)
                        // TODO: Add projects from viewModel
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Status") {
                    Picker("Status", selection: $viewModel.selectedStatus) {
                        Text("Wszystkie").tag(nil as TaskStatus?)
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status as TaskStatus?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Priorytet") {
                    Picker("Priorytet", selection: $viewModel.selectedPriority) {
                        Text("Wszystkie").tag(nil as TaskPriority?)
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority as TaskPriority?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Sortowanie") {
                    Picker("Sortuj według", selection: $viewModel.sortOption) {
                        ForEach(TaskSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Filtry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Wyczyść") {
                        viewModel.clearFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") {
                        dismiss()
                    }
                }
            }
        }
    }
}
