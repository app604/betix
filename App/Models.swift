import Foundation
import SwiftUI
import SwiftData

// MARK: - Training category
enum TrainingCategory: String, CaseIterable, Codable, Identifiable {
    case strength  = "Strength"
    case endurance = "Endurance"
    case stability = "Stability"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .strength:  return "dumbbell.fill"
        case .endurance: return "bolt.heart.fill"
        case .stability: return "figure.cooldown"
        }
    }

    var tint: Color {
        switch self {
        case .strength:  return Palette.accent
        case .endurance: return Palette.accent2
        case .stability: return Palette.cyan
        }
    }
}

// MARK: - Logged workout session
@Model
final class Workout {
    var id: UUID
    var title: String
    var categoryRaw: String
    var date: Date
    var durationMinutes: Int
    var intensity: Int          // 1...5 perceived effort
    var note: String
    var isCompleted: Bool

    init(title: String,
         category: TrainingCategory,
         date: Date = .now,
         durationMinutes: Int = 45,
         intensity: Int = 3,
         note: String = "",
         isCompleted: Bool = true) {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.date = date
        self.durationMinutes = durationMinutes
        self.intensity = intensity
        self.note = note
        self.isCompleted = isCompleted
    }

    var category: TrainingCategory { TrainingCategory(rawValue: categoryRaw) ?? .strength }
    /// Training load = duration weighted by effort.
    var load: Int { durationMinutes * intensity }
}

// MARK: - Planned workout (day / week planner)
@Model
final class WorkoutPlan {
    var id: UUID
    var title: String
    var categoryRaw: String
    var weekday: Int            // 1 = Monday ... 7 = Sunday
    var targetMinutes: Int
    var note: String
    var isDone: Bool

    init(title: String,
         category: TrainingCategory,
         weekday: Int,
         targetMinutes: Int = 45,
         note: String = "",
         isDone: Bool = false) {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.weekday = weekday
        self.targetMinutes = targetMinutes
        self.note = note
        self.isDone = isDone
    }

    var category: TrainingCategory { TrainingCategory(rawValue: categoryRaw) ?? .strength }
}

// MARK: - Goal with circular progress
enum GoalAccent: String, CaseIterable, Codable, Identifiable {
    case blue, purple, cyan
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .blue:   return Palette.accent
        case .purple: return Palette.accent2
        case .cyan:   return Palette.cyan
        }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    var current: Double
    var target: Double
    var unit: String
    var accentRaw: String
    var createdAt: Date

    init(title: String,
         current: Double = 0,
         target: Double,
         unit: String,
         accent: GoalAccent = .blue) {
        self.id = UUID()
        self.title = title
        self.current = current
        self.target = target
        self.unit = unit
        self.accentRaw = accent.rawValue
        self.createdAt = .now
    }

    var accent: GoalAccent { GoalAccent(rawValue: accentRaw) ?? .blue }
    var progress: Double { target <= 0 ? 0 : min(current / target, 1) }
    var percent: Int { Int((progress * 100).rounded()) }
}

// MARK: - Derived performance analytics (no separate storage)
struct WeekBucket: Identifiable {
    let id = UUID()
    let weekStart: Date
    var loads: [TrainingCategory: Int] = [:]
    var total: Int { loads.values.reduce(0, +) }
    func load(_ c: TrainingCategory) -> Int { loads[c] ?? 0 }
    var shortLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: weekStart)
    }
}

enum PerformanceStats {

    /// Performance index 0...100 from the last 7 days of logged load + consistency.
    static func index(_ workouts: [Workout], on day: Date = .now, calendar: Calendar = .current) -> Int {
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: day))!
        let recent = workouts.filter { $0.isCompleted && $0.date >= weekAgo }
        guard !recent.isEmpty else { return 0 }
        let totalLoad = recent.reduce(0) { $0 + $1.load }
        let distinctDays = Set(recent.map { calendar.startOfDay(for: $0.date) }).count
        let base = min(85.0, Double(totalLoad) / 12.0)          // ~1020 load -> 85
        let consistency = min(15.0, Double(distinctDays) * 3.0) // up to 5 days -> 15
        return min(100, Int((base + consistency).rounded()))
    }

    static func label(for index: Int) -> String {
        switch index {
        case 0:        return "No data yet"
        case 1...39:   return "Recovering"
        case 40...64:  return "Steady"
        case 65...84:  return "Strong"
        default:       return "Peak form"
        }
    }

    /// Consecutive days up to today with at least one completed workout.
    static func currentStreak(_ workouts: [Workout], calendar: Calendar = .current) -> Int {
        let days = Set(workouts.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        // Allow the streak to "hold" if today has no entry yet but yesterday does.
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
            if !days.contains(cursor) { return 0 }
        }
        while days.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    static func bestStreak(_ workouts: [Workout], calendar: Calendar = .current) -> Int {
        let days = workouts.filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
        let unique = Set(days).sorted()
        guard !unique.isEmpty else { return 0 }
        var best = 1, run = 1
        for i in 1..<unique.count {
            if calendar.date(byAdding: .day, value: 1, to: unique[i - 1]) == unique[i] {
                run += 1; best = max(best, run)
            } else { run = 1 }
        }
        return best
    }

    /// Weekly load split by category for the trailing `weeks` weeks.
    static func weeklyLoad(_ workouts: [Workout], weeks: Int = 6, calendar: Calendar = .current) -> [WeekBucket] {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let today = cal.startOfDay(for: .now)
        let thisWeekStart = cal.dateInterval(of: .weekOfYear, for: today)!.start

        var buckets: [WeekBucket] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            let start = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart)!
            var bucket = WeekBucket(weekStart: start)
            for c in TrainingCategory.allCases { bucket.loads[c] = 0 }
            buckets.append(bucket)
        }
        for w in workouts where w.isCompleted {
            guard let wStart = cal.dateInterval(of: .weekOfYear, for: w.date)?.start else { continue }
            if let i = buckets.firstIndex(where: { $0.weekStart == wStart }) {
                buckets[i].loads[w.category, default: 0] += w.load
            }
        }
        return buckets
    }

    static func minutes(_ workouts: [Workout], inLast days: Int, calendar: Calendar = .current) -> Int {
        let from = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now))!
        return workouts.filter { $0.isCompleted && $0.date >= from }.reduce(0) { $0 + $1.durationMinutes }
    }
}

// MARK: - Small date helpers
extension Date {
    var weekdayIndexMonFirst: Int {     // 1 = Monday ... 7 = Sunday
        let wd = Calendar.current.component(.weekday, from: self) // 1 = Sunday
        return wd == 1 ? 7 : wd - 1
    }
}

enum Weekday {
    static let shortNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    static let fullNames  = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    static func short(_ index1: Int) -> String { shortNames[(index1 - 1 + 7) % 7] }
    static func full(_ index1: Int) -> String { fullNames[(index1 - 1 + 7) % 7] }
    static var todayIndex: Int { Date().weekdayIndexMonFirst }
}

// MARK: - Week calendar helper (real dates, Monday-first)
enum CalendarWeek {
    static var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // Monday
        return c
    }

    /// Monday of the week containing `date`.
    static func start(of date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// Monday of the week `offset` weeks away from the current one.
    static func weekStart(offset: Int) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: start(of: .now))!
    }

    /// Real date for a weekday index (1 = Mon ... 7 = Sun) in the week at `offset`.
    static func date(weekdayIndex: Int, offset: Int) -> Date {
        calendar.date(byAdding: .day, value: weekdayIndex - 1, to: weekStart(offset: offset))!
    }
}

// MARK: - Exercise library (quick-pick presets)
struct ExercisePreset: Identifiable, Hashable {
    let name: String
    let category: TrainingCategory
    let defaultMinutes: Int
    var id: String { name }
}

enum ExerciseLibrary {
    static let all: [ExercisePreset] = [
        // Strength
        ExercisePreset(name: "Bench Press",        category: .strength,  defaultMinutes: 45),
        ExercisePreset(name: "Back Squat",         category: .strength,  defaultMinutes: 50),
        ExercisePreset(name: "Deadlift",           category: .strength,  defaultMinutes: 45),
        ExercisePreset(name: "Overhead Press",     category: .strength,  defaultMinutes: 40),
        ExercisePreset(name: "Pull-Ups",           category: .strength,  defaultMinutes: 35),
        ExercisePreset(name: "Barbell Row",        category: .strength,  defaultMinutes: 40),
        ExercisePreset(name: "Romanian Deadlift",  category: .strength,  defaultMinutes: 40),
        ExercisePreset(name: "Hip Thrust",         category: .strength,  defaultMinutes: 35),
        ExercisePreset(name: "Dumbbell Lunges",    category: .strength,  defaultMinutes: 35),
        ExercisePreset(name: "Push Day",           category: .strength,  defaultMinutes: 50),
        ExercisePreset(name: "Pull Day",           category: .strength,  defaultMinutes: 50),
        ExercisePreset(name: "Leg Day",            category: .strength,  defaultMinutes: 55),

        // Endurance
        ExercisePreset(name: "Tempo Run",          category: .endurance, defaultMinutes: 35),
        ExercisePreset(name: "Interval Sprints",   category: .endurance, defaultMinutes: 30),
        ExercisePreset(name: "Zone 2 Ride",        category: .endurance, defaultMinutes: 60),
        ExercisePreset(name: "Rowing 2K",          category: .endurance, defaultMinutes: 25),
        ExercisePreset(name: "Lap Swim",           category: .endurance, defaultMinutes: 40),
        ExercisePreset(name: "Stair Climb",        category: .endurance, defaultMinutes: 30),
        ExercisePreset(name: "Jump Rope",          category: .endurance, defaultMinutes: 20),
        ExercisePreset(name: "Hill Repeats",       category: .endurance, defaultMinutes: 35),
        ExercisePreset(name: "Long Run",           category: .endurance, defaultMinutes: 70),
        ExercisePreset(name: "Assault Bike",       category: .endurance, defaultMinutes: 25),

        // Stability
        ExercisePreset(name: "Plank Circuit",      category: .stability, defaultMinutes: 20),
        ExercisePreset(name: "Mobility Flow",      category: .stability, defaultMinutes: 25),
        ExercisePreset(name: "Yoga Flow",          category: .stability, defaultMinutes: 40),
        ExercisePreset(name: "Core Stability",     category: .stability, defaultMinutes: 25),
        ExercisePreset(name: "Balance Drills",     category: .stability, defaultMinutes: 20),
        ExercisePreset(name: "Foam Rolling",       category: .stability, defaultMinutes: 15),
        ExercisePreset(name: "Pilates Mat",        category: .stability, defaultMinutes: 35),
        ExercisePreset(name: "Hip Mobility",       category: .stability, defaultMinutes: 20),
        ExercisePreset(name: "Single-Leg Work",    category: .stability, defaultMinutes: 25),
        ExercisePreset(name: "Stretch & Recover",  category: .stability, defaultMinutes: 20)
    ]

    static func presets(for category: TrainingCategory) -> [ExercisePreset] {
        all.filter { $0.category == category }
    }
}
