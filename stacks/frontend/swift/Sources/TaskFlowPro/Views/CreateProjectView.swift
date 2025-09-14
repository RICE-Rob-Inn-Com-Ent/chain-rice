import SwiftUI

// MARK: - Create Project View
struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "folder"
    
    private let colors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30",
        "#8E44AD", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8"
    ]
    
    private let icons = [
        "folder", "briefcase", "house", "star",
        "heart", "lightbulb", "gear", "book",
        "paintbrush", "hammer", "wrench", "car"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Podstawowe informacje") {
                    TextField("Nazwa projektu", text: $name)
                    
                    TextField("Opis (opcjonalny)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Kolor") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Ikona") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: selectedIcon == icon ? 3 : 0)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Podgląd") {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: selectedIcon)
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Nazwa projektu" : name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(description.isEmpty ? "Opis projektu" : description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Nowy projekt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Utwórz") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        dashboardViewModel.createProject(
            name: name,
            description: description,
            color: selectedColor
        )
        dismiss()
    }
}
