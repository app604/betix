import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]

    @State private var showAdd = false
    @State private var editing: Goal?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if goals.isEmpty {
                    EmptyStateView(icon: "target",
                                   title: "No goals set",
                                   message: "Set a target and bet on yourself. Track it with a live progress ring.",
                                   actionTitle: "Set a goal") { showAdd = true }
                        .padding(.top, 30)
                } else {
                    overallCard
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(goals) { goal in goalCard(goal) }
                    }
                }
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showAdd) { AddGoalView() }
        .sheet(item: $editing) { goal in AddGoalView(editing: goal) }
    }

    private var header: some View {
        HStack {
            ScreenHeader(title: "Goals", subtitle: "Bet on yourself")
            Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Palette.accentGradient, in: Circle())
                    .shadow(color: Palette.accent.opacity(0.4), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var overallCard: some View {
        let avg = goals.isEmpty ? 0 : goals.reduce(0.0) { $0 + $1.progress } / Double(goals.count)
        let done = goals.filter { $0.progress >= 1 }.count
        return HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: avg, lineWidth: 9).frame(width: 64, height: 64)
                Text("\(Int(avg * 100))%")
                    .font(AppFont.metric(16))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .frame(width: 46)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall progress").font(AppFont.title(17)).foregroundStyle(Palette.textPrimary)
                Text("\(done) of \(goals.count) goals reached")
                    .font(AppFont.body(13)).foregroundStyle(Palette.textSecondary)
            }
            Spacer()
        }
        .glass(padding: 16)
    }

    private func goalCard(_ goal: Goal) -> some View {
        VStack(spacing: 12) {
            ZStack {
                ProgressRing(progress: goal.progress, lineWidth: 9,
                             colors: [goal.accent.color, goal.accent.color.opacity(0.55)])
                    .frame(width: 92, height: 92)
                VStack(spacing: 0) {
                    Text("\(goal.percent)%")
                        .font(AppFont.metric(20))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 70)
                    if goal.progress >= 1 {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Palette.positive)
                    }
                }
            }
            VStack(spacing: 3) {
                Text(goal.title).font(AppFont.body(14).weight(.semibold))
                    .foregroundStyle(Palette.textPrimary).lineLimit(1)
                Text("\(format(goal.current)) / \(format(goal.target)) \(goal.unit)")
                    .font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .glass(padding: 16)
        .contentShape(Rectangle())
        .onTapGesture { editing = goal }
        .contextMenu {
            Button { editing = goal } label: { Label("Update", systemImage: "slider.horizontal.3") }
            Button(role: .destructive) { context.delete(goal) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func format(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
