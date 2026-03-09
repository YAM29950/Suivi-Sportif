import SwiftUI
import SDWebImageSwiftUI

// MARK: - Modèle de données

struct WorkoutSession: Identifiable {
    let id: String
    let day: String
    let title: String
    let duration: String
    let blocks: [WorkoutBlock]
    let nutritionTip: String
}

struct WorkoutBlock: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let fcZone: String?
    let details: [String]
}

struct CompletedSession: Codable, Identifiable {
    let id = UUID()
    let sessionId: String
    let week: Int
    let date: Date
    var notes: String?
}

// MARK: - Vue principale

struct TrainingPlanView: View {
    @State private var selectedWeek: Int = 1
    @State private var expandedSession: String? = nil
    @AppStorage("completedSessions") private var completedSessionsData: Data = Data()
    @AppStorage("fcMax")  private var fcMax:  Int = 163
    @AppStorage("fcRest") private var fcRest: Int = 60
    @State private var completedSessions: [CompletedSession] = []
    @State private var deletedSessions:   [CompletedSession] = []
    @State private var showCalendar    = false
    @State private var isLayoutReady   = false
    @State private var showDatePicker  = false
    @State private var showFCSettings  = false
    @State private var selectedSessionForDate: (session: WorkoutSession, week: Int)? = nil
    @State private var fcMaxInput:  String = ""
    @State private var fcRestInput: String = ""
    @State private var animate:     Bool   = false

    // ── affichage GIF Dead Bug ──────────────────────────────────────
    @State private var showDeadBugGif = false
    // ── affichage GIF Pont Fessier ──────────────────────────────────
    @State private var showPontFessierGif = false
    // ── affichage GIF Mountain Climbers ─────────────────────────────
    @State private var showMountainClimbersGif = false
    // ── affichage GIF Burpees ───────────────────────────────────────
    @State private var showBurpeesGif = false
    // ── affichage GIF Kettlebell Swing ───────────────────────────────
    @State private var showKettlebellSwingGif = false
    // ── affichage GIF Squat Jump ─────────────────────────────────────
    @State private var showSquatJumpGif = false
    // ── affichage GIF Fentes ─────────────────────────────────────────
    @State private var showFentesGif = false

    let weeks = [1, 2, 3, 4, 5, 6, 7, 8]

    // MARK: - Karvonen

    private var hrr: Int { max(fcMax - fcRest, 1) }

    private func karvonen(_ pct: Double) -> Int {
        Int(Double(hrr) * pct) + fcRest
    }

    private func zoneFC(_ zone: Int) -> String {
        switch zone {
        case 1: return "Z1: \(karvonen(0.50))–\(karvonen(0.60)) bpm"
        case 2: return "Z2: \(karvonen(0.60))–\(karvonen(0.70)) bpm"
        case 3: return "Z3: \(karvonen(0.70))–\(karvonen(0.80)) bpm"
        case 4: return "Z4: \(karvonen(0.80))–\(karvonen(0.90)) bpm"
        default: return ""
        }
    }

    private var zoneZ1Z2: String {
        "Z1-Z2: \(karvonen(0.50))–\(karvonen(0.70)) bpm"
    }

    private var alertBpm: Int { karvonen(0.80) }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return .green
        case 2: return .blue
        case 3: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case 4: return .orange
        case 5: return .red
        default: return .white
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.8)]),
                startPoint: .bottom, endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                weekSelector
                ScrollView {
                    VStack(spacing: 20) {
                        if showCalendar { calendarView }
                        weekDescription
                        ForEach(workoutsForWeek(selectedWeek)) { session in
                            sessionCard(session)
                        }
                        HStack(alignment: .top, spacing: 20) {
                            fcWidget
                            nutritionCard
                            trackingCard
                        }
                        .frame(maxWidth: 1260)
                    }
                    .frame(maxWidth: .infinity)
                    .id(selectedWeek)
                    .padding(16)
                    .layoutPriority(1)
                }
                .animation(isLayoutReady ? .default : .none, value: selectedWeek)
            }

            if showFCSettings {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { showFCSettings = false }
                fcSettingsPopup
            }

            if showDatePicker, let info = selectedSessionForDate {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { showDatePicker = false }
                datePickerPopup(session: info.session, week: info.week)
            }
        }
        .onAppear {
            loadCompletedSessions()
            fcMaxInput  = "\(fcMax)"
            fcRestInput = "\(fcRest)"
            DispatchQueue.main.async { isLayoutReady = true }
        }
    }

    // MARK: - Widget FC

    private var fcWidget: some View {
        Button(action: {
            fcMaxInput  = "\(fcMax)"
            fcRestInput = "\(fcRest)"
            showFCSettings = true
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    AnimatedImage(name: "cardio2").resizable().scaledToFit()
                        .frame(width: 76, height: 76)
                    Text("Max \(fcMax) bpm").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
                HStack(spacing: 5) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.cyan)
                        .scaleEffect(animate ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                        .onAppear { animate = true }
                        .frame(width: 76, height: 76)
                    Text("Repos \(fcRest) bpm").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
                Text("HRR \(hrr) bpm")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white.opacity(0.12)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.5), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Popup réglages FC

    private var fcSettingsPopup: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill").font(.system(size: 24)).foregroundColor(.red)
                Text("Réglage des Fréquences Cardiaques")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("Méthode Karvonen")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.yellow)
                Text("Zone = ((FCmax − FCrepos) × %) + FCrepos")
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(10).background(Color.yellow.opacity(0.1)).cornerRadius(8)

            fcInputRow(label: "FC Maximale", sublabel: "Méthode conseillée : test terrain ou 220 − âge",
                icon: "arrow.up.heart.fill", color: .red, value: $fcMax, text: $fcMaxInput, min: 140, max: 220)
            fcInputRow(label: "FC de Repos", sublabel: "Mesurer le matin, avant de se lever",
                icon: "moon.zzz.fill", color: .blue, value: $fcRest, text: $fcRestInput, min: 35, max: 100)

            HStack(spacing: 8) {
                Image(systemName: "gauge.medium").foregroundColor(.purple)
                Text("Réserve cardiaque (HRR) : \(hrr) bpm")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
            }
            .padding(10).frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.2)).cornerRadius(8)

            VStack(spacing: 6) {
                Text("Zones d'entraînement (Karvonen)")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.7))

                let zones: [(Int, String, String, String)] = [
                    (1, "Z1", "Echauffement",               "\(karvonen(0.50))–\(karvonen(0.60)) bpm"),
                    (2, "Z2", "Endurance fondamentale",     "\(karvonen(0.60))–\(karvonen(0.70)) bpm"),
                    (3, "Z3", "Résistance douce Aérobie",   "\(karvonen(0.70))–\(karvonen(0.80)) bpm"),
                    (4, "Z4", "Résistance dure Seuil",      "\(karvonen(0.80))–\(karvonen(0.90)) bpm"),
                    (5, "Z5", "VMA Maximum",                "\(karvonen(0.90))–\(fcMax) bpm"),
                ]

                ForEach(zones, id: \.0) { z, label, name, range in
                    HStack(spacing: 10) {
                        Text(label)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(zoneColor(z))
                            .cornerRadius(8)
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(range)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(zoneColor(z).opacity(0.25))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(zoneColor(z).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(zoneColor(z).opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(zoneColor(z).opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Button("Fermer") { showFCSettings = false }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Color.blue.opacity(0.6)).cornerRadius(12)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.08, green: 0.12, blue: 0.30).opacity(0.98))
            .shadow(color: .black.opacity(0.5), radius: 24))
        .frame(maxWidth: 420).padding(40)
    }

    private func fcInputRow(label: String, sublabel: String, icon: String, color: Color,
        value: Binding<Int>, text: Binding<String>, min: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(sublabel).font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
                }
            }
            HStack(spacing: 14) {
                Button(action: { if value.wrappedValue > min { value.wrappedValue -= 1; text.wrappedValue = "\(value.wrappedValue)" } }) {
                    Image(systemName: "minus.circle.fill").font(.system(size: 32)).foregroundColor(color.opacity(0.85))
                }.buttonStyle(.plain)
                TextField("", text: text)
                    .font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                    .multilineTextAlignment(.center).frame(width: 76)
                    .padding(8).background(Color.white.opacity(0.12)).cornerRadius(10)
                    .onChange(of: text.wrappedValue) { v in if let i = Int(v), i >= min, i <= max { value.wrappedValue = i } }
                Text("bpm").font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.6))
                Button(action: { if value.wrappedValue < max { value.wrappedValue += 1; text.wrappedValue = "\(value.wrappedValue)" } }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 32)).foregroundColor(color.opacity(0.85))
                }.buttonStyle(.plain)
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(color)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(color.opacity(0.2)).cornerRadius(10)
            }
        }
        .padding(14).background(Color.white.opacity(0.07)).cornerRadius(12)
    }

    // MARK: - Date Picker Popup

    private func datePickerPopup(session: WorkoutSession, week: Int) -> some View {
        VStack(spacing: 12) {
            Text("Date de réalisation").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(session.day + " - " + session.title).font(.system(size: 14, weight: .medium)).foregroundColor(.yellow)
            let dateBinding = Binding(
                get: { completedSessions.first(where: { $0.sessionId == session.id && $0.week == week })?.date ?? Date() },
                set: { updateSessionDate(session: session, week: week, date: $0) }
            )
            DatePicker("", selection: dateBinding, displayedComponents: [.date])
                .datePickerStyle(.graphical).colorScheme(.dark).labelsHidden()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1)).cornerRadius(12)
            HStack(spacing: 20) {
                Image(systemName: "clock.fill").font(.system(size: 22)).foregroundColor(.white.opacity(0.7))
                Spacer()
                VStack(spacing: 4) {
                    Button(action: { dateBinding.wrappedValue = Calendar.current.date(byAdding: .hour, value: 1, to: dateBinding.wrappedValue) ?? dateBinding.wrappedValue }) {
                        Image(systemName: "chevron.up").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }.buttonStyle(.plain)
                    Text(String(format: "%02d", Calendar.current.component(.hour, from: dateBinding.wrappedValue)))
                        .font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        .frame(width: 60).background(Color.black.opacity(0.5)).cornerRadius(8)
                    Button(action: { dateBinding.wrappedValue = Calendar.current.date(byAdding: .hour, value: -1, to: dateBinding.wrappedValue) ?? dateBinding.wrappedValue }) {
                        Image(systemName: "chevron.down").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }.buttonStyle(.plain)
                }
                Text(":").font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                VStack(spacing: 4) {
                    Button(action: { dateBinding.wrappedValue = Calendar.current.date(byAdding: .minute, value: 1, to: dateBinding.wrappedValue) ?? dateBinding.wrappedValue }) {
                        Image(systemName: "chevron.up").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }.buttonStyle(.plain)
                    Text(String(format: "%02d", Calendar.current.component(.minute, from: dateBinding.wrappedValue)))
                        .font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        .frame(width: 60).background(Color.black.opacity(0.5)).cornerRadius(8)
                    Button(action: { dateBinding.wrappedValue = Calendar.current.date(byAdding: .minute, value: -1, to: dateBinding.wrappedValue) ?? dateBinding.wrappedValue }) {
                        Image(systemName: "chevron.down").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }.buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Color.white.opacity(0.1)).cornerRadius(12)
            HStack(spacing: 12) {
                Button("Annuler") { showDatePicker = false }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(12).background(Color.gray.opacity(0.5)).cornerRadius(10)
                Button(action: {
                    if let info = selectedSessionForDate {
                        if let idx = completedSessions.firstIndex(where: { $0.sessionId == info.session.id && $0.week == info.week }) {
                            deletedSessions.append(completedSessions[idx])
                            completedSessions.remove(at: idx)
                            saveCompletedSessions()
                        }
                    }
                    showDatePicker = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill").font(.system(size: 13))
                        Text("Dévalider")
                    }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(12).background(Color.red.opacity(0.7)).cornerRadius(10)
                }
                Button("Valider") { showDatePicker = false }
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(12).background(Color.green.opacity(0.6)).cornerRadius(10)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.blue.opacity(0.95)).shadow(color: .black.opacity(0.5), radius: 20))
        .frame(width: 560).padding(20)
        .scaleEffect(1.35)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showCalendar.toggle() }
            }) {
                AnimatedImage(name: "cal").resizable().scaledToFit()
                    .frame(width: 82, height: 82).opacity(showCalendar ? 1.0 : 0.7)
            }.buttonStyle(.plain)
            Spacer()
            VStack(spacing: 4) {
                Text("Plan d'Entraînement").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text("Cycle 8 semaines - Renouvelable").font(.system(size: 14, weight: .medium)).foregroundColor(.yellow)
            }
            Spacer()
            Button(action: {}) { }.buttonStyle(.plain).padding(.leading, 8)
        }
        .padding().background(Color.black.opacity(0.2))
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) { ForEach(weeks, id: \.self) { week in weekButton(week) } }.padding(.horizontal)
        }
        .padding(.vertical, 12).background(Color.white.opacity(0.1))
    }

    private func weekButton(_ week: Int) -> some View {
        let weekSessions = workoutsForWeek(week)
        let completed = weekSessions.filter { s in completedSessions.contains { $0.sessionId == s.id && $0.week == week } }.count
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) { selectedWeek = week; expandedSession = nil }
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text("Semaine \(week)").font(.system(size: 14, weight: .bold))
                    if completed > 0 {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.3)).frame(width: 22, height: 22)
                            Text("\(completed)").font(.system(size: 11, weight: .bold)).foregroundColor(.green)
                        }
                    }
                }
                Text(weekType(week)).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedWeek == week ? .white : .white.opacity(0.6))
            .frame(width: 120, height: 60)
            .background(selectedWeek == week ? Color.orange.opacity(0.6) : Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedWeek == week ? Color.yellow : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain)
    }

    // MARK: - Week Description

    private var weekDescription: some View {
        HStack(spacing: 12) {
            Image(systemName: "target").font(.system(size: 16)).foregroundColor(.yellow)
            Text("Objectif S\(selectedWeek) :").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(weekObjective(selectedWeek))
                .font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.9))
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer()
            progressBadge
        }
        .frame(maxWidth: 1240)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.purple.opacity(0.3)).cornerRadius(12)
    }

    private var progressBadge: some View {
        let ws = workoutsForWeek(selectedWeek)
        let c  = ws.filter { s in completedSessions.contains { $0.sessionId == s.id && $0.week == selectedWeek } }.count
        return HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(.green)
            Text("\(c)/\(ws.count)").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
        }
        .padding(.horizontal, 12).padding(.vertical, 6).background(Color.green.opacity(0.3)).cornerRadius(20)
    }

    // MARK: - Calendar

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AnimatedImage(name: "cal").resizable().scaledToFit().frame(width: 40, height: 40)
                Text("Calendrier de Suivi").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { withAnimation { deleteLastWorkout() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash.fill").font(.system(size: 14))
                            Text("Supprimer").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.red.opacity(0.6)).cornerRadius(8)
                    }
                    .buttonStyle(.plain).disabled(completedSessions.isEmpty).opacity(completedSessions.isEmpty ? 0.5 : 1)
                    Button(action: { withAnimation { restoreLastWorkout() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 14))
                            Text("Restaurer").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.blue.opacity(0.6)).cornerRadius(8)
                    }
                    .buttonStyle(.plain).disabled(deletedSessions.isEmpty).opacity(deletedSessions.isEmpty ? 0.5 : 1)
                }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 16)).foregroundColor(.orange)
                    Text("\(completedSessions.count) séances").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
                .padding(.horizontal, 14).padding(.vertical, 8).background(Color.orange.opacity(0.3)).cornerRadius(12)
            }
            ForEach(weeks, id: \.self) { week in weekCalendarRow(week: week) }
            if !completedSessions.isEmpty { statsView }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.3)).shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5))
        .frame(maxWidth: 1260)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func weekCalendarRow(week: Int) -> some View {
        let ws = workoutsForWeek(week)
        let c  = ws.filter { s in completedSessions.contains { $0.sessionId == s.id && $0.week == week } }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Semaine \(week)").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(weekType(week)).font(.system(size: 14, weight: .medium)).foregroundColor(.orange)
                    .padding(.horizontal, 10).padding(.vertical, 5).background(Color.orange.opacity(0.2)).cornerRadius(6)
                Spacer()
                HStack(spacing: 4) {
                    if c == ws.count { Image(systemName: "checkmark.seal.fill").font(.system(size: 18)).foregroundColor(.green) }
                    Text("\(c)/\(ws.count)").font(.system(size: 15, weight: .bold))
                        .foregroundColor(c == ws.count ? .green : .white.opacity(0.7))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(c == ws.count ? Color.green.opacity(0.3) : Color.white.opacity(0.1)).cornerRadius(8)
            }
            HStack(spacing: 12) {
                HStack(spacing: 12) { ForEach(ws) { s in calendarSessionButton(session: s, week: week) } }
                Spacer()
                weekDatesRectangle(week: week, sessions: ws)
            }
        }
        .padding().background(Color.white.opacity(0.1)).cornerRadius(12)
    }

    private func weekDatesRectangle(week: Int, sessions: [WorkoutSession]) -> some View {
        let dates = sessions.compactMap { s -> Date? in
            completedSessions.first(where: { $0.sessionId == s.id && $0.week == week })?.date
        }.sorted()
        return VStack(alignment: .leading, spacing: 8) {
            if dates.isEmpty {
                Text("Aucune séance").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.5)).italic()
            } else {
                ForEach(dates, id: \.self) { d in
                    HStack(spacing: 8) {
                        Image(systemName: "calendar").font(.system(size: 13)).foregroundColor(.green)
                        Text(formatFullDate(d)).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .frame(minWidth: 140, alignment: .leading).padding(12).background(Color.black.opacity(0.3)).cornerRadius(8)
    }

    private func calendarSessionButton(session: WorkoutSession, week: Int) -> some View {
        let isCompleted = completedSessions.contains { $0.sessionId == session.id && $0.week == week }
        let completionDate = completedSessions.first(where: { $0.sessionId == session.id && $0.week == week })?.date
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if !isCompleted { toggleSessionCompletion(session: session, week: week) }
                selectedSessionForDate = (session, week); showDatePicker = true
            }
        }) {
            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(isCompleted ? Color.green.opacity(0.3) : Color.white.opacity(0.1)).frame(width: 20, height: 20)
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 25)).foregroundColor(isCompleted ? .green : .white.opacity(0.4))
                    }
                    Text(session.day.prefix(3).uppercased()).font(.system(size: 14, weight: .bold))
                        .foregroundColor(isCompleted ? .green : .white.opacity(0.7))
                }
                if let d = completionDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatCompletionDate(d)).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text(formatCompletionTime(d)).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }.buttonStyle(.plain)
    }

    private var statsView: some View {
        VStack(spacing: 12) {
            Divider().background(Color.white.opacity(0.3))
            HStack(spacing: 20) {
                statItem(icon: "chart.bar.fill", value: "\(completedSessions.count)", label: "Total")
                statItem(icon: "calendar.badge.clock", value: lastWorkoutText(), label: "Dernière")
                statItem(icon: "flame.fill", value: "\(currentStreak())", label: "Série")
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(.yellow)
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6))
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Session Card

    private func sessionCard(_ session: WorkoutSession) -> some View {
        let isExpanded  = expandedSession == session.id
        let isCompleted = completedSessions.contains { $0.sessionId == session.id && $0.week == selectedWeek }
        return VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) { expandedSession = isExpanded ? nil : session.id }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(dayColor(session.day)).frame(width: 12, height: 12)
                            Text(session.day).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                            if isCompleted { Image(systemName: "checkmark.seal.fill").font(.system(size: 18)).foregroundColor(.green) }
                        }
                        Text(session.title).font(.system(size: 16, weight: .semibold)).foregroundColor(.yellow)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill").font(.system(size: 30))
                            Text(session.duration).font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 30)).foregroundColor(.yellow.opacity(0.6))
                    }
                }
                .padding()
                .background(isCompleted ? Color.green.opacity(0.15) : Color.white.opacity(0.15))
                .cornerRadius(12)
            }.buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if !isCompleted { toggleSessionCompletion(session: session, week: selectedWeek) }
                            selectedSessionForDate = (session, selectedWeek); showDatePicker = true
                        }
                    }) {
                        HStack {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24)).foregroundColor(isCompleted ? .green : .white.opacity(0.6))
                            Text(isCompleted ? "Séance complétée ✓" : "Marquer comme complétée")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            if isCompleted {
                                HStack(spacing: 4) {
                                    Text(completionDateText(session: session)).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.7))
                                    Image(systemName: "pencil.circle.fill").font(.system(size: 16)).foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding()
                        .background(isCompleted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                        .cornerRadius(12)
                    }.buttonStyle(.plain)

                    ForEach(session.blocks) { block in blockView(block) }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "leaf.fill").font(.system(size: 16)).foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nutrition post-effort").font(.system(size: 16, weight: .bold)).foregroundColor(.green)
                            Text(session.nutritionTip).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(12).background(Color.green.opacity(0.2)).cornerRadius(8)
                }
                .padding().background(Color.black.opacity(0.2)).cornerRadius(12)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(Color.white.opacity(0.08)).cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .frame(maxWidth: 1260)
    }

    // MARK: - Block View (avec GIFs intégrés)

    private func blockView(_ block: WorkoutBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill").font(.system(size: 14)).foregroundColor(.orange)
                Text(block.name).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                if let zone = block.fcZone {
                    Spacer()
                    Text(zone).font(.system(size: 18, weight: .semibold)).foregroundColor(.red)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.white.opacity(0.6)).cornerRadius(6)
                }
            }
            Text(block.description).font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.7)).italic()

            ForEach(block.details, id: \.self) { detail in
                if detail.contains("Dead bug") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showDeadBugGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showDeadBugGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showDeadBugGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "deadbug")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Dead Bug — bras + jambe opposés")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Pont fessier") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showPontFessierGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showPontFessierGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showPontFessierGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "pontfessier")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Pont fessier + marche")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Mountain climbers") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showMountainClimbersGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showMountainClimbersGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showMountainClimbersGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "mountainclimbers")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Mountain climbers lents")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Burpees") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showBurpeesGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showBurpeesGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showBurpeesGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "Burpees")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Burpees modifiés (sans saut)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Kettlebell") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showKettlebellSwingGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showKettlebellSwingGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showKettlebellSwingGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "kettlebellswing")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Kettlebell swing — propulsion hanches")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Squat jump") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showSquatJumpGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showSquatJumpGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showSquatJumpGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "squatjump")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Squat jump — explosivité membres inférieurs")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else if detail.contains("Fentes") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("•").foregroundColor(.yellow)
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showFentesGif.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.yellow)
                                        .underline()
                                    Image(systemName: showFentesGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow.opacity(0.9))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        if showFentesGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "fentes")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 155)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Fentes — 8 reps par jambe")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .italic()
                            }
                            .padding(.leading, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
                        }
                    }
                } else {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundColor(.yellow)
                        Text(detail).font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(12).background(Color.white.opacity(0.1)).cornerRadius(10)
    }

    // MARK: - Nutrition & Tracking

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife.circle.fill").font(.system(size: 44)).foregroundColor(.green)
                Text("Nutrition Hebdomadaire").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                AnimatedImage(name: "balance").resizable().scaledToFit().frame(width: 80, height: 80)
            }
            VStack(alignment: .leading, spacing: 8) {
                nutritionPoint("Déficit calorique : -300 à -500 kcal/jour")
                nutritionPoint("Protéines : 120-150g/jour (1,6-2g/kg)")
                nutritionPoint("Collation pré-effort : 20g protéines 30min avant")
                nutritionPoint("Post-effort : 25-30g protéines + glucides modérés")
                nutritionPoint("Hydratation : Pendant l'effort (surtout tapis 12%)")
            }
        }
        .padding().background(Color.green.opacity(0.2)).cornerRadius(16)
    }

    private func nutritionPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundColor(.green)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.9))
        }
    }

    private var trackingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill").font(.system(size: 44)).foregroundColor(.purple)
                Text("Indicateurs de Suivi").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 10) {
                trackingIndicator(icon: "heart.fill",     title: "FC Repos (chaque matin)",       warning: "Si +5 bpm vs moyenne → fatigue excessive")
                trackingIndicator(icon: "ruler.fill",     title: "Tour de taille (tous les 15j)",  warning: "Cible : -0,5 à -1 cm/15 jours")
                trackingIndicator(icon: "scalemass.fill", title: "Poids (1x/semaine)",             warning: "Cible : -0,25 à -0,5 kg/semaine MAX")
                trackingIndicator(icon: "moon.zzz.fill",  title: "Qualité du sommeil",             warning: "Indicateur clé de récupération")
            }
        }
        .padding().background(Color.purple.opacity(0.2)).cornerRadius(16)
    }

    private func trackingIndicator(icon: String, title: String, warning: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.purple).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                Text(warning).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.7)).italic()
            }
        }
    }

    // MARK: - Utilitaires

    private func weekType(_ week: Int) -> String {
        switch week {
        case 1, 3: return "Semaine A"
        case 2, 4: return "Semaine B"
        case 5, 7: return "Semaine C"
        case 6, 8: return "Semaine D"
        default:   return ""
        }
    }

    private func weekObjective(_ week: Int) -> String {
        switch week {
        case 1: return "Apprentissage - Respecter strictement les zones FC"
        case 2: return "Intensité - Intégrer la force et habituer le corps"
        case 3: return "Progression - Augmenter légèrement le volume tapis (+5 min)"
        case 4: return "Déload - Réduire le volume de 30%, pas de Z4"
        case 5: return "Cardio Endurance — Augmenter le volume aérobie total, consolider la Z2 longue durée"
        case 6: return "HIIT Pyramidal + Cardio Croisé — Maximiser l'EPOC et la dépense calorique globale"
        case 7: return "Cardio Progressif — Pousser les seuils : Z2 plus longue, tempo Z3 étendu, circuit core"
        case 8: return "Déload Cardio — Récupération active, aucune Z4, préparer le prochain cycle"
        default: return ""
        }
    }

    private func dayColor(_ day: String) -> Color {
        switch day { case "MARDI": return .orange; case "JEUDI": return .green; case "SAMEDI": return .red; default: return .white }
    }

    private func workoutsForWeek(_ week: Int) -> [WorkoutSession] {
        switch week {
        case 1, 3: return semanaAWorkouts(week: week)
        case 2, 4: return semanaBWorkouts(week: week)
        case 5, 7: return semanaCWorkouts(week: week)
        case 6, 8: return semanaDWorkouts(week: week)
        default:   return []
        }
    }

    // MARK: - Persistence

    private func toggleSessionCompletion(session: WorkoutSession, week: Int) {
        if let idx = completedSessions.firstIndex(where: { $0.sessionId == session.id && $0.week == week }) {
            completedSessions.remove(at: idx)
        } else {
            completedSessions.append(CompletedSession(sessionId: session.id, week: week, date: Date()))
        }
        saveCompletedSessions()
    }

    private func updateSessionDate(session: WorkoutSession, week: Int, date: Date) {
        if let idx = completedSessions.firstIndex(where: { $0.sessionId == session.id && $0.week == week }) {
            completedSessions[idx] = CompletedSession(sessionId: session.id, week: week, date: date)
            saveCompletedSessions()
        }
    }

    private func deleteLastWorkout() {
        guard let last = completedSessions.sorted(by: { $0.date > $1.date }).first,
              let idx  = completedSessions.firstIndex(where: { $0.id == last.id }) else { return }
        deletedSessions.append(last); completedSessions.remove(at: idx); saveCompletedSessions()
    }

    private func restoreLastWorkout() {
        guard let last = deletedSessions.last else { return }
        completedSessions.append(last); deletedSessions.removeLast(); saveCompletedSessions()
    }

    private func saveCompletedSessions() {
        if let enc = try? JSONEncoder().encode(completedSessions) { completedSessionsData = enc }
    }

    private func loadCompletedSessions() {
        if let dec = try? JSONDecoder().decode([CompletedSession].self, from: completedSessionsData) { completedSessions = dec }
    }

    private func completionDateText(session: WorkoutSession) -> String {
        guard let c = completedSessions.first(where: { $0.sessionId == session.id && $0.week == selectedWeek }) else { return "" }
        let f = DateFormatter(); f.dateFormat = "dd/MM"; return f.string(from: c.date)
    }

    private func lastWorkoutText() -> String {
        guard let last = completedSessions.sorted(by: { $0.date > $1.date }).first else { return "-" }
        let d = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
        return d == 0 ? "Aujourd'hui" : d == 1 ? "Hier" : "\(d)j"
    }

    private func currentStreak() -> Int {
        var streak = 0, cur = Date()
        for s in completedSessions.sorted(by: { $0.date > $1.date }) {
            let d = Calendar.current.dateComponents([.day], from: s.date, to: cur).day ?? 0
            guard d <= 2 else { break }; streak += 1; cur = s.date
        }
        return streak
    }

    private func formatFullDate(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd/MM à HH:mm"; return f.string(from: date)
    }
    private func formatCompletionDate(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd/MM/yyyy"; return f.string(from: date)
    }
    private func formatCompletionTime(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "HH:mm"; return f.string(from: date)
    }

    // =========================================================
    // MARK: - DONNÉES SEMAINES 1-4
    // =========================================================

    private func semanaAWorkouts(week: Int) -> [WorkoutSession] {
        let tapisDuration = week == 3 ? "30 min" : "25 min"
        return [
            WorkoutSession(id: "semA-\(week)-mardi", day: "MARDI", title: "FORCE + Endurance Z2", duration: "70 min",
                blocks: [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: ["20g de protéines (shake ou yaourt grec)", "Permet de préserver le muscle pendant l'effort"]),
                    WorkoutBlock(name: "Échauffement", description: "Rameur léger pour préparer le corps", fcZone: zoneFC(1),
                        details: ["10 min rameur en zone 1", "Mouvements fluides, technique propre"]),
                    WorkoutBlock(name: "Circuit Force (4 tours)", description: "Préserver la masse musculaire", fcZone: nil,
                        details: ["Squat ou presse → 8-10 reps", "Tirage (rameur lent ou poulie) → 10 reps",
                                  "Fentes → 8 reps/jambe", "Gainage → 45s", "Repos 90s entre tours", "⏱️ Total : ~35 min"]),
                    WorkoutBlock(name: "Retour au calme", description: "Home trainer en zone endurance", fcZone: zoneFC(2),
                        details: ["20 min home trainer Z2", "Cadence fluide, récupération active"])
                ], nutritionTip: "Dans les 30-45 min : 25-30g protéines + glucides modérés (ex: shake protéiné + banane)"),
            WorkoutSession(id: "semA-\(week)-jeudi", day: "JEUDI", title: "TAPIS 12% + Endurance Z2", duration: "75 min",
                blocks: [
                    WorkoutBlock(name: "Tapis Incliné 12%", description: "Arme anti-graisse viscérale", fcZone: zoneFC(2),
                        details: ["\(tapisDuration) de marche inclinée", "Vitesse : 5 km/h", "Posture droite, bras actifs",
                                  "Si FC > \(alertBpm) bpm → passer à 10% d'inclinaison", "⚠️ Surveiller FC repos le lendemain"]),
                    WorkoutBlock(name: "Endurance Z2", description: "Oxydation des graisses", fcZone: zoneFC(2),
                        details: [week == 3 ? "45 min endurance" : "50 min endurance", "Home trainer OU elliptique", "Rythme stable et confortable"])
                ], nutritionTip: "Hydratation PENDANT l'effort (tapis 12%). Post-effort : protéines + glucides"),
            WorkoutSession(id: "semA-\(week)-samedi", day: "SAMEDI",
                title: week == 4 ? "DÉLOAD - Récupération Active" : "Récupération Active Mixte",
                duration: week == 4 ? "45 min" : "60 min",
                blocks: week == 4 ? [
                    WorkoutBlock(name: "Séance Déload", description: "Récupération complète du système nerveux", fcZone: zoneFC(1),
                        details: ["15 min home trainer Z1", "15 min rameur très léger", "15 min elliptique Z1",
                                  "⚠️ PAS de zones élevées cette semaine", "Objectif : recharger les batteries"])
                ] : [
                    WorkoutBlock(name: "Rotation d'appareils", description: "Récupération active, pas de fatigue", fcZone: zoneZ1Z2,
                        details: ["20 min home trainer Z1 → \(zoneFC(1))", "20 min rameur technique léger",
                                  "20 min elliptique Z2 → \(zoneFC(2))", "Séance 'calorie propre' sans stress"])
                ], nutritionTip: "Séance légère : protéines suffisent, pas besoin de glucides")
        ]
    }

    private func semanaBWorkouts(week: Int) -> [WorkoutSession] {
        let hiitIntervals = week == 2 ? "9 × (30s/90s)" : "8 × (30s/90s)"
        return [
            WorkoutSession(id: "semB-\(week)-mardi", day: "MARDI", title: "HIIT Lipolytique",
                duration: week == 4 ? "30 min" : "60 min",
                blocks: week == 4 ? [
                    WorkoutBlock(name: "DÉLOAD - Version allégée", description: "Pas de HIIT cette semaine", fcZone: zoneZ1Z2,
                        details: ["30 min home trainer en Z2 tranquille", "Pas d'intervalles Z4", "Récupération prioritaire"])
                ] : [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: ["20g de protéines", "Crucial pour tenir l'intensité du HIIT"]),
                    WorkoutBlock(name: "Échauffement Progressif", description: "Monter progressivement en intensité", fcZone: zoneZ1Z2,
                        details: ["15 min home trainer", "Démarrer Z1, finir Z2 haute"]),
                    WorkoutBlock(name: "HIIT Lipolytique", description: "Déclencheur hormonal - EPOC", fcZone: zoneFC(4),
                        details: ["\(hiitIntervals) sur home trainer", "30s en Z4 → \(zoneFC(4)) (haute résistance)", "90s en Z1 → récupération complète",
                                  week == 2 ? "⚡ +1 intervalle vs semaine 1" : "⏱️ Total intervalles : ~20 min"]),
                    WorkoutBlock(name: "Retour au calme", description: "Évacuer les lactates", fcZone: zoneFC(1),
                        details: ["10 min home trainer Z1", "Récupération complète"])
                ], nutritionTip: "CRUCIAL : 25-30g protéines + glucides dans les 30 min post-HIIT"),
            WorkoutSession(id: "semB-\(week)-jeudi", day: "JEUDI", title: "TAPIS 12% + Endurance Z2", duration: week == 4 ? "45 min" : "75 min",
                blocks: [
                    WorkoutBlock(name: "Tapis Incliné 12%", description: "Graisse viscérale - séance clé", fcZone: zoneFC(2),
                        details: [week == 4 ? "15 min (déload)" : "20 min de marche inclinée", "Vitesse : 5 km/h",
                                  "Si FC > \(alertBpm) bpm → réduire à 10%",
                                  week == 4 ? "Volume réduit pour récupération" : "Maintenir la posture"]),
                    WorkoutBlock(name: "Endurance Z2", description: "Oxydation des graisses", fcZone: zoneFC(2),
                        details: [week == 4 ? "35 min" : "50 min endurance", "Elliptique OU home trainer", "Rythme stable"])
                ], nutritionTip: "Hydratation pendant. Post-effort : protéines + glucides légers"),
            WorkoutSession(id: "semB-\(week)-samedi", day: "SAMEDI",
                title: week == 4 ? "DÉLOAD - Récupération" : "Cardiaque Tempo Contrôlé",
                duration: week == 4 ? "45 min" : "70 min",
                blocks: week == 4 ? [
                    WorkoutBlock(name: "Récupération Active", description: "Semaine de déload", fcZone: zoneFC(1),
                        details: ["15 min home trainer Z1", "15 min rameur léger", "15 min elliptique Z1", "⚠️ PAS de Z3 cette semaine"])
                ] : [
                    WorkoutBlock(name: "Échauffement", description: "Montée progressive", fcZone: zoneZ1Z2,
                        details: ["15 min échauffement progressif", "Démarrer Z1, finir Z2"]),
                    WorkoutBlock(name: "Tempo Contrôlé (2 blocs)", description: "Cardiaque intelligent - peu de cortisol", fcZone: zoneFC(3),
                        details: ["Bloc 1 : 10 min Z3 → \(zoneFC(3))", "5 min Z1 (récupération)",
                                  "Bloc 2 : 10 min Z3 → \(zoneFC(3))", "⏱️ Total Z3 : 20 min (dans les limites)"]),
                    WorkoutBlock(name: "Endurance + Retour", description: "Finir en douceur", fcZone: "Z2-Z1",
                        details: ["15 min Z2", "15 min retour au calme Z1"])
                ], nutritionTip: week == 4 ? "Séance légère : protéines suffisent" : "Protéines + glucides modérés post-effort")
        ]
    }

    // =========================================================
    // MARK: - DONNÉES SEMAINES 5-8
    // =========================================================

    private func semanaCWorkouts(week: Int) -> [WorkoutSession] {
        let enduranceDuration = week == 7 ? "60 min" : "40 min"
        let tapisDuration     = week == 7 ? "35 min" : "30 min"
        let coreSets          = week == 7 ? "4" : "3"
        return [
            WorkoutSession(id: "semC-\(week)-mardi", day: "MARDI",
                title: week == 7 ? "Cardio Z2 Étendu + Core Intensifié" : "Endurance Z2 Longue + Circuit Core",
                duration: week == 7 ? "85 min" : "75 min",
                blocks: [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant — focus énergie durable", fcZone: nil,
                        details: ["20g protéines + 1 fruit (banane ou pomme)", "Privilégier les glucides lents pour une Z2 longue", "Éviter les graisses qui ralentissent l'assimilation"]),
                    WorkoutBlock(name: "Échauffement Cardio", description: "Activation progressive du système aérobie", fcZone: zoneFC(1),
                        details: ["10 min rameur ou vélo — allure très légère", "Augmenter progressivement la cadence sur les 3 dernières minutes", "Objectif : FC stable à la limite basse de Z1"]),
                    WorkoutBlock(name: "Endurance Z2 Longue", description: "Bloc principal — oxydation maximale des graisses", fcZone: zoneFC(2),
                        details: ["\(enduranceDuration) sur home trainer OU elliptique", "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm — rester DANS cette plage",
                                  "Cadence vélo : 85-95 rpm / elliptique : foulée ample", "Boire 150-200 ml toutes les 15 min",
                                  week == 7 ? "⚡ +10 min vs semaine 5 — progression volume" : "📊 Séance pilier du cycle C"]),
                    WorkoutBlock(name: "Circuit Core Anti-Graisse (\(coreSets) tours)", description: "Renforcement gainage profond + dépense calorique", fcZone: nil,
                        details: ["Planche frontale → 60s", "Planche latérale droite → 40s", "Planche latérale gauche → 40s",
                                  "Dead bug (bras + jambe opposés) → 12 reps/côté", "Mountain climbers lents → 20 reps",
                                  "Pont fessier + marche → 15 reps", "Repos 60s entre tours",
                                  week == 7 ? "⚡ 4 tours : effort soutenu, technique irréprochable" : "⏱️ Total circuit : ~20 min"]),
                    WorkoutBlock(name: "Retour au Calme", description: "Retour progressif à la FC de repos", fcZone: zoneFC(1),
                        details: ["5 min marche ou pédalage très léger", "Étirements dynamiques : hanches, ischios, mollets", "Respiration diaphragmatique 2 min"])
                ], nutritionTip: "Fenêtre anabolique : 25-30g protéines + glucides modérés dans les 40 min. Ex : riz + blanc de poulet ou shake whey + flocons d'avoine"),
            WorkoutSession(id: "semC-\(week)-jeudi", day: "JEUDI",
                title: week == 7 ? "Tapis 15% Intense + Cardio Croisé Progressif" : "Tapis 15% + Cardio Croisé",
                duration: week == 7 ? "85 min" : "70 min",
                blocks: [
                    WorkoutBlock(name: "Tapis Incliné 15%", description: "Inclinaison maximale — ciblage graisse viscérale et fessiers", fcZone: zoneFC(2),
                        details: ["\(tapisDuration) de marche inclinée à 15%", "Vitesse : 4,5 à 5 km/h — adapter selon la FC",
                                  "Maintenir une posture droite, ne pas s'appuyer sur les barres latérales",
                                  "Si FC > \(alertBpm) bpm → réduire à 12% immédiatement", "⚠️ Hydratation obligatoire : 200 ml toutes les 10 min",
                                  week == 7 ? "⚡ Inclinaison maximale du cycle — 5% de plus que le cycle A" : "📊 +3% vs semaines 1-4 pour plus de dépense calorique"]),
                    WorkoutBlock(name: "Récupération Active Inter-Blocs", description: "Transition contrôlée entre les appareils", fcZone: zoneFC(1),
                        details: ["5 min marche légère ou rameur très doux", "Faire baisser FC sous \(karvonen(0.65)) bpm avant le bloc suivant", "Profiter pour s'hydrater"]),
                    WorkoutBlock(name: "Cardio Croisé — Elliptique", description: "Continuité aérobie, membres supérieurs actifs", fcZone: zoneFC(2),
                        details: [week == 7 ? "25 min elliptique en Z2" : "20 min elliptique en Z2",
                                  "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                                  "Utiliser activement les bras pour augmenter la dépense calorique", "Varier la résistance toutes les 5 min (+1 cran, -1 cran)"]),
                    WorkoutBlock(name: "Cardio Croisé — Rameur Technique", description: "Cardio + gainage dorsal + bras — brûlage calorique complet", fcZone: zoneFC(2),
                        details: [week == 7 ? "20 min rameur rythme modéré" : "15 min rameur rythme modéré",
                                  "Ratio traction : 60% jambes / 40% dos-bras", "Cadence : 22-26 coups/minute",
                                  "Maintenir FC dans \(zoneFC(2))", "⏱️ Séance multi-appareils = moins d'ennui, plus de muscle sollicité"])
                ], nutritionTip: "Effort long : hydratation pendant (500-700 ml). Post-effort : protéines rapides + glucides pour reconstituer le glycogène. Ex : shake whey + riz soufflé"),
            WorkoutSession(id: "semC-\(week)-samedi", day: "SAMEDI",
                title: week == 7 ? "Fartlek Cardio Progressif Z2→Z3" : "Fartlek Contrôlé Z2↔Z3",
                duration: week == 7 ? "75 min" : "65 min",
                blocks: [
                    WorkoutBlock(name: "Échauffement", description: "Préparer les filières aérobie et mixte", fcZone: zoneFC(1),
                        details: ["10 min home trainer ou elliptique en Z1", "Augmenter la résistance par pallier toutes les 2 min",
                                  "Ne pas dépasser \(karvonen(0.62)) bpm en fin d'échauffement"]),
                    WorkoutBlock(name: "Fartlek Z2 ↔ Z3 (blocs alternés)", description: "Cardio intelligent — brûle plus sans épuiser les surrénales", fcZone: zoneFC(3),
                        details: ["Bloc 1 : 8 min Z2 → \(zoneFC(2))", "Bloc 2 : 5 min Z3 → \(zoneFC(3))",
                                  "Bloc 3 : 8 min Z2", "Bloc 4 : 5 min Z3",
                                  week == 7 ? "Bloc 5 : 8 min Z2  |  Bloc 6 : 5 min Z3  (tour supplémentaire)" : "⏱️ Total fartlek : ~26 min",
                                  "Appareil au choix : home trainer, elliptique ou rameur",
                                  "📊 Méthode fartlek = alternance naturelle, pas d'intervalles fixes"]),
                    WorkoutBlock(name: "Bloc Endurance de Finition", description: "Vider les réserves de glycogène restantes", fcZone: zoneFC(2),
                        details: [week == 7 ? "15 min Z2 continue à FC stable" : "20 min Z2 continue à FC stable",
                                  "Changer d'appareil si possible (motor memory reset)", "Maintenir une respiration nasale si possible"]),
                    WorkoutBlock(name: "Retour au Calme + Mobilité", description: "Récupération complète post-fartlek", fcZone: zoneFC(1),
                        details: ["9 min marche ou pédalage Z1 très léger",
                                  "Étirements statiques : quadriceps 30s, fléchisseurs hanche 30s, mollets 30s",
                                  "Massage rouleau si disponible : mollets, TFL, ischios", "⚠️ Ne pas s'arrêter brusquement après le Z3"])
                ], nutritionTip: week == 7 ? "Séance modérée-haute : 25g protéines + glucides légers (yaourt grec + fruits rouges). Recharge partielle du glycogène." : "Post-fartlek : protéines + glucides modérés. Éviter le jeûne post-effort sur une séance Z3.")
        ]
    }

    private func semanaDWorkouts(week: Int) -> [WorkoutSession] {
        let isDeload = week == 8
        return [
            WorkoutSession(id: "semD-\(week)-mardi", day: "MARDI",
                title: isDeload ? "DÉLOAD D — Cardio Doux Z2" : "HIIT Pyramidal Lipolytique",
                duration: isDeload ? "35 min" : "65 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "DÉLOAD — Cardio Récupérateur", description: "Semaine 8 : zéro HIIT, récupération hormonale", fcZone: zoneFC(2),
                        details: ["35 min home trainer ou elliptique en Z2", "FC cible : \(karvonen(0.60))–\(karvonen(0.68)) bpm — rester dans le bas de Z2",
                                  "Aucune accélération, aucun intervalle", "⚠️ Cette semaine prépare votre corps pour un nouveau cycle à venir",
                                  "Profiter pour évaluer vos progrès : poids, tour de taille, FC repos"])
                ] : [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant — carburant pour le HIIT", fcZone: nil,
                        details: ["20g protéines rapides (whey ou blanc d'œuf)", "15-20g glucides rapides (1 datte ou 1 petit fruit)", "🚫 Pas de repas lourd : nausées possibles en Z4"]),
                    WorkoutBlock(name: "Échauffement Progressif", description: "Préparer le cœur et les muscles aux intensités élevées", fcZone: zoneZ1Z2,
                        details: ["5 min home trainer Z1 très léger", "5 min Z2 — cadence normale",
                                  "3 × 20s accélérations à 80% d'effort (pas en Z4) pour activer les fibres rapides", "Récupération 40s entre chaque accélération"]),
                    WorkoutBlock(name: "HIIT Pyramidal (montée + descente)", description: "EPOC maximal — dépense calorique 24-48h après", fcZone: zoneFC(4),
                        details: ["🔺 MONTÉE de la pyramide :", "   Série 1 : 20s effort Z4 → \(zoneFC(4)) + 90s récup Z1",
                                  "   Série 2 : 30s effort Z4 + 90s récup Z1", "   Série 3 : 40s effort Z4 + 90s récup Z1",
                                  "   Série 4 : 50s effort Z4 + 90s récup Z1", "🔻 DESCENTE de la pyramide :",
                                  "   Série 5 : 40s effort Z4 + 90s récup Z1", "   Série 6 : 30s effort Z4 + 90s récup Z1",
                                  "   Série 7 : 20s effort Z4 + 90s récup Z1", "⏱️ Total pyramide : ~17 min",
                                  "⚡ Méthode pyramidale = moins de fatigue mentale, plus d'adaptation"]),
                    WorkoutBlock(name: "Cardio de Finition Z2", description: "Oxyder les acides gras libérés par le HIIT", fcZone: zoneFC(2),
                        details: ["15 min elliptique ou vélo en Z2", "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                                  "📊 Cette phase post-HIIT maximise l'utilisation des graisses"]),
                    WorkoutBlock(name: "Retour au Calme", description: "Descente contrôlée de la FC", fcZone: zoneFC(1),
                        details: ["5 min vélo ou marche très légère en Z1", "Ne pas s'arrêter brutalement après le HIIT", "Étirements légers membres inférieurs"])
                ], nutritionTip: isDeload ? "Séance légère : protéines seules suffisent. Pas besoin de recharge glucidique." : "PRIORITÉ : 30g protéines rapides + 40-50g glucides dans les 20-30 min. Fenêtre anabolique critique post-HIIT pyramidal."),
            WorkoutSession(id: "semD-\(week)-jeudi", day: "JEUDI",
                title: isDeload ? "DÉLOAD D — Tapis Léger + Récupération" : "Tapis 12% + Endurance Longue Variée",
                duration: isDeload ? "50 min" : "80 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Tapis Incliné (déload)", description: "Version allégée — récupération active", fcZone: zoneFC(1),
                        details: ["15 min tapis à 8% d'inclinaison — vitesse 4 km/h", "FC cible : rester en bas de Z1 → \(karvonen(0.50))–\(karvonen(0.56)) bpm",
                                  "Pas de Z2, pas de contrainte — marche thérapeutique"]),
                    WorkoutBlock(name: "Récupération Active Multi-Appareils", description: "Retour en douceur, mobilité articulaire", fcZone: zoneFC(1),
                        details: ["10 min elliptique Z1 — foulée ample et lente", "10 min rameur Z1 — technique parfaite, aucune précipitation",
                                  "Étirements dynamiques 15 min : hanche, épaule, mollet", "⚠️ Cette séance prépare le corps à l'arrêt du cycle"])
                ] : [
                    WorkoutBlock(name: "Tapis Incliné 12%", description: "Graisse viscérale + gainage postural sous charge", fcZone: zoneFC(2),
                        details: ["25 min de marche inclinée à 12%", "Vitesse : 5 km/h — régulier et contrôlé",
                                  "Si FC > \(alertBpm) bpm → passer à 10% d'inclinaison",
                                  "Alterner 5 min bras libres / 5 min bras actifs (push sur les barres avant)", "⚠️ Hydratation obligatoire"]),
                    WorkoutBlock(name: "Transition Active", description: "Récupération partielle avant le long bloc Z2", fcZone: zoneFC(1),
                        details: ["5 min marche ou rameur très léger", "Attendre que FC descende sous \(karvonen(0.63)) bpm"]),
                    WorkoutBlock(name: "Endurance Longue — Bloc 1 : Elliptique", description: "Cardio à faible impact — articulations préservées", fcZone: zoneFC(2),
                        details: ["25 min elliptique en Z2", "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                                  "Résistance modérée — augmenter tous les 5 min d'1 cran puis redescendre"]),
                    WorkoutBlock(name: "Endurance Longue — Bloc 2 : Home Trainer", description: "Finition cardio — fibres lentes au maximum", fcZone: zoneFC(2),
                        details: ["25 min home trainer en Z2", "Cadence : 85-90 rpm", "Maintenir FC stable sans accélération",
                                  "📊 Total cardio continu semaine D : 75 min — record du cycle"])
                ], nutritionTip: isDeload ? "Séance légère : protéines + légumes. Bilan de la semaine : évaluer les progrès." : "Effort long : hydratation pendant (700 ml). Post-effort : protéines (30g) + glucides complexes (riz, patate douce, quinoa)"),
            WorkoutSession(id: "semD-\(week)-samedi", day: "SAMEDI",
                title: isDeload ? "DÉLOAD D — Récupération Complète" : "Circuit Cardio-Force Fonctionnelle",
                duration: isDeload ? "45 min" : "75 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Récupération Complète Semaine 8", description: "Dernière séance du cycle — bilan et relâchement", fcZone: zoneFC(1),
                        details: ["15 min home trainer Z1 très léger → \(zoneFC(1))", "15 min marche ou elliptique Z1",
                                  "15 min étirements statiques complets : corps entier",
                                  "⚠️ Aucune intensité — ce cycle de 8 semaines se termine ici",
                                  "🎯 Bilan : pesée, tour de taille, FC repos → comparer avec semaine 1"])
                ] : [
                    WorkoutBlock(name: "Échauffement Cardio-Articulaire", description: "Activer cœur, hanches et épaules simultanément", fcZone: zoneFC(1),
                        details: ["10 min de mobilité dynamique enchaînée", "Cercles de bras larges × 10 reps",
                                  "Leg swings avant-arrière × 12 reps/côté", "Squats de mobilité lents × 10 reps",
                                  "3 min vélo ou marche rapide pour monter en Z1 haute"]),
                    WorkoutBlock(name: "Circuit Cardio-Force (4 tours)", description: "Dépense calorique maximale — force + cardio fusionnés", fcZone: zoneFC(3),
                        details: ["🔥 Exercice 1 : Kettlebell swing (ou haltère) → 15 reps", "🔥 Exercice 2 : Squat jump (sans charge ou léger) → 10 reps",
                                  "🔥 Exercice 3 : Pompes pieds surélevés → 10 reps", "🔥 Exercice 4 : Fentes marchées → 12 reps/jambe",
                                  "🔥 Exercice 5 : Burpees modifiés (sans saut) → 8 reps", "🔥 Exercice 6 : Mountain climbers rapides → 20 reps",
                                  "Repos 90s entre tours", "⏱️ Total circuit : ~35 min",
                                  "📊 FC cible circuit : \(karvonen(0.70))–\(karvonen(0.80)) bpm (bas Z3)"]),
                    WorkoutBlock(name: "Cardio de Finition Z2", description: "Oxyder les lipides post-circuit", fcZone: zoneFC(2),
                        details: ["15 min home trainer ou elliptique en Z2", "Transition directe depuis le circuit — ne pas s'asseoir",
                                  "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm"]),
                    WorkoutBlock(name: "Retour au Calme + Bilan Semaine", description: "Récupération et auto-évaluation", fcZone: zoneFC(1),
                        details: ["15 min marche légère", "Étirements : quadriceps 30s, ischios 30s, fléchisseurs hanche 30s",
                                  "🎯 Fin du cycle D : noter sa FC repos, son niveau d'énergie, son poids"])
                ], nutritionTip: isDeload ? "Fin du cycle 8 semaines : repas complet équilibré. Faire un bilan nutritionnel de la période et ajuster pour le prochain cycle." : "Post-circuit cardio-force : 30-35g protéines + glucides modérés obligatoires. Le circuit a sollicité toutes les fibres musculaires.")
        ]
    }
}

#Preview {
    TrainingPlanView()
}
