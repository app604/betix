import SwiftUI

enum AppTab: String, CaseIterable {
    case dashboard, plans, progress, goals, settings
    var title: String {
        switch self {
        case .dashboard: return "Today"
        case .plans:     return "Plans"
        case .progress:  return "Progress"
        case .goals:     return "Goals"
        case .settings:  return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "speedometer"
        case .plans:     return "calendar"
        case .progress:  return "chart.line.uptrend.xyaxis"
        case .goals:     return "target"
        case .settings:  return "gearshape"
        }
    }
}

struct MainTabView: View {
    @State private var tab: AppTab = .dashboard
    @State private var showTimer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            // All screens stay mounted so per-tab state is preserved.
            ZStack {
                page(.dashboard) { DashboardView(openTimer: { showTimer = true }) }
                page(.plans)     { PlansView(openTimer: { showTimer = true }) }
                page(.progress)  { ProgressAnalyticsView() }
                page(.goals)     { GoalsView() }
                page(.settings)  { SettingsView() }
            }

            CustomTabBar(selection: $tab)
        }
        .fullScreenCover(isPresented: $showTimer) { WorkoutTimerView() }
    }

    @ViewBuilder
    private func page<V: View>(_ which: AppTab, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .opacity(tab == which ? 1 : 0)
            .allowsHitTesting(tab == which)
    }
}

// MARK: - Floating glass tab bar
struct CustomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = item }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selection == item ? Palette.accent : Palette.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(alignment: .top) {
                        if selection == item {
                            Capsule()
                                .fill(Palette.accentGradient)
                                .frame(width: 22, height: 3)
                                .offset(y: -9)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Palette.surface.opacity(0.35)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.10)))
        }
        .clipShape(Capsule(style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }
}
