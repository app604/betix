import SwiftUI
import SwiftData
import UIKit

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: TrainingCategory = .strength
    @State private var duration: Double = 45
    @State private var intensity = 3
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        LabeledField(label: "Session name") {
                            DarkTextField(placeholder: "Push day, Tempo run...", text: $title)
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
                                duration = Double(ex.defaultMinutes)
                            } isSelected: { $0.name == title }
                        }

                        LabeledField(label: "Duration · \(Int(duration)) min") {
                            Slider(value: $duration, in: 5...180, step: 5).tint(Palette.accent)
                        }

                        LabeledField(label: "Effort") {
                            IntensityPicker(value: $intensity)
                        }

                        LabeledField(label: "When") {
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(Palette.accent)
                        }

                        LabeledField(label: "Note (optional)") {
                            DarkTextField(placeholder: "How did it feel?", text: $note)
                        }

                        PrimaryButton(title: "Save session", systemImage: "checkmark") { save() }
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Log workout")
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
    }

    private func save() {
        let name = title.trimmingCharacters(in: .whitespaces)
        let workout = Workout(title: name.isEmpty ? category.rawValue + " session" : name,
                              category: category,
                              date: date,
                              durationMinutes: Int(duration),
                              intensity: intensity,
                              note: note)
        context.insert(workout)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Exercise quick-pick (library presets filtered by focus)
struct ExercisePicker: View {
    let category: TrainingCategory
    var onPick: (ExercisePreset) -> Void
    var isSelected: (ExercisePreset) -> Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseLibrary.presets(for: category)) { ex in
                    let selected = isSelected(ex)
                    Button {
                        onPick(ex)
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        Text(ex.name)
                            .font(AppFont.label(13))
                            .foregroundStyle(selected ? .white : Palette.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background {
                                Capsule().fill(selected ? AnyShapeStyle(category.tint)
                                                         : AnyShapeStyle(Color.white.opacity(0.05)))
                            }
                            .overlay(Capsule().strokeBorder(Color.white.opacity(selected ? 0 : 0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Effort picker (1...5)
struct IntensityPicker: View {
    @Binding var value: Int
    private let labels = ["Easy", "Light", "Moderate", "Hard", "Max"]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button { value = i } label: {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(i <= value ? AnyShapeStyle(Palette.accentGradient)
                                             : AnyShapeStyle(Color.white.opacity(0.06)))
                            .frame(height: 36)
                            .overlay(Text("\(i)").font(AppFont.metric(13))
                                .foregroundStyle(i <= value ? .white : Palette.textFaint))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(labels[value - 1]).font(AppFont.label(12)).foregroundStyle(Palette.textSecondary)
        }
    }
}
