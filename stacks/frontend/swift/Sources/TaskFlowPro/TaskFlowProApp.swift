import SwiftUI
import RealmSwift

// MARK: - Main App
@main
struct TaskFlowProApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    setupRealm()
                }
        }
    }
    
    private func setupRealm() {
        // Configure Realm
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                // Handle migrations if needed
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: Int
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var taskListViewModel = TaskListViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            TaskListView()
                .environmentObject(taskListViewModel)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Zadania")
                }
                .tag(1)
            
            ProjectListView()
                .environmentObject(projectViewModel)
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Projekty")
                }
                .tag(2)
            
            AnalyticsView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(3)
            
            ProfileView()
                .environmentObject(profileViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}
