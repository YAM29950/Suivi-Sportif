import SwiftUI
import Combine

// MARK: - Models

struct WorkoutIntervalS5: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let zone: Zone
    let durationMinutes: Int
    let tips: [String]
    let bpmRange: String?

    var durationSeconds: Int { durationMinutes * 60 }

    enum Zone: String {
        case z1   = "Z1"
        case z2   = "Z2"
        case z3   = "Z3"

        var color: Color {
            switch self {
            case .z1: return Color(red: 0.29, green: 0.64, blue: 0.96)
            case .z2: return Color(red: 0.25, green: 0.84, blue: 0.60)
            case .z3: return Color(red: 1.0,  green: 0.45, blue: 0.25)
            }
        }

        var label: String { rawValue }

        var icon: String {
            switch self {
            case .z1: return "tortoise.fill"
            case .z2: return "figure.run"
            case .z3: return "bolt.fill"
            }
        }

        var intensity: String {
            switch self {
            case .z1: return "Faible"
            case .z2: return "Modérée"
            case .z3: return "Élevée"
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TempoS5ViewModel: ObservableObject {

    let sectionTitle = "FARTLEK Z2 ↔ Z3"
    let sectionSubtitle = "46 min • 6 blocs"

    let intervals: [WorkoutIntervalS5] = [
        WorkoutIntervalS5(
            name: "Échauffement",
            subtitle: "Préparer les filières aérobie et mixte",
            zone: .z1,
            durationMinutes: 10,
            tips: [
                "Home trainer ou elliptique",
                "Augmenter résistance par pallier / 2 min",
                "Ne pas dépasser 118 bpm en fin"
            ],
            bpmRange: "< 118 bpm"
        ),
        WorkoutIntervalS5(
            name: "Bloc 1 — Fartlek",
            subtitle: "Cardio intelligent, filière aérobie",
            zone: .z2,
            durationMinutes: 8,
            tips: [
                "Allure confortable et stable",
                "Respiration nasale si possible",
                "Home trainer, elliptique ou rameur"
            ],
            bpmRange: "116–127 bpm"
        ),
        WorkoutIntervalS5(
            name: "Bloc 2 — Fartlek",
            subtitle: "Brûle plus sans épuiser les surrénales",
            zone: .z3,
            durationMinutes: 5,
            tips: [
                "Montée naturelle, pas de sprint",
                "Alternance fartlek = pas d'intervalles fixes",
                "Maintenir la cadence"
            ],
            bpmRange: "127–138 bpm"
        ),
        WorkoutIntervalS5(
            name: "Bloc 3 — Fartlek",
            subtitle: "Retour à la filière aérobie",
            zone: .z2,
            durationMinutes: 8,
            tips: [
                "Redescendre naturellement",
                "Conserver le même appareil ou changer",
                "Respiration contrôlée"
            ],
            bpmRange: "116–127 bpm"
        ),
        WorkoutIntervalS5(
            name: "Bloc 4 — Fartlek",
            subtitle: "Dernier effort intense",
            zone: .z3,
            durationMinutes: 5,
            tips: [
                "Effort progressif, pas explosif",
                "Garder une technique propre",
                "Penser à la finition"
            ],
            bpmRange: "127–138 bpm"
        ),
        WorkoutIntervalS5(
            name: "Endurance Finition",
            subtitle: "Vider les réserves de glycogène",
            zone: .z2,
            durationMinutes: 10,
            tips: [
                "FC stable et continue",
                "Changer d'appareil si possible",
                "Maintenir respiration nasale"
            ],
            bpmRange: "116–127 bpm"
        ),
    ]

    @Published var currentIntervalIndex: Int = 0
    @Published var secondsRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false
    @Published var showTips: Bool = false
    @Published var showWarmupInfo: Bool = false
    @Published var showCooldownInfo: Bool = false

    private var timer: Timer?

    var totalDurationSeconds: Int { intervals.reduce(0) { $0 + $1.durationSeconds } }

    var elapsedSeconds: Int {
        let past = intervals.prefix(currentIntervalIndex).reduce(0) { $0 + $1.durationSeconds }
        return past + (currentInterval.durationSeconds - secondsRemaining)
    }

    var overallProgress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalDurationSeconds)
    }

    var currentInterval: WorkoutIntervalS5 { intervals[currentIntervalIndex] }

    var intervalProgress: Double {
        guard currentInterval.durationSeconds > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(currentInterval.durationSeconds)
    }

    var totalTimeString: String { formatTime(totalDurationSeconds) }

    // Identifier les blocs spéciaux
    var warmupInterval: WorkoutIntervalS5 { intervals[0] }
    var cooldownInterval: WorkoutIntervalS5 { intervals[5] }

    init() { reset() }

    func reset() {
        pause()
        currentIntervalIndex = 0
        secondsRemaining = intervals[0].durationSeconds
        isFinished = false
    }

    func toggleTimer() { isRunning ? pause() : start() }

    private func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard secondsRemaining > 0 else { advanceInterval(); return }
        secondsRemaining -= 1
    }

    private func advanceInterval() {
        if currentIntervalIndex < intervals.count - 1 {
            currentIntervalIndex += 1
            secondsRemaining = currentInterval.durationSeconds
        } else {
            pause()
            isFinished = true
        }
    }

    func skipToInterval(_ index: Int) {
        guard index < intervals.count else { return }
        currentIntervalIndex = index
        secondsRemaining = intervals[index].durationSeconds
    }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - View

struct ModalTemposamS5: View {

    @StateObject private var vm = TempoS5ViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.13),
                         Color(red: 0.09, green: 0.11, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection        .padding(.top, 20)
                    timerRingSection     .padding(.top, 24)
                    bpmBadge             .padding(.top, 12)
                    tipsSection          .padding(.top, 16).padding(.horizontal, 20)
                    specialBlocksSection .padding(.top, 20).padding(.horizontal, 20)
                    overallProgressBar   .padding(.horizontal, 24).padding(.top, 20)
                    controlsSection      .padding(.top, 24)
                    intervalsListSection .padding(.top, 28).padding(.bottom, 32)
                }
            }

            if vm.isFinished { finishOverlay }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private var headerSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 3) {
                Text(vm.sectionTitle)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
                    .kerning(2.5)
                Text(vm.sectionSubtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: { vm.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Timer Ring

    private var timerRingSection: some View {
        ZStack {
            // Glow
            Circle()
                .stroke(vm.currentInterval.zone.color.opacity(0.12), lineWidth: 32)
                .frame(width: 224, height: 224)
                .blur(radius: 14)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 10)
                .frame(width: 200, height: 200)

            // Arc
            Circle()
                .trim(from: 0, to: vm.intervalProgress)
                .stroke(
                    LinearGradient(
                        colors: [vm.currentInterval.zone.color,
                                 vm.currentInterval.zone.color.opacity(0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: vm.intervalProgress)

            // Center
            VStack(spacing: 5) {
                Image(systemName: vm.currentInterval.zone.icon)
                    .font(.system(size: 20))
                    .foregroundColor(vm.currentInterval.zone.color)

                Text(vm.formatTime(vm.secondsRemaining))
                    .font(.system(size: 46, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(vm.currentInterval.zone.label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(vm.currentInterval.zone.color)
                    .kerning(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(vm.currentInterval.zone.color.opacity(0.16))
                    .clipShape(Capsule())

                Text(vm.currentInterval.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 130)
            }
        }
    }

    // MARK: BPM Badge

    private var bpmBadge: some View {
        Group {
            if let bpm = vm.currentInterval.bpmRange {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(vm.currentInterval.zone.color)
                    Text(bpm)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(vm.currentInterval.zone.color.opacity(0.12))
                .overlay(
                    Capsule().stroke(vm.currentInterval.zone.color.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Tips Section

    private var tipsSection: some View {
        VStack(spacing: 0) {
            // Toggle header
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { vm.showTips.toggle() } }) {
                HStack {
                    Text(vm.currentInterval.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .italic()
                    Spacer()
                    Image(systemName: vm.showTips ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: vm.showTips ? 12 : 12,
                                            style: .continuous))
            }
            .buttonStyle(.plain)

            if vm.showTips {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.currentInterval.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(vm.currentInterval.zone.color)
                                .frame(width: 5, height: 5)
                                .padding(.top, 5)
                            Text(tip)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Special Blocks Section (Warmup & Cooldown)

    private var specialBlocksSection: some View {
        VStack(spacing: 12) {
            // Échauffement
            SpecialBlockCard(
                title: "⚡️ Échauffement",
                subtitle: "Préparer les filières aérobie et mixte",
                duration: "10 min",
                zone: vm.warmupInterval.zone,
                tips: [
                    "10 min home trainer ou elliptique en Z1",
                    "Augmenter la résistance par pallier toutes les 2 min",
                    "Ne pas dépasser 118 bpm en fin d'échauffement"
                ],
                isExpanded: $vm.showWarmupInfo
            )

            // Bloc Endurance de Finition
            SpecialBlockCard(
                title: "⚡️ Bloc Endurance de Finition",
                subtitle: "Vider les réserves de glycogène restantes",
                duration: "10 min",
                zone: vm.cooldownInterval.zone,
                tips: [
                    "10 min Z2 continue à FC stable",
                    "Changer d'appareil si possible (motor memory reset)",
                    "Maintenir une respiration nasale si possible"
                ],
                isExpanded: $vm.showCooldownInfo
            )
        }
    }

    // MARK: Progress Bar

    private var overallProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROGRESSION TOTALE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .kerning(2)
                Spacer()
                Text(vm.totalTimeString)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.29, green: 0.64, blue: 0.96),
                                     Color(red: 0.25, green: 0.84, blue: 0.60),
                                     Color(red: 1.0,  green: 0.45, blue: 0.25)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * vm.overallProgress, height: 5)
                        .animation(.linear(duration: 0.5), value: vm.overallProgress)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: Controls

    private var controlsSection: some View {
        HStack(spacing: 20) {
            Button(action: {
                if vm.currentIntervalIndex > 0 { vm.skipToInterval(vm.currentIntervalIndex - 1) }
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 17))
                    .foregroundColor(vm.currentIntervalIndex > 0 ? .white : .white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == 0)

            Button(action: { vm.toggleTimer() }) {
                ZStack {
                    Circle()
                        .fill(vm.currentInterval.zone.color)
                        .frame(width: 70, height: 70)
                        .shadow(color: vm.currentInterval.zone.color.opacity(0.45), radius: 18)
                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                        .offset(x: vm.isRunning ? 0 : 2)
                }
            }
            .animation(.spring(response: 0.3), value: vm.isRunning)

            Button(action: {
                let next = vm.currentIntervalIndex + 1
                if next < vm.intervals.count { vm.skipToInterval(next) }
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 17))
                    .foregroundColor(vm.currentIntervalIndex < vm.intervals.count - 1 ? .white : .white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == vm.intervals.count - 1)
        }
    }

    // MARK: Intervals List

    private var intervalsListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGRAMME")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .kerning(3)
                .padding(.horizontal, 20)

            ForEach(Array(vm.intervals.enumerated()), id: \.element.id) { index, interval in
                S5IntervalRowView(
                    interval: interval,
                    index: index,
                    isCurrent: index == vm.currentIntervalIndex,
                    isDone: index < vm.currentIntervalIndex
                )
                .onTapGesture { vm.skipToInterval(index) }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Finish Overlay

    private var finishOverlay: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea().transition(.opacity)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(red: 0.25, green: 0.84, blue: 0.60))

                Text("SÉANCE TERMINÉE !")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(2)

                VStack(spacing: 6) {
                    Text("46 min · Fartlek Z2 ↔ Z3")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Excellent travail 💪")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.65))
                }

                Button(action: { vm.reset() }) {
                    Text("Recommencer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 170, height: 46)
                        .background(Color(red: 0.25, green: 0.84, blue: 0.60).opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 23)
                                .stroke(Color(red: 0.25, green: 0.84, blue: 0.60), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: vm.isFinished)
    }
}

// MARK: - Special Block Card

struct SpecialBlockCard: View {
    let title: String
    let subtitle: String
    let duration: String
    let zone: WorkoutIntervalS5.Zone
    let tips: [String]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(zone.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: zone.icon)
                            .font(.system(size: 14))
                            .foregroundColor(zone.color)
                    }

                    // Title & subtitle
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .italic()
                    }

                    Spacer()

                    // Duration
                    Text(duration)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(zone.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(zone.color.opacity(0.12))
                        .clipShape(Capsule())

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(zone.color.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded tips
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 5, height: 5)
                                .padding(.top, 5)
                            Text(tip)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Interval Row

struct S5IntervalRowView: View {
    let interval: WorkoutIntervalS5
    let index: Int
    let isCurrent: Bool
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Index / check
            ZStack {
                Circle()
                    .fill(isCurrent
                          ? interval.zone.color
                          : (isDone ? Color.white.opacity(0.10) : Color.white.opacity(0.05)))
                    .frame(width: 32, height: 32)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrent ? .white : .white.opacity(0.35))
                }
            }

            // Name + zone
            VStack(alignment: .leading, spacing: 2) {
                Text(interval.name)
                    .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(isCurrent ? .white : .white.opacity(isDone ? 0.3 : 0.70))
                HStack(spacing: 4) {
                    Circle()
                        .fill(interval.zone.color)
                        .frame(width: 5, height: 5)
                    Text(interval.zone.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(interval.zone.color.opacity(isDone ? 0.45 : 0.9))
                    if let bpm = interval.bpmRange {
                        Text("· \(bpm)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(isDone ? 0.2 : 0.35))
                    }
                }
            }

            Spacer()

            Text("\(interval.durationMinutes) min")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(isCurrent ? .white : .white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? interval.zone.color.opacity(0.10) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? interval.zone.color.opacity(0.30) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
}

// MARK: - Preview

#Preview {
    ModalTemposamS5()
}
