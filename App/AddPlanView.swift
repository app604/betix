import SwiftUI
import SwiftData
import UIKit

struct AddPlanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editing: WorkoutPlan? = nil
    var defaultWeekday: Int = Weekday.todayIndex

    @State private var title = ""
    @State private var category: TrainingCategory = .strength
    @State private var weekday = Weekday.todayIndex
    @State private var target: Double = 45
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        LabeledField(label: "Session name") {
                            DarkTextField(placeholder: "Lower body, Intervals...", text: $title)
                        }

                        LabeledField(label: "Focus") {
                            HStack(spacing: 10) {
                                ForEach(TrainingCategory.allCases) { c in
                                    Button { category = c } label: { CategoryChip(category: c, selected: category == c) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }

                        LabeledField(label: "Quick pick") {
                            ExercisePicker(category: category) { ex in
                                title = ex.name
                                target = Double(ex.defaultMinutes)
                            } isSelected: { $0.name == title }
                        }

                        LabeledField(label: "Day") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(1...7, id: \.self) { d in
                                        Button { weekday = d } label: {
                                            Text(Weekday.short(d))
                                                .font(AppFont.label(13))
                                                .foregroundStyle(weekday == d ? .white : Palette.textSecondary)
                                                .frame(width: 44, height: 44)
                                                .background {
                                                    Circle().fill(weekday == d ? AnyShapeStyle(Palette.accentGradient)
                                                                                : AnyShapeStyle(Color.white.opacity(0.05)))
                                                }
                                                .overlay(Circle().strokeBorder(Color.white.opacity(weekday == d ? 0 : 0.08)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        LabeledField(label: "Target · \(Int(target)) min") {
                            Slider(value: $target, in: 10...180, step: 5).tint(Palette.accent)
                        }

                        LabeledField(label: "Note (optional)") {
                            DarkTextField(placeholder: "Key sets, focus cue...", text: $note)
                        }

                        PrimaryButton(title: editing == nil ? "Add to plan" : "Save changes",
                                      systemImage: "checkmark") { save() }
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(editing == nil ? "New session" : "Edit session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: load)
    }

    private func load() {
        if let p = editing {
            title = p.title; category = p.category; weekday = p.weekday
            target = Double(p.targetMinutes); note = p.note
        } else {
            weekday = defaultWeekday
        }
    }

    private func save() {
        let name = title.trimmingCharacters(in: .whitespaces)
        let finalName = name.isEmpty ? category.rawValue + " session" : name
        if let p = editing {
            p.title = finalName; p.categoryRaw = category.rawValue
            p.weekday = weekday; p.targetMinutes = Int(target); p.note = note
        } else {
            context.insert(WorkoutPlan(title: finalName, category: category,
                                       weekday: weekday, targetMinutes: Int(target), note: note))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
