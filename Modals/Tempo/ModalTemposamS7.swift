import SwiftUI
import Combine

// MARK: - Models

struct WorkoutIntervalS7: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let zone: Zone
    let durationMinutes: Int
    let tips: [String]
    let bpmRange: String?
    let warning: String?

    var durationSeconds: Int { durationMinutes * 60 }

    init(name: String, subtitle: String, zone: Zone, durationMinutes: Int,
         tips: [String], bpmRange: String? = nil, warning: String? = nil) {
        self.name = name
        self.subtitle = subtitle
        self.zone = zone
        self.durationMinutes = durationMinutes
        self.tips = tips
        self.bpmRange = bpmRange
        self.warning = warning
    }

    enum Zone: String {
        case z1    = "Z1"
        case z2    = "Z2"
        case z3    = "Z3"
        case calme = "Calme"

        var color: Color {
            switch self {
            case .z1:    return Color(red: 0.29, green: 0.64, blue: 0.96)
            case .z2:    return Color(red: 0.25, green: 0.84, blue: 0.60)
            case .z3:    return Color(red: 1.0,  green: 0.45, blue: 0.25)
            case .calme: return Color(red: 0.72, green: 0.55, blue: 0.98)
            }
        }

        var label: String { rawValue }

        var icon: String {
            switch self {
            case .z1:    return "tortoise.fill"
            case .z2:    return "figure.run"
            case .z3:    return "bolt.fill"
            case .calme: return "leaf.fill"
            }
        }
    }
}

// MARK: - Section grouping

struct WorkoutSection {
    let title: String
    let subtitle: String
    let intervalIndices: [Int]
}

// MARK: - ViewModel

@MainActor
final class TempoS7ViewModel: ObservableObject {

    let sessionTitle  = "FARTLEK ÉTENDU Z2↔Z3"
    let sessionDetail = "75 min • 9 blocs • 3 tours"

    let intervals: [WorkoutIntervalS7] = [
        // 1 — Échauffement
        WorkoutIntervalS7(
            name: "Échauffement",
            subtitle: "Préparer les filières aérobie et mixte",
            zone: .z1,
            durationMinutes: 15,
            tips: [
                "15 min home trainer ou elliptique en Z1",
                "Augmenter la résistance par pallier toutes les 3 min",
                "Ne pas dépasser 118 bpm en fin d'échauffement"
            ],
            bpmRange: "< 118 bpm"
        ),
        // 2 — Bloc 1
        WorkoutIntervalS7(
            name: "Bloc 1 — Z2",
            subtitle: "Cardio intelligent — filière aérobie",
            zone: .z2,
            durationMinutes: 8,
            tips: [
                "Allure confortable et stable",
                "Home trainer, elliptique ou rameur",
                "Respiration nasale si possible"
            ],
            bpmRange: "116–127 bpm"
        ),
        // 3 — Bloc 2
        WorkoutIntervalS7(
            name: "Bloc 2 — Z3",
            subtitle: "Brûle plus sans épuiser les surrénales",
            zone: .z3,
            durationMinutes: 5,
            tips: [
                "Montée naturelle, pas de sprint",
                "Alterner les appareils si possible",
                "Maintenir la cadence"
            ],
            bpmRange: "127–138 bpm"
        ),
        // 4 — Bloc 3
        WorkoutIntervalS7(
            name: "Bloc 3 — Z2",
            subtitle: "Retour à la filière aérobie",
            zone: .z2,
            durationMinutes: 8,
            tips: [
                "Redescendre naturellement",
                "Respiration contrôlée",
                "Méthode fartlek = alternance naturelle"
            ],
            bpmRange: "116–127 bpm"
        ),
        // 5 — Bloc 4
        WorkoutIntervalS7(
            name: "Bloc 4 — Z3",
            subtitle: "Deuxième effort intense",
            zone: .z3,
            durationMinutes: 5,
            tips: [
                "Effort progressif, pas explosif",
                "Garder une technique propre",
                "Pas d'intervalles fixes — aller au ressenti"
            ],
            bpmRange: "127–138 bpm"
        ),
        // 6 — Bloc 5 (tour supplémentaire)
        WorkoutIntervalS7(
            name: "Bloc 5 — Z2 ★",
            subtitle: "Tour supplémentaire — filière aérobie",
            zone: .z2,
            durationMinutes: 8,
            tips: [
                "Tour bonus — rester régulier",
                "Changer d'appareil si possible",
                "FC stable, ne pas forcer"
            ],
            bpmRange: "116–127 bpm"
        ),
        // 7 — Bloc 6 (tour supplémentaire)
        WorkoutIntervalS7(
            name: "Bloc 6 — Z3 ★",
            subtitle: "Tour supplémentaire — dernier effort",
            zone: .z3,
            durationMinutes: 5,
            tips: [
                "Dernier effort soutenu",
                "Rester technique sous la fatigue",
                "Préparer la finition mentalement"
            ],
            bpmRange: "127–138 bpm"
        ),
        // 8 — Endurance finition
        WorkoutIntervalS7(
            name: "Endurance Finition",
            subtitle: "Vider les réserves de glycogène",
            zone: .z2,
            durationMinutes: 15,
            tips: [
                "15 min Z2 continue à FC stable",
                "Changer d'appareil si possible (motor memory reset)",
                "Maintenir une respiration nasale si possible"
            ],
            bpmRange: "116–127 bpm"
        ),
        // 9 — Retour au calme + mobilité
        WorkoutIntervalS7(
            name: "Retour au Calme",
            subtitle: "Récupération complète post-fartlek",
            zone: .calme,
            durationMinutes: 6,
            tips: [
                "6 min marche ou pédalage Z1 très léger",
                "Étirements statiques : quadriceps 30s, fléchisseurs hanche 30s, mollets 30s",
                "Massage rouleau si disponible : mollets, TFL, ischios"
            ],
            bpmRange: nil,
            warning: "⚠️ Ne pas s'arrêter brusquement après le Z3"
        ),
    ]

    @Published var currentIntervalIndex: Int = 0
    @Published var secondsRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false
    @Published var expandedIndex: Int? = nil

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

    var currentInterval: WorkoutIntervalS7 { intervals[currentIntervalIndex] }

    var intervalProgress: Double {
        guard currentInterval.durationSeconds > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(currentInterval.durationSeconds)
    }

    var totalTimeString: String { formatTime(totalDurationSeconds) }

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
            expandedIndex = nil
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

    func toggleExpand(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            expandedIndex = expandedIndex == index ? nil : index
        }
    }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - View

struct ModalTemposamS7: View {

    @StateObject private var vm = TempoS7ViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.07, blue: 0.13),
                         Color(red: 0.09, green: 0.10, blue: 0.17)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection          .padding(.top, 20)
                    timerRingSection       .padding(.top, 22)
                    bpmBadgeAndWarning     .padding(.top, 10)
                    overallProgressBar     .padding(.horizontal, 24).padding(.top, 18)
                    tourIndicator          .padding(.top, 14)
                    controlsSection        .padding(.top, 20)
                    intervalsListSection   .padding(.top, 24).padding(.bottom, 32)
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
                Text(vm.sessionTitle)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(2)
                Text(vm.sessionDetail)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: { vm.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
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
            Circle()
                .stroke(vm.currentInterval.zone.color.opacity(0.12), lineWidth: 30)
                .frame(width: 216, height: 216)
                .blur(radius: 14)

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 9)
                .frame(width: 196, height: 196)

            Circle()
                .trim(from: 0, to: vm.intervalProgress)
                .stroke(
                    LinearGradient(
                        colors: [vm.currentInterval.zone.color,
                                 vm.currentInterval.zone.color.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .frame(width: 196, height: 196)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: vm.intervalProgress)

            VStack(spacing: 5) {
                Image(systemName: vm.currentInterval.zone.icon)
                    .font(.system(size: 20))
                    .foregroundColor(vm.currentInterval.zone.color)

                Text(vm.formatTime(vm.secondsRemaining))
                    .font(.system(size: 44, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(vm.currentInterval.zone.label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(vm.currentInterval.zone.color)
                    .kerning(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(vm.currentInterval.zone.color.opacity(0.15))
                    .clipShape(Capsule())

                Text(vm.currentInterval.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 130)
            }
        }
    }

    // MARK: BPM + Warning

    private var bpmBadgeAndWarning: some View {
        VStack(spacing: 8) {
            if let bpm = vm.currentInterval.bpmRange {
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(vm.currentInterval.zone.color)
                    Text(bpm)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(vm.currentInterval.zone.color.opacity(0.11))
                .overlay(Capsule().stroke(vm.currentInterval.zone.color.opacity(0.28), lineWidth: 1))
                .clipShape(Capsule())
            }

            if let warning = vm.currentInterval.warning {
                HStack(spacing: 6) {
                    Text("⚠️")
                        .font(.system(size: 11))
                    Text(warning)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.35))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(red: 1.0, green: 0.82, blue: 0.35).opacity(0.08))
                .overlay(
                    Capsule().stroke(Color(red: 1.0, green: 0.82, blue: 0.35).opacity(0.25), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
    }

    // MARK: Tour Indicator

    private var tourIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { tour in
                let tourIntervals = [1, 2, 3, 4, 5, 6]
                let tourStart = tour * 2 + 1
                let tourEnd   = tourStart + 1
                let isDone    = vm.currentIntervalIndex > tourEnd
                let isActive  = vm.currentIntervalIndex == tourStart || vm.currentIntervalIndex == tourStart + 1

                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        ForEach(tourStart...tourEnd, id: \.self) { i in
                            let _ = tourIntervals
                            let segDone = vm.currentIntervalIndex > i
                            let segActive = vm.currentIntervalIndex == i
                            RoundedRectangle(cornerRadius: 2)
                                .fill(segActive
                                      ? vm.intervals[i].zone.color
                                      : (segDone ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                                .frame(width: 28, height: 5)
                        }
                    }
                    Text("Tour \(tour + 1)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(isActive ? .white.opacity(0.7) : (isDone ? .white.opacity(0.3) : .white.opacity(0.2)))
                }
            }

            // Finition
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(vm.currentIntervalIndex == 7
                          ? vm.intervals[7].zone.color
                          : (vm.currentIntervalIndex > 7 ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                    .frame(width: 28, height: 5)
                Text("Fin")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(vm.currentIntervalIndex >= 7 ? .white.opacity(0.6) : .white.opacity(0.2))
            }

            // Calme
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(vm.currentIntervalIndex == 8
                          ? vm.intervals[8].zone.color
                          : (vm.currentIntervalIndex > 8 ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                    .frame(width: 28, height: 5)
                Text("Calme")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(vm.currentIntervalIndex >= 8 ? .white.opacity(0.6) : .white.opacity(0.2))
            }
        }
    }

    // MARK: Progress Bar

    private var overallProgressBar: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("PROGRESSION TOTALE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.28))
                    .kerning(2)
                Spacer()
                Text(vm.totalTimeString)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.38))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.64, blue: 0.96),
                                Color(red: 0.25, green: 0.84, blue: 0.60),
                                Color(red: 1.0,  green: 0.45, blue: 0.25),
                                Color(red: 0.72, green: 0.55, blue: 0.98)
                            ],
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
        HStack(spacing: 18) {
            Button(action: {
                if vm.currentIntervalIndex > 0 { vm.skipToInterval(vm.currentIntervalIndex - 1) }
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
                    .foregroundColor(vm.currentIntervalIndex > 0 ? .white : .white.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == 0)

            Button(action: { vm.toggleTimer() }) {
                ZStack {
                    Circle()
                        .fill(vm.currentInterval.zone.color)
                        .frame(width: 68, height: 68)
                        .shadow(color: vm.currentInterval.zone.color.opacity(0.4), radius: 18)
                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
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
                    .font(.system(size: 16))
                    .foregroundColor(vm.currentIntervalIndex < vm.intervals.count - 1 ? .white : .white.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == vm.intervals.count - 1)
        }
    }

    // MARK: Intervals List

    private var intervalsListSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("PROGRAMME")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.28))
                .kerning(3)
                .padding(.horizontal, 20)

            ForEach(Array(vm.intervals.enumerated()), id: \.element.id) { index, interval in
                S7IntervalRowView(
                    vm: vm,
                    interval: interval,
                    index: index,
                    isCurrent: index == vm.currentIntervalIndex,
                    isDone: index < vm.currentIntervalIndex,
                    isExpanded: vm.expandedIndex == index
                )
                .onTapGesture { vm.toggleExpand(index) }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Finish Overlay

    private var finishOverlay: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea().transition(.opacity)

            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 68))
                    .foregroundColor(Color(red: 0.72, green: 0.55, blue: 0.98))

                Text("SÉANCE TERMINÉE !")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(2)

                VStack(spacing: 5) {
                    Text("75 min · Fartlek étendu Z2↔Z3")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                    Text("3 tours complets + finition 💜")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Button(action: { vm.reset() }) {
                    Text("Recommencer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 165, height: 44)
                        .background(Color(red: 0.72, green: 0.55, blue: 0.98).opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color(red: 0.72, green: 0.55, blue: 0.98), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: vm.isFinished)
    }
}

// MARK: - Interval Row

struct S7IntervalRowView: View {
    @ObservedObject var vm: TempoS7ViewModel
    let interval: WorkoutIntervalS7
    let index: Int
    let isCurrent: Bool
    let isDone: Bool
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 11) {
                // Index / check
                ZStack {
                    Circle()
                        .fill(isCurrent
                              ? interval.zone.color
                              : (isDone ? Color.white.opacity(0.09) : Color.white.opacity(0.04)))
                        .frame(width: 30, height: 30)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isCurrent ? .white : .white.opacity(0.3))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(interval.name)
                        .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? .white : .white.opacity(isDone ? 0.28 : 0.68))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(interval.zone.color)
                            .frame(width: 5, height: 5)
                        Text(interval.zone.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(interval.zone.color.opacity(isDone ? 0.4 : 0.9))
                        if let bpm = interval.bpmRange {
                            Text("· \(bpm)")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(isDone ? 0.18 : 0.32))
                        }
                    }
                }

                Spacer()

                Text("\(interval.durationMinutes) min")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(isCurrent ? .white : .white.opacity(0.28))

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)

            // Expanded tips
            if isExpanded {
                VStack(alignment: .leading, spacing: 7) {
                    Divider().background(Color.white.opacity(0.07))
                        .padding(.horizontal, 11)

                    Text(interval.subtitle)
                        .font(.system(size: 11).italic())
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 11)

                    ForEach(interval.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 7) {
                            Circle()
                                .fill(interval.zone.color)
                                .frame(width: 4, height: 4)
                                .padding(.top, 5)
                            Text(tip)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.62))
                        }
                        .padding(.horizontal, 11)
                    }

                    if let warning = interval.warning {
                        HStack(spacing: 5) {
                            Text("⚠️").font(.system(size: 11))
                            Text(warning)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.35))
                        }
                        .padding(.horizontal, 11)
                        .padding(.bottom, 2)
                    }
                }
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? interval.zone.color.opacity(0.09) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? interval.zone.color.opacity(0.28) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
}

// MARK: - Preview

#Preview {
    ModalTemposamS7()
}
