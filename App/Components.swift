import SwiftUI

// MARK: - Glass surface
struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func glass(padding: CGFloat = 16, radius: CGFloat = 22) -> some View {
        modifier(GlassCard(padding: padding, radius: radius))
    }
}

// MARK: - Screen header (large title + caption)
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(AppFont.label(12))
                    .tracking(1.4)
                    .foregroundStyle(Palette.accent)
            }
            Text(title)
                .font(AppFont.display(30))
                .foregroundStyle(Palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Section header with optional trailing action
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.title(18))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.label(13))
                        .foregroundStyle(Palette.accent)
                }
            }
        }
    }
}

// MARK: - Progress ring
struct ProgressRing: View {
    var progress: Double                  // 0...1
    var lineWidth: CGFloat = 10
    var colors: [Color] = [Palette.accent, Palette.accent2]
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: colors + [colors.first ?? Palette.accent]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

// MARK: - Open gauge (270°) for the performance index
struct GaugeRing: View {
    var progress: Double                  // 0...1
    var lineWidth: CGFloat = 16
    private let span = 0.75                // 270 degrees
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: span)
                .stroke(Color.white.opacity(0.07),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: span * max(0.001, min(progress, 1)))
                .stroke(Palette.ringGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
                .animation(.spring(response: 0.7, dampingFraction: 0.85), value: progress)
        }
    }
}

// MARK: - Pills & chips
struct CategoryChip: View {
    let category: TrainingCategory
    var selected: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.symbol).font(.system(size: 12, weight: .semibold))
            Text(category.rawValue).font(AppFont.label(13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(selected ? Color.white : Palette.textSecondary)
        .background {
            Capsule().fill(selected ? AnyShapeStyle(category.tint) : AnyShapeStyle(Color.white.opacity(0.05)))
        }
        .overlay(Capsule().strokeBorder(Color.white.opacity(selected ? 0 : 0.08)))
    }
}

struct DeltaTag: View {
    let value: Int                        // signed percentage
    var body: some View {
        let up = value >= 0
        return HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text("\(abs(value))%").font(AppFont.metric(12, weight: .semibold))
        }
        .foregroundStyle(up ? Palette.positive : Palette.warn)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill((up ? Palette.positive : Palette.warn).opacity(0.14)))
    }
}

// MARK: - Primary button
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 15, weight: .semibold)) }
                Text(title).font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Palette.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Palette.accent.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PressableStyle())
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Empty state
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.white.opacity(0.05)).frame(width: 76, height: 76)
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Palette.accent)
            }
            VStack(spacing: 6) {
                Text(title).font(AppFont.title(18)).foregroundStyle(Palette.textPrimary)
                Text(message)
                    .font(AppFont.body(14))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.label(14))
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .overlay(Capsule().strokeBorder(Palette.accent.opacity(0.5)))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Stat tile
struct StatTile: View {
    let value: String
    let unit: String
    let caption: String
    var tint: Color = Palette.accent
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(AppFont.metric(26)).foregroundStyle(Palette.textPrimary)
                Text(unit).font(AppFont.label(12)).foregroundStyle(Palette.textSecondary)
            }
            Text(caption.uppercased())
                .font(AppFont.label(11)).tracking(0.8)
                .foregroundStyle(Palette.textFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(padding: 14)
        .overlay(alignment: .topTrailing) {
            Circle().fill(tint).frame(width: 7, height: 7).padding(12)
        }
    }
}

// MARK: - Field used in add/edit sheets
struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(AppFont.label(11)).tracking(1)
                .foregroundStyle(Palette.textFaint)
            content
        }
    }
}

struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Palette.textFaint))
            .font(AppFont.body(16))
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.stroke))
    }
}
