import SwiftUI
import SwiftData
import Charts

struct ProgressAnalyticsView: View {
    @Query(sort: \Workout.date) private var workouts: [Workout]
    @State private var selected: TrainingCategory? = nil

    private var completed: [Workout] { workouts.filter { $0.isCompleted } }
    private var buckets: [WeekBucket] { PerformanceStats.weeklyLoad(completed, weeks: 6) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(title: "Progress", subtitle: "Analytics")

                if completed.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "No data to chart",
                                   message: "Strength, endurance and stability trends appear here once you log sessions.")
                        .padding(.top, 40)
                } else {
                    summaryRow
                    filterRow
                    trendCard
                    distributionCard
                    insightCard
                }
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Summary
    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(completed.count)", unit: "total", caption: "Sessions", tint: Palette.accent)
            StatTile(value: "\(completed.reduce(0){ $0 + $1.durationMinutes })", unit: "min", caption: "Volume", tint: Palette.accent2)
            StatTile(value: avgIntensity, unit: "rpe", caption: "Avg effort", tint: Palette.cyan)
        }
    }
    private var avgIntensity: String {
        guard !completed.isEmpty else { return "0" }
        let avg = Double(completed.reduce(0){ $0 + $1.intensity }) / Double(completed.count)
        return String(format: "%.1f", avg)
    }

    // MARK: Filter
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { withAnimation(.spring(response: 0.3)) { selected = nil } } label: {
                    Text("All")
                        .font(AppFont.label(13))
                        .foregroundStyle(selected == nil ? .white : Palette.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background {
                            Capsule().fill(selected == nil ? AnyShapeStyle(Palette.accentGradient)
                                                           : AnyShapeStyle(Color.white.opacity(0.05)))
                        }
                        .overlay(Capsule().strokeBorder(Color.white.opacity(selected == nil ? 0 : 0.08)))
                }
                .buttonStyle(.plain)
                ForEach(TrainingCategory.allCases) { c in
                    Button { withAnimation(.spring(response: 0.3)) { selected = c } } label: {
                        CategoryChip(category: c, selected: selected == c)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Trend chart
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: selected?.rawValue ?? "Weekly load")
            Chart {
                if let cat = selected {
                    ForEach(buckets) { b in
                        AreaMark(x: .value("Week", b.shortLabel),
                                 y: .value("Load", b.load(cat)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(colors: [cat.tint.opacity(0.45), cat.tint.opacity(0.02)],
                                               startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Week", b.shortLabel),
                                 y: .value("Load", b.load(cat)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(cat.tint)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                } else {
                    ForEach(TrainingCategory.allCases) { cat in
                        ForEach(buckets) { b in
                            LineMark(x: .value("Week", b.shortLabel),
                                     y: .value("Load", b.load(cat)))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(by: .value("Category", cat.rawValue))
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                }
            }
            .chartForegroundStyleScale(
                domain: TrainingCategory.allCases.map { $0.rawValue },
                range: [Palette.accent, Palette.accent2, Palette.cyan]
            )
            .chartLegend(selected == nil ? .visible : .hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Palette.textFaint)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Palette.textFaint)
                }
            }
            .frame(height: 200)
        }
        .glass(padding: 16)
    }

    // MARK: Distribution
    private var distributionCard: some View {
        let totals = TrainingCategory.allCases.map { c in
            (c, completed.filter { $0.category == c }.reduce(0) { $0 + $1.load })
        }
        let sum = max(totals.reduce(0) { $0 + $1.1 }, 1)
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Focus distribution")
            ForEach(totals, id: \.0) { item in
                VStack(spacing: 6) {
                    HStack {
                        Label(item.0.rawValue, systemImage: item.0.symbol)
                            .font(AppFont.label(13)).foregroundStyle(Palette.textSecondary)
                        Spacer()
                        Text("\(Int(Double(item.1) / Double(sum) * 100))%")
                            .font(AppFont.metric(13)).foregroundStyle(Palette.textPrimary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.05)).frame(height: 8)
                            Capsule().fill(item.0.tint)
                                .frame(width: max(6, geo.size.width * CGFloat(item.1) / CGFloat(sum)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .glass(padding: 16)
    }

    // MARK: Insight
    private var insightCard: some View {
        let totals = TrainingCategory.allCases.map { c in
            (c, completed.filter { $0.category == c }.reduce(0) { $0 + $1.load })
        }
        let top = totals.max { $0.1 < $1.1 }?.0 ?? .strength
        let recent = buckets.suffix(2)
        let delta: Int = {
            guard recent.count == 2 else { return 0 }
            let prev = recent.first!.total, curr = recent.last!.total
            guard prev > 0 else { return curr > 0 ? 100 : 0 }
            return Int(Double(curr - prev) / Double(prev) * 100)
        }()
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(top.tint.opacity(0.16)).frame(width: 48, height: 48)
                Image(systemName: top.symbol).foregroundStyle(top.tint).font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Leading focus: \(top.rawValue)")
                    .font(AppFont.body(15).weight(.semibold)).foregroundStyle(Palette.textPrimary)
                Text("Weekly load is \(delta >= 0 ? "up" : "down") \(abs(delta))% vs last week.")
                    .font(AppFont.body(13)).foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            DeltaTag(value: delta)
        }
        .glass(padding: 16)
    }
}
