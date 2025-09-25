import SwiftUI

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    var showOverdueIndicator: Bool = false
    var showDueDate: Bool = false
    @EnvironmentObject var taskListViewModel: TaskListViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion Button
            Button(action: {
                taskListViewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Task Title
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                // Project Name
                if let project = task.project {
                    Text(project.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Due Date or Overdue Indicator
                if showOverdueIndicator && task.isOverdue {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                        
                        Text("Zaległe")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                } else if showDueDate, let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Priority Indicator
            PriorityIndicator(priority: task.priority)
            
            // Status Indicator
            StatusIndicator(status: task.status)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Priority Indicator
struct PriorityIndicator: View {
    let priority: TaskPriority
    
    var body: some View {
        Circle()
            .fill(Color(hex: priority.color))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: TaskStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .todo:
            return .gray
        case .inProgress:
            return .blue
        case .review:
            return .orange
        case .completed:
            return .green
        }
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            // Project Icon
            ZStack {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 40, height: 40)
                
                Image(systemName: project.icon)
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Project Name
                Text(project.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Task Count
                Text("\(project.taskCount) zadań")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress Bar
                ProgressView(value: project.progressPercentage / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: project.color)))
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
            }
            
            Spacer()
            
            // Progress Percentage
            Text("\(Int(project.progressPercentage))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: project.color))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
