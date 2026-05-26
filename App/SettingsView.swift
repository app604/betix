import SwiftUI
import UIKit
import UserNotifications

private let privacyPolicyURL = "https://app.websitepolicies.com/policies/view/1w2ld11z"

struct SettingsView: View {
    @AppStorage("appBrightness") private var brightness: Double = 0.7
    @AppStorage("pushEnabled")   private var pushEnabled: Bool = false
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "Settings", subtitle: "Preferences")

                // DISPLAY
                settingsGroup("Display") {
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            iconBox("sun.max.fill", Palette.accent)
                            Text("Brightness").font(AppFont.body(15)).foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("\(Int(brightness * 100))%")
                                .font(AppFont.metric(13)).foregroundStyle(Palette.textFaint)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "sun.min").font(.system(size: 13)).foregroundStyle(Palette.textFaint)
                            Slider(value: $brightness, in: 0...1)
                                .tint(Palette.accent)
                                .onChange(of: brightness) { _, newValue in
                                    UIScreen.main.brightness = CGFloat(newValue)
                                }
                            Image(systemName: "sun.max").font(.system(size: 15)).foregroundStyle(Palette.textFaint)
                        }
                    }
                }

                // NOTIFICATIONS
                settingsGroup("Notifications") {
                    VStack(spacing: 0) {
                        toggleRow("bell.badge.fill", Palette.accent2, "Push notifications", $pushEnabled) { on in
                            if on { requestNotificationAuthorization() }
                        }
                        rowDivider
                        toggleRow("flame.fill", Palette.accent2, "Streak reminders", $reminderEnabled)
                        rowDivider
                        toggleRow("hand.tap.fill", Palette.cyan, "Haptic feedback", $hapticsEnabled)
                    }
                }

                // ABOUT
                settingsGroup("About") {
                    VStack(spacing: 0) {
                        Button { openPrivacy() } label: {
                            HStack(spacing: 12) {
                                iconBox("lock.shield.fill", Palette.cyan)
                                Text("Privacy Policy").font(AppFont.body(15)).foregroundStyle(Palette.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.textFaint)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        rowDivider
                        HStack(spacing: 12) {
                            iconBox("info.circle.fill", Palette.textSecondary)
                            Text("Version").font(AppFont.body(15)).foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("1.0.0").font(AppFont.metric(13)).foregroundStyle(Palette.textFaint)
                        }
                    }
                }

                Text("Betix Sports & Trainings\nBet on yourself, every session.")
                    .font(AppFont.label(12)).foregroundStyle(Palette.textFaint)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .onAppear { UIScreen.main.brightness = CGFloat(brightness) }
    }

    // MARK: Building blocks
    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFont.label(11)).tracking(1.2)
                .foregroundStyle(Palette.textFaint)
                .padding(.leading, 4)
            content().glass(padding: 16)
        }
    }

    private func iconBox(_ symbol: String, _ tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.16))
                .frame(width: 32, height: 32)
            Image(systemName: symbol).font(.system(size: 15, weight: .semibold)).foregroundStyle(tint)
        }
    }

    private func toggleRow(_ symbol: String, _ tint: Color, _ title: String,
                           _ binding: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) -> some View {
        HStack(spacing: 12) {
            iconBox(symbol, tint)
            Text(title).font(AppFont.body(15)).foregroundStyle(Palette.textPrimary)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Palette.accent)
                .onChange(of: binding.wrappedValue) { _, newValue in onChange?(newValue) }
        }
        .padding(.vertical, 10)
    }

    private var rowDivider: some View {
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 44)
    }

    // MARK: Actions
    private func openPrivacy() {
        guard let url = URL(string: privacyPolicyURL) else { return }
        UIApplication.shared.open(url)
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if !granted {
                DispatchQueue.main.async { pushEnabled = false }
            }
        }
    }
}
