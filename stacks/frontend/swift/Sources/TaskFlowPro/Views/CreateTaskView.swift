import SwiftUI

// MARK: - Create Task View
struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority = TaskPriority.medium
    @State private var selectedProject: Project?
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Podstawowe informacje") {
                    TextField("Tytuł zadania", text: $title)
                    
                    TextField("Opis (opcjonalny)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Priorytet") {
                    Picker("Priorytet", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(hex: priority.color))
                                    .frame(width: 12, height: 12)
                                
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Projekt") {
                    Picker("Projekt", selection: $selectedProject) {
                        Text("Bez projektu").tag(nil as Project?)
                        ForEach(dashboardViewModel.projects, id: \.id) { project in
                            HStack {
                                Circle()
                                    .fill(Color(hex: project.color))
                                    .frame(width: 12, height: 12)
                                
                                Text(project.name)
                            }
                            .tag(project as Project?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Data wykonania") {
                    Toggle("Ustaw datę wykonania", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Data wykonania",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
            }
            .navigationTitle("Nowe zadanie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Utwórz") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        dashboardViewModel.createTask(
            title: title,
            description: description,
            priority: selectedPriority,
            dueDate: hasDueDate ? dueDate : nil,
            project: selectedProject
        )
        dismiss()
    }
}
