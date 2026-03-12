import SwiftUI

// MARK: - Section Enum

private enum NoticeSection: String, CaseIterable, Identifiable {
    case home    = "Menu Principal"
    case add     = "Mes Entr."
    case modal   = "Modal Ajout"
    case stats   = "Statistiques"
    case detail  = "Detail Entr."
    case plan    = "Plan 8 Semaines"
    case heart   = "Freq. Cardiaque"
    case profile = "Profil Utilisateur"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .add:     return "list.bullet.clipboard"
        case .modal:   return "square.and.pencil"
        case .stats:   return "chart.bar.fill"
        case .detail:  return "doc.text.fill"
        case .plan:    return "calendar.badge.clock"
        case .heart:   return "heart.fill"
        case .profile: return "person.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .home:    return .blue
        case .add:     return .green
        case .modal:   return Color(red: 0.08, green: 0.72, blue: 0.65)
        case .stats:   return .purple
        case .detail:  return .orange
        case .plan:    return .cyan
        case .heart:   return .red
        case .profile: return .orange
        }
    }
}

// MARK: - Bar Chart Data

private struct YearKm: Identifiable {
    let id = UUID()
    let year: String
    let km: Double
    var isCurrent: Bool { year == "2026" }
}

private let htData: [YearKm] = [
    YearKm(year: "2019", km: 98),
    YearKm(year: "2020", km: 168),
    YearKm(year: "2021", km: 3236),
    YearKm(year: "2022", km: 3381),
    YearKm(year: "2023", km: 2305),
    YearKm(year: "2024", km: 3718),
    YearKm(year: "2025", km: 2997),
    YearKm(year: "2026", km: 282),
]

private let activityRows: [(emoji: String, name: String, modal: String, highlight: Bool, note: String)] = [
    ("P", "Tous",         "TousModal",        false, "cumul toutes activites"),
    ("M", "Marche",       "MarcheModal",      false, ""),
    ("T", "Tapis",        "TapisModal",       false, ""),
    ("E", "Elliptique",   "ElliptiqueModal",  false, ""),
    ("R", "Rameur",       "RameurModal",      false, ""),
    ("H", "Home Trainer", "HomeTrainerModal", true,  "<-- exemple ci-dessous"),
    ("X", "Triathlon",    "TriathlonModal",   false, ""),
    ("P", "Piste",        "PisteModal",       false, ""),
    ("C", "Route",        "RouteModal",       false, ""),
    ("V", "VTT",          "VTTModal",         false, ""),
    ("N", "Piscine",      "PiscineModal",     false, ""),
    ("O", "Mer",          "MerModal",         false, ""),
]

// MARK: - Main Modal

struct NoticeModal: View {
    @Binding var isPresented: Bool
    @State private var selected: NoticeSection = .home
    @State private var showHTDemo: Bool = false
    @State private var showListDemo: Bool = false
    @State private var showStatsDemo: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.02, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebarView
                Divider().background(Color.white.opacity(0.12))
                ScrollView {
                    pageContent(for: selected)
                        .padding(26)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 900, height: 660)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.6), radius: 40)
    }

    // MARK: Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("Notice")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 10)

            ForEach(NoticeSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selected = section
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: section.icon)
                            .font(.system(size: 13))
                            .foregroundColor(section.color)
                            .frame(width: 20)
                        Text(section.rawValue)
                            .font(.system(size: 12, weight: selected == section ? .bold : .medium))
                            .foregroundColor(selected == section ? .white : .white.opacity(0.65))
                        Spacer()
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(
                        selected == section
                            ? section.color.opacity(0.30)
                            : Color.white.opacity(0.04)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selected == section ? section.color.opacity(0.50) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                    Text("Fermer")
                    Spacer()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 9)
                .background(Color.red.opacity(0.40))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 195)
        .background(Color.white.opacity(0.06))
    }

    // MARK: Page Router

    @ViewBuilder
    private func pageContent(for section: NoticeSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            pageHeaderView(section: section)
            switch section {
            case .home:    homePageView
            case .add:     addPageView
            case .modal:   modalPageView
            case .stats:   statsPageView
            case .detail:  detailPageView
            case .plan:    planPageView
            case .heart:   heartPageView
            case .profile: profilePageView
            }
        }
    }

    // MARK: Shared UI Helpers

    private func pageHeaderView(section: NoticeSection) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(section.color.opacity(0.22))
                    .frame(width: 50, height: 50)
                    .shadow(color: section.color.opacity(0.35), radius: 12)
                Image(systemName: section.icon)
                    .font(.system(size: 24))
                    .foregroundColor(section.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(section.rawValue)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                LinearGradient(
                    colors: [section.color, section.color.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 2)
                .cornerRadius(1)
            }
        }
        .padding(.bottom, 4)
    }

    private func introBox(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.86))
            .lineSpacing(4)
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.30), lineWidth: 1)
            )
            .cornerRadius(10)
    }

    private func blockView(heading: String, color: Color, body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(heading)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    // MARK: - HOME PAGE

    private var homePageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "L'ecran d'accueil est le coeur de l'application. Il centralise toutes les informations cles et donne acces a toutes les fonctionnalites via le menu lateral.",
                color: .blue
            )
            blockView(heading: "Menu lateral gauche", color: .blue,
                      body: "Huit boutons permettent de naviguer entre les differentes vues : Menu principal, Mes Entrainements, Ajouter, Statistiques, Plan 8 Semaines, Frequence Cardiaque, Profil et Notice. Le bouton actif est mis en evidence par une couleur plus vive.")
            blockView(heading: "Bandeau defilant", color: .blue,
                      body: "Affiche en temps reel la date du jour, le numero du jour dans l'annee et les jours restants, sous forme de texte anime qui defile en continu.")
            activityIconsBlockView
            modalStructureBlockView
            blockView(heading: "Tableau de kilometrage", color: .blue,
                      body: "Trois lignes comparatives affichent pour chaque activite : les km du mois (annee N-1), les km du mois en cours (annee N), et un symbole pouce haut / pouce bas / ok indiquant la progression.")
            blockView(heading: "Panneau Fete et Dicton (bouton orange)", color: .blue,
                      body: "Accessible via le bouton chevron orange, ce panneau revele la fete du jour et le dicton associe, issus du calendrier interne.")
            blockView(heading: "Panneau personnalisable (bouton violet)", color: .blue,
                      body: "Accessible via le bouton chevron violet, ce panneau est reserve a un usage futur ou a vos informations personnelles.")
        }
    }

    // MARK: Activity Icons Block (extracted to help compiler)

    private var activityIconsBlockView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icones d'activite - 12 boutons, 12 modals graphiques")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.blue)
            Text("Chaque icone correspond a une categorie sportive. Un simple clic ouvre le modal graphique dedie a ce sport, affichant l'historique complet en barres annuelles.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.78))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            activityRowsListView
            htDemoToggleButton
            if showHTDemo {
                homeTrainerDemoView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.22), lineWidth: 1))
        .cornerRadius(10)
    }

    private var activityRowsListView: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(activityRows, id: \.name) { item in
                activityRowItem(item: item)
            }
        }
    }

    private func activityRowItem(item: (emoji: String, name: String, modal: String, highlight: Bool, note: String)) -> some View {
        Group {
            if item.highlight {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showHTDemo.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(item.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 110, alignment: .leading)
                        Text("->")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                        Text(item.modal)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(red: 0.76, green: 0.71, blue: 0.99))
                        Text(item.note)
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Spacer()
                        Image(systemName: showHTDemo ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.purple.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(showHTDemo ? 0.35 : 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.purple.opacity(0.60), lineWidth: 1)
                    )
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 110, alignment: .leading)
                    Text("->")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                    Text(item.modal)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.blue.opacity(0.85))
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.40))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .cornerRadius(7)
            }
        }
    }

    private var htDemoToggleButton: some View {
        EmptyView()
    }

    // MARK: Modal Structure Block (extracted to help compiler)

    private var modalStructureBlockView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structure commune de chaque modal graphique")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.blue)
            structureRow(num: "1", title: "En-tete colore",
                         desc: "Nom du sport, icone, et bandeau affichant les km du mois en cours (annee actuelle) et les km du meme mois l'annee precedente.")
            structureRow(num: "2", title: "Graphique a barres",
                         desc: "Une barre par annee depuis la premiere seance. La valeur est affichee au-dessus. L'annee en cours est coloree differemment et marquee d'une etoile.")
            structureRow(num: "3", title: "Bouton Quitter",
                         desc: "Ferme le modal et revient a l'ecran principal.")
            Text("Les couleurs varient selon le sport (violet pour Home Trainer, bleu pour Piscine...) pour une identification immediate.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.40))
                .italic()
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.22), lineWidth: 1))
        .cornerRadius(10)
    }

    private func structureRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.20))
                    .overlay(Circle().stroke(Color.blue.opacity(0.50), lineWidth: 1))
                    .frame(width: 24, height: 24)
                Text(num)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: HomeTrainer Demo

    private var homeTrainerDemoView: some View {
        VStack(spacing: 0) {
            // Header bar
            ZStack {
                Color.purple.opacity(0.45)
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Text("Home Trainer")
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        kmBadgeView(km: "60 Km", period: "Mars 2026", color: .cyan)
                        Text("en")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.50))
                        kmBadgeView(km: "414 Km", period: "Mars 2025", color: .red)
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Quitter")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.40))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.red.opacity(0.50), lineWidth: 1))
                        .cornerRadius(7)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(height: 52)

            // Chart area
            VStack(spacing: 6) {
                Text("Statistiques Home Trainer")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 12)

                htBarChartView
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.11, blue: 0.55).opacity(0.8),
                        Color(red: 0.07, green: 0.04, blue: 0.18).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.35), lineWidth: 1))
    }

    private func kmBadgeView(km: String, period: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(km)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(color)
            Text(period)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(color.opacity(0.18))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(color.opacity(0.45), lineWidth: 1))
        .cornerRadius(7)
    }

    private var htBarChartView: some View {
        let maxKm = htData.map(\.km).max() ?? 1.0
        return GeometryReader { geo in
            let count = CGFloat(htData.count)
            let spacing: CGFloat = 6
            let barW = (geo.size.width - spacing * (count - 1)) / count
            let chartH = geo.size.height - 36

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(htData) { item in
                    VStack(spacing: 0) {
                        // Value label
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.isCurrent
                                      ? Color.cyan.opacity(0.90)
                                      : Color(red: 0.12, green: 0.08, blue: 0.30))
                            Text(item.isCurrent
                                 ? "\(Int(item.km)) *"
                                 : (item.km >= 1000
                                    ? "\(Int(item.km / 1000))k"
                                    : "\(Int(item.km))"))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(.horizontal, 2)
                        }
                        .frame(width: barW, height: 16)
                        .padding(.bottom, 2)

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                item.isCurrent
                                ? LinearGradient(
                                    colors: [.cyan, Color(red: 0.0, green: 0.55, blue: 0.80)],
                                    startPoint: .top, endPoint: .bottom)
                                : LinearGradient(
                                    colors: [Color(red: 0.65, green: 0.20, blue: 0.90), Color(red: 0.45, green: 0.10, blue: 0.65)],
                                    startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: barW, height: max(4, CGFloat(item.km / maxKm) * chartH))

                        // Year label
                        Text(item.year)
                            .font(.system(size: 8, weight: item.isCurrent ? .black : .regular))
                            .foregroundColor(item.isCurrent ? .cyan : .white.opacity(0.60))
                            .frame(height: 16)
                    }
                    .frame(width: barW)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(height: 200)
    }

    // MARK: - MES ENTRAINEMENTS PAGE

    private var addPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "La vue Mes Entrainements (TrainingsListView) est le journal complet de toutes vos seances. Une rangee de boutons-images en haut permet de filtrer instantanement la liste par sport.",
                color: .green
            )

            // Bloc Boutons-images avec toggle demo intégré
            VStack(alignment: .leading, spacing: 8) {
                Text("Boutons-images de filtrage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
                Text("Chaque image represente un sport. Cliquer dessus selectionne ce sport (bordure verte) et filtre immediatement la liste pour n'afficher que les seances de cette activite.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.78))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showListDemo.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: showListDemo ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 13))
                        Text(showListDemo ? "Masquer l'exemple" : "Voir l'exemple — TrainingsListView")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.85, green: 1.0, blue: 0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(showListDemo ? 0.40 : 0.22))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)

                if showListDemo {
                    trainingListDemoView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.22), lineWidth: 1))
            .cornerRadius(10)

            blockView(heading: "Colonnes du tableau", color: .green,
                      body: "La liste affiche : Date, Sport, Km, Temps, Moyenne, Calories, A jeun (Oui/Non), Forme (etoiles), Observations et un bouton Details.")
            blockView(heading: "Tri par colonne", color: .green,
                      body: "Cliquez sur l'en-tete d'une colonne pour trier la liste croissant ou decroissant. Une fleche indique le tri actif.")
            blockView(heading: "Acces au detail", color: .green,
                      body: "La fleche en colonne Details ouvre la fiche complete de la seance (TrainingDetailView).")
            blockView(heading: "Mise a jour automatique", color: .green,
                      body: "La liste se recharge automatiquement apres chaque ajout ou modification grace a la notification trainingsDidUpdate.")
        }
    }

    // MARK: Training List Demo

    private var trainingListDemoView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image("TrainingsListExample")
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                )
            Text("Exemple : filtrage par Home Trainer (bordure verte), cartes statistiques et tableau de seances.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.55))
                .italic()
        }
    }

    // MARK: - MODAL PAGE

    private var modalPageView: some View {
        let c = Color(red: 0.08, green: 0.72, blue: 0.65)
        return VStack(alignment: .leading, spacing: 12) {
            introBox(
                "AddTrainingModal est une fenetre flottante superposee a l'ecran courant. Elle permet d'enregistrer rapidement un entrainement sans quitter la vue en cours.",
                color: c
            )
            blockView(heading: "Acces rapide", color: c,
                      body: "Ouvrez le modal en appuyant sur le bouton vert Ajouter du menu lateral. La saisie est simplifiee pour aller a l'essentiel.")
            blockView(heading: "Mise a jour en temps reel", color: c,
                      body: "Des la validation, le modal se ferme et toutes les statistiques sont recalculees immediatement grace a la notification trainingsDidUpdate.")
            blockView(heading: "Annulation", color: c,
                      body: "Fermez le modal a tout moment via le bouton Annuler. Aucune donnee n'est enregistree si vous annulez.")
        }
    }

    // MARK: - STATS PAGE

    private var statsPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "StatisticsView offre une analyse approfondie de vos performances sur l'ensemble de votre historique d'entrainement.",
                color: .purple
            )
            blockView(heading: "Boutons-images de filtrage par sport", color: .purple,
                      body: "Comme dans Mes Entrainements, une rangee d'images permet de cibler un sport. Cliquer sur une image (bordure verte) filtre tous les graphiques et statistiques pour ce sport uniquement.")
            blockView(heading: "Vue d'ensemble", color: .purple,
                      body: "Six cartes affichent les indicateurs cles : nombre d'Entrainements, Distance totale (km), Calories totales, Temps total, Moyenne calories et Serie actuelle (jours consecutifs).")
            blockView(heading: "Graphique Evolution", color: .purple,
                      body: "Un graphique mensuel visualise l'evolution de la Distance, des Calories ou de la Duree selon la metrique choisie. Trois styles disponibles : Barres, Barres empilees (par sport) et Ligne.")
            blockView(heading: "Repartition par sport", color: .purple,
                      body: "Un tableau liste chaque activite avec son nombre de seances, distance totale, temps total et pourcentage par rapport a l'ensemble.")
            blockView(heading: "Records", color: .purple,
                      body: "Quatre records personnels sont affiches : distance maximale, calories maximales, duree maximale et meilleure vitesse.")

            // Bloc Filtres avec demo integree
            VStack(alignment: .leading, spacing: 8) {
                Text("Filtres periode")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.purple)
                Text("Combinez le filtre Annee, le filtre Mois et les boutons de periode rapide (7 jours, 30 jours, 3 mois, 1 an, Tout) pour affiner les donnees. Un bouton Reset remet tout a zero.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.78))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showStatsDemo.toggle()
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: showStatsDemo ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 13))
                        Text(showStatsDemo ? "Masquer l'exemple" : "Voir l'exemple — StatisticsView")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.88, green: 0.78, blue: 1.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.purple.opacity(showStatsDemo ? 0.45 : 0.22))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)

                if showStatsDemo {
                    VStack(alignment: .leading, spacing: 6) {
                        Image("StatisticsExample")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.40), lineWidth: 1)
                            )
                        Text("Exemple : sport Home Trainer selectionne (bordure verte), Vue d'ensemble avec 53 entrainements / 2 074 km, graphique Evolution en mode Barres / Distance.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                            .italic()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.22), lineWidth: 1))
            .cornerRadius(10)
        }
    }

    // MARK: - DETAIL PAGE

    private var detailPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "TrainingDetailView affiche l'ensemble des donnees d'une seance selectionnee dans la liste des entrainements.",
                color: .orange
            )
            blockView(heading: "Fiche complete", color: .orange,
                      body: "Retrouvez toutes les informations saisies : type, date, distance, duree, allure, frequences cardiaques moyenne et maximale, ainsi que vos notes.")
            blockView(heading: "Modification", color: .orange,
                      body: "Un bouton d'edition vous permet de corriger ou completer les donnees d'une seance existante. La modification est enregistree immediatement.")
            blockView(heading: "Suppression", color: .orange,
                      body: "Supprimez definitivement un entrainement depuis cette vue. Une confirmation est demandee avant la suppression pour eviter les erreurs.")
            blockView(heading: "Navigation", color: .orange,
                      body: "Accedez a la vue detail en selectionnant une ligne dans Mes Entrainements. Le bouton Retour ramene a la liste.")
        }
    }

    // MARK: - PLAN PAGE

    private var planPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "TrainingPlanView est un programme d'entrainement complet sur 8 semaines, pre-programme et renouvelable. Chaque semaine contient 3 seances (Mardi, Jeudi, Samedi) avec blocs detailles, zones FC calculees par la methode Karvonen et conseils nutritionnels.",
                color: .cyan
            )
            blockView(heading: "Selecteur de semaines", color: .cyan,
                      body: "Une rangee de 8 boutons permet de naviguer entre les semaines. Chaque bouton affiche le type de semaine (A, B, C ou D) et un badge vert comptant les seances deja validees. La semaine active est mise en evidence en orange.")
            blockView(heading: "4 types de semaines — cycle repetable", color: .cyan,
                      body: "Semaine A (S1, S3) : Force + Endurance Z2 + Tapis 12%. Semaine B (S2, S4) : HIIT Lipolytique + Tempo controle. Semaine C (S5, S7) : Cardio Z2 long + Circuit Core + Fartlek. Semaine D (S6, S8) : HIIT Pyramidal + Cardio Croise + Circuit Cardio-Force. Les semaines 4 et 8 sont des semaines de deload (volume reduit).")
            blockView(heading: "Cartes de seance depliables", color: .cyan,
                      body: "Chaque seance (Mardi / Jeudi / Samedi) est une carte cliquable. En la depliant, vous accedeez aux blocs detailles : nom du bloc, description, zone FC cible calculee dynamiquement, liste des exercices avec repetitions et durees. Un bouton permet de marquer la seance comme completee.")
            blockView(heading: "Zones FC calculees (Methode Karvonen)", color: .cyan,
                      body: "Toutes les plages FC (Z1 a Z5) sont calculees en temps reel depuis votre FCmax et votre FC de repos. La formule : Zone = ((FCmax - FCrepos) x %) + FCrepos. Ces valeurs s'affichent directement dans chaque bloc de seance.")
            blockView(heading: "Widget FC — reglage FCmax et FCrepos", color: .cyan,
                      body: "En bas de l'ecran, un widget rouge affiche FCmax, FCrepos et la Reserve cardiaque (HRR). Cliquer dessus ouvre un popup pour modifier ces valeurs (+/-) et visualiser instantanement les 5 zones recalculees.")
            blockView(heading: "GIFs exercices interactifs", color: .cyan,
                      body: "Certains exercices (Dead Bug, Pont Fessier, Mountain Climbers, Burpees, Kettlebell Swing, Squat Jump, Fentes) sont des boutons cliquables qui deployent un GIF anime illustrant le mouvement. Cliquer a nouveau masque le GIF.")
            blockView(heading: "Validation et Calendrier de suivi", color: .cyan,
                      body: "Chaque seance peut etre validee via un bouton coche. Une fenetre permet de saisir la date et l'heure exacte de realisation. Le calendrier (icone en haut) affiche la progression semaine par semaine avec compteur de seances, boutons Supprimer / Restaurer et serie actuelle.")
            blockView(heading: "Nutrition et Indicateurs de suivi", color: .cyan,
                      body: "Deux cartes permanentes completent chaque semaine : Nutrition Hebdomadaire (deficit calorique, proteines, collation pre-effort, hydratation) et Indicateurs de Suivi (FC repos le matin, tour de taille, poids, qualite du sommeil).")
        }
    }

    // MARK: - HEART PAGE

    private var heartPageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "HeartRateModal est une fenetre flottante deplagable (drag & drop) avec 3 onglets : Fc %, Fc Age et Calculer. Elle permet de calculer votre FC cible, de la deduire de votre age, et de visualiser vos 5 zones d'entrainement personnalisees.",
                color: .red
            )
            blockView(heading: "Onglet 1 — Fc %  (methode Karvonen manuelle)", color: .red,
                      body: "Affiche votre FCmax (issue du Profil) et votre FC de repos. Selectionnez un pourcentage d'effort (50, 60, 70, 80, 90 ou 100 %) dans le menu. Le calcul s'effectue immediatement : FC = (% × (FCmax - FCrepos)) + FCrepos. Le resultat s'affiche dans un encadre jaune en bas a droite, sur fond d'une image de reference FC.")
            blockView(heading: "Onglet 2 — Fc Age  (calcul par l'age)", color: .red,
                      body: "Saisissez votre age dans le champ prevu. L'application calcule automatiquement votre FCmax estimee (220 - age). Selectionnez un pourcentage pour obtenir deux resultats simultanes : FC sans FCR (methode simple : % × FCmax) et FC avec FCR (methode Karvonen : integre la FC de repos du Profil). Un GIF de cycliste apparait des qu'un pourcentage est selectionne.")
            blockView(heading: "Onglet 3 — Calculer (5 zones d'entrainement)", color: .red,
                      body: "Saisissez FCmax et FC repos dans les champs. La FC Reserve (FCmax - FCrepos) est calculee automatiquement. Les 5 zones s'affichent avec les plages min/max en bpm : Z1 Echauffement (50-60%), Z2 Endurance fondamentale (60-70%), Z3 Resistance douce Aerobie (70-80%), Z4 Resistance dure Seuil (80-90%), Z5 VMA Maximum (90-100%). Un GIF anime de cardio apparait des que les deux valeurs sont renseignees.")
            blockView(heading: "Deplacement de la fenetre", color: .red,
                      body: "La barre d'en-tete (avec l'icone de lignes horizontales) est une zone de drag & drop. Maintenez le clic et glissez pour repositionner le modal librement sur l'ecran.")
            blockView(heading: "Donnees partagees avec le Profil", color: .red,
                      body: "FCmax (calculee depuis votre date de naissance : 220 - age) et FC de repos sont lues directement depuis les AppStorage du Profil Utilisateur. Modifier ces valeurs dans le Profil les met a jour automatiquement dans HeartRateModal.")
        }
    }

    // MARK: - PROFILE PAGE

    private var profilePageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            introBox(
                "UserProfileModal est une fenetre scrollable en deux colonnes : colonne gauche pour la photo de profil, colonne droite pour les donnees personnelles. Toutes les valeurs sont persistantes via AppStorage et partagees avec HeartRateModal et TrainingPlanView.",
                color: .orange
            )
            blockView(heading: "Colonne gauche — Bandeau date et age", color: .orange,
                      body: "Un bandeau anime defile en continu avec la date du jour en francais (ex : Mercredi 12 Mars 2026). En dessous, un encadre bleu affiche l'age calcule automatiquement a partir de la date de naissance saisie dans la colonne droite.")
            blockView(heading: "Colonne gauche — Photo de profil", color: .orange,
                      body: "Un bouton 'Choisir une photo' ouvre le selecteur de fichiers macOS (formats PNG, JPEG, HEIC). La photo s'affiche dans un rectangle personnalisable. Un bouton 'Reglages photo' (violet) deployable expose 5 sliders : largeur image, hauteur image, contraste, largeur du rectangle et hauteur du rectangle. Un bouton 'Supprimer' efface la photo. Tous les reglages sont sauvegardes automatiquement.")
            blockView(heading: "Colonne droite — Identite", color: .orange,
                      body: "Deux champs de saisie : Nom et Prenom. Les valeurs sont stockees en AppStorage et persistantes entre les sessions.")
            blockView(heading: "Colonne droite — Date de naissance", color: .orange,
                      body: "Trois menus deroulants independants : Jour (1-31), Mois (nom en francais), Annee (1960 a aujourd'hui). La combinaison des trois calcule automatiquement l'age affiche dans la colonne gauche, et la FCmax utilisee dans les zones cardiaques (220 - age).")
            blockView(heading: "Colonne droite — Mesures physiques", color: .orange,
                      body: "Deux champs : Poids (kg) et Taille (cm). Ces donnees sont sauvegardees en AppStorage.")
            blockView(heading: "Colonne droite — Frequences cardiaques", color: .orange,
                      body: "FCmax est calculee et affichee automatiquement (220 - age) en jaune, en lecture seule. FC de repos est un champ libre modifiable. Cette valeur de FC repos est partagee directement avec HeartRateModal (onglets Fc % et Fc Age) et avec TrainingPlanView (widget FC et calcul des zones Karvonen).")
        }
    }
}

// MARK: - Preview

#Preview {
    NoticeModal(isPresented: .constant(true))
}
