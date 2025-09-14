import SwiftUI

// MARK: - Profile ViewModel
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        loadUserProfile()
    }
    
    func loadUserProfile() {
        // In a real app, this would load from the API
        // For demo purposes, we'll create a mock user
        user = createMockUser()
    }
    
    private func createMockUser() -> User {
        let user = User()
        user.name = "Jan Kowalski"
        user.email = "jan.kowalski@example.com"
        user.avatarURL = ""
        return user
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showingSettings = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Header
                    UserProfileHeader()
                    
                    // Statistics Section
                    UserStatisticsSection()
                    
                    // Quick Actions
                    QuickActionsSection(
                        showingSettings: $showingSettings,
                        showingAbout: $showingAbout
                    )
                    
                    // App Information
                    AppInformationSection()
                }
                .padding()
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - User Profile Header
struct UserProfileHeader: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 100, height: 100)
                
                if let user = profileViewModel.user {
                    Text(user.initials)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(spacing: 4) {
                if let user = profileViewModel.user {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            // Edit Profile Button
            Button("Edytuj profil") {
                // TODO: Show edit profile view
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - User Statistics Section
struct UserStatisticsSection: View {
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Twoje statystyki")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Projekty",
                    value: "\(dashboardViewModel.totalProjects)",
                    icon: "folder.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Zadania",
                    value: "\(dashboardViewModel.totalTasks)",
                    icon: "checklist",
                    color: .green
                )
                
                StatCard(
                    title: "Ukończone",
                    value: "\(dashboardViewModel.completedTasks)",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Akcje")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ActionRow(
                    icon: "gear",
                    title: "Ustawienia",
                    color: .blue
                ) {
                    showingSettings = true
                }
                
                ActionRow(
                    icon: "info.circle",
                    title: "O aplikacji",
                    color: .green
                ) {
                    showingAbout = true
                }
                
                ActionRow(
                    icon: "square.and.arrow.up",
                    title: "Eksportuj dane",
                    color: .orange
                ) {
                    // TODO: Export data functionality
                }
                
                ActionRow(
                    icon: "questionmark.circle",
                    title: "Pomoc i wsparcie",
                    color: .purple
                ) {
                    // TODO: Help and support
                }
                
                ActionRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Wyloguj się",
                    color: .red
                ) {
                    authViewModel.logout()
                }
            }
        }
    }
}

// MARK: - Action Row
struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Information Section
struct AppInformationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informacje o aplikacji")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(title: "Wersja", value: "1.0.0")
                InfoRow(title: "Build", value: "2024.01.15")
                InfoRow(title: "Platforma", value: "iOS 16.0+")
                InfoRow(title: "Deweloper", value: "TaskFlow Pro Team")
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var autoSyncEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Powiadomienia") {
                    Toggle("Włącz powiadomienia", isOn: $notificationsEnabled)
                    Toggle("Powiadomienia o terminach", isOn: $notificationsEnabled)
                    Toggle("Powiadomienia o zmianach", isOn: $notificationsEnabled)
                }
                
                Section("Wygląd") {
                    Toggle("Tryb ciemny", isOn: $darkModeEnabled)
                    Picker("Język", selection: .constant("Polski")) {
                        Text("Polski").tag("pl")
                        Text("English").tag("en")
                    }
                }
                
                Section("Synchronizacja") {
                    Toggle("Automatyczna synchronizacja", isOn: $autoSyncEnabled)
                    Button("Synchronizuj teraz") {
                        // TODO: Manual sync
                    }
                }
                
                Section("Dane") {
                    Button("Wyczyść cache") {
                        // TODO: Clear cache
                    }
                    Button("Eksportuj dane", role: .destructive) {
                        // TODO: Export data
                    }
                }
            }
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Logo
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("TaskFlow Pro")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Wersja 1.0.0")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    Text("TaskFlow Pro to zaawansowana aplikacja do zarządzania projektami i zadaniami, stworzona z myślą o profesjonalistach. Aplikacja wykorzystuje najnowsze technologie Swift i SwiftUI, oferując intuicyjny interfejs i potężne funkcje.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Główne funkcje:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        FeatureRow(icon: "folder", text: "Zarządzanie projektami")
                        FeatureRow(icon: "checklist", text: "Organizacja zadań")
                        FeatureRow(icon: "chart.bar", text: "Analytics i raporty")
                        FeatureRow(icon: "person.2", text: "Praca zespołowa")
                        FeatureRow(icon: "icloud", text: "Synchronizacja w chmurze")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Contact Info
                    VStack(spacing: 8) {
                        Text("Kontakt")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("support@taskflowpro.com")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("O aplikacji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Gotowe") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
