import SwiftUI
import SwiftData
import UIKit

struct AddGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editing: Goal? = nil

    @State private var title = ""
    @State private var current: Double = 0
    @State private var target: Double = 0
    @State private var unit = ""
    @State private var accent: GoalAccent = .blue

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        LabeledField(label: "Goal") {
                            DarkTextField(placeholder: "Run 50 km this month", text: $title)
                        }

                        HStack(spacing: 12) {
                            LabeledField(label: "Current") { numberField($current) }
                            LabeledField(label: "Target") { numberField($target) }
                        }

                        LabeledField(label: "Unit") {
                            DarkTextField(placeholder: "km, sessions, kg...", text: $unit)
                        }

                        LabeledField(label: "Accent") {
                            HStack(spacing: 12) {
                                ForEach(GoalAccent.allCases) { a in
                                    Button { accent = a } label: {
                                        Circle().fill(a.color).frame(width: 36, height: 36)
                                            .overlay(Circle().strokeBorder(.white, lineWidth: accent == a ? 2 : 0))
                                            .overlay {
                                                if accent == a {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }

                        if target > 0 {
                            HStack {
                                Spacer()
                                ZStack {
                                    ProgressRing(progress: min(current / max(target, 1), 1), lineWidth: 8,
                                                 colors: [accent.color, accent.color.opacity(0.55)])
                                        .frame(width: 72, height: 72)
                                    Text("\(Int(min(current / max(target, 1), 1) * 100))%")
                                        .font(AppFont.metric(15)).foregroundStyle(Palette.textPrimary)
                                }
                                Spacer()
                            }
                        }

                        PrimaryButton(title: editing == nil ? "Set goal" : "Save changes",
                                      systemImage: "checkmark") { save() }
                            .padding(.top, 4)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(editing == nil ? "New goal" : "Update goal")
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

    private func numberField(_ binding: Binding<Double>) -> some View {
        TextField("0", value: binding, format: .number)
            .keyboardType(.decimalPad)
            .font(AppFont.metric(18))
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.stroke))
    }

    private func load() {
        guard let g = editing else { return }
        title = g.title; current = g.current; target = g.target; unit = g.unit; accent = g.accent
    }

    private func save() {
        let name = title.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, target > 0 else { dismiss(); return }
        let unitText = unit.trimmingCharacters(in: .whitespaces)
        if let g = editing {
            g.title = name; g.current = current; g.target = target
            g.unit = unitText; g.accentRaw = accent.rawValue
        } else {
            context.insert(Goal(title: name, current: current, target: target,
                                unit: unitText, accent: accent))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
