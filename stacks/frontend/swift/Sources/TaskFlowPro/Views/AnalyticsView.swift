import SwiftUI
import Charts

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                    
                    // Overview Cards
                    OverviewCardsView()
                    
                    // Charts Section
                    ChartsSection()
                    
                    // Performance Metrics
                    PerformanceMetricsView()
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                dashboardViewModel.refreshData()
            }
        }
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Zakres czasowy", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

// MARK: - Overview Cards View
struct OverviewCardsView: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            OverviewCard(
                title: "Całkowita produktywność",
                value: "\(Int(dashboardViewModel.completionRate))%",
                icon: "chart.bar.fill",
                color: .blue,
                trend: .up
            )
            
            OverviewCard(
                title: "Średni czas wykonania",
                value: "2.5h",
                icon: "clock.fill",
                color: .green,
                trend: .down
            )
            
            OverviewCard(
                title: "Zadania w trakcie",
                value: "\(dashboardViewModel.recentTasks.filter { $0.status == .inProgress }.count)",
                icon: "play.circle.fill",
                color: .orange,
                trend: .stable
            )
            
            OverviewCard(
                title: "Zespół aktywny",
                value: "85%",
                icon: "person.2.fill",
                color: .purple,
                trend: .up
            )
        }
    }
}

// MARK: - Overview Card
struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .foregroundColor(trend.color)
                    .font(.caption)
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

// MARK: - Charts Section
struct ChartsSection: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Tasks Completion Chart
            TasksCompletionChart()
            
            // Priority Distribution Chart
            PriorityDistributionChart()
            
            // Project Progress Chart
            ProjectProgressChart()
        }
    }
}

// MARK: - Tasks Completion Chart
struct TasksCompletionChart: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ukończenie zadań")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(dashboardViewModel.tasksByStatus.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { status, tasks in
                    BarMark(
                        x: .value("Status", status.displayName),
                        y: .value("Liczba", tasks.count)
                    )
                    .foregroundStyle(statusColor(for: status))
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return .gray
        case .inProgress: return .blue
        case .review: return .orange
        case .completed: return .green
        }
    }
}

// MARK: - Priority Distribution Chart
struct PriorityDistributionChart: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rozkład priorytetów")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(dashboardViewModel.tasksByPriority.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { priority, tasks in
                    SectorMark(
                        angle: .value("Liczba", tasks.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: priority.color))
                    .opacity(0.8)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Project Progress Chart
struct ProjectProgressChart: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Postęp projektów")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(dashboardViewModel.projectsWithProgress, id: \.id) { project in
                    BarMark(
                        x: .value("Projekt", project.name),
                        y: .value("Postęp", project.progressPercentage)
                    )
                    .foregroundStyle(Color(hex: project.color))
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metryki wydajności")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Najlepszy dzień",
                    value: "Poniedziałek",
                    icon: "calendar",
                    color: .blue
                )
                
                MetricCard(
                    title: "Najczęstszy priorytet",
                    value: "Średni",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
                
                MetricCard(
                    title: "Średni czas na zadanie",
                    value: "2.5h",
                    icon: "clock",
                    color: .green
                )
                
                MetricCard(
                    title: "Najaktywniejszy projekt",
                    value: "Frontend",
                    icon: "folder",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Supporting Types
enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "Tydzień"
        case .month: return "Miesiąc"
        case .quarter: return "Kwartał"
        case .year: return "Rok"
        }
    }
}

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}
