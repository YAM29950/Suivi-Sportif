import SwiftUI
import Combine

// MARK: - Models

struct WorkoutInterval: Identifiable {
    let id = UUID()
    let name: String
    let zone: Zone
    let durationMinutes: Int

    var durationSeconds: Int { durationMinutes * 60 }

    enum Zone: String {
        case z1   = "Z1"
        case z2   = "Z2"
        case z1z2 = "Z1 → Z2"
        case z3   = "Z3"

        var color: Color {
            switch self {
            case .z1:   return Color(red: 0.29, green: 0.64, blue: 0.96)
            case .z2:   return Color(red: 0.25, green: 0.84, blue: 0.60)
            case .z1z2: return Color(red: 0.29, green: 0.75, blue: 0.80)
            case .z3:   return Color(red: 1.0,  green: 0.45, blue: 0.25)
            }
        }

        var label: String { rawValue }

        var icon: String {
            switch self {
            case .z1:   return "tortoise.fill"
            case .z2:   return "figure.run"
            case .z1z2: return "arrow.up.right"
            case .z3:   return "bolt.fill"
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TempoWorkoutViewModel: ObservableObject {

    let intervals: [WorkoutInterval] = [
        WorkoutInterval(name: "Échauffement",    zone: .z1z2, durationMinutes: 15),
        WorkoutInterval(name: "Bloc 1",          zone: .z3,   durationMinutes: 10),
        WorkoutInterval(name: "Récupération",    zone: .z1,   durationMinutes:  5),
        WorkoutInterval(name: "Bloc 2",          zone: .z3,   durationMinutes: 10),
        WorkoutInterval(name: "Retour au calme", zone: .z2,   durationMinutes: 15),
        WorkoutInterval(name: "Cool-down",       zone: .z1,   durationMinutes: 15),
    ]

    @Published var currentIntervalIndex: Int = 0
    @Published var secondsRemaining: Int = 0
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false

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

    var currentInterval: WorkoutInterval { intervals[currentIntervalIndex] }

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

struct ModalTemposamS2: View {

    @StateObject private var vm = TempoWorkoutViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.07, blue: 0.12),
                         Color(red: 0.10, green: 0.10, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection    .padding(.top, 20)
                    timerRingSection .padding(.top, 24)
                    overallProgressBar
                        .padding(.horizontal, 28)
                        .padding(.top, 20)
                    controlsSection  .padding(.top, 24)
                    intervalsListSection
                        .padding(.top, 28)
                        .padding(.bottom, 32)
                }
            }

            if vm.isFinished { finishOverlay }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private var headerSection: some View {
        ZStack {
            // Texte centré absolument dans tout l'espace disponible
            VStack(spacing: 2) {
                Text("S2 SAMEDI")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.92))
                    .kerning(2.5)
                Text("70 min • 6 blocs")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Boutons sur les bords, superposés sans affecter le centrage
            HStack {
                // Placeholder transparent de même taille que le bouton reset,
                // pour que le ZStack soit bien symétrique
                Color.clear
                    .frame(width: 36, height: 36)

                Spacer()

                Button(action: { vm.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Timer Ring

    private var timerRingSection: some View {
        ZStack {
            Circle()
                .stroke(vm.currentInterval.zone.color.opacity(0.15), lineWidth: 28)
                .frame(width: 220, height: 220)
                .blur(radius: 12)

            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 10)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: vm.intervalProgress)
                .stroke(
                    LinearGradient(
                        colors: [vm.currentInterval.zone.color,
                                 vm.currentInterval.zone.color.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: vm.intervalProgress)

            VStack(spacing: 6) {
                Image(systemName: vm.currentInterval.zone.icon)
                    .font(.system(size: 22))
                    .foregroundColor(vm.currentInterval.zone.color)

                Text(vm.formatTime(vm.secondsRemaining))
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(vm.currentInterval.zone.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(vm.currentInterval.zone.color)
                    .kerning(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(vm.currentInterval.zone.color.opacity(0.18))
                    .clipShape(Capsule())

                Text(vm.currentInterval.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    // MARK: Progress Bar

    private var overallProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROGRESSION TOTALE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.35))
                    .kerning(2)
                Spacer()
                Text(vm.totalTimeString)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.29, green: 0.64, blue: 0.96),
                                     Color(red: 1.0,  green: 0.45, blue: 0.25)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * vm.overallProgress, height: 6)
                        .animation(.linear(duration: 0.5), value: vm.overallProgress)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Controls

    private var controlsSection: some View {
        HStack(spacing: 20) {
            Button(action: {
                if vm.currentIntervalIndex > 0 {
                    vm.skipToInterval(vm.currentIntervalIndex - 1)
                }
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18))
                    .foregroundColor(vm.currentIntervalIndex > 0 ? .white : .white.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == 0)

            Button(action: { vm.toggleTimer() }) {
                ZStack {
                    Circle()
                        .fill(vm.currentInterval.zone.color)
                        .frame(width: 72, height: 72)
                        .shadow(color: vm.currentInterval.zone.color.opacity(0.5), radius: 16)
                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
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
                    .font(.system(size: 18))
                    .foregroundColor(vm.currentIntervalIndex < vm.intervals.count - 1 ? .white : .white.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .disabled(vm.currentIntervalIndex == vm.intervals.count - 1)
        }
    }

    // MARK: Intervals List

    private var intervalsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRAMME")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .kerning(3)
                .padding(.horizontal, 20)

            ForEach(Array(vm.intervals.enumerated()), id: \.element.id) { index, interval in
                IntervalRowView(
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
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Color(red: 0.25, green: 0.84, blue: 0.60))

                Text("SÉANCE TERMINÉE !")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(2)

                Text("Excellent travail 💪")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))

                Button(action: { vm.reset() }) {
                    Text("Recommencer")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 180, height: 48)
                        .background(Color(red: 0.25, green: 0.84, blue: 0.60).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
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

// MARK: - Interval Row

struct IntervalRowView: View {
    let interval: WorkoutInterval
    let index: Int
    let isCurrent: Bool
    let isDone: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCurrent ? interval.zone.color : (isDone ? Color.white.opacity(0.12) : Color.white.opacity(0.06)))
                    .frame(width: 34, height: 34)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrent ? .white : .white.opacity(0.4))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(interval.name)
                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                    .foregroundColor(isCurrent ? .white : .white.opacity(isDone ? 0.35 : 0.75))
                HStack(spacing: 4) {
                    Circle()
                        .fill(interval.zone.color)
                        .frame(width: 6, height: 6)
                    Text(interval.zone.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(interval.zone.color.opacity(isDone ? 0.5 : 1.0))
                }
            }

            Spacer()

            Text("\(interval.durationMinutes) min")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(isCurrent ? .white : .white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrent ? interval.zone.color.opacity(0.12) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isCurrent ? interval.zone.color.opacity(0.35) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isCurrent)
    }
}

// MARK: - Preview

#Preview {
    ModalTemposamS2()
}
