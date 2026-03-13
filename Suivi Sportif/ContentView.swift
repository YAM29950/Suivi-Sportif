import SwiftUI
import SDWebImageSwiftUI

// Structure pour les zones de texte d'en-tête
struct HeaderTextZone {
    var text: String
    var width: CGFloat
    var height: CGFloat
    var fontSize: CGFloat
    var contrast: Double
}

// Enum pour gérer la navigation
enum NavigationDestination {
    case home
    case trainings
    case statistics
    case trainingPlan
}

struct ContentView: View {
        @State private var showQuitAlert = false
        @State private var showAddModal = false
        @State private var showProfileModal = false
        @State private var showNoticeModal = false
        @State private var showTousModal = false
        @State private var showMarcheModal = false
        @State private var showTapisModal = false
        @State private var showElliptiqueModal = false
        @State private var showRameurModal = false
        @State private var showHomeTrainerModal = false
        @State private var showTriathlonModal = false
        @State private var showPisteModal = false
        @State private var showRouteModal = false
        @State private var showVTTModal = false
        @State private var showPiscineModal = false
        @State private var showMerModal = false
        @State private var zoom = false

    @State private var scrollOffset: CGFloat = 0
    @State private var scrollOffsetRight: CGFloat = 0
    @State private var allTrainings: [Training] = []
    @State private var mainContainerHeight: CGFloat = 350
    @State private var showHeartRateModal = false
    @State private var currentDestination: NavigationDestination = .home
    
    // Variables pour l'animation de l'icône
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0
    @State private var iconOpacity: Double = 1.0

    // Configuration zones
    @State private var scrollingTextWidth: CGFloat = 1340
    @State private var scrollingTextWidthRight: CGFloat = 350
    @State private var scrollingTextHeight: CGFloat = 40
    @State private var scrollingTextPaddingLeft: CGFloat = 5
    @State private var scrollingTextPaddingTop: CGFloat = 10
    @State private var titlePaddingTop: CGFloat = -30
    @State private var imageSpacings: [CGFloat] = [24, 24, 24, 44, 44, 24, 44, 24, 24, 44, 24, 0]
    
    @State private var imageZones: [ImageZoneConfig] = [
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Tous", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Marche", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Tapis", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "elliptique", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Rameur", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Home trainer", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "triathlon", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 67, contrast: 1.0, name: "", imageName: "Piste", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Route", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "VTT", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Piscine", textBoxWidth: 70, textBoxHeight: 30),
        ImageZoneConfig(width: 70, height: 70, contrast: 1.0, name: "", imageName: "Mer", textBoxWidth: 70, textBoxHeight: 30)
    ]
    
    @State private var additionalZonesValues: [String] = Array(1...33).map { "Valeur \($0)" }
    
    @State private var headerTextSpacings: [CGFloat] = [10, 25, 35, 15, 15, 15, 15, 0]
    @State private var headerLeftPadding: CGFloat = 14
    @State private var rectangle2GlobalPadding: CGFloat = 12
    @State private var headerBackgroundColor: Color = .blue
    @State private var headerBackgroundOpacity: CGFloat = 0.25
    @State private var headerKmBackgroundColor: Color = .white
    @State private var headerKmBackgroundOpacity: CGFloat = 0.50
    @State private var headerKmTextColor: Color = .red
    @State private var headerKmTextOpacity: CGFloat = 1.0
    @State private var headerKmFontWeight: Font.Weight = .black
    
    @State private var showOrangeRectangle = false
    @State private var showPurpleRectangle = false
    @State private var bottomRectHeight1: CGFloat = 200
    @State private var bottomRectHeight2: CGFloat = 200

    @State private var todayInfo: DayInfo? = nil

    private let activityTypes = ["Tous", "Marche", "Tapis", "Elliptique", "Rameur", "Home trainer", "Triathlon", "Piste", "Route", "VTT", "Piscine", "Mer"]
    
    private let kmFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
    
    // MARK: - Fonctions génériques
    
    private func calculateKmForYear(_ year: Int) -> Double {
        let calendar = Calendar.current
        
        let totalKm = allTrainings
            .filter { calendar.component(.year, from: $0.date) == year }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        return totalKm
    }
    
    private func formattedKmForYear(_ year: Int) -> String {
        let totalKm = calculateKmForYear(year)
        let formatted = kmFormatter.string(from: NSNumber(value: totalKm)) ?? "0"
        return "\(formatted) Km"
    }
    
    private func yearComparisonColor(_ year: Int) -> Color {
        if year == 2016 { return Color.white.opacity(0.3) }
        
        let currentYearKm = calculateKmForYear(year)
        let previousYearKm = calculateKmForYear(year - 1)
        
        if currentYearKm > previousYearKm {
            return .green
        } else if currentYearKm < previousYearKm {
            return .red
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private func calculateKm(type: String, year: Int? = nil, month: Int? = nil, useFormatter: Bool = false, currentMonthOnly: Bool = false) -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        let totalKm = allTrainings
            .filter { training in
                guard training.type == type else { return false }
                let trainYear = calendar.component(.year, from: training.date)
                let trainMonth = calendar.component(.month, from: training.date)
                
                if currentMonthOnly {
                    return trainYear == currentYear && trainMonth == currentMonth
                }
                
                if let y = year, let m = month {
                    return trainYear == y && trainMonth == m
                }
                if let y = year {
                    return trainYear == y
                }
                if let m = month {
                    return trainMonth == m && trainYear == currentYear
                }
                return trainYear == currentYear
            }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        if useFormatter {
            let formatted = kmFormatter.string(from: NSNumber(value: totalKm)) ?? "0"
            return "\(formatted) Km"
        }
        return totalKm > 0 ? String(format: "%.0f Km", totalKm) : "0 Km"
    }
    
    private func totalAllSportsKm() -> String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let totalKm = allTrainings
            .filter { calendar.component(.year, from: $0.date) == currentYear }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        let formatted = kmFormatter.string(from: NSNumber(value: totalKm)) ?? "0"
        return "\(formatted) Km"
    }
    
    private func totalPreviousYearSameMonthKm() -> String {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let previousYear = calendar.component(.year, from: Date()) - 1
        
        let totalKm = allTrainings
            .filter {
                let trainMonth = calendar.component(.month, from: $0.date)
                let trainYear = calendar.component(.year, from: $0.date)
                return trainMonth == currentMonth && trainYear == previousYear
            }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        return totalKm > 0 ? String(format: "%.0f Km", totalKm) : "0 Km"
    }
    
    private func currentYearKm(_ type: String) -> String {
        if type == "Tous" {
            return totalAllSportsKm()
        }
        return calculateKm(type: type, useFormatter: type == "Home trainer")
    }
    
    private func previousYearSameMonthKm(_ type: String) -> String {
        if type == "Tous" {
            return totalPreviousYearSameMonthKm()
        }
        let year = Calendar.current.component(.year, from: Date()) - 1
        let month = Calendar.current.component(.month, from: Date())
        return calculateKm(type: type, year: year, month: month, useFormatter: type == "Home trainer")
    }
    
    private func currentYearSameMonthKm(_ type: String) -> String {
        if type == "Tous" {
            return currentMonthYearKm
        }
        return calculateKm(type: type, useFormatter: type == "Home trainer", currentMonthOnly: true)
    }
    
    private func comparisonSymbol(_ type: String) -> String {
        let previousRaw = previousYearSameMonthKm(type)
        let currentRaw = currentYearSameMonthKm(type)
        
        let previousStr = previousRaw
            .replacingOccurrences(of: "Km", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let currentStr = currentRaw
            .replacingOccurrences(of: "Km", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let previous = Double(previousStr) ?? 0
        let current = Double(currentStr) ?? 0
        
        if current < previous { return "👎" }
        else if current == previous { return "✌️" }
        else { return "👍" }
    }
    
    private var sumKmZones2And3: String {
        let tapisKm = allTrainings.filter { $0.type == "Tapis" }.compactMap { $0.distance }.reduce(0, +)
        let elliptiqueKm = allTrainings.filter { $0.type == "Elliptique" }.compactMap { $0.distance }.reduce(0, +)
        return String(format: "%.1f km", tapisKm + elliptiqueKm)
    }
    
    private var currentMonthYearKm: String {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let totalKm = allTrainings
            .filter {
                let trainMonth = calendar.component(.month, from: $0.date)
                let trainYear = calendar.component(.year, from: $0.date)
                return trainMonth == currentMonth && trainYear == currentYear
            }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        return totalKm > 0 ? String(format: "%.0f Km", totalKm) : "0 Km"
    }
    
    private var previousYearSameMonthKm: String {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let previousYear = calendar.component(.year, from: Date()) - 1
        
        let totalKm = allTrainings
            .filter {
                let trainMonth = calendar.component(.month, from: $0.date)
                let trainYear = calendar.component(.year, from: $0.date)
                return trainMonth == currentMonth && trainYear == previousYear
            }
            .compactMap { $0.distance }
            .reduce(0, +)
        
        return totalKm > 0 ? String(format: "%.0f Km", totalKm) : "0 Km"
    }
    
    private var headerTextZones: [HeaderTextZone] {
        let currentMonth = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "MMMM"
            return formatter.string(from: Date()).capitalized
        }()
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return [
            HeaderTextZone(text: "Mois de", width: 180, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: currentMonth, width: 120, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: "\(currentYear)", width: 120, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: currentMonthYearKm, width: 80, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: "en", width: 40, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: currentMonth, width: 200, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: "\(currentYear - 1)", width: 80, height: 30, fontSize: 18, contrast: 1.0),
            HeaderTextZone(text: previousYearSameMonthKm, width: 100, height: 30, fontSize: 18, contrast: 1.0)
        ]
    }
    
    private var formattedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: Date()).capitalized
    }
    
    private var daysInfoText: String {
        let calendar = Calendar.current
        let now = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let totalDaysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let daysRemaining = totalDaysInYear - dayOfYear
        return "Jour \(dayOfYear) de l'année   •   \(daysRemaining) jours restants"
    }
    
    // MARK: - Données pour les lignes
    
    private var headerRowValues: [String] { headerTextZones.map { $0.text } }
    private var previousYearSameMonthValues: [String] { activityTypes.map { previousYearSameMonthKm($0) } }
    private var currentYearSameMonthValues: [String] { activityTypes.map { currentYearSameMonthKm($0) } }
    private var symbolsRowValues: [String] { activityTypes.map { comparisonSymbol($0) } }

    // MARK: - Body et Vue Principale
        
        var body: some View {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.8)]), startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
                
                HStack(spacing: 10) {
                    sideMenu
                    
                    Group {
                        switch currentDestination {
                        case .home:
                            homeView
                        case .trainings:
                            TrainingsListView()
                        case .statistics:
                            StatisticsView()
                        case .trainingPlan:
                            TrainingPlanView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if showAddModal { AddTrainingModal(isPresented: $showAddModal) }
                    if showProfileModal { UserProfileModal(isPresented: $showProfileModal) }
                    if showHeartRateModal { HeartRateModal(isPresented: $showHeartRateModal) }
                    if showTousModal { TousModal(isPresented: $showTousModal) }
                    if showMarcheModal { MarcheModal(isPresented: $showMarcheModal) }
                    if showTapisModal { TapisModal(isPresented: $showTapisModal) }
                    if showElliptiqueModal { ElliptiqueModal(isPresented: $showElliptiqueModal) }
                    if showRameurModal { RameurModal(isPresented: $showRameurModal) }
                    if showHomeTrainerModal { HomeTrainerModal(isPresented: $showHomeTrainerModal) }
                    if showTriathlonModal { TriathlonModal(isPresented: $showTriathlonModal) }
                    if showPisteModal { PisteModal(isPresented: $showPisteModal) }
                    if showRouteModal { RouteModal(isPresented: $showRouteModal) }
                    if showVTTModal { VTTModal(isPresented: $showVTTModal) }
                    if showPiscineModal { PiscineModal(isPresented: $showPiscineModal) }
                    if showMerModal { MerModal(isPresented: $showMerModal) }
                    if showNoticeModal { NoticeModal(isPresented: $showNoticeModal) }
            }
            .alert("Êtes-vous sûr de vouloir quitter l'application ?", isPresented: $showQuitAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Quitter", role: .destructive) { NSApplication.shared.terminate(nil) }
            } message: {
                Text("Vous perdrez votre navigation actuelle.")
            }
            .onAppear {
                allTrainings = TrainingDataManager.shared.loadTrainings()
                todayInfo = CalendarDataManager.shared.getTodayInfo()
            }
            .onReceive(NotificationCenter.default.publisher(for: .trainingsDidUpdate)) { _ in
                print("🔄 ContentView: Rechargement des données...")
                allTrainings = TrainingDataManager.shared.loadTrainings()
            }
        }
        
        // MARK: - Vue principale (Home)
        
        private var homeView: some View {
            ZStack {
                Image("Menu")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .opacity(0.66)
                    .scaleEffect(zoom ? 1.3 : 1.1)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: zoom)
                    .onAppear { zoom = true }
                    .padding(.top, 520)

                VStack(spacing: 10) {
                    HStack {
                        scrollingTextView
                        Spacer()
                    }
                    titleView
                    mainDataContainer
                    
                    Spacer()
                        .frame(height: 20)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showOrangeRectangle.toggle()
                        }
                    }) {
                        Image(systemName: showOrangeRectangle ? "chevron.right" : "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .padding(8)
                            .background(Color.orange.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)

                    if showOrangeRectangle {
                        VStack(spacing: 15) {
                            // 1. FÊTE DU JOUR
                            ZStack {
                                Rectangle()
                                    .fill(Color.orange.opacity(0.35))
                                    .cornerRadius(16)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.yellow)
                                        Text("Fête du jour")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if let info = todayInfo {
                                        Text(info.fete)
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.5))
                                            Text("Aucune information disponible")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.7))
                                                .italic()
                                        }
                                    }
                                }
                                .padding()
                            }
                            .frame(height: 90)
                            .padding(.horizontal, 20)
                            
                            // 2. DICTON DU JOUR
                            ZStack {
                                Rectangle()
                                    .fill(Color.orange.opacity(0.30))
                                    .cornerRadius(16)
                                
                                VStack(spacing: 6) {
                                    HStack {
                                        Image(systemName: "quote.opening")
                                            .font(.system(size: 18))
                                            .foregroundColor(.yellow)
                                        Text("Dicton du jour")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if let info = todayInfo, !info.dicton.isEmpty && info.dicton != "Aucun dicton pour aujourd'hui" {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\"")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.yellow)
                                                .offset(y: -5)
                                            Text(info.dicton)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.white.opacity(0.95))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(5)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Text("\"")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.yellow)
                                                .offset(y: 10)
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "text.quote")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.5))
                                            Text("Pas de dicton pour aujourd'hui")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.7))
                                                .italic()
                                        }
                                    }
                                }
                                .padding()
                            }
                            .frame(height: 120)
                            .padding(.horizontal, 20)
                        }
                        .transition(.move(edge: .trailing))
                        .padding(.top, 0)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showPurpleRectangle.toggle()
                        }
                    }) {
                        Image(systemName: showPurpleRectangle ? "chevron.right" : "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .padding(8)
                            .background(Color.purple.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)

                    if showPurpleRectangle {
                        ZStack {
                                Rectangle()
                                    .fill(Color.purple.opacity(0.35))
                                    .cornerRadius(16)
                            }
                            .frame(height: 100)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .trailing))
                    }
                         
                    Spacer()
                }
            }
        }

    // MARK: - Sous-vues
        
        private var scrollingTextView: some View {
            ZStack {
                GeometryReader { geo in
                    let combinedText = formattedDateText + "   •   " + daysInfoText + "   ⭐️    "
                    let repeatedText = String(repeating: combinedText, count: 3)
                    
                    Text(repeatedText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                        .fixedSize()
                        .position(x: geo.size.width / 2 + scrollOffset, y: geo.size.height / 2)
                        .onAppear {
                            scrollOffset = 0
                            withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
                                scrollOffset = -geo.size.width
                            }
                        }
                }
                .clipped()
            }
            .frame(width: scrollingTextWidth, height: scrollingTextHeight)
            .padding(.leading, scrollingTextPaddingLeft)
            .padding(.top, scrollingTextPaddingTop)
        }
        
        private var scrollingTextViewRight: some View {
            ZStack {
                Rectangle()
                    .fill(Color.purple.opacity(0.3))
                    .cornerRadius(12)
                
                GeometryReader { geo in
                    let repeatedText = String(repeating: daysInfoText + "   •   ", count: 3)
                    
                    Text(repeatedText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                        .fixedSize()
                        .position(x: geo.size.width / 2 + scrollOffsetRight, y: geo.size.height / 2)
                        .onAppear {
                            scrollOffsetRight = 0
                            withAnimation(Animation.linear(duration: 35).repeatForever(autoreverses: false)) {
                                scrollOffsetRight = -geo.size.width
                            }
                        }
                }
                .clipped()
            }
            .frame(width: scrollingTextWidthRight, height: scrollingTextHeight)
            .padding(.trailing, scrollingTextPaddingLeft)
            .padding(.top, scrollingTextPaddingTop)
        }
        
        private var titleView: some View {
            HStack(spacing: 15) {
                if let gifURL = Bundle.main.url(forResource: "coureur", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .offset(x: 120, y: 15)
                        .zIndex(10)
                } else {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .offset(x: 10, y: 15)
                        .zIndex(10)
                }
                
                Text("Suivi      Entrainements")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(x: -90)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, titlePaddingTop)
        }
        
        private var mainDataContainer: some View {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 15) {
                    imageZonesContainer
                    additionalZonesContainer
                }
                .padding(15)
            }
            .frame(height: mainContainerHeight)
            .padding(.leading, 6)
            .padding(.trailing, 20)
        }
        
        private var imageZonesContainer: some View {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.white.opacity(0))
                    .cornerRadius(12)
                    .padding(.top, 20)

                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Rectangle()
                            .fill(Color.green.opacity(0.6))
                            .cornerRadius(6)
                        Text("\(Calendar.current.component(.year, from: Date()))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 35)
                    .offset(y: -47)

                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(0..<12, id: \.self) { index in
                            
                            let imageWidth: CGFloat = {
                                switch imageZones[index].imageName {
                                case "Rameur": return imageZones[index].width + 20
                                case "Home trainer": return imageZones[index].width + 10
                                case "elliptique": return imageZones[index].width + 10
                                case "VTT": return imageZones[index].width + 10
                                case "Piste": return imageZones[index].width + 10
                                case "Piscine": return imageZones[index].width + 1
                                case "Mer": return imageZones[index].width + 1                                default: return imageZones[index].width
                                }
                            }()
                            let imageHeight: CGFloat = {
                                switch imageZones[index].imageName {
                                case "Rameur": return imageZones[index].height + 22
                                case "Home trainer": return imageZones[index].height + 6
                                case "elliptique": return imageZones[index].height + 6
                                case "VTT": return imageZones[index].height + 2
                                case "Piste": return imageZones[index].height + 2
                                case "Piscine": return imageZones[index].height + 18
                                case "Mer": return imageZones[index].height + 18
                                default: return imageZones[index].height
                                }
                            }()
                            
                            VStack(spacing: 4) {
                                Button(action: {
                                    switch imageZones[index].imageName {
                                    case "Tous": showTousModal = true
                                    case "Marche": showMarcheModal = true
                                    case "Tapis": showTapisModal = true
                                    case "elliptique": showElliptiqueModal = true
                                    case "Rameur": showRameurModal = true
                                    case "Home trainer": showHomeTrainerModal = true
                                    case "triathlon": showTriathlonModal = true
                                    case "Piste": showPisteModal = true
                                    case "Route": showRouteModal = true
                                    case "VTT": showVTTModal = true
                                    case "Piscine": showPiscineModal = true
                                    case "Mer": showMerModal = true
                                    default: break
                                    }
                                }) {
                                    Group {
                                        if NSImage(named: imageZones[index].imageName) != nil {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                                    .frame(width: imageZones[index].width, height: imageZones[index].height)
                                                Image(imageZones[index].imageName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: imageWidth, height: imageHeight)
                                            }
                                            .frame(width: imageZones[index].width, height: imageZones[index].height)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            VStack(spacing: 4) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white.opacity(0.5))
                                                Text("Ajouter")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            .frame(width: imageZones[index].width, height: imageZones[index].height)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Text(imageZones[index].name)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: imageZones[index].width)

                                ZStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .cornerRadius(6)

                                    Text(currentYearKm(activityTypes[index]))
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(4)
                                }
                                .frame(width: imageZones[index].textBoxWidth, height: imageZones[index].textBoxHeight)
                            }
                            .padding(.trailing, index < 11 ? imageSpacings[index] : 0)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                    .padding(.top, 1)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 12)
                .padding(.top, 20)
                .padding(.bottom, 4)
            }
            .frame(height: 150)
        }
        
        private func yearBox(_ year: Int?, color: Color) -> some View {
            ZStack {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .cornerRadius(6)
                if let year {
                    Text("\(year)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 60, height: 35)
        }
        
        private func dataRow(values: [String], fontSize: CGFloat = 14, backgroundColor: Color = Color.white.opacity(0.25)) -> some View {
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<12, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .fill(backgroundColor)
                            .cornerRadius(6)
                        Text(values[index])
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(4)
                    }
                    .frame(width: imageZones[index].textBoxWidth, height: 35)
                    .padding(.trailing, index < 11 ? imageSpacings[index] : 0)
                }
            }
        }
        
        private var additionalZonesContainer: some View {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .cornerRadius(12)

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { index in
                            ZStack {
                                Rectangle()
                                    .fill(
                                        (index == 3 || index == 7)
                                        ? headerKmBackgroundColor.opacity(headerKmBackgroundOpacity)
                                        : headerBackgroundColor.opacity(headerBackgroundOpacity)
                                    )
                                    .cornerRadius(6)
                                Text(headerRowValues[index])
                                    .font(.system(
                                        size: headerTextZones[index].fontSize,
                                        weight: (index == 3 || index == 7) ? headerKmFontWeight : .semibold
                                    ))
                                    .foregroundColor(
                                        (index == 3 || index == 7)
                                        ? headerKmTextColor.opacity(headerKmTextOpacity)
                                        : .white
                                    )
                                    .multilineTextAlignment(.center)
                                    .padding(4)
                            }
                            .frame(width: headerTextZones[index].width, height: headerTextZones[index].height)
                            .padding(.trailing, index < 7 ? headerTextSpacings[index] : 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, headerLeftPadding)
                    .padding(.bottom, 10)
                    
                    HStack(spacing: 8) {
                        yearBox(Calendar.current.component(.year, from: Date()) - 1, color: .green)
                        dataRow(values: previousYearSameMonthValues)
                    }

                    HStack(spacing: 8) {
                        yearBox(Calendar.current.component(.year, from: Date()), color: .orange)
                        dataRow(values: currentYearSameMonthValues)
                    }

                    HStack(spacing: 8) {
                        yearBox(nil, color: .clear)
                        dataRow(values: symbolsRowValues, fontSize: 20, backgroundColor: Color.clear)
                    }
                }
                .padding(rectangle2GlobalPadding)
            }
            .frame(height: 195)
        }
        
        // MARK: - Menu latéral
        
        private var sideMenu: some View {
            VStack(spacing: 16) {
                Button(action: { currentDestination = .home }) {
                    menuButton(
                        title: "Menu",
                        icon: "house.fill",
                        bg: currentDestination == .home ? Color.blue.opacity(0.5) : Color.blue.opacity(0.25)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { currentDestination = .trainings }) {
                    menuButton(
                        title: "Mes Entr.",
                        icon: "list.bullet.clipboard",
                        bg: currentDestination == .trainings ? Color.white.opacity(0.35) : Color.white.opacity(0.18)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showAddModal = true }) {
                    menuButton(title: "Ajouter", icon: "plus.circle.fill", bg: Color.green.opacity(0.25))
                }
                .buttonStyle(.plain)
                
                Button(action: { currentDestination = .statistics }) {
                    menuButton(
                        title: "Stats",
                        icon: "chart.bar.fill",
                        bg: currentDestination == .statistics ? Color.purple.opacity(0.45) : Color.purple.opacity(0.25)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { currentDestination = .trainingPlan }) {
                    menuButton(
                        title: "Plan 8S",
                        icon: "calendar.badge.clock",
                        bg: currentDestination == .trainingPlan ? Color.cyan.opacity(0.5) : Color.cyan.opacity(0.25)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { showHeartRateModal = true }) {
                    menuButton(title: "FC", icon: "heart.fill", bg: Color.red.opacity(0.25))
                }
                .buttonStyle(.plain)
                
                Button(action: { showProfileModal = true }) {
                    menuButton(title: "Profil", icon: "person.circle.fill", bg: Color.orange.opacity(0.25))
                }
                .buttonStyle(.plain)
                
                Button(action: { showNoticeModal = true }) {
                    menuButton(title: "Notice", icon: "book.fill", bg: Color.indigo.opacity(0.30))
                }
                .buttonStyle(.plain)

                Button(action: { showQuitAlert = true }) {
                    menuButton(title: "Quitter", icon: "xmark.circle.fill", bg: Color.red.opacity(0.25))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            .padding(.leading, 10)
            .frame(width: 100)
        }
        
        private func menuButton(title: String, icon: String, bg: Color) -> some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(bg)
            .cornerRadius(12)
        }
    }

    #Preview {
        ContentView()
    }
