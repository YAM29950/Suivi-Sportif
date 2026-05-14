import SwiftUI
import SDWebImageSwiftUI

// MARK: - Vue Plan Névrome de Morton — 4 Semaines (Équipement maison)

struct TrainingPlanMortoneView: View {
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

    // ── GIFs existants ────────────────────────────────────────────────────────
    @State private var showDeadBugGif              = false
    @State private var showPontFessierGif          = false
    @State private var showMountainClimbersGif     = false
    @State private var showCrunchCroiseGif         = false
    @State private var showTirageHorizontalGif     = false
    @State private var showCurlBicepsGif           = false
    @State private var showDeveloppeEpaulesGif     = false
    @State private var showExtensionTricepsGif     = false
    @State private var showRowingHorizontalGif     = false
    @State private var showExtensionHorizontaleGif = false
    // ── Ajoutés S2 ────────────────────────────────────────────────────────────
    @State private var showTirageVerticalGif           = false
    @State private var showRowingHorizontalDeuxBrasGif = false
    @State private var showDeveloppeMillitaireGif      = false
    @State private var showCurlBicepsBilateralGif      = false
    // ── NOUVEAUX (S3) ─────────────────────────────────────────────────────────
    @State private var showCurlMarteauGif              = false   // Curl marteau (pouce en haut)
    @State private var showRowingBilateralGif          = false   // Rowing bilatéral assis
    @State private var showExtensionTricepsHautGif     = false   // Extension triceps ancrage haut
    // ── NOUVEAU : Rowing élastique bilatéral assis (S3 mardi) ─────────────────
    @State private var showRowingElastiqueBilateralGif = false
    // ──────────────────────────────────────────────────────────────────────────

    let weeks = [1, 2, 3, 4]

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
                Text("Névrome de Morton — Récupération 4 semaines")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.yellow)
                Text("🏠 Rameur · Home Trainer · Elliptique · Tapis · Élastiques")
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.cyan.opacity(0.9))
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
                    gifRow(detail: detail, gifName: "deadbug",
                           borderColor: .yellow, caption: "Dead Bug — bras + jambe opposés",
                           isShowing: $showDeadBugGif)
                } else if detail.contains("Pont fessier") {
                    gifRow(detail: detail, gifName: "pontfessier",
                           borderColor: .orange, caption: "Pont fessier — talons posés, pas d'orteils",
                           isShowing: $showPontFessierGif)
                } else if detail.contains("Mountain climbers") {
                    gifRow(detail: detail, gifName: "mountainclimbers",
                           borderColor: .cyan, caption: "Mountain climbers lents — genou vers poitrine",
                           isShowing: $showMountainClimbersGif)
                } else if detail.contains("Crunches croisés") {
                    gifRow(detail: detail, gifName: "crunchcroise",
                           borderColor: .red, caption: "Crunches croisés lents — coude vers genou opposé",
                           isShowing: $showCrunchCroiseGif)

                // ── Rowing élastique bilatéral assis (S3 mardi) ──────────────
                // IMPORTANT : cette condition doit être AVANT "Tirage horizontal assis"
                // et AVANT "Rowing bilatéral assis" pour capturer la variante exacte S3
                } else if detail.contains("Rowing élastique bilatéral assis") {
                    gifRow(detail: detail, gifName: "tiragehorizontal",
                           borderColor: .blue, caption: "Rowing élastique bilatéral assis — élastique ancré devant",
                           isShowing: $showRowingElastiqueBilateralGif)

                } else if detail.contains("Tirage horizontal assis") {
                    gifRow(detail: detail, gifName: "tiragehorizontal",
                           borderColor: .blue, caption: "Tirage horizontal assis — élastique ancré devant",
                           isShowing: $showTirageHorizontalGif)

                // ── Rowing bilatéral assis (générique) ───────────────────────
                } else if detail.contains("Rowing bilatéral assis") {
                    gifRow(detail: detail, gifName: "tiragehorizontal",
                           borderColor: .blue, caption: "Rowing bilatéral assis — élastique ancré devant",
                           isShowing: $showRowingBilateralGif)

                // ── Curl biceps bilatéral élastique assis (S2+) ──────────────
                } else if detail.contains("Curl biceps bilatéral élastique assis") {
                    gifRow(detail: detail, gifName: "curlbiceps",
                           borderColor: .purple, caption: "Curl biceps bilatéral assis — élastique sous le pied sain",
                           isShowing: $showCurlBicepsBilateralGif)

                // ── NOUVEAU : Curl marteau (pouce en haut) ───────────────────
                } else if detail.contains("Curl marteau") {
                    gifRow(detail: detail, gifName: "curlavecelastique",
                           borderColor: .purple, caption: "Curl marteau — pouce en haut, élastique sous le pied sain",
                           isShowing: $showCurlMarteauGif)

                // ── Curl biceps unilatéral (S1) ───────────────────────────────
                } else if detail.contains("Curl biceps") {
                    gifRow(detail: detail, gifName: "curlbiceps",
                           borderColor: .purple, caption: "Curl biceps assis — élastique sous le pied sain",
                           isShowing: $showCurlBicepsGif)

                // ── Développé militaire élastique assis (S2+) ────────────────
                } else if detail.contains("Développé militaire élastique assis") || detail.contains("Développé militaire assis élastique") {
                    gifRow(detail: detail, gifName: "developpe",
                           borderColor: .green, caption: "Développé militaire assis — élastique sous le pied sain",
                           isShowing: $showDeveloppeMillitaireGif)

                // ── Développé épaules élastique assis (S1) ───────────────────
                } else if detail.contains("Développé épaules") {
                    gifRow(detail: detail, gifName: "developpe",
                           borderColor: .green, caption: "Développé épaules assis — élastique sous le pied sain",
                           isShowing: $showDeveloppeEpaulesGif)

                // ── NOUVEAU : Extension triceps ancrage haut (S3) ─────────────
                } else if detail.contains("Extension triceps ancrage haut") {
                    gifRow(detail: detail, gifName: "extension-triceps",
                           borderColor: .orange, caption: "Extension triceps ancrage haut — élastique ancré en hauteur",
                           isShowing: $showExtensionTricepsHautGif)

                // ── Triceps extension derrière la tête (S1/S2) ───────────────
                } else if detail.contains("Triceps extension") {
                    gifRow(detail: detail, gifName: "extension-triceps",
                           borderColor: .orange, caption: "Triceps extension derrière la tête — élastique ancré bas",
                           isShowing: $showExtensionTricepsGif)

                // ── Rowing horizontal deux bras assis (S2+) ──────────────────
                } else if detail.contains("Rowing horizontal deux bras assis") {
                    gifRow(detail: detail, gifName: "rowing-horizontal",
                           borderColor: .cyan, caption: "Rowing horizontal deux bras assis — élastique ancré devant",
                           isShowing: $showRowingHorizontalDeuxBrasGif)

                // ── Tirage vertical élastique / large assis (S2+) ────────────
                } else if detail.contains("Tirage vertical élastique assis") || detail.contains("Tirage vertical large assis") {
                    gifRow(detail: detail, gifName: "tiragevertical",
                           borderColor: .blue, caption: "Tirage vertical assis — élastique ancré en hauteur",
                           isShowing: $showTirageVerticalGif)

                // ── Rowing unilatéral assis coude vers hanche ─────────────────
                } else if detail.contains("Rowing unilatéral assis coude vers hanche") {
                    gifRow(detail: detail, gifName: "rowing-horizontal",
                           borderColor: .cyan, caption: "Rowing unilatéral — coude vers la hanche, élastique ancré devant",
                           isShowing: $showRowingHorizontalGif)

                // ── Face pull élastique horizontal ────────────────────────────
                } else if detail.contains("Face pull élastique horizontal") {
                    gifRow(detail: detail, gifName: "extension-horizontale",
                           borderColor: .pink, caption: "Face pull élastique horizontal — coudes hauts, mains vers le visage",
                           isShowing: $showExtensionHorizontaleGif)

                // ── Texte ordinaire ───────────────────────────────────────────
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

    // MARK: - GIF Row Helper (factorisé)

    @ViewBuilder
    private func gifRow(detail: String,
                        gifName: String,
                        borderColor: Color,
                        caption: String,
                        isShowing: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Text("•").foregroundColor(.yellow)
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { isShowing.wrappedValue.toggle() }
                }) {
                    HStack(spacing: 6) {
                        Text(detail).font(.system(size: 16, weight: .medium)).foregroundColor(.yellow).underline()
                        Image(systemName: isShowing.wrappedValue ? "chevron.up.circle.fill" : "play.circle.fill")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.yellow.opacity(0.9))
                    }
                }.buttonStyle(.plain)
            }
            if isShowing.wrappedValue {
                VStack(spacing: 6) {
                    AnimatedImage(name: gifName).resizable().scaledToFit()
                        .frame(width: 220, height: 155).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor.opacity(0.6), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                    Text(caption)
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.6)).italic()
                }
                .padding(.leading, 18)
                .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .topLeading)))
            }
        }
    }

    // MARK: - Précautions Card

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
                    text: "JAMAIS d'inclinaison tapis / sauts / impacts")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Rameur : sangle sur milieu/talon uniquement")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Home trainer : selle haute, appui milieu de pied")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Elliptique : test 5 min sans douleur d'abord (S3+)")
                precautionPoint(icon: "checkmark.circle.fill", color: .green,
                    text: "Tapis : marche PLATE uniquement, pas de course (S4)")
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
        case 1: return "Phase A — Post-op"
        case 2: return "Phase B — Consolidation"
        case 3: return "Phase C — Reprise"
        case 4: return "Phase D — Bilan Final"
        default: return ""
        }
    }

    private func weekObjective(_ week: Int) -> String {
        switch week {
        case 1: return "Rameur talon + élastiques assis + Core sol — zéro appui avant-pied"
        case 2: return "Cardio croisé + renforcement élastiques haut du corps, volume en hausse"
        case 3: return "Elliptique progressif + HIIT rameur + circuit élastiques complet"
        case 4: return "Déload final — marche tapis plate + récupération + bilan complet"
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
        case 1: return semaineMortone1()
        case 2: return semaineMortone2()
        case 3: return semaineMortone3()
        case 4: return semaineMortone4()
        default: return []
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
    // MARK: - SEMAINE 1 : Phase A — Post-op immédiat
    // =========================================================

    private func semaineMortone1() -> [WorkoutSession] {
        return [
            WorkoutSession(
                id: "mort1-mardi",
                day: "MARDI",
                title: "Rameur Technique + Core Sol",
                duration: "45 min",
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
                            "20 min continu à cadence modérée (20-22 coups/min)",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.68)) bpm",
                            "Ratio : 65% jambes (poussée talon) / 35% dos-bras",
                            "Surveiller l'appui : le pied opéré ne doit pas flex en hyper-extension",
                            "📊 Séance fondatrice — poser les bases du geste technique"
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
                            "⚠️ Tous les exercices se font au sol — 0 appui debout"
                        ]),
                    WorkoutBlock(name: "Retour au Calme",
                        description: "Mobilisation assis sur chaise ou au sol",
                        fcZone: zoneFC(1),
                        details: [
                            "5 min home trainer très léger",
                            "Étirements ischios et hanches en position allongée",
                            "Cercles de cheville LENTS en l'air (mobilité sans charge) → 10 reps",
                            "Élévation du pied opéré 10 min après la séance"
                        ])
                ],
                nutritionTip: "Dans les 30-40 min : 25g protéines + glucides légers. Pied surélevé pendant la récupération. Oméga-3 réguliers pour la régénération nerveuse."
            ),

            WorkoutSession(
                id: "mort1-jeudi",
                day: "JEUDI",
                title: "Élastiques Haut du Corps + Home Trainer",
                duration: "60 min",
                blocks: [
                    WorkoutBlock(name: "Home Trainer — Cardio Échauffement",
                        description: "Pédalage milieu de pied — réglage hauteur selle impératif",
                        fcZone: zoneFC(1),
                        details: [
                            "⚠️ Régler la selle très haute : jambe quasi-tendue en bas de course",
                            "10 min en Z1 — montée progressive vers Z2",
                            "Objectif : appui sur le milieu/talon, pas sur l'avant-pied",
                            "FC cible : \(karvonen(0.50))–\(karvonen(0.60)) bpm"
                        ]),
                    WorkoutBlock(name: "Home Trainer — Cardio Principal",
                        description: "Endurance fondamentale assis — pied protégé",
                        fcZone: zoneFC(2),
                        details: [
                            "20 min en Z2 — résistance légère",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                            "Cadence : 80-90 rpm — éviter les grosses résistances",
                            "Boire 150 ml à mi-séance"
                        ]),
                    WorkoutBlock(name: "Renforcement Élastiques Haut du Corps (3 tours)",
                        description: "Élastique ancré à un point fixe ou porté sous le pied sain",
                        fcZone: nil,
                        details: [
                            "🔴 Tirage horizontal assis (élastique ancré devant) → 15 reps",
                            "🔴 Curl biceps assis avec élastique → 15 reps/côté",
                            "🔴 Développé épaules élastique assis → 12 reps",
                            "🔴 Triceps extension derrière la tête (élastique) → 12 reps",
                            "🔴 Rowing unilatéral assis coude vers hanche (élastique) → 12 reps/côté",
                            "🔴 Face pull élastique horizontal → 15 reps",
                            "Repos 75s entre tours — ⏱️ Total : ~22 min",
                            "⚠️ Ancrage élastique : porte, pied de table ou pied sain — JAMAIS avant-pied opéré"
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
                id: "mort1-samedi",
                day: "SAMEDI",
                title: "Récupération Très Légère",
                duration: "35 min",
                blocks: [
                    WorkoutBlock(name: "Séance de Récupération — S1",
                        description: "Corps et pied fraîchement opérés — aller très doucement",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min rameur TRÈS léger (15 coups/min, résistance minimale)",
                            "FC cible : rester sous \(karvonen(0.58)) bpm",
                            "10 min home trainer Z1 — maintenir la circulation",
                            "⚠️ S1 post-op : si douleur même légère → ARRÊT et repos total",
                            "Objectif : activer la circulation sanguine pour la cicatrisation"
                        ]),
                    WorkoutBlock(name: "Mobilité Sol — Récupération Active",
                        description: "Étirements et travail respiratoire",
                        fcZone: nil,
                        details: [
                            "Cat-cow au sol → 10 reps",
                            "Étirements fléchisseurs hanche allongé → 30s/côté",
                            "Respiration cohérence cardiaque 5 min (inspiration 5s / expiration 5s)",
                            "Cercles de cheville lents en l'air → 10 reps"
                        ])
                ],
                nutritionTip: "Séance légère : protéines suffisent. Privilégier oméga-3 (poisson gras, graines de lin) pour réduire l'inflammation post-opératoire."
            )
        ]
    }

    // =========================================================
    // MARK: - SEMAINE 2 : Phase B — Consolidation
    // =========================================================

    private func semaineMortone2() -> [WorkoutSession] {
        return [
            WorkoutSession(
                id: "mort2-mardi",
                day: "MARDI",
                title: "Home Trainer Z2 Long + Élastiques Force",
                duration: "70 min",
                blocks: [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: [
                            "20g protéines + 1 source glucides lents (flocons d'avoine)",
                            "Hydratation : 300 ml avant de commencer"
                        ]),
                    WorkoutBlock(name: "Home Trainer — Cardio Principal",
                        description: "Séance pivot — volume en hausse vs S1",
                        fcZone: zoneFC(2),
                        details: [
                            "40 min home trainer en Z2",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm",
                            "10 premières minutes : montée progressive (Z1→Z2)",
                            "Vérifier appui pied à chaque changement de résistance",
                            "Boire 150 ml toutes les 10 min",
                            "⚡ +15-20 min vs S1 — consolidation cardio"
                        ]),
                    WorkoutBlock(name: "Circuit Élastiques Complet (3 tours)",
                        description: "Force haut du corps + gainage — élastiques ancrage fixe",
                        fcZone: nil,
                        details: [
                            "🔴 Tirage vertical élastique assis (ancre haute, ex: dessus de porte) → 12 reps",
                            "🔴 Rowing horizontal deux bras assis (élastique ancré devant) → 15 reps",
                            "🔴 Développé militaire élastique assis → 12 reps",
                            "🔴 Curl biceps bilatéral élastique assis → 15 reps",
                            "🔴 Pompes genoux au sol → 12 reps",
                            "Gainage ventral avant-bras → 50s",
                            "Pont fessier bilatéral (talons posés) → 18 reps",
                            "Repos 90s entre tours — ⏱️ Total : ~25 min",
                            "💡 Ancrer l'élastique sous le pied sain pour les exercices en position debout"
                        ])
                ],
                nutritionTip: "Phase B : augmenter progressivement les protéines à 130-150g/j. Post-effort : protéines rapides + glucides complexes (riz, avoine)."
            ),

            WorkoutSession(
                id: "mort2-jeudi",
                day: "JEUDI",
                title: "Rameur Intensité Modérée + Core Avancé",
                duration: "65 min",
                blocks: [
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
                            "Dead bug avec bras tendus (élastique léger en option) → 12 reps/côté",
                            "Pont fessier unilatéral (côté sain) → 12 reps",
                            "Abdos bicycle lents → 16 reps",
                            "Superman dorsal + maintien 2s → 12 reps",
                            "Repos 60s entre tours — ⏱️ Total : ~20 min"
                        ])
                ],
                nutritionTip: "Effort modéré-long : hydratation 500 ml pendant. Post-effort dans les 30 min : 30g protéines + glucides modérés."
            ),

            WorkoutSession(
                id: "mort2-samedi",
                day: "SAMEDI",
                title: "Cardio Croisé Assis (Rameur + Home Trainer)",
                duration: "65 min",
                blocks: [
                    WorkoutBlock(name: "Cardio Croisé — Bloc 1 : Rameur",
                        description: "Démarrer par le rameur — moins de résistance pied",
                        fcZone: zoneFC(2),
                        details: [
                            "25 min rameur en Z2",
                            "Cadence cible : 22-26 coups/min",
                            "FC cible : \(karvonen(0.60))–\(karvonen(0.70)) bpm"
                        ]),
                    WorkoutBlock(name: "Transition Active",
                        description: "Laisser descendre la FC entre les deux machines",
                        fcZone: zoneFC(1),
                        details: [
                            "3 min marche légère à plat (appui pied plat obligatoire)",
                            "Boire 200 ml — régler la selle du home trainer"
                        ]),
                    WorkoutBlock(name: "Cardio Croisé — Bloc 2 : Home Trainer",
                        description: "Alterner les appareils = moins de fatigue locale sur le pied",
                        fcZone: zoneFC(2),
                        details: [
                            "30 min home trainer Z2",
                            "Résistance légère à modérée — pied milieu",
                            "Varier la cadence toutes les 5 min : 85 rpm puis 95 rpm",
                            "📊 Total cardio croisé : ~55 min — maximum Phase B"
                        ]),
                    WorkoutBlock(name: "Retour au Calme + Mobilité Pied",
                        description: "Récupération active et rééducation précoce",
                        fcZone: zoneFC(1),
                        details: [
                            "7 min home trainer très léger Z1",
                            "Étirements mollets ASSIS avec élastique → 30s/côté",
                            "Cercles de cheville passifs → 15 reps",
                            "Massage léger voûte plantaire avec balle froide (loin de la cicatrice)"
                        ])
                ],
                nutritionTip: "Séance longue cardio : protéines + glucides complexes. Oméga-3 réguliers toute la Phase B pour optimiser la cicatrisation nerveuse."
            )
        ]
    }

    // =========================================================
    // MARK: - SEMAINE 3 : Phase C — Reprise elliptique + HIIT
    // =========================================================

    private func semaineMortone3() -> [WorkoutSession] {
        return [
            WorkoutSession(
                id: "mort3-mardi",
                day: "MARDI",
                title: "Elliptique Progressif + Circuit Élastiques",
                duration: "75 min",
                blocks: [
                    WorkoutBlock(name: "Collation Pré-Effort", description: "30 min avant la séance", fcZone: nil,
                        details: [
                            "20g protéines + 1 fruit",
                            "💡 S3 = réintroduction elliptique — observer attentivement les sensations pied"
                        ]),
                    WorkoutBlock(name: "Elliptique — Test Puis Cardio",
                        description: "⚠️ Première utilisation depuis l'opération : progresser doucement",
                        fcZone: zoneFC(2),
                        details: [
                            "5 min test à résistance NULLE — observer douleur/fourmillement",
                            "Si 0 douleur → continuer 25 min en Z2",
                            "Si douleur → remplacer par home trainer 25 min",
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
                    WorkoutBlock(name: "Circuit Élastiques + Sol (3 tours)",
                        description: "Force corps entier — élastiques + poids de corps, sans avant-pied",
                        fcZone: nil,
                        details: [
                            "🔴 Tirage vertical élastique assis → 12 reps",
                            "🔴 Rowing élastique bilatéral assis → 15 reps",
                            "Planche sur avant-bras → 60s",
                            "Dead bug avec bras tendus → 14 reps/côté",
                            "Pont fessier unilatéral (alterner les 2 côtés) → 12 reps",
                            "Superman hold 3s → 12 reps",
                            "🔴 Extension triceps élastique ancrage haut → 12 reps",
                            "Repos 60s entre tours — ⏱️ Total : ~22 min"
                        ]),
                    WorkoutBlock(name: "Retour au Calme",
                        description: "Toujours finir en douceur et noter les sensations",
                        fcZone: zoneFC(1),
                        details: [
                            "5 min home trainer très léger",
                            "📝 NOTER : douleur elliptique 0-10 ? Fourmillement ? Œdème post-séance ?",
                            "Glace 10 min sur le pied si sensation de chaleur après l'elliptique",
                            "Étirements hanches et ischio allongé avec élastique"
                        ])
                ],
                nutritionTip: "Phase C : si elliptique toléré, augmenter les glucides complexes post-effort. 30g protéines + riz ou patate douce."
            ),

            WorkoutSession(
                id: "mort3-jeudi",
                day: "JEUDI",
                title: "Rameur HIIT Assis + Élastiques Force Haut",
                duration: "70 min",
                blocks: [
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
                            "📊 Alternative si douleur pied : 8 × (30s/90s) sur home trainer haute cadence"
                        ]),
                    WorkoutBlock(name: "Retour au Calme Rameur",
                        description: "Évacuer les lactates — toujours assis",
                        fcZone: zoneFC(1),
                        details: [
                            "8 min rameur très léger (16-18 coups/min)",
                            "FC doit redescendre sous \(karvonen(0.58)) bpm avant d'arrêter"
                        ]),
                    WorkoutBlock(name: "Circuit Élastiques Haut du Corps (3 tours)",
                        description: "Volume supérieur consolidé — élastiques ancrage fixe",
                        fcZone: nil,
                        details: [
                            "🔴 Tirage vertical large assis (élastique ancrage haut) → 12 reps",
                            "🔴 Rowing bilatéral assis (élastique ancrage devant) → 15 reps",
                            "🔴 Développé militaire assis élastique → 12 reps",
                            "🔴 Curl marteau (pouce en haut) élastique → 12 reps/côté",
                            "🔴 Extension triceps ancrage haut → 12 reps",
                            "🔴 Face pull élastique horizontal → 15 reps",
                            "Repos 75s entre tours — ⏱️ Total : ~20 min"
                        ])
                ],
                nutritionTip: "HIIT assis = même réponse hormonale que HIIT debout. Fenêtre anabolique : 30g protéines rapides + 40g glucides dans les 25 min post-HIIT."
            ),

            WorkoutSession(
                id: "mort3-samedi",
                day: "SAMEDI",
                title: "Cardio Croisé Long + Proprioception",
                duration: "70 min",
                blocks: [
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
                            "Étirements mollets assis avec élastique → 30s/côté",
                            "Massage voûte plantaire avec balle froide (loin de la cicatrice) → 2 min",
                            "⚠️ NOTER toute sensation anormale et rapporter au kinésithérapeute"
                        ])
                ],
                nutritionTip: "Séance cardio mixte : protéines + glucides modérés. Continuer les oméga-3 — régénération du nerf digital."
            )
        ]
    }

    // =========================================================
    // MARK: - SEMAINE 4 : Phase D — Déload Final & Bilan
    // =========================================================

    private func semaineMortone4() -> [WorkoutSession] {
        return [
            WorkoutSession(
                id: "mort4-mardi",
                day: "MARDI",
                title: "DÉLOAD FINAL — Cardio Récupérateur",
                duration: "40 min",
                blocks: [
                    WorkoutBlock(name: "Déload — Dernière Semaine du Cycle",
                        description: "Volume réduit de 30% — récupération avant bilan final",
                        fcZone: zoneFC(2),
                        details: [
                            "20 min home trainer Z2 bas → \(karvonen(0.60))–\(karvonen(0.65)) bpm",
                            "Résistance très légère — cadence confortable 75-85 rpm"
                        ]),
                    WorkoutBlock(name: "Core Sol Léger",
                        description: "Maintien du tonus — pas de progression cette semaine",
                        fcZone: nil,
                        details: [
                            "Planche avant-bras → 45s",
                            "Dead bug → 10 reps/côté",
                            "Pont fessier bilatéral → 15 reps",
                            "Superman dorsal → 10 reps",
                            "⏱️ 1 seul tour — récupération prioritaire"
                        ]),
                    WorkoutBlock(name: "Bilan Intermédiaire",
                        description: "Évaluer les progrès avant la dernière séance",
                        fcZone: nil,
                        details: [
                            "🎯 Mesurer FC repos ce matin (avant levée)",
                            "🎯 Peser + tour de taille — comparer avec S1",
                            "🎯 Sensibilité du pied : noter 0-10 vs début S1",
                            "⚠️ Consultation de suivi recommandée avant de reprendre le cycle"
                        ])
                ],
                nutritionTip: "Déload : alimentation équilibrée sans surcharge. Protéines 120g/j pour maintenir la masse. Oméga-3 jusqu'à la fin."
            ),

            WorkoutSession(
                id: "mort4-jeudi",
                day: "JEUDI",
                title: "DÉLOAD FINAL — Tapis Marche + Rameur Doux",
                duration: "45 min",
                blocks: [
                    WorkoutBlock(name: "🆕 Tapis de Course — Marche Plate Uniquement",
                        description: "Première réintroduction marche motorisée — INCLINAISON 0% OBLIGATOIRE",
                        fcZone: zoneFC(1),
                        details: [
                            "⚠️ Inclinaison : 0% — JAMAIS de pente en phase post-op Morton",
                            "Vitesse : 3,5–4,5 km/h — marche confortable uniquement",
                            "15 min en Z1 — observer attentivement les sensations du pied",
                            "FC cible : \(karvonen(0.50))–\(karvonen(0.60)) bpm",
                            "Si douleur ou fourmillement → arrêter immédiatement et noter",
                            "Chaussures larges à semelle plate — éviter tout appui avant-pied",
                            "📝 NOTER : douleur 0-10 ? Durée de tolérance ?"
                        ]),
                    WorkoutBlock(name: "Rameur Technique Déload",
                        description: "Focus qualité du geste — pas de performance",
                        fcZone: zoneFC(1),
                        details: [
                            "20 min rameur en Z1 bas → \(karvonen(0.50))–\(karvonen(0.58)) bpm",
                            "Travailler la séquence : jambes → dos → bras, finition propre",
                            "Cadence 18-20 coups/min — qualité sur quantité",
                            "🎯 Évaluer la technique propre pour le cycle suivant"
                        ]),
                    WorkoutBlock(name: "Proprioception + Étirements",
                        description: "Rééducation finale et récupération douce",
                        fcZone: nil,
                        details: [
                            "Équilibre unipodal pied opéré : 3 × 20s si sans douleur",
                            "Étirements mollets assis avec élastique → 30s/côté",
                            "Étirements ischio allongé avec élastique → 30s/côté",
                            "Étirements dos : cat-cow → 10 reps"
                        ])
                ],
                nutritionTip: "Récupération active : glucides modérés + protéines. Zinc et vitamine C pour finaliser la cicatrisation nerveuse."
            ),

            WorkoutSession(
                id: "mort4-samedi",
                day: "SAMEDI",
                title: "BILAN FINAL — Récupération Complète",
                duration: "40 min",
                blocks: [
                    WorkoutBlock(name: "Récupération Complète — Fin du Cycle 4 Semaines",
                        description: "Dernière séance — bilan et préparation au cycle suivant",
                        fcZone: zoneFC(1),
                        details: [
                            "15 min home trainer Z1 très léger → \(zoneFC(1))",
                            "10 min tapis marche plate Z1 (si bien toléré jeudi)",
                            "⚠️ Aucune intensité — ce cycle adapté Morton se termine ici",
                            "🎯 BILAN FINAL : peser, tour de taille, FC repos, sensibilité pied",
                            "📋 Comparer avec début S1 et consulter le chirurgien avant cycle suivant",
                            "💡 Si pied OK → prochain cycle peut allonger la marche tapis et introduire l'elliptique long"
                        ]),
                    WorkoutBlock(name: "Étirements Corps Entier",
                        description: "Dernière session de mobilité du cycle",
                        fcZone: nil,
                        details: [
                            "Étirements quadriceps debout appui pied plat → 30s/côté",
                            "Pigeon pose au sol (fléchisseurs hanche) → 30s/côté",
                            "Étirements ischio avec élastique allongé → 30s/côté",
                            "Respiration cohérence cardiaque 5 min (5s/5s) — fin du cycle"
                        ])
                ],
                nutritionTip: "Fin du cycle 4 semaines Morton : repas complet équilibré. Évaluer les progrès et planifier le retour progressif aux exercices debout pour le prochain cycle."
            )
        ]
    }
}

#Preview {
    TrainingPlanMortoneView()
}
