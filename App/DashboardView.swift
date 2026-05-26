import SwiftUI
import SwiftData

struct DashboardView: View {
    var openTimer: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showLog = false

    private var index: Int { PerformanceStats.index(workouts) }
    private var streak: Int { PerformanceStats.currentStreak(workouts) }
    private var bestStreak: Int { PerformanceStats.bestStreak(workouts) }
    private var minutesWeek: Int { PerformanceStats.minutes(workouts, inLast: 7) }
    private var minutesToday: Int {
        let cal = Calendar.current
        return workouts.filter { $0.isCompleted && cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.durationMinutes }
    }
    private var sessionsWeek: Int {
        let from = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return workouts.filter { $0.isCompleted && $0.date >= from }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                heroCard
                streakCard
                statsRow
                weekChart
                quickActions
                recentActivity
                Color.clear.frame(height: 96)   // space for floating tab bar
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showLog) { AddWorkoutView() }
    }

    // MARK: Header
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BETIX  ·  \(todayLine)".uppercased())
                    .font(AppFont.label(12)).tracking(1.2)
                    .foregroundStyle(Palette.accent)
                Text(greeting)
                    .font(AppFont.display(28))
                    .foregroundStyle(Palette.textPrimary)
            }
            Spacer()
            Button { showLog = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Palette.accentGradient, in: Circle())
                    .shadow(color: Palette.accent.opacity(0.4), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 4)
    }

    // MARK: Hero gauge
    private var heroCard: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Performance index", systemImage: "waveform.path.ecg")
                    .font(AppFont.label(13))
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                Text("7-day").font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
            }

            ZStack {
                GaugeRing(progress: Double(index) / 100, lineWidth: 18)
                    .frame(width: 196, height: 196)
                VStack(spacing: 2) {
                    Text("\(index)")
                        .font(AppFont.metric(58))
                        .foregroundStyle(Palette.textPrimary)
                        .contentTransition(.numericText())
                    Text(PerformanceStats.label(for: index).uppercased())
                        .font(AppFont.label(12)).tracking(1.2)
                        .foregroundStyle(index == 0 ? Palette.textFaint : Palette.accent)
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 0) {
                miniStat("\(minutesWeek)", "min this week")
                divider
                miniStat("\(sessionsWeek)", "sessions")
                divider
                miniStat("\(streak)", "day streak")
            }
        }
        .glass(padding: 20)
    }

    private func miniStat(_ value: String, _ caption: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.metric(20)).foregroundStyle(Palette.textPrimary)
            Text(caption).font(AppFont.label(11)).foregroundStyle(Palette.textFaint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
    }

    // MARK: Streak ("bet on yourself")
    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Palette.accent2.opacity(0.18)).frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Palette.accent2)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak) day streak")
                    .font(AppFont.title(18)).foregroundStyle(Palette.textPrimary)
                Text(streak == 0 ? "Stake a session today to start your run."
                                 : "Best run so far: \(bestStreak) days. Keep it alive.")
                    .font(AppFont.body(13)).foregroundStyle(Palette.textSecondary)
            }
            Spacer()
        }
        .glass(padding: 16)
    }

    // MARK: Stats row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(minutesToday)", unit: "min", caption: "Today", tint: Palette.accent)
            StatTile(value: "\(totalLoadWeek)", unit: "load", caption: "Week load", tint: Palette.accent2)
        }
    }
    private var totalLoadWeek: Int {
        let from = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return workouts.filter { $0.isCompleted && $0.date >= from }.reduce(0) { $0 + $1.load }
    }

    // MARK: 7-day mini chart
    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Last 7 days")
            let data = last7DaysLoad
            let maxV = max(data.map { $0.1 }.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 92)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.1 > 0 ? AnyShapeStyle(Palette.accentGradient) : AnyShapeStyle(Color.clear))
                                .frame(height: max(4, 92 * CGFloat(item.1) / CGFloat(maxV)))
                        }
                        Text(item.0).font(AppFont.label(10)).foregroundStyle(Palette.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glass(padding: 16)
    }

    private var last7DaysLoad: [(String, Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).reversed().map { offset -> (String, Int) in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let load = workouts.filter { $0.isCompleted && cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.load }
            let f = DateFormatter(); f.dateFormat = "EEEEE"   // single letter
            return (f.string(from: day), load)
        }
    }

    // MARK: Quick actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Start workout", systemImage: "play.fill", action: openTimer)
            Button { showLog = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                    Text("Log").font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 104, height: 52)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke))
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: Recent
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recent activity")
            if workouts.isEmpty {
                EmptyStateView(icon: "figure.run",
                               title: "No sessions yet",
                               message: "Log your first workout to build your performance index and streak.",
                               actionTitle: "Log a session") { showLog = true }
            } else {
                VStack(spacing: 10) {
                    ForEach(workouts.prefix(5)) { w in WorkoutRow(workout: w) }
                }
            }
        }
    }

    // MARK: Helpers
    private var todayLine: String {
        let f = DateFormatter(); f.dateFormat = "EEE, d MMM"
        return f.string(from: .now)
    }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Late session"
        }
    }
}

// MARK: - Workout row
struct WorkoutRow: View {
    let workout: Workout
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(workout.category.tint.opacity(0.16)).frame(width: 42, height: 42)
                Image(systemName: workout.category.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(workout.category.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(workout.title).font(AppFont.body(15).weight(.semibold))
                    .foregroundStyle(Palette.textPrimary).lineLimit(1)
                Text("\(workout.category.rawValue) · \(relativeDay(workout.date))")
                    .font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(workout.durationMinutes)m")
                    .font(AppFont.metric(15)).foregroundStyle(Palette.textPrimary)
                Text("load \(workout.load)")
                    .font(AppFont.label(11)).foregroundStyle(Palette.textFaint)
            }
        }
        .glass(padding: 12, radius: 18)
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
