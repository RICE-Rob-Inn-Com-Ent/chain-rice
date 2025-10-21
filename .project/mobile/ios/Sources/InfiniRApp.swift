import SwiftUI

@main
struct InfiniRApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.345, green: 0.110, blue: 0.529), // purple-900
                    Color(red: 0.118, green: 0.227, blue: 0.541), // blue-900
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 16) {
                Text("InfiniR")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.753, green: 0.518, blue: 0.988), // purple-400
                                Color(red: 0.925, green: 0.282, blue: 0.600), // pink-500
                                Color(red: 0.231, green: 0.510, blue: 0.965)  // blue-500
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Infinite Reality Awaits")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.820, green: 0.835, blue: 0.859)) // gray-300
            }
        }
    }
}

#Preview {
    ContentView()
}
