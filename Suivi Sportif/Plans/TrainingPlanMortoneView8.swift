import SwiftUI
import SDWebImageSwiftUI

// MARK: - Vue Plan Névrome de Morton

struct TrainingPlanMortoneView8: View {
    @State private var selectedWeek: Int = 1
    @State private var expandedSession: String? = nil
    @AppStorage("completedSessionsMortone") private var completedSessionsData: Data = Data()
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

    // GIF states (réutilisés pour Dead bug et Pont fessier dans les séances Morton)
    @State private var showDeadBugGif          = false
    @State private var showPontFessierGif      = false
    @State private var showMountainClimbersGif = false

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
        case 2: return .yellow
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
                gradient: Gradient(colors: [Color.yellow.opacity(0.25), Color.purple.opacity(0.7)]),
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
                            precautionsCard
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
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)
                    Text("Plan Post-Opératoire").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                }
                Text("Névrome de Morton — Récupération 8 semaines")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.yellow)
                Text("⚠️  Valider chaque phase avec votre chirurgien / kinésithérapeute")
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.65))
            }
            Spacer()
            Button(action: {}) { }.buttonStyle(.plain).padding(.leading, 8)
        }
        .padding().background(Color.black.opacity(0.25))
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
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.6), lineWidth: 1.5))
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
                icon: "moon.zzz.fill", color: .yellow, value: $fcRest, text: $fcRestInput, min: 35, max: 100)

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
                    (1, "Z1", "Échauffement",             "\(karvonen(0.50))–\(karvonen(0.60)) bpm"),
                    (2, "Z2", "Endurance fondamentale",   "\(karvonen(0.60))–\(karvonen(0.70)) bpm"),
                    (3, "Z3", "Résistance douce Aérobie", "\(karvonen(0.70))–\(karvonen(0.80)) bpm"),
                    (4, "Z4", "Résistance dure Seuil",    "\(karvonen(0.80))–\(karvonen(0.90)) bpm"),
                    (5, "Z5", "VMA Maximum",              "\(karvonen(0.90))–\(fcMax) bpm"),
                ]
                ForEach(zones, id: \.0) { z, label, name, range in
                    HStack(spacing: 10) {
                        Text(label)
                            .font(.system(size: 13, weight: .black)).foregroundColor(.white)
                            .frame(width: 34, height: 34).background(zoneColor(z)).cornerRadius(8)
                        Text(name)
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(range)
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(zoneColor(z).opacity(0.25)).cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(zoneColor(z).opacity(0.5), lineWidth: 1))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(zoneColor(z).opacity(0.12)).cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(zoneColor(z).opacity(0.3), lineWidth: 1))
                }
            }
            Button("Fermer") { showFCSettings = false }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding()
                .background(Color.yellow.opacity(0.6)).cornerRadius(12)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 0.15, green: 0.08, blue: 0.22).opacity(0.98))
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
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.purple.opacity(0.95)).shadow(color: .black.opacity(0.5), radius: 20))
        .frame(width: 560).padding(20)
        .scaleEffect(1.35)
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
            .frame(width: 130, height: 60)
            .background(selectedWeek == week ? Color.yellow.opacity(0.6) : Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedWeek == week ? Color.yellow : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain)
    }

    // MARK: - Week Description

    private var weekDescription: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.walk.motion").font(.system(size: 16)).foregroundColor(.yellow)
            Text("Objectif S\(selectedWeek) :").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(weekObjective(selectedWeek))
                .font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.9))
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer()
            progressBadge
        }
        .frame(maxWidth: 1240)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.yellow.opacity(0.2)).cornerRadius(12)
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
                Text("Calendrier de Suivi — Post Morton").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
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
                        .background(Color.yellow.opacity(0.6)).cornerRadius(8)
                    }
                    .buttonStyle(.plain).disabled(deletedSessions.isEmpty).opacity(deletedSessions.isEmpty ? 0.5 : 1)
                }
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk.motion").font(.system(size: 16)).foregroundColor(.yellow)
                    Text("\(completedSessions.count) séances").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
                .padding(.horizontal, 14).padding(.vertical, 8).background(Color.yellow.opacity(0.3)).cornerRadius(12)
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
                Text(weekType(week)).font(.system(size: 14, weight: .medium)).foregroundColor(.yellow)
                    .padding(.horizontal, 10).padding(.vertical, 5).background(Color.yellow.opacity(0.2)).cornerRadius(6)
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
                statItem(icon: "chart.bar.fill",          value: "\(completedSessions.count)", label: "Total")
                statItem(icon: "calendar.badge.clock",    value: lastWorkoutText(),            label: "Dernière")
                statItem(icon: "figure.walk.motion",      value: "\(currentStreak())",         label: "Série")
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
                            .font(.system(size: 30)).foregroundColor(.yellow.opacity(0.7))
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
                        .background(isCompleted ? Color.green.opacity(0.3) : Color.yellow.opacity(0.25))
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

    // MARK: - Block View

    private func blockView(_ block: WorkoutBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill").font(.system(size: 14)).foregroundColor(.yellow)
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
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showDeadBugGif.toggle() }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail).font(.system(size: 16, weight: .medium)).foregroundColor(.yellow).underline()
                                    Image(systemName: showDeadBugGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.yellow.opacity(0.9))
                                }
                            }.buttonStyle(.plain)
                        }
                        if showDeadBugGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "deadbug").resizable().scaledToFit()
                                    .frame(width: 220, height: 155).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Dead Bug — bras + jambe opposés")
                                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6)).italic()
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
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showPontFessierGif.toggle() }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail).font(.system(size: 16, weight: .medium)).foregroundColor(.yellow).underline()
                                    Image(systemName: showPontFessierGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.yellow.opacity(0.9))
                                }
                            }.buttonStyle(.plain)
                        }
                        if showPontFessierGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "pontfessier").resizable().scaledToFit()
                                    .frame(width: 220, height: 155).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Pont fessier — talons posés, pas d'orteils")
                                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6)).italic()
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
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { showMountainClimbersGif.toggle() }
                            }) {
                                HStack(spacing: 6) {
                                    Text(detail).font(.system(size: 16, weight: .medium)).foregroundColor(.yellow).underline()
                                    Image(systemName: showMountainClimbersGif ? "chevron.up.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.yellow.opacity(0.9))
                                }
                            }.buttonStyle(.plain)
                        }
                        if showMountainClimbersGif {
                            VStack(spacing: 6) {
                                AnimatedImage(name: "mountainclimbers").resizable().scaledToFit()
                                    .frame(width: 220, height: 155).cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                                Text("Mountain climbers lents — genou vers poitrine")
                                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6)).italic()
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

    // MARK: - Précautions Card (remplace Nutrition hebdo)

    private var precautionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 36)).foregroundColor(.yellow)
                Text("Précautions Morton").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                precautionPoint(icon: "xmark.circle.fill", color: .red,
                    text: "JAMAIS d'appui avant-pied en charge")
                precautionPoint(icon: "xmark.circle.fill", color: .red,
                    text: "JAMAIS de tapis incliné / sauts / burpees")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Rameur : sangle sur milieu/talon uniquement")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Vélo : selle haute, appui milieu de pied")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Elliptique : test 5 min sans douleur d'abord (S5+)")
                precautionPoint(icon: "heart.fill", color: .yellow,
                    text: "Oméga-3 réguliers : soutien régénération nerveuse")
                precautionPoint(icon: "thermometer.snowflake", color: .cyan,
                    text: "Glace 10 min post-effort si chaleur du pied")
            }
        }
        .padding().background(Color.yellow.opacity(0.15)).cornerRadius(16)
    }

    private func precautionPoint(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.9))
        }
    }

    // MARK: - Tracking Card

    private var trackingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill").font(.system(size: 36)).foregroundColor(.purple)
                Text("Suivi de Récupération").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 10) {
                trackingIndicator(icon: "heart.fill",           title: "FC Repos (chaque matin)",       warning: "Si +5 bpm vs moyenne → fatigue excessive")
                trackingIndicator(icon: "figure.walk.motion",   title: "Sensibilité du pied (0–10)",     warning: "Noter après chaque séance — trend décroissant attendu")
                trackingIndicator(icon: "drop.fill",            title: "Œdème post-séance",              warning: "Si œdème > 12h → réduire intensité et consulter")
                trackingIndicator(icon: "moon.zzz.fill",        title: "Qualité du sommeil",             warning: "Indicateur clé de récupération nerveuse")
                trackingIndicator(icon: "scalemass.fill",       title: "Poids (1x/semaine)",             warning: "Maintien masse musculaire : cible ≤ -0,3 kg/sem")
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
        case 1, 2: return "Phase A — Post-op"
        case 3, 4: return "Phase B — Consolidation"
        case 5, 6: return "Phase C — Reprise"
        case 7, 8: return "Phase D — Progression"
        default:   return ""
        }
    }

    private func weekObjective(_ week: Int) -> String {
        switch week {
        case 1: return "Post-op immédiat — Rameur talon + Core sol, zéro appui avant-pied"
        case 2: return "Augmenter le volume rameur + home trainer, surveiller la cicatrice"
        case 3: return "Cardio croisé assis + HIIT rameur, introduction force haut du corps"
        case 4: return "Déload — Volume -30%, laisser le pied consolider"
        case 5: return "Réintroduire l'elliptique progressivement — observer les sensations pied"
        case 6: return "Déload C — Confirmer la tolérance elliptique avant Phase D"
        case 7: return "Volume cardio maximal du cycle + force fonctionnelle + proprioception"
        case 8: return "Déload final — Récupération, bilan complet, préparation prochain cycle"
        default: return ""
        }
    }

    private func dayColor(_ day: String) -> Color {
        switch day {
        case "MARDI":   return .yellow
        case "JEUDI":   return Color(red: 0.6, green: 0.3, blue: 0.9)
        case "SAMEDI":  return .cyan
        default:        return .white
        }
    }

    private func workoutsForWeek(_ week: Int) -> [WorkoutSession] {
        switch week {
        case 1, 2: return semaineMortoneA(week: week)
        case 3, 4: return semaineMortoneB(week: week)
        case 5, 6: return semaineMortoneC(week: week)
        case 7, 8: return semaineMortoneD(week: week)
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
    // MARK: - DONNÉES SEMAINES 1–2 : Phase A
    // =========================================================

    private func semaineMortoneA(week: Int) -> [WorkoutSession] {
        return [
            WorkoutSession(
                id: "mortA-\(week)-mardi",
                day: "MARDI",
                title: "Rameur Technique + Core Sol",
                duration: week == 1 ? "45 min" : "55 min",
                blocks: [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: [
                            "20g de protéines (shake ou yaourt grec)",
                            "⚠️ Pied surélevé pendant la préparation si encore œdème"
                        ]),
                    WorkoutBlock(name: "Rameur — Échauffement Léger",
                        description: "Poussée talon uniquement — NE PAS utiliser l'avant-pied",
                        fcZone: zoneFC(1),
                        details: [
                            "10 min rameur cadence très lente (18 coups/min)",
                            "Réglage pied : sangle sur le milieu/talon du pied opéré",
                            "Pression 80% jambes / 20% bras — éviter la flexion dorsale forcée",
                            "Si douleur ou picotement → arrêter immédiatement",
                            "FC cible : \(karvonen(0.50))–\(karvonen(0.58)) bpm"
                        ]),
                    WorkoutBlock(name: "Rameur — Bloc Cardio Principal",
                        description: "Endurance assise — zéro choc articulaire",
                        fcZone: zoneFC(2),
                        details: [
                            week == 1 ? "20 min continu à cadence modérée (20-22 coups/min)"
                                      : "25 min continu à cadence modérée (22-24 coups/min)",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.68)) bpm",
                            "Ratio : 65% jambes (poussée talon) / 35% dos-bras",
                            "Surveiller l'appui : le pied opéré ne doit pas flex en hyper-extension",
                            week == 2 ? "⚡ +5 min vs S1 — progression douce" : "📊 Séance fondatrice de la phase A"
                        ]),
                    WorkoutBlock(name: "Circuit Core Sol (3 tours)",
                        description: "Gainage profond allongé — AUCUN appui pied en charge",
                        fcZone: nil,
                        details: [
                            "Planche sur avant-bras (genoux au sol si besoin) → 45s",
                            "Dead bug bras + jambe opposés → 10 reps/côté",
                            "Pont fessier bilatéral (talons posés, pas d'orteils) → 15 reps",
                            "Crunches croisés lents → 12 reps/côté",
                            "Superman dorsal → 12 reps",
                            "Respiration diaphragmatique 4-4-4 → 1 min",
                            "Repos 60s entre tours",
                            "⚠️ Tous les exercices se font au sol ou assis — 0 appui debout"
                        ]),
                    WorkoutBlock(name: "Retour au Calme",
                        description: "Mobilisation assis sur chaise ou au sol",
                        fcZone: zoneFC(1),
                        details: [
                            "5 min pédalage très léger (vélo bras si disponible)",
                            "Étirements ischios et hanches en position allongée",
                            "Cercles de cheville LENTS en l'air (mobilité sans charge) → 10 reps",
                            "Élévation du pied opéré 10 min après la séance"
                        ])
                ],
                nutritionTip: "Dans les 30-40 min : 25g protéines + glucides légers. Pied surélevé pendant la récupération. Oméga-3 réguliers pour la régénération nerveuse."
            ),

            WorkoutSession(
                id: "mortA-\(week)-jeudi",
                day: "JEUDI",
                title: "Haut du Corps + Home Trainer Adapté",
                duration: "60 min",
                blocks: [
                    WorkoutBlock(name: "Home Trainer — Cardio Principal",
                        description: "Pédalage milieu de pied — réglage hauteur selle impératif",
                        fcZone: zoneFC(2),
                        details: [
                            "⚠️ Régler la selle très haute : jambe quasi-tendue en bas de course",
                            "Objectif : appui sur le milieu/talon, pas sur l'avant-pied",
                            week == 1 ? "25 min en Z2 — résistance légère"
                                      : "30 min en Z2 — résistance légère à modérée",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                            "Cadence : 80-90 rpm — éviter les grosses résistances"
                        ]),
                    WorkoutBlock(name: "Renforcement Haut du Corps (3 tours)",
                        description: "Conserver la masse musculaire — assis ou debout appui plat",
                        fcZone: nil,
                        details: [
                            "Tirage horizontal câble ou élastique → 12 reps",
                            "Développé épaules haltères assis → 10 reps",
                            "Curl biceps haltères assis → 12 reps",
                            "Triceps poulie ou dips fesses sur banc → 12 reps",
                            "Rowing haltère unilatéral assis → 10 reps/côté",
                            "Repos 75s entre tours",
                            "⚠️ En station debout : appui pied PLAT obligatoire",
                            "⏱️ Total : ~25 min"
                        ]),
                    WorkoutBlock(name: "Core Sol + Mobilité Cheville",
                        description: "Travail proprioceptif sans charge",
                        fcZone: nil,
                        details: [
                            "Planche latérale genoux → 30s chaque côté",
                            "Pont fessier unilatéral (côté sain en charge) → 10 reps",
                            "Mobilité cheville en l'air : cercles, flexion-extension → 2 × 15 reps",
                            "⚠️ Mobilité passive uniquement sur pied opéré (sans résistance)"
                        ])
                ],
                nutritionTip: "Hydratation optimale : la sédentarité forcée augmente les risques de rétention. Protéines 120g/jour minimum pour limiter la fonte musculaire."
            ),

            WorkoutSession(
                id: "mortA-\(week)-samedi",
                day: "SAMEDI",
                title: week == 1 ? "Récupération Très Légère" : "Rameur Doux + Étirements Complets",
                duration: week == 1 ? "35 min" : "50 min",
                blocks: week == 1 ? [
                    WorkoutBlock(name: "Séance de Récupération Semaine 1",
                        description: "Corps et pied fraîchement opérés — aller très doucement",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min rameur TRÈS léger (15 coups/min, résistance minimale)",
                            "FC cible : rester sous \(karvonen(0.58)) bpm",
                            "15 min mouvements bras libres assis ou au sol",
                            "⚠️ S1 post-op : si douleur même légère → ARRÊT et repos total",
                            "Objectif : maintenir la circulation sanguine pour la cicatrisation"
                        ])
                ] : [
                    WorkoutBlock(name: "Rameur — Endurance Prolongée",
                        description: "Séance plus longue — toujours assis, toujours talon",
                        fcZone: zoneFC(2),
                        details: [
                            "30 min rameur en Z2 continue",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.68)) bpm",
                            "Varier : 3 min à 20 coups/min puis 2 min à 24 coups/min",
                            "Travailler la technique : finition bras, dos droit"
                        ]),
                    WorkoutBlock(name: "Mobilité + Étirements Complets",
                        description: "Récupération musculaire et articulaire complète",
                        fcZone: nil,
                        details: [
                            "Cat-cow au sol → 10 reps",
                            "Pigeon pose allongé (fléchisseurs hanche) → 30s/côté",
                            "Étirements ischio allongé avec sangle → 30s/côté",
                            "Respiration cohérence cardiaque 5 min (5s/5s)",
                            "Massage rouleau : mollets et TFL (⚠️ éviter la plante du pied opéré)"
                        ])
                ],
                nutritionTip: "Séance légère : protéines suffisent. Privilégier oméga-3 (poisson gras, graines de lin) pour réduire l'inflammation post-opératoire."
            )
        ]
    }

    // =========================================================
    // MARK: - DONNÉES SEMAINES 3–4 : Phase B
    // =========================================================

    private func semaineMortoneB(week: Int) -> [WorkoutSession] {
        let isDeload = week == 4
        return [
            WorkoutSession(
                id: "mortB-\(week)-mardi",
                day: "MARDI",
                title: isDeload ? "DÉLOAD B — Cardio Doux + Core" : "Home Trainer Z2 Long + Force Haut",
                duration: isDeload ? "45 min" : "70 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "DÉLOAD — Récupération Semaine 4",
                        description: "Volume réduit de 30% — laisser le pied consolider",
                        fcZone: zoneFC(2),
                        details: [
                            "20 min home trainer Z2 très tranquille",
                            "FC cible : bas de Z2 → \(karvonen(0.60))–\(karvonen(0.65)) bpm",
                            "⚠️ Si consultation chirurgien cette semaine → adapter selon bilan",
                            "15 min core sol : planche, dead bug, pont fessier",
                            "10 min étirements complets"
                        ])
                ] : [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: [
                            "20g protéines + 1 source glucides lents (flocons d'avoine)",
                            "Hydratation : 300 ml avant de commencer"
                        ]),
                    WorkoutBlock(name: "Home Trainer — Cardio Principal",
                        description: "Séance pivot — volume en hausse vs Phase A",
                        fcZone: zoneFC(2),
                        details: [
                            "40 min home trainer en Z2",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                            "10 premières minutes : montée progressive (Z1→Z2)",
                            "Vérifier appui pied à chaque changement de résistance",
                            "Boire 150 ml toutes les 10 min",
                            "⚡ +10-15 min vs Phase A — consolidation cardio"
                        ]),
                    WorkoutBlock(name: "Force Haut du Corps + Gainage (3 tours)",
                        description: "Conserver et reconstruire — programme assis/debout adapté",
                        fcZone: nil,
                        details: [
                            "Tractions assistées ou tirage vertical → 10 reps",
                            "Développé couché haltères → 10 reps",
                            "Rowing machines assis → 12 reps",
                            "Gainage ventral sur avant-bras → 50s",
                            "Pont fessier bilatéral → 18 reps",
                            "Repos 90s entre tours",
                            "⚠️ En station debout : chaussures larges, appui pied plat obligatoire"
                        ])
                ],
                nutritionTip: "Phase B : augmenter progressivement les protéines à 130-150g/j. Post-effort : whey + glucides complexes."
            ),

            WorkoutSession(
                id: "mortB-\(week)-jeudi",
                day: "JEUDI",
                title: isDeload ? "DÉLOAD B — Rameur Léger" : "Rameur Intensité Modérée + Core Avancé",
                duration: isDeload ? "40 min" : "70 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Rameur Déload",
                        description: "Intensité minimale — récupération physiologique",
                        fcZone: zoneFC(1),
                        details: [
                            "25 min rameur en Z1 très léger",
                            "Travailler la technique : finition bras, dos stable",
                            "15 min étirements dos et hanches"
                        ])
                ] : [
                    WorkoutBlock(name: "Rameur — Progression Phase B",
                        description: "Montée en volume et légèrement en intensité",
                        fcZone: zoneFC(2),
                        details: [
                            "10 min échauffement Z1 (18 coups/min)",
                            "30 min Z2 continu (22-24 coups/min)",
                            "FC cible : \(karvonen(0.62))–\(karvonen(0.70)) bpm",
                            "Option fartlek léger : 5 × (2 min à 26 coups/min + 3 min à 20 coups/min)",
                            "⏱️ Durée rameur : 40 min total"
                        ]),
                    WorkoutBlock(name: "Circuit Core Avancé (3 tours)",
                        description: "Progression du gainage — diversification des plans",
                        fcZone: nil,
                        details: [
                            "Planche frontale avant-bras → 60s",
                            "Planche latérale (genou ou pied selon tolérance) → 40s/côté",
                            "Dead bug avec résistance légère (haltère sur poitrine) → 12 reps",
                            "Pont fessier unilatéral (côté sain) → 12 reps",
                            "Abdos bicycle lents → 16 reps",
                            "Superman dorsal + maintien 2s → 12 reps",
                            "Repos 60s entre tours — ⏱️ Total : ~20 min"
                        ])
                ],
                nutritionTip: "Effort modéré-long : hydratation 500 ml pendant. Post-effort dans les 30 min : 30g protéines + glucides modérés."
            ),

            WorkoutSession(
                id: "mortB-\(week)-samedi",
                day: "SAMEDI",
                title: isDeload ? "DÉLOAD B — Récupération Active" : "Cardio Croisé Assis (Rameur + Vélo)",
                duration: isDeload ? "40 min" : "65 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Récupération Active Semaine 4",
                        description: "Laisser le corps et le pied récupérer pleinement",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min home trainer Z1",
                            "15 min rameur très léger",
                            "10 min mobilité sol complète",
                            "⚠️ Bilan pied : évaluer la sensibilité, noter les progrès sur l'œdème"
                        ])
                ] : [
                    WorkoutBlock(name: "Cardio Croisé — Bloc 1 : Rameur",
                        description: "Démarrer par le rameur — moins de résistance pied",
                        fcZone: zoneFC(2),
                        details: [
                            "25 min rameur en Z2",
                            "Cadence cible : 22-26 coups/min",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm"
                        ]),
                    WorkoutBlock(name: "Transition Active",
                        description: "Laisser descendre la FC avant le vélo",
                        fcZone: zoneFC(1),
                        details: [
                            "3 min marche légère (appui pied plat obligatoire)",
                            "Boire 200 ml — régler la selle avant de commencer"
                        ]),
                    WorkoutBlock(name: "Cardio Croisé — Bloc 2 : Home Trainer",
                        description: "Alterner les appareils = moins de fatigue sur le pied opéré",
                        fcZone: zoneFC(2),
                        details: [
                            "30 min home trainer Z2",
                            "Résistance légère à modérée — pied milieu",
                            "Varier la cadence toutes les 5 min : 85 rpm puis 95 rpm",
                            "📊 Total cardio croisé : 55 min — maximum Phase B"
                        ]),
                    WorkoutBlock(name: "Retour au Calme + Mobilité Pied",
                        description: "Récupération active et rééducation précoce",
                        fcZone: zoneFC(1),
                        details: [
                            "7 min pédalage très léger",
                            "Étirements mollets ASSIS (pas en appui debout) → 30s/côté",
                            "Cercles de cheville passifs → 15 reps",
                            "Massage léger voûte plantaire avec balle froide (loin de la cicatrice)"
                        ])
                ],
                nutritionTip: "Séance longue cardio : protéines + glucides complexes. Oméga-3 réguliers toute la Phase B pour optimiser la cicatrisation nerveuse."
            )
        ]
    }

    // =========================================================
    // MARK: - DONNÉES SEMAINES 5–6 : Phase C
    // =========================================================

    private func semaineMortoneC(week: Int) -> [WorkoutSession] {
        let isDeload = week == 6
        return [
            WorkoutSession(
                id: "mortC-\(week)-mardi",
                day: "MARDI",
                title: isDeload ? "DÉLOAD C — Cardio Léger Mixte" : "Elliptique Progressif + Circuit Sol",
                duration: isDeload ? "45 min" : "75 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "DÉLOAD Semaine 6",
                        description: "Volume réduit, qualité de mouvement prioritaire",
                        fcZone: zoneFC(2),
                        details: [
                            "20 min home trainer Z2 tranquille",
                            "10 min rameur léger",
                            "15 min core sol : planche, dead bug, pont",
                            "⚠️ Évaluer si l'elliptique est bien toléré avant la semaine 7"
                        ])
                ] : [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: [
                            "20g protéines + 1 fruit",
                            "💡 S5 = réintroduction elliptique — observer attentivement les sensations pied"
                        ]),
                    WorkoutBlock(name: "Elliptique — Test Puis Cardio",
                        description: "⚠️ Première utilisation depuis l'opération : progresser doucement",
                        fcZone: zoneFC(2),
                        details: [
                            "5 min test à résistance NULLE — observer douleur/fourmillement",
                            "Si 0 douleur → continuer 25 min en Z2",
                            "Si douleur → arrêter et remplacer par home trainer",
                            "Appui pied ENTIER sur la pédale — éviter l'avant-pied",
                            "Utiliser ACTIVEMENT les bras pour réduire la charge sur les pieds",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm"
                        ]),
                    WorkoutBlock(name: "Home Trainer — Complément Cardio",
                        description: "Compléter le volume cardio en sécurité",
                        fcZone: zoneFC(2),
                        details: [
                            "15 min home trainer en Z2",
                            "FC cible stable : \(karvonen(0.62))–\(karvonen(0.70)) bpm"
                        ]),
                    WorkoutBlock(name: "Circuit Sol Complet (3 tours)",
                        description: "Gainage + force corps entier sans appui avant-pied",
                        fcZone: nil,
                        details: [
                            "Planche sur avant-bras → 60s",
                            "Dead bug avec mouvement de bras alterné → 14 reps/côté",
                            "Pont fessier unilatéral (alterner les 2 côtés) → 12 reps",
                            "Superman hold 3s → 12 reps",
                            "Crunch oblique lent → 15 reps/côté",
                            "Extension de hanche en quadrupédie → 12 reps/côté",
                            "Repos 60s entre tours — ⏱️ Total : ~20 min"
                        ]),
                    WorkoutBlock(name: "Retour au Calme",
                        description: "Toujours finir en douceur et noter les sensations",
                        fcZone: zoneFC(1),
                        details: [
                            "5 min pédalage très léger",
                            "📝 NOTER : douleur elliptique 0-10 ? Fourmillement ? Œdème post-séance ?",
                            "Glace 10 min sur le pied si sensation de chaleur après l'elliptique",
                            "Étirements hanches et ischio allongé"
                        ])
                ],
                nutritionTip: "Phase C : si elliptique toléré, augmenter les glucides complexes post-effort. 30g protéines + riz ou patate douce."
            ),

            WorkoutSession(
                id: "mortC-\(week)-jeudi",
                day: "JEUDI",
                title: isDeload ? "DÉLOAD C — Rameur Doux" : "Rameur HIIT Assis + Force Haut",
                duration: isDeload ? "45 min" : "70 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Rameur Déload C",
                        description: "Maintien du volume minimal — pas d'intervalles",
                        fcZone: zoneFC(2),
                        details: [
                            "30 min rameur Z2 continue et calme",
                            "15 min étirements complets au sol"
                        ])
                ] : [
                    WorkoutBlock(name: "Rameur — Échauffement",
                        description: "Montée progressive vers les intervalles",
                        fcZone: zoneZ1Z2,
                        details: [
                            "12 min rameur en montée progressive Z1 → Z2",
                            "Les 2 dernières minutes : accélérations douces (24-26 coups/min)"
                        ]),
                    WorkoutBlock(name: "HIIT Assis Rameur (Adapté Morton)",
                        description: "EPOC sans aucun impact — intervalles sur ergomètre",
                        fcZone: zoneFC(4),
                        details: [
                            "8 × (30s effort intense + 90s récupération)",
                            "30s : rythme maximal rameur (28-32 coups/min) → \(zoneFC(4))",
                            "90s : cadence très lente 16 coups/min → \(zoneFC(1))",
                            "⚠️ Vérifier l'appui pied pendant les intervalles — éviter la traction orteils",
                            "⏱️ Total intervalles : ~16 min",
                            "📊 Alternative si douleur pied : 8 × (30s/90s) sur vélo haute cadence"
                        ]),
                    WorkoutBlock(name: "Retour au Calme Rameur",
                        description: "Évacuer les lactates — toujours assis",
                        fcZone: zoneFC(1),
                        details: [
                            "8 min rameur très léger (16-18 coups/min)",
                            "FC doit redescendre sous \(karvonen(0.58)) bpm avant d'arrêter"
                        ]),
                    WorkoutBlock(name: "Force Haut du Corps (3 tours)",
                        description: "Volume supérieur augmenté — pas de perte musculaire",
                        fcZone: nil,
                        details: [
                            "Tirage vertical large prise → 10 reps",
                            "Rowing haltère bilatéral assis → 12 reps",
                            "Développé militaire haltères assis → 10 reps",
                            "Curl marteau alternés assis → 12 reps",
                            "Extensions triceps poulie → 12 reps",
                            "Face pull avec élastique → 15 reps",
                            "Repos 75s entre tours — ⏱️ Total : ~20 min"
                        ])
                ],
                nutritionTip: "HIIT assis = même réponse hormonale que HIIT debout. Fenêtre anabolique : 30g protéines rapides + 40g glucides dans les 25 min post-HIIT."
            ),

            WorkoutSession(
                id: "mortC-\(week)-samedi",
                day: "SAMEDI",
                title: isDeload ? "DÉLOAD C — Récupération Active" : "Cardio Croisé Long + Proprioception",
                duration: isDeload ? "40 min" : "70 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Récupération Active Semaine 6",
                        description: "Préparer le corps à la Phase D finale",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min home trainer Z1 très léger",
                            "15 min rameur technique (focus qualité du geste)",
                            "10 min mobilité complète sol",
                            "🎯 Bilan intermédiaire : peser, noter FC repos, évaluer pied"
                        ])
                ] : [
                    WorkoutBlock(name: "Bloc 1 — Elliptique",
                        description: "Appui pied entier — maintenir la vigilance",
                        fcZone: zoneFC(2),
                        details: [
                            "25 min elliptique en Z2",
                            "FC cible : \(karvonen(0.62))–\(karvonen(0.70)) bpm",
                            "Résistance légère — pied entier sur la pédale",
                            "Varier l'inclinaison toutes les 5 min si disponible"
                        ]),
                    WorkoutBlock(name: "Bloc 2 — Home Trainer Fartlek Doux",
                        description: "Cardio varié sans montée en Z4",
                        fcZone: zoneFC(3),
                        details: [
                            "5 min Z2 | 3 min Z3 → \(karvonen(0.72)) bpm",
                            "5 min Z2 | 3 min Z3",
                            "5 min Z2 (retour au calme)",
                            "⏱️ Total bloc 2 : 21 min — fartlek doux"
                        ]),
                    WorkoutBlock(name: "Mobilité + Proprioception",
                        description: "Rééducation fonctionnelle du pied — phase active",
                        fcZone: nil,
                        details: [
                            "Équilibre unipodal sur pied sain : 3 × 30s (yeux ouverts)",
                            "Transfert de poids lent pied sain → pied opéré : 10 reps si sans douleur",
                            "Étirements mollets assis avec sangle → 30s/côté",
                            "Massage voûte plantaire avec balle froide (loin de la cicatrice) → 2 min",
                            "⚠️ NOTER toute sensation anormale et rapporter au kinésithérapeute"
                        ])
                ],
                nutritionTip: "Séance cardio mixte : protéines + glucides modérés. Continuer les oméga-3 — régénération du nerf digital."
            )
        ]
    }

    // =========================================================
    // MARK: - DONNÉES SEMAINES 7–8 : Phase D
    // =========================================================

    private func semaineMortoneD(week: Int) -> [WorkoutSession] {
        let isDeload = week == 8
        return [
            WorkoutSession(
                id: "mortD-\(week)-mardi",
                day: "MARDI",
                title: isDeload ? "DÉLOAD FINAL — Cardio Récupérateur" : "Cardio Z2 Volume Max + Circuit Sol",
                duration: isDeload ? "40 min" : "85 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "DÉLOAD — Dernière Semaine du Cycle",
                        description: "Récupération complète avant bilan final",
                        fcZone: zoneFC(2),
                        details: [
                            "20 min home trainer Z2 bas → \(karvonen(0.60))–\(karvonen(0.65)) bpm",
                            "15 min core sol léger",
                            "🎯 Bilan complet : FC repos, poids, tour de taille, sensibilité du pied",
                            "⚠️ Consultation de suivi recommandée avant de reprendre le cycle"
                        ])
                ] : [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "Séance longue — apport énergétique adapté", fcZone: nil,
                        details: [
                            "20g protéines + 30g glucides lents (flocons d'avoine + banane)",
                            "300 ml eau avant le démarrage"
                        ]),
                    WorkoutBlock(name: "Elliptique — Bloc Cardio Principal",
                        description: "Séance record du cycle — surveiller le pied",
                        fcZone: zoneFC(2),
                        details: [
                            "50 min elliptique en Z2 continue",
                            "FC cible : \(karvonen(0.62))–\(karvonen(0.70)) bpm",
                            "Varier résistance : +1 cran toutes les 10 min puis retour",
                            "Utiliser les bras activement pour réduire charge pied",
                            "Boire 150-200 ml toutes les 15 min",
                            "⚡ Durée record du cycle — progression certifiée !"
                        ]),
                    WorkoutBlock(name: "Circuit Sol Intensifié (4 tours)",
                        description: "Gainage profond + force membres sans appui avant-pied",
                        fcZone: nil,
                        details: [
                            "Planche frontale avant-bras → 70s",
                            "Planche latérale pied ou genou → 50s/côté",
                            "Dead bug avec haltère léger → 14 reps/côté",
                            "Pont fessier unilatéral → 14 reps/côté",
                            "Extension de hanche quadrupédie → 15 reps/côté",
                            "Crunch oblique lent → 18 reps/côté",
                            "Repos 60s entre tours — 4 tours = maximum Phase D"
                        ])
                ],
                nutritionTip: "Séance longue : 25-30g protéines + glucides modérés dans les 40 min. S7 = point haut du cycle. Récupération prioritaire la nuit suivante."
            ),

            WorkoutSession(
                id: "mortD-\(week)-jeudi",
                day: "JEUDI",
                title: isDeload ? "DÉLOAD FINAL — Rameur Technique" : "Rameur Intensifié + Force Haut Complète",
                duration: isDeload ? "45 min" : "80 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Rameur Technique Déload",
                        description: "Focus qualité du geste — pas de performance",
                        fcZone: zoneFC(1),
                        details: [
                            "30 min rameur en Z1-Z2 bas",
                            "Travailler : séquence jambes-dos-bras, finition propre",
                            "15 min étirements dos, hanches, mollets",
                            "🎯 Évaluer la technique pour le cycle suivant"
                        ])
                ] : [
                    WorkoutBlock(name: "Rameur — Volume Phase D",
                        description: "Séance longue — record volume rameur",
                        fcZone: zoneFC(2),
                        details: [
                            "10 min échauffement progressif Z1→Z2",
                            "35 min continu en Z2 (24-26 coups/min)",
                            "FC cible : \(karvonen(0.63))–\(karvonen(0.72)) bpm",
                            "Option : 3 × (5 min à 26 coups/min + 5 min à 22 coups/min) = fartlek rameur",
                            "5 min retour au calme Z1"
                        ]),
                    WorkoutBlock(name: "Force Haut du Corps — Volume Complet (4 tours)",
                        description: "Maintien musculaire optimal — s'approcher du niveau pré-op",
                        fcZone: nil,
                        details: [
                            "Tirage vertical prise large → 10 reps",
                            "Rowing haltère unilatéral → 10 reps/côté",
                            "Développé couché haltères → 10 reps",
                            "Développé militaire assis → 10 reps",
                            "Curl marteau → 12 reps",
                            "Triceps poulie corde → 12 reps",
                            "Face pull → 15 reps",
                            "Repos 75s entre tours — 4 tours = maximum Phase D"
                        ]),
                    WorkoutBlock(name: "Proprioception + Mobilité Active",
                        description: "Rééducation fonctionnelle avancée",
                        fcZone: nil,
                        details: [
                            "Équilibre unipodal pied opéré : 3 × 20s si sans douleur",
                            "Marche talon-pointe sur ligne droite (courte distance) → 2 × 10m",
                            "Étirements mollets debout dos contre mur (pied opéré) → 20s si toléré",
                            "⚠️ Tout inconfort = noter + communiquer au kiné",
                            "🎯 Objectif fin Phase D : retour progressif à la marche normale"
                        ])
                ],
                nutritionTip: "Force haut + cardio long : 30-35g protéines + glucides complexes obligatoires. Zinc et vitamine C pour soutenir la cicatrisation nerveuse."
            ),

            WorkoutSession(
                id: "mortD-\(week)-samedi",
                day: "SAMEDI",
                title: isDeload ? "BILAN FINAL — Récupération Complète" : "Circuit Cardio-Force Fonctionnelle Adaptée",
                duration: isDeload ? "45 min" : "75 min",
                blocks: isDeload ? [
                    WorkoutBlock(name: "Récupération Complète — Fin du Cycle 8 Semaines",
                        description: "Dernière séance — bilan et préparation au cycle suivant",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min home trainer Z1 très léger → \(zoneFC(1))",
                            "15 min marche ou elliptique Z1",
                            "15 min étirements statiques corps entier",
                            "⚠️ Aucune intensité — ce cycle adapté Morton se termine ici",
                            "🎯 BILAN FINAL : peser, tour de taille, FC repos, sensibilité pied",
                            "📋 Comparer avec début S1 et consulter le chirurgien avant cycle suivant",
                            "💡 Si pied OK → prochain cycle peut réintroduire l'elliptique long et fentes légères"
                        ])
                ] : [
                    WorkoutBlock(name: "Échauffement Cardio-Articulaire",
                        description: "Activation complète avant le circuit",
                        fcZone: zoneFC(1),
                        details: [
                            "10 min mobilité dynamique assise et debout",
                            "Cercles d'épaules larges × 12 reps",
                            "Leg swings latéraux × 10 reps/côté (appui plat)",
                            "Squats de mobilité lents sur toute la plante de pied × 10 reps",
                            "3 min home trainer pour monter en Z1 haute"
                        ]),
                    WorkoutBlock(name: "Circuit Cardio-Force Adapté Morton (4 tours)",
                        description: "Version sans impact ni appui avant-pied — dépense maximale",
                        fcZone: zoneFC(3),
                        details: [
                            "🔥 Kettlebell swing assis sur banc (mouvement bras + buste) → 15 reps",
                            "🔥 Squat gobelet lent PIED PLAT (descente 4s) → 10 reps si toléré",
                            "🔥 Pompes genou ou standard → 12 reps",
                            "🔥 Rowing haltères debout pied plat OU assis → 12 reps",
                            "🔥 Gainage alternance : planche 30s + superman 10 reps",
                            "🔥 Mountain climbers lents au sol → 20 reps",
                            "Repos 90s entre tours — ⏱️ Total : ~35 min",
                            "📊 FC cible : \(karvonen(0.70))–\(karvonen(0.78)) bpm",
                            "⚠️ Squat : pieds à plat, poids sur les talons — JAMAIS avant-pied"
                        ]),
                    WorkoutBlock(name: "Cardio de Finition Z2",
                        description: "Oxyder les lipides libérés par le circuit",
                        fcZone: zoneFC(2),
                        details: [
                            "15 min elliptique ou home trainer en Z2",
                            "Transition directe depuis le circuit — ne pas s'asseoir",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm"
                        ]),
                    WorkoutBlock(name: "Retour au Calme + Bilan Semaine 7",
                        description: "Récupération et auto-évaluation",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min marche très légère ou pédalage Z1",
                            "Étirements : quadriceps couché → 30s, fléchisseurs hanche → 30s, mollets assis → 30s",
                            "🎯 S7 : noter FC repos demain matin, sensations pied, niveau d'énergie",
                            "📋 Préparer le bilan S8 (déload) et prévoir la consultation de suivi"
                        ])
                ],
                nutritionTip: isDeload
                    ? "Fin du cycle 8 semaines Morton : repas complet équilibré. Évaluer les progrès et planifier le retour aux exercices debout pour le prochain cycle."
                    : "Post-circuit cardio-force : 30-35g protéines + glucides modérés obligatoires. Récupération maximale requise."
            )
        ]
    }
}

#Preview {
    TrainingPlanMortoneView()
}
