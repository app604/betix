import SwiftUI
import SwiftData

@main
struct BetixApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
        }
        .modelContainer(for: [Workout.self, WorkoutPlan.self, Goal.self])
    }
}
