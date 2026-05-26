import SwiftUI
import SwiftData
import UIKit

struct PlansView: View {
    var openTimer: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.targetMinutes, order: .reverse) private var plans: [WorkoutPlan]

    @State private var selectedDay = Weekday.todayIndex
    @State private var weekOffset = 0          // 0 = current week
    @State private var mode: Mode = .day
    @State private var showAdd = false
    @State private var editingPlan: WorkoutPlan?

    enum Mode: String, CaseIterable { case day = "Day", week = "Week" }

    private var cal: Calendar { CalendarWeek.calendar }
    private var selectedDate: Date { CalendarWeek.date(weekdayIndex: selectedDay, offset: weekOffset) }
    private var isSelectedToday: Bool { cal.isDateInToday(selectedDate) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                modePicker
                if mode == .day {
                    calendarNav
                    weekStrip
                    dayList
                } else {
                    weekOverview
                }
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showAdd) { AddPlanView(defaultWeekday: selectedDay) }
        .sheet(item: $editingPlan) { plan in AddPlanView(editing: plan) }
    }

    private var header: some View {
        HStack {
            ScreenHeader(title: "Training plan", subtitle: "Schedule")
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

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(Mode.allCases, id: \.self) { m in
                Button { withAnimation(.spring(response: 0.3)) { mode = m } } label: {
                    Text(m.rawValue)
                        .font(AppFont.label(14))
                        .foregroundStyle(mode == m ? .white : Palette.textSecondary)
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background {
                            if mode == m {
                                RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Palette.accentGradient)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.stroke))
    }

    // MARK: Calendar navigation
    private var monthLabel: String {
        let mid = CalendarWeek.date(weekdayIndex: 4, offset: weekOffset)   // Thursday is representative
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: mid)
    }
    private var rangeLabel: String {
        let start = CalendarWeek.weekStart(offset: weekOffset)
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        let d = DateFormatter(); d.dateFormat = "d"
        let dm = DateFormatter(); dm.dateFormat = "d MMM"
        return "\(d.string(from: start)) – \(dm.string(from: end))"
    }

    private var calendarNav: some View {
        HStack(spacing: 10) {
            navArrow("chevron.left") { withAnimation(.spring(response: 0.3)) { weekOffset -= 1 } }
            Button {
                if weekOffset != 0 {
                    withAnimation(.spring(response: 0.3)) { weekOffset = 0; selectedDay = Weekday.todayIndex }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                VStack(spacing: 2) {
                    Text(monthLabel).font(AppFont.title(17)).foregroundStyle(Palette.textPrimary)
                    Text(weekOffset == 0 ? rangeLabel : "Tap to return · \(rangeLabel)")
                        .font(AppFont.label(12))
                        .foregroundStyle(weekOffset == 0 ? Palette.textFaint : Palette.accent)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(weekOffset == 0)
            navArrow("chevron.right") { withAnimation(.spring(response: 0.3)) { weekOffset += 1 } }
        }
    }

    private func navArrow(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.05), in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Week strip (real dates)
    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { day in dayCell(day) }
        }
        .padding(.vertical, 10).padding(.horizontal, 6)
        .glass(padding: 6)
    }

    private func dayCell(_ day: Int) -> some View {
        let date = CalendarWeek.date(weekdayIndex: day, offset: weekOffset)
        let isToday = cal.isDateInToday(date)
        let isSelected = selectedDay == day
        let dayItems = plans.filter { $0.weekday == day }
        let dayNum = cal.component(.day, from: date)
        return Button { withAnimation(.spring(response: 0.3)) { selectedDay = day } } label: {
            VStack(spacing: 6) {
                Text(Weekday.short(day))
                    .font(AppFont.label(11))
                    .foregroundStyle(isSelected ? Palette.textPrimary : Palette.textSecondary)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(Palette.accentGradient)
                                         : AnyShapeStyle(Color.white.opacity(0.05)))
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Palette.accent, lineWidth: 1.5)
                    }
                    Text("\(dayNum)")
                        .font(AppFont.metric(15))
                        .foregroundStyle(isSelected ? .white : (isToday ? Palette.accent : Palette.textPrimary))
                }
                .frame(height: 38)
                HStack(spacing: 3) {
                    ForEach(Array(dayItems.prefix(3).enumerated()), id: \.offset) { _, p in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.9) : p.category.tint)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: Day mode list
    private var dayPlans: [WorkoutPlan] { plans.filter { $0.weekday == selectedDay } }

    private var dayHeadline: String {
        let f = DateFormatter(); f.dateFormat = "EEEE d"
        return f.string(from: selectedDate)
    }

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dayHeadline).font(AppFont.title(18)).foregroundStyle(Palette.textPrimary)
                if isSelectedToday {
                    Text("TODAY").font(AppFont.label(10)).tracking(1)
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(Palette.accent.opacity(0.16)))
                }
                Spacer()
                if !dayPlans.isEmpty {
                    Text("\(dayPlans.count) planned").font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
                }
            }
            if dayPlans.isEmpty {
                EmptyStateView(icon: "calendar.badge.plus",
                               title: "Nothing planned",
                               message: "Add a session to \(Weekday.full(selectedDay)) and commit to it.",
                               actionTitle: "Add session") { showAdd = true }
            } else {
                ForEach(dayPlans) { plan in planRow(plan) }
            }
        }
    }

    private func planRow(_ plan: WorkoutPlan) -> some View {
        HStack(spacing: 14) {
            Button { toggleDone(plan) } label: {
                Image(systemName: plan.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(plan.isDone ? Palette.positive : Palette.textFaint)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(AppFont.body(15).weight(.semibold))
                    .foregroundStyle(plan.isDone ? Palette.textFaint : Palette.textPrimary)
                    .strikethrough(plan.isDone, color: Palette.textFaint)
                HStack(spacing: 8) {
                    Label(plan.category.rawValue, systemImage: plan.category.symbol)
                        .font(AppFont.label(12)).foregroundStyle(plan.category.tint)
                    Text("·").foregroundStyle(Palette.textFaint)
                    Text("\(plan.targetMinutes) min").font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
                }
            }
            Spacer()
            Button(action: openTimer) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 36, height: 36)
                    .background(Palette.accent.opacity(0.14), in: Circle())
            }
            .buttonStyle(PressableStyle())
        }
        .glass(padding: 14, radius: 18)
        .contextMenu {
            Button { editingPlan = plan } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { context.delete(plan) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func toggleDone(_ plan: WorkoutPlan) {
        withAnimation(.spring(response: 0.3)) { plan.isDone.toggle() }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: Week mode (current week, real dates)
    private var weekOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(1...7, id: \.self) { day in
                let date = CalendarWeek.date(weekdayIndex: day, offset: 0)
                let isToday = cal.isDateInToday(date)
                let dayNum = cal.component(.day, from: date)
                let items = plans.filter { $0.weekday == day }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(Weekday.full(day)) \(dayNum)")
                            .font(AppFont.label(13).weight(.semibold))
                            .foregroundStyle(isToday ? Palette.accent : Palette.textSecondary)
                        Spacer()
                        Text(items.isEmpty ? "Rest" : "\(items.reduce(0){ $0 + $1.targetMinutes }) min")
                            .font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
                    }
                    if items.isEmpty {
                        Text("No session").font(AppFont.body(13)).foregroundStyle(Palette.textFaint)
                    } else {
                        ForEach(items) { plan in
                            HStack(spacing: 10) {
                                Circle().fill(plan.category.tint).frame(width: 8, height: 8)
                                Text(plan.title).font(AppFont.body(14)).foregroundStyle(Palette.textPrimary)
                                Spacer()
                                if plan.isDone {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Palette.positive)
                                }
                                Text("\(plan.targetMinutes)m").font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
                            }
                        }
                    }
                }
                .glass(padding: 14, radius: 18)
            }
        }
    }
}
