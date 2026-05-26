import SwiftUI
import UIKit

struct WorkoutTimerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var total: Int = 60
    @State private var remaining: Int = 60
    @State private var isRunning = false
    @State private var rounds = 0

    private let presets: [(String, Int)] = [("0:30", 30), ("1:00", 60), ("5:00", 300), ("10:00", 600), ("20:00", 1200)]
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double { total <= 0 ? 0 : Double(remaining) / Double(total) }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                topBar
                Spacer()
                dial
                Spacer()
                presetRow
                    .padding(.bottom, 24)
                controls
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 22)
        }
        .onReceive(ticker) { _ in tick() }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT TIMER").font(AppFont.label(12)).tracking(1.4).foregroundStyle(Palette.accent)
                Text(rounds == 0 ? "Ready" : "Round \(rounds + 1)")
                    .font(AppFont.title(20)).foregroundStyle(Palette.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
        }
        .padding(.top, 16)
    }

    private var dial: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.07), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.0001, progress))
                .stroke(Palette.ringGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: remaining)
            VStack(spacing: 6) {
                Text(timeString(remaining))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textPrimary)
                Text(isRunning ? "RUNNING" : (remaining == 0 ? "DONE" : "PAUSED"))
                    .font(AppFont.label(12)).tracking(2)
                    .foregroundStyle(isRunning ? Palette.accent : Palette.textFaint)
            }
        }
        .frame(width: 280, height: 280)
    }

    private var presetRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presets, id: \.1) { preset in
                    Button { setPreset(preset.1) } label: {
                        Text(preset.0)
                            .font(AppFont.metric(14))
                            .foregroundStyle(total == preset.1 ? .white : Palette.textSecondary)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background {
                                Capsule().fill(total == preset.1 ? AnyShapeStyle(Palette.accentGradient)
                                                                  : AnyShapeStyle(Color.white.opacity(0.05)))
                            }
                            .overlay(Capsule().strokeBorder(Color.white.opacity(total == preset.1 ? 0 : 0.08)))
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button { reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.05), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.stroke))
            }
            .buttonStyle(PressableStyle())

            Button { toggleRun() } label: {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 84, height: 84)
                    .background(Palette.accentGradient, in: Circle())
                    .shadow(color: Palette.accent.opacity(0.45), radius: 20, y: 8)
            }
            .buttonStyle(PressableStyle())

            Button { addTime(30) } label: {
                VStack(spacing: 0) {
                    Image(systemName: "goforward.30").font(.system(size: 20, weight: .semibold))
                }
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.05), in: Circle())
                .overlay(Circle().strokeBorder(Palette.stroke))
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: Logic
    private func tick() {
        guard isRunning, remaining > 0 else { return }
        remaining -= 1
        if remaining == 0 {
            isRunning = false
            rounds += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    private func toggleRun() {
        if remaining == 0 { remaining = total }
        isRunning.toggle()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    private func reset() {
        isRunning = false
        remaining = total
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    private func setPreset(_ seconds: Int) {
        total = seconds
        remaining = seconds
        isRunning = false
    }
    private func addTime(_ seconds: Int) {
        total += seconds
        remaining += seconds
    }
    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
