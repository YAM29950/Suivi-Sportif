
import SwiftUI

// MARK: - PARTIE 1/3 : STRUCTURES, ÉTAT ET CONSTANTES

// MARK: - Extensions avec constantes
extension AddTrainingModal {
    static let puissanceOptions = [
        ("60", 60), ("70", 70), ("80", 80), ("90", 90), ("100", 100),
        ("110", 110), ("120", 120), ("130", 130), ("140", 140), ("150", 150),("160", 170),("170", 170),("180", 180),("190", 190),("200", 200)]
    
    static let cadenceOptions = [("5", 50), ("60", 60), ("70", 70), ("80", 80), ("90", 90), ("100", 100),("110", 110),("120", 130),("130", 130)]
    static let niveauOptions = [("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5)]
    static let penteOptions = [("0%", 0),("1%", 1), ("2%", 2), ("3%", 3), ("4%", 4), ("5%", 5)]
    static let plateauOptions = [("30", 30), ("42", 42), ("53", 53)]
    
    static let rameurWattsOptions = [
        ("50", 50), ("60", 60), ("70", 70), ("80", 80), ("90", 90), ("100", 100),
        ("110", 110), ("120", 120), ("130", 130), ("140", 140), ("150", 150),
        ("160", 160), ("170", 170), ("180", 180), ("190", 190), ("200", 200)
    ]
    
    static let rameurForceOptions = [
        ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5),
        ("6", 6), ("7", 7), ("8", 8), ("9", 9)
    ]
    
    static let rameurCMOptions = [
        ("18", 18), ("19", 19), ("20", 20), ("21", 21), ("22", 22), ("23", 23), ("24", 24)
    ]
    
    static let rameurTemp500Options = [("1:30", 90), ("1:45", 105), ("2:00", 120)]
    static let rameurProgrammeOptions = [("PdP", 1), ("Endurance", 2), ("Interval", 3)]
    
    static let elliptiqueForceOptions = [
        ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5),
        ("6", 6), ("7", 7), ("8", 8), ("9", 9), ("10", 10)
    ]
    
    static let elliptiqueInclineOptions = [
        ("0", 0), ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5),
        ("6", 6), ("7", 7), ("8", 8), ("9", 9), ("10", 10)
    ]
    
    static let tapisPenteOptions: [(String, Int?)] = [
        ("", nil), ("-3", -3), ("-2", -2), ("-1", -1),
        ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5), ("6", 6),
        ("7", 7), ("8", 8), ("9", 9), ("10", 10), ("11", 11), ("12", 12)
    ]
    
    static let triathlonKmOptions: [(String, Int?)] = [
        ("", nil), ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5),
        ("6", 6), ("8", 8), ("9", 9),("10", 10), ("11", 11), ("12", 12), ("13", 13), ("14", 14),("15", 15),("16", 16),("17", 17),("18", 18),("19", 19),("20", 20),("21", 21),("22", 22),("23", 23),("24", 24),("25", 25)
 ]
    
    static let triathlonTempsOptions: [(String, Int?)] = [
        ("", nil), ("0:10", 10), ("0:20", 20), ("0:30", 30)
    ]
    
    // ✅ NOUVELLES OPTIONS POUR LE PLAN
    static let planOptions = [
        ("", ""),
        ("M / FORCE + Endurance Z2", "M / FORCE + Endurance Z2"),
        ("M / HIIT Lipolytique", "M / HIIT Lipolytique"),
        ("J / TAPIS 12% + Endurance Z2", "J / TAPIS 12% + Endurance Z2"),
        ("S / Récupération Active mixte", "S / Récupération Active mixte"),
        ("S / Cardiaque Tempo Contrôlé", "S / Cardiaque Tempo Contrôlé")
    ]
}
struct AddTrainingModal: View {
    @Binding var isPresented: Bool

    // MARK: - État de base
    @State private var selectedDate = Date()
    @State private var selectedMinutes: Int? = nil
    @State private var selectedForme: Int? = nil
    @State private var kmText = ""
    @State private var calorieText = ""
    @State private var fcMaxText = ""
    @State private var fcMoyenneText = ""
    @State private var observationsText = ""
    @State private var selectedPlan: String? = nil  // ✅ NOUVEAU : Picker au lieu de TextField
    @State private var aJeunOui = false
    @State private var aJeunNon = false

    // 🆕 Sauvegarde de la position
    @AppStorage("modalOffsetX") private var savedOffsetX: Double = 0
    @AppStorage("modalOffsetY") private var savedOffsetY: Double = 0

    // MARK: - Profil utilisateur
    @AppStorage("userFCRepos") private var fcReposProfile = ""
    @AppStorage("userBirthDay") private var userBirthDay: Int = 0
    @AppStorage("userBirthMonth") private var userBirthMonth: Int = 0
    @AppStorage("userBirthYear") private var userBirthYear: Int = 0

    // MARK: - État des rectangles
    @State private var showRectangle3 = false
    @State private var showRectangle4 = false
    @State private var showRectangle5 = false
    @State private var showRectangleTapis = false
    @State private var showRectangleElliptique = false
    @State private var showRectanglePiste = false
    @State private var showRectangleRoute = false
    @State private var showRectangleVTT = false
    @State private var showRectanglePiscine = false
    @State private var showRectangleMer = false

    // MARK: - Données équipements
    @State private var homeTrainerPuissance: Int? = nil
    @State private var homeTrainerCadence: Int? = nil
    @State private var homeTrainerNiveau: Int? = nil
    @State private var homeTrainerPente: Int? = nil
    @State private var homeTrainerPlateau: Int? = nil
    @State private var rameurWatts: Int? = nil
    @State private var rameurForce: Int? = nil
    @State private var rameurCM: Int? = nil
    @State private var rameurTemp500: Int? = nil
    @State private var rameurProgramme: Int? = nil
    @State private var elliptiqueForce: Int? = nil
    @State private var elliptiqueIncline: Int? = nil

    // MARK: - Triathlon
    @State private var rameurKm: Int? = nil
    @State private var rameurTemps: Int? = nil
    @State private var homeTrainerTriKm: Int? = nil
    @State private var homeTrainerTriTemps: Int? = nil
    @State private var tapisTriKm: Int? = nil
    @State private var tapisTriTemps: Int? = nil
    @State private var triKmText = ""
    @State private var triTempsText = ""

    // MARK: - Autres activités
    @State private var tapisText = ""
    @State private var tapisPicker: Int? = nil
    @State private var elliptiqueText = ""
    @State private var elliptiquePicker: Int? = nil
    @State private var pisteText = ""
    @State private var pistePicker: Int? = nil
    @State private var routeText = ""
    @State private var routePicker: Int? = nil
    @State private var vttText = ""
    @State private var vttPicker: Int? = nil
    @State private var piscineText = ""
    @State private var piscinePicker: Int? = nil
    @State private var merText = ""
    @State private var merPicker: Int? = nil
    
    // MARK: - Navigation
    enum FocusedField: Hashable {
        case km, calories, fcMax, fcMoy, observations  // ✅ plan retiré
    }
    @FocusState private var focusedField: FocusedField?

    // MARK: - Rectangle personnalisé
    @State private var customTexts: [String] = Array(repeating: "", count: 13)  // ✅ 12 → 13
    @State private var sportText = ""
    @State private var hasClickedCalendar = false
    @State private var showCustomSettings = false
    @State private var showSaveSettingsAlert = false
    @State private var isInitialLoad = true
    @State private var customTextWidths: [CGFloat] = Array(repeating: 80, count: 13)
    @State private var modalScale: Double = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var modalOffset: CGSize = .zero
    @State private var isDragging = false

    // MARK: - Réglages sauvegardés
    @AppStorage("customFontSize") private var customFontSize: Double = 14
    @AppStorage("customFontWeight") private var customFontWeight: Double = 400
    @AppStorage("customSpacing") private var customSpacing: Double = 12
    @AppStorage("customLeadingPadding") private var customLeadingPadding: Double = 20
    @AppStorage("sportTextWidth") private var sportTextWidth: Double = 150
    @AppStorage("customTextColorRed") private var customTextColorRed: Double = 1.0
    @AppStorage("customTextColorGreen") private var customTextColorGreen: Double = 1.0
    @AppStorage("customTextColorBlue") private var customTextColorBlue: Double = 1.0
    @AppStorage("settingsSaved") private var settingsSaved: Bool = false
    @AppStorage("customTextWidthsJSON") private var customTextWidthsJSON: String = ""
    
    // MARK: - Propriétés calculées
    private var showCustomRectangle: Bool { hasClickedCalendar }
    
    private var fontWeight: Font.Weight {
        switch customFontWeight {
        case ...200: return .ultraLight
        case ...300: return .light
        case ...400: return .regular
        case ...500: return .medium
        case ...600: return .semibold
        case ...700: return .bold
        case ...800: return .heavy
        default: return .black
        }
    }
    
    private var textColor: Color {
        Color(red: customTextColorRed, green: customTextColorGreen, blue: customTextColorBlue)
    }
    
    private var fontWeightLabel: String {
        switch customFontWeight {
        case ...200: return "Ultra Light"
        case ...300: return "Light"
        case ...400: return "Regular"
        case ...500: return "Medium"
        case ...600: return "Semibold"
        case ...700: return "Bold"
        case ...800: return "Heavy"
        default: return "Black"
        }
    }
    
    private var formattedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: Date()).capitalized
    }

    private var calculatedMoyenne: String {
        guard let km = Double(kmText), let minutes = selectedMinutes,
              km > 0, minutes > 0 else { return "" }
        let moyenne = km / (Double(minutes) / 60.0)
        return String(format: "%.0f", moyenne)  // ← Changé de %.2f à %.0f (pas de décimales)
    }
    
    private var calculatedAge: Int {
        guard userBirthDay > 0, userBirthMonth > 0, userBirthYear > 0 else { return 0 }
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = userBirthYear
        dateComponents.month = userBirthMonth
        dateComponents.day = userBirthDay
        guard let birthDate = calendar.date(from: dateComponents) else { return 0 }
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    private var fcMaxProfile: Int { max(0, 220 - calculatedAge) }

    private var calculatedFCMaxPercent: String {
        guard let fcRepos = Double(fcReposProfile),
              let fcMax = Double(fcMaxText),
              fcMaxProfile > 0,
              fcMax > fcRepos else { return "" }
        let percent = ((fcMax - fcRepos) / (Double(fcMaxProfile) - fcRepos)) * 100
        return String(format: "%.0f", percent)  // ← Changé de %.1f à %.0f
    }
    
    private var calculatedFCMoyPercent: String {
        guard let fcRepos = Double(fcReposProfile),
              let fcMoyenne = Double(fcMoyenneText),
              fcMaxProfile > 0,
              fcMoyenne > fcRepos else { return "" }
        let percent = ((fcMoyenne - fcRepos) / (Double(fcMaxProfile) - fcRepos)) * 100
        return String(format: "%.0f", percent)  // ← Changé de %.1f à %.0f
    }

    private var triathlonTotalKm: Int {
        (rameurKm ?? 0) + (homeTrainerTriKm ?? 0) + (tapisTriKm ?? 0)
    }

    private var triathlonTotalTemps: Int {
        (rameurTemps ?? 0) + (homeTrainerTriTemps ?? 0) + (tapisTriTemps ?? 0)
    }

    // MARK: - Body Principal
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            GeometryReader { geometry in
                VStack(spacing: 15) {
                    HStack(alignment: .top, spacing: 20) {
                        leftColumn()
                        rightColumn()
                    }
                    .padding(.top, 10)
                    .padding(.leading, 5)
                    .padding(.trailing, 10)  // ← 😱 AJOUTÉ ICI
                    Spacer()
                    closeButton()
                    .padding(.bottom, 10)  // ← Ajout d'espace en-dessous
                    .padding(.leading, 10)  // ← Augmenté de 20 à 40
                                   }
                .frame(width: min(geometry.size.width - 10, 1400), height: 660)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.95), Color.blue.opacity(   0.95)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .shadow(radius: 30)
                .scaleEffect(modalScale)
                .offset(modalOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            modalOffset = CGSize(
                                width: savedOffsetX + gesture.translation.width,
                                height: savedOffsetY + gesture.translation.height
                            )
                        }
                        .onEnded { gesture in
                            isDragging = false
                            // Sauvegarder la position finale
                            savedOffsetX += gesture.translation.width
                            savedOffsetY += gesture.translation.height
                        }
                )
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .onChange(of: rameurKm) { _ in updateTriFields() }
        .onChange(of: homeTrainerTriKm) { _ in updateTriFields() }
        .onChange(of: tapisTriKm) { _ in updateTriFields() }
        .onChange(of: rameurTemps) { _ in updateTriFields() }
        .onChange(of: homeTrainerTriTemps) { _ in updateTriFields() }
        .onChange(of: tapisTriTemps) { _ in updateTriFields() }
        .onAppear(perform: handleAppear)
        .onChange(of: selectedDate) { _ in handleDateChange() }
        .onChange(of: aJeunOui) { _ in if hasClickedCalendar { updateCustomZone(1) } }
        .onChange(of: aJeunNon) { _ in if hasClickedCalendar { updateCustomZone(1) } }
        .onChange(of: selectedForme) { _ in if hasClickedCalendar { updateCustomZone(2) } }
        .onChange(of: kmText) { _ in if hasClickedCalendar { updateCustomZone(3) } }
        .onChange(of: selectedMinutes) { _ in if hasClickedCalendar { updateCustomZone(4) } }
        .onChange(of: calculatedMoyenne) { _ in if hasClickedCalendar { updateCustomZone(5) } }
        .onChange(of: calorieText) { _ in if hasClickedCalendar { updateCustomZone(6) } }
        .onChange(of: fcMaxText) { _ in if hasClickedCalendar { updateCustomZone(7) } }
        .onChange(of: fcMoyenneText) { _ in if hasClickedCalendar { updateCustomZone(8) } }
        .onChange(of: calculatedFCMaxPercent) { _ in if hasClickedCalendar { updateCustomZone(9) } }
        .onChange(of: calculatedFCMoyPercent) { _ in if hasClickedCalendar { updateCustomZone(10) } }
        
        .onChange(of: selectedPlan) { _ in if hasClickedCalendar { updateCustomZone(11) } }  // ✅
        .onChange(of: observationsText) { _ in if hasClickedCalendar { updateCustomZone(12) } }  // ✅ 11 → 12
    }
}

// MARK: - PARTIE 2/3 : LOGIQUE ET FONCTIONS

// MARK: - Fonctions de gestion des valeurs
extension AddTrainingModal {
    func getValueForZone(_ index: Int) -> String {
        switch index {
        case 0: return formatDate(selectedDate)
        case 1: return getAJeunValue()
        case 2: return getFormeStars()
        case 3: return kmText
        case 4: return formatMinutes(selectedMinutes)
        case 5: return calculatedMoyenne.isEmpty ? "" : "\(calculatedMoyenne) km/h"
        case 6: return calorieText
        case 7: return fcMaxText
        case 8: return fcMoyenneText
        case 9: return calculatedFCMaxPercent.isEmpty ? "" : "\(calculatedFCMaxPercent)%"
        case 10: return calculatedFCMoyPercent.isEmpty ? "" : "\(calculatedFCMoyPercent)%"
        case 11: return selectedPlan ?? ""  // ✅
        case 12: return observationsText  // ✅ 11 → 12
        default: return ""
        }
    }
    
    func getZoneName(_ index: Int) -> String {
        let names = ["Date", "A jeun", "Forme", "Km", "Temps", "Moyenne",
                     "Calories", "FC Max", "FC Moy", "% FC Max", "% FC Moy", "Plan", "Observations"]  // ✅ "Plan" ajouté
        return index < names.count ? names[index] : "Zone \(index + 1)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func getAJeunValue() -> String {
        if aJeunOui { return "Oui" }
        if aJeunNon { return "Non" }
        return ""
    }
    
    private func getFormeStars() -> String {
        guard let forme = selectedForme else { return "" }
        return String(repeating: "⭐️", count: forme / 15)
    }
    
    private func formatMinutes(_ minutes: Int?) -> String {
        guard let minutes = minutes else { return "" }
        let hours = minutes / 60
        let mins = minutes % 60
        
        // Format "1:00" au lieu de "1h00"
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", mins))"
        } else {
            return "0:\(String(format: "%02d", mins))"
        }
    }
    
    // Getters pour équipements
    func getPenteValue() -> String {
        guard let pente = tapisPicker else { return "" }
        return "\(pente)"
    }
    
    func getElliptiqueForceValue() -> String {
        guard let force = elliptiqueForce else { return "" }
        return "\(force)"
    }
    
    func getElliptiqueInclineValue() -> String {
        guard let incline = elliptiqueIncline else { return "" }
        return "\(incline)"
    }
    
    func getRameurWattsValue() -> String {
        guard let watts = rameurWatts else { return "" }
        return "\(watts)W"
    }
    
    func getRameurForceValue() -> String {
        guard let force = rameurForce else { return "" }
        return "\(force)"
    }
    
    func getRameurCMValue() -> String {
        guard let cm = rameurCM else { return "" }
        return "\(cm)"
    }
    
    func getRameurTemp500Value() -> String {
        guard let temp = rameurTemp500 else { return "" }
        return "\(temp / 60):\(String(format: "%02d", temp % 60))"
    }
    
    func getRameurProgrammeValue() -> String {
        guard let prog = rameurProgramme else { return "" }
        let programmes = [1: "PdP", 2: "Endurance", 3: "Interval"]
        return programmes[prog] ?? ""
    }
    
    func getHomeTrainerPuissanceValue() -> String {
        guard let puissance = homeTrainerPuissance else { return "" }
        return "\(puissance)W"
    }
    
    func getHomeTrainerCadenceValue() -> String {
        guard let cadence = homeTrainerCadence else { return "" }
        return "\(cadence)"
    }
    
    func getHomeTrainerNiveauValue() -> String {
        guard let niveau = homeTrainerNiveau else { return "" }
        return "\(niveau)"
    }
    
    func getHomeTrainerPenteValue() -> String {
        guard let pente = homeTrainerPente else { return "" }
        return "\(pente)%"
    }
    
    func getHomeTrainerPlateauValue() -> String {
        guard let plateau = homeTrainerPlateau else { return "" }
        return "\(plateau)"
    }
}

// MARK: - Fonctions utilitaires
extension AddTrainingModal {
    func autoFillAllZones() {
        for i in 0..<12 {
            customTexts[i] = getValueForZone(i)
        }
    }
    
    func updateCustomZone(_ index: Int) {
        customTexts[index] = getValueForZone(index)
    }
    
    func updateTriFields() {
        triKmText = "\(triathlonTotalKm)"
        triTempsText = "\(triathlonTotalTemps)"
    }
    
    func saveSettings() {
        settingsSaved = true
        saveWidthsToJSON()
    }
    
    func saveWidthsToJSON() {
        if let jsonData = try? JSONEncoder().encode(customTextWidths),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            customTextWidthsJSON = jsonString
        }
    }
    
    func loadWidthsFromJSON() {
        guard !customTextWidthsJSON.isEmpty,
              let jsonData = customTextWidthsJSON.data(using: .utf8),
              let widths = try? JSONDecoder().decode([CGFloat].self, from: jsonData),
              widths.count == 13 else {  // 🔥 Vérifier qu'il y a bien 13 éléments
            // Si pas de sauvegarde valide, utiliser les valeurs par défaut
            customTextWidths = [
                80, 50, 80, 50, 80, 90, 60, 60, 60, 80, 80, 200, 150
            ]
            return
        }
        customTextWidths = widths
    }
    
    func shouldShowSecondLine() -> Bool {
        ["Tapis", "Elliptique", "Rameur", "Home trainer", "Triathlon"].contains(sportText)
    }
    
    func handleAppear() {
        customTextWidthsJSON = ""  // Force réinitialisation
        
        customTextWidths = [
            80,  // 0: Date
            24,  // 1: A jeun (🔥 VOTRE TEST)
            80,  // 2: Forme
            22,  // 3: Km
            32,  // 4: Temps
            48,  // 5: Moyenne
            32,  // 6: Calories
            32,  // 7: FC Max
            36,  // 8: FC Moy
            40,  // 9: % FC Max
            40,  // 10: % FC Moy
            200, // 11: Plan
            150  // 12: Observations
        ]
        
        resetFields()
        updateTriFields()
        // 🔥 NE PAS charger les anciennes valeurs
        // loadWidthsFromJSON()  // ← COMMENTEZ CETTE LIGNE pour forcer vos valeurs

        modalOffset = CGSize(width: savedOffsetX, height: savedOffsetY)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialLoad = false
        }
    }
    
    func handleDateChange() {
        guard !isInitialLoad else { return }
        if !hasClickedCalendar {
            hasClickedCalendar = true
            autoFillAllZones()
        } else {
            updateCustomZone(0)
        }
    }
    
    func resetFields() {
        selectedDate = Date()
        selectedMinutes = nil
        selectedForme = nil
        kmText = ""
        calorieText = ""
        fcMaxText = ""
        fcMoyenneText = ""
        observationsText = ""
        selectedPlan = nil  // ✅
        aJeunOui = false
        aJeunNon = false
        showRectangle3 = false
        showRectangle4 = false
        showRectangle5 = false
        showRectangleTapis = false
        showRectangleElliptique = false
        showRectanglePiste = false
        showRectangleRoute = false
        showRectangleVTT = false
        showRectanglePiscine = false
        showRectangleMer = false
        homeTrainerPuissance = nil
        homeTrainerCadence = nil
        homeTrainerNiveau = nil
        homeTrainerPente = nil
        homeTrainerPlateau = nil
        rameurWatts = nil
        rameurForce = nil
        rameurCM = nil
        rameurTemp500 = nil
        rameurProgramme = nil
        elliptiqueForce = nil
        elliptiqueIncline = nil
        rameurKm = nil
        rameurTemps = nil
        homeTrainerTriKm = nil
        homeTrainerTriTemps = nil
        tapisTriKm = nil
        tapisTriTemps = nil
        triKmText = ""
        triTempsText = ""
        tapisText = ""
        tapisPicker = nil
        elliptiqueText = ""
        elliptiquePicker = nil
        pisteText = ""
        pistePicker = nil
        routeText = ""
        routePicker = nil
        vttText = ""
        vttPicker = nil
        piscineText = ""
        piscinePicker = nil
        merText = ""
        merPicker = nil
        customTexts = Array(repeating: "", count: 13)  // ✅ 12 → 13
        
        if !settingsSaved {
            customFontSize = 14
            customSpacing = 12
            customLeadingPadding = 20
            customTextWidths = Array(repeating: 80, count: 13)  // ✅ 12 → 13
        }
        
        showCustomSettings = false
        hasClickedCalendar = false
        isInitialLoad = true
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).lowercased()
    }
    
    func backgroundColorForDate(isToday: Bool, isSelected: Bool) -> Color {
        if isToday {
            return Color.blue  // ← Le 1er janvier sera bleu
        }
        else if isSelected {
                return Color.gray.opacity(0.1)
            }
        else {
                return Color.gray.opacity(0.1)
            }

    }
}

// MARK: - Fonction de sauvegarde (LA PLUS IMPORTANTE !)
extension AddTrainingModal {
    func saveTraining() {
        guard !sportText.isEmpty else {
            print("❌ Sport non sélectionné")
            return
        }
        
        // 1. Tapis Data
        var finalTapisData: TapisData? = nil
        if tapisPicker != nil || !tapisText.isEmpty {
            finalTapisData = TapisData(
                pente: tapisPicker != nil ? "\(tapisPicker!)" : nil,
                force: tapisText.isEmpty ? nil : tapisText
            )
        }
        
        // 2. Elliptique Data
        var finalElliptiqueData: ElliptiqueData? = nil
        if elliptiqueIncline != nil || elliptiqueForce != nil {
            finalElliptiqueData = ElliptiqueData(
                inclinaison: elliptiqueIncline != nil ? "\(elliptiqueIncline!)" : nil,
                watts: elliptiqueForce != nil ? "\(elliptiqueForce!)" : nil
            )
        }
        
        // 3. Rameur Data
        var finalRameurData: RameurData? = nil
        if rameurWatts != nil || rameurForce != nil || rameurCM != nil || rameurTemp500 != nil {
            var temps500String: String? = nil
            if let temp = rameurTemp500 {
                temps500String = "\(temp / 60):\(String(format: "%02d", temp % 60))"
            }
            
            finalRameurData = RameurData(
                watts: rameurWatts != nil ? "\(rameurWatts!)" : nil,
                force: rameurForce != nil ? "\(rameurForce!)" : nil,
                cM: rameurCM != nil ? "\(rameurCM!)" : nil,
                temps500m: temps500String
            )
        }
        
        // 4. Home Trainer Data
        var finalHomeTrainerData: HomeTrainerData? = nil
        if rameurProgramme != nil || homeTrainerPuissance != nil ||
           homeTrainerCadence != nil || homeTrainerNiveau != nil ||
           homeTrainerPente != nil || homeTrainerPlateau != nil {
            
            var programmeString: String? = nil
            if let prog = rameurProgramme {
                programmeString = [1: "PdP", 2: "Endurance", 3: "Interval"][prog]
            }
            
            finalHomeTrainerData = HomeTrainerData(
                programme: programmeString,
                puissance: homeTrainerPuissance != nil ? "\(homeTrainerPuissance!)" : nil,
                cadence: homeTrainerCadence != nil ? "\(homeTrainerCadence!)" : nil,
                niveau: homeTrainerNiveau != nil ? "\(homeTrainerNiveau!)" : nil,
                pente: homeTrainerPente != nil ? "\(homeTrainerPente!)" : nil,
                plateau: homeTrainerPlateau != nil ? "\(homeTrainerPlateau!)" : nil
            )
        }
        
        // 5. Triathlon Data
        var finalTriathlonData: TriathlonData? = nil
        if rameurKm != nil || homeTrainerTriKm != nil || tapisTriKm != nil {
            finalTriathlonData = TriathlonData(
                rameurKm: rameurKm != nil ? "\(rameurKm!)" : nil,
                rameurTemps: rameurTemps != nil ? "\(rameurTemps!)" : nil,
                homeTrainerKm: homeTrainerTriKm != nil ? "\(homeTrainerTriKm!)" : nil,
                homeTrainerTemps: homeTrainerTriTemps != nil ? "\(homeTrainerTriTemps!)" : nil,
                tapisKm: tapisTriKm != nil ? "\(tapisTriKm!)" : nil,
                tapisTemps: tapisTriTemps != nil ? "\(tapisTriTemps!)" : nil,
                resultatKm: triathlonTotalKm > 0 ? "\(triathlonTotalKm)" : nil,
                resultatTemps: triathlonTotalTemps > 0 ? "\(triathlonTotalTemps)" : nil
            )
        }
        
        // 6. Création Training
        let training = Training(
            date: selectedDate,
            type: sportText,
            distance: kmText.isEmpty ? nil : Double(kmText),
            duration: formatMinutes(selectedMinutes),
            averageSpeed: calculatedMoyenne.isEmpty ? nil : "\(calculatedMoyenne) km/h",
            calories: calorieText.isEmpty ? nil : Int(calorieText),
            aJeun: getAJeunValue().isEmpty ? nil : getAJeunValue(),
            forme: getFormeStars().isEmpty ? nil : getFormeStars(),
            maxHeartRate: fcMaxText.isEmpty ? nil : Int(fcMaxText),
            avgHeartRate: fcMoyenneText.isEmpty ? nil : Int(fcMoyenneText),
            heartRatePercent: calculatedFCMaxPercent.isEmpty ? nil : calculatedFCMaxPercent,
            heartRatePercentAvg: calculatedFCMoyPercent.isEmpty ? nil : calculatedFCMoyPercent,
            tapisData: finalTapisData,
            elliptiqueData: finalElliptiqueData,
            rameurData: finalRameurData,
            homeTrainerData: finalHomeTrainerData,
            triathlonData: finalTriathlonData,
            observations: observationsText,
            plan: selectedPlan  // ✅ (déjà optional, pas besoin de vérifier isEmpty)
        )
        
        // 7. Chargement + Sauvegarde
        var allTrainings: [Training] = []
        if let data = UserDefaults.standard.data(forKey: "trainings"),
           let decoded = try? JSONDecoder().decode([Training].self, from: data) {
            allTrainings = decoded
        }
        
        allTrainings.append(training)
        
        if let encoded = try? JSONEncoder().encode(allTrainings) {
            UserDefaults.standard.set(encoded, forKey: "trainings")
            print("✅ Entrainement enregistré!")
            print("📊 Sport: \(sportText)")
            print("📅 Date: \(formatDate(selectedDate))")
            if !kmText.isEmpty { print("🏃 Distance: \(kmText) km") }
            if selectedMinutes != nil { print("⏱️ Durée: \(formatMinutes(selectedMinutes))") }
           
            // 🔥 AJOUTEZ CETTE LIGNE
                    NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
            isPresented = false
        } else {
            print("❌ Erreur encodage")
        }
    }
}

// MARK: - PARTIE 3/3 : INTERFACE UI (TOUTES LES VUES)

// MARK: - Colonne Gauche
extension AddTrainingModal {
    @ViewBuilder
    func leftColumn() -> some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                
                GeometryReader { geo in
                    let repeatedText = String(repeating: formattedDateText + "   •   ", count: 3)
                    
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
            .frame(width: 250, height: 40)
            
            Spacer().frame(height: 15)
            
            customCalendar()
                .frame(width: 250, height: 240)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

            Spacer().frame(height: 36)

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A jeun")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        HStack(spacing: 16) {
                            checkboxButton(title: "Oui", isSelected: $aJeunOui, opposite: $aJeunNon)
                            checkboxButton(title: "Non", isSelected: $aJeunNon, opposite: $aJeunOui)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Forme")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Picker("Forme", selection: $selectedForme) {
                            Text("").tag(nil as Int?)
                            Text("⭐️").tag(15 as Int?)
                            Text("⭐️⭐️").tag(30 as Int?)
                            Text("⭐️⭐️⭐️").tag(45 as Int?)
                            Text("⭐️⭐️⭐️⭐️").tag(60 as Int?)
                            Text("⭐️⭐️⭐️⭐️⭐️").tag(75 as Int?)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(height: 34)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(width: 220, height: 100)
        }
    }
}

// MARK: - Calendrier
extension AddTrainingModal {
    @ViewBuilder
    func customCalendar() -> some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "fr_FR")
        calendar.firstWeekday = 2  // Lundi en premier
        
        let today = Date()
        
        // Premier jour du mois
        var components = calendar.dateComponents([.year, .month], from: selectedDate)
        components.day = 1
        guard let monthStart = calendar.date(from: components) else {
            return AnyView(EmptyView())
        }
        
        // Nombre de jours
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return AnyView(EmptyView())
        }
        let monthDays = range.count
        
        // Position du 1er jour
        // weekday retourne 1=Dimanche, 2=Lundi, 3=Mardi, 4=Mercredi, 5=Jeudi, 6=Vendredi, 7=Samedi
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        // Conversion pour calendrier français (L=0, Ma=1, Me=2, J=3, V=4, S=5, D=6)
        // Dimanche(1) → 6, Lundi(2) → 0, Mardi(3) → 1, Mercredi(4) → 2, Jeudi(5) → 3, etc.
        let emptyDays = (firstWeekday + 5) % 7
        
        return AnyView(
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(monthYearString(from: selectedDate))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                HStack(spacing: 0) {
                    let weekDays = ["L", "Ma", "Me", "J", "V", "S", "D"]
                    ForEach(0..<weekDays.count, id: \.self) { index in
                        Text(weekDays[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                    // Cases vides
                    ForEach(0..<emptyDays, id: \.self) { index in
                        Color.clear
                            .frame(height: 28)
                            .id("empty-\(index)")
                    }
                    
                    // Jours
                    ForEach(1...monthDays, id: \.self) { day in
                        if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                            let isToday = calendar.isDate(date, inSameDayAs: today)
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            
                            Button(action: {
                                selectedDate = date
                            }) {
                                Text("\(day)")
                                    .font(.system(size: 13, weight: isToday || isSelected ? .bold : .regular))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(backgroundColorForDate(isToday: isToday, isSelected: isSelected))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .id("day-\(day)")
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        )
    }
}
// MARK: - Colonne Droite
extension AddTrainingModal {
    @ViewBuilder
    func rightColumn() -> some View {
        VStack(spacing: 10) {
            activityButtonsRow()
            mainDataRow()
            
            // 🔥 Déplacer le rectangle Home trainer ICI (juste après mainDataRow)
            if showRectangle3 { homeTrainerRectangle() }
            if showRectangle4 { rameurRectangle() }

            if showCustomRectangle { customTextRectangle() }
            
            if showRectangle5 { triathlonRectangle() }
            if showRectangleTapis { genericRectangle(title: "Tapis", text: $tapisText, picker: $tapisPicker) }
            if showRectangleElliptique { elliptiqueRectangle() }
        }
        .padding(.trailing, 10)
    }
}

// MARK: - Boutons d'activités
extension AddTrainingModal {
    @ViewBuilder
        func activityButtonsRow() -> some View {
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .cornerRadius(12)

                HStack {
                    activityButton(image: "Marche", sport: "Marche")
                    Spacer().frame(width: 18)
                    activityToggleButton(image: "Tapis", sport: "Tapis", show: $showRectangleTapis)
                    Spacer().frame(width: 8)
                    activityToggleButton(image: "elliptique", sport: "Elliptique", show: $showRectangleElliptique)
                    Spacer().frame(width: 18)
                    activityToggleButton(image: "Rameur", sport: "Rameur", show: $showRectangle4)
                    Spacer().frame(width: 18)
                    activityToggleButton(image: "Home trainer", sport: "Home trainer", show: $showRectangle3)
                    activityToggleButton(image: "triathlon", sport: "Triathlon", show: $showRectangle5)
                    Spacer().frame(width: 18)
                    activityToggleButton(image: "Piste", sport: "Piste", show: $showRectanglePiste)
                    Spacer().frame(width: 8)
                    activityToggleButton(image: "Route", sport: "Route", show: $showRectangleRoute)
                    Spacer().frame(width: 8)
                    activityToggleButton(image: "VTT", sport: "VTT", show: $showRectangleVTT)
                    Spacer().frame(width: 18)
                    activityToggleButton(image: "Piscine", sport: "Piscine", show: $showRectanglePiscine)
                    Spacer().frame(width: 8)
                    activityToggleButton(image: "Mer", sport: "Mer", show: $showRectangleMer)
                    Spacer()
                }
                .padding(.leading, 20)
            }
            .frame(width: 940, height: 80)  // Au lieu de .frame(height: 80)
            .layoutPriority(1)
        }
    
    @ViewBuilder
    func activityButton(image: String, sport: String) -> some View {
        Button(action: { sportText = sport }) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func activityToggleButton(image: String, sport: String, show: Binding<Bool>) -> some View {
        Button(action: {
            show.wrappedValue.toggle()
            sportText = sport
        }) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ligne de données principales
extension AddTrainingModal {
    @ViewBuilder
    func mainDataRow() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(spacing: 12) {
                inputField(label: "Km:", text: $kmText, width: 30, focus: .km, nextFocus: .calories)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temps:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Picker("Temps", selection: $selectedMinutes) {
                        Text("").tag(nil as Int?)
                        Text("0:15").tag(15 as Int?)
                        Text("0:30").tag(30 as Int?)
                        Text("0:45").tag(45 as Int?)
                        Text("1:00").tag(60 as Int?)
                        Text("1:10").tag(70 as Int?)
                        Text("1:15").tag(75 as Int?)
                        Text("1:30").tag(90 as Int?)
                        Text("1:45").tag(105 as Int?)
                        Text("2:00").tag(120 as Int?)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 70, height: 34)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }

                displayField(label: "Moyenne", value: calculatedMoyenne.isEmpty ? "-" : "\(calculatedMoyenne) km/h", width: 66)
                inputField(label: "Calories", text: $calorieText, width: 40, focus: .calories, nextFocus: .fcMax)
                inputField(label: "FC Max", text: $fcMaxText, width: 36, focus: .fcMax, nextFocus: .fcMoy)
                inputField(label: "FC Moy", text: $fcMoyenneText, width: 36, focus: .fcMoy, nextFocus: .observations)  // ✅ nextFocus: .plan
                displayField(label: "% FC Max", value: calculatedFCMaxPercent.isEmpty ? "-" : "\(calculatedFCMaxPercent) %", width: 60)
                displayField(label: "% FC Moy", value: calculatedFCMoyPercent.isEmpty ? "-" : "\(calculatedFCMoyPercent) %", width: 60)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Picker("Plan", selection: $selectedPlan) {
                        ForEach(AddTrainingModal.planOptions, id: \.0) { option in
                            Text(option.1).tag(option.0 as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 140, height: 34)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                inputField(label: "Observations", text: $observationsText, width: 170, focus: .observations, nextFocus: .km)

                Spacer()
            }
            .padding(.leading, 20)
        }
        .frame(height: 80)
    }
}

// MARK: - Rectangle personnalisé
extension AddTrainingModal {
    @ViewBuilder
    func customTextRectangle() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            VStack(spacing: 10) {
                customTextHeader()
                if showCustomSettings { customSettingsPanel() }
                customTextZones()
            }
        }
        .frame(height: showCustomSettings ? 320 : 200)
        .alert("Garder ces réglages ?", isPresented: $showSaveSettingsAlert) {
            Button("Oui") {
                saveSettings()
                showCustomSettings = false
            }
            Button("Non", role: .cancel) {
                showCustomSettings = false
            }
        } message: {
            Text("Voulez-vous sauvegarder ces réglages pour les prochaines fois ?")
        }
    }
    
    @ViewBuilder
    func customTextHeader() -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("Sport", text: $sportText)
                    .textFieldStyle(.plain)
                    .frame(width: CGFloat(sportTextWidth))
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(textColor)
                    .font(.system(size: CGFloat(customFontSize), weight: fontWeight))
                
                if showCustomSettings {
                    Slider(value: $sportTextWidth, in: 80...250, step: 10)
                        .frame(width: CGFloat(sportTextWidth))
                        .accentColor(.green.opacity(0.5))
                    
                    Text("👉 \(Int(sportTextWidth))px")
                        .font(.system(size: 8))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            
            Spacer()
            
            Button(action: {
                if showCustomSettings {
                    showSaveSettingsAlert = true
                } else {
                    showCustomSettings = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showCustomSettings ? "checkmark.circle.fill" : "gearshape.fill")
                        .font(.system(size: 12))
                    Text(showCustomSettings ? "Valider" : "Réglages")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(showCustomSettings ? Color.green.opacity(0.6) : Color.orange.opacity(0.6))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                customTexts = Array(repeating: "", count: 12)
                sportText = ""
                hasClickedCalendar = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .help("Effacer toutes les zones")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    func customSettingsPanel() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                settingSlider(label: "👉 Police:", value: $customFontSize, range: 10...24, step: 1, format: { "\(Int($0))pt" })
                settingSlider(label: "👉 Épaisseur:", value: $customFontWeight, range: 100...900, step: 100, format: { _ in fontWeightLabel })
                settingSlider(label: "👉 Espacement:", value: $customSpacing, range: 4...30, step: 2, format: { "\(Int($0))px" })
                settingSlider(label: "👉 Marge gauche:", value: $customLeadingPadding, range: 0...50, step: 5, format: { "\(Int($0))px" })
                Spacer()
            }
            
            HStack(spacing: 15) {
                Text("👉 Couleur:")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
                colorSlider(label: "Rouge", value: $customTextColorRed, color: .red)
                colorSlider(label: "Vert", value: $customTextColorGreen, color: .green)
                colorSlider(label: "Bleu", value: $customTextColorBlue, color: .blue)
                
                VStack(spacing: 2) {
                    Text("Aperçu")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                    Rectangle()
                        .fill(textColor)
                        .frame(width: 40, height: 20)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.5), lineWidth: 1))
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    func customTextZones() -> some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CGFloat(customSpacing)) {
                    ForEach(0..<13, id: \.self) { index in  // ✅ 12 → 13
                        customTextZone(index: index)
                    }
                }
                .padding(.leading, CGFloat(customLeadingPadding))
                .padding(.trailing, 20)
            }
            
            if shouldShowSecondLine() {
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CGFloat(customSpacing)) {
                        secondLineZones()
                    }
                    .padding(.leading, CGFloat(customLeadingPadding))
                    .padding(.trailing, 20)
                }
            }
        }
        .frame(height: showCustomSettings ? 140 : 100)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    func customTextZone(index: Int) -> some View {
        // 🔥 SÉCURITÉ : Vérifier que l'index est valide
        guard index < customTextWidths.count && index < customTexts.count else {
            return AnyView(EmptyView())
        }
        
        // ✅ AJOUT : Wrapper dans AnyView pour cohérence de type
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Text(getZoneName(index))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                VStack(spacing: 2) {
                    TextField("", text: $customTexts[index])
                        .textFieldStyle(.plain)
                        .frame(width: customTextWidths[index])
                        .padding(6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(textColor)
                        .font(.system(size: CGFloat(customFontSize), weight: fontWeight))
                    
                    if showCustomSettings {
                        let minWidth: CGFloat = (index == 1 || index == 3 || index == 6) ? 30 : 40
                        let maxWidth: CGFloat = (index == 11 || index == 12) ? 250 : 150
                        Slider(value: $customTextWidths[index], in: minWidth...maxWidth, step: 10)
                            .frame(width: customTextWidths[index])
                            .accentColor(.green.opacity(0.5))
                            .onChange(of: customTextWidths[index]) { _ in
                                if settingsSaved { saveWidthsToJSON() }
                            }
                        
                        Text("👉 \(Int(customTextWidths[index]))px")
                            .font(.system(size: 8))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
            }
        )
    }
    @ViewBuilder
    func secondLineZones() -> some View {
        Group {
            if sportText == "Tapis" {
                customZone(label: "Pente", value: getPenteValue(), color: .orange)
            }
            
            if sportText == "Elliptique" {
                customZone(label: "Force", value: getElliptiqueForceValue(), color: .purple)
                customZone(label: "Inclinaison", value: getElliptiqueInclineValue(), color: .purple)
            }
            
            if sportText == "Rameur" {
                customZone(label: "Watts", value: getRameurWattsValue(), color: .blue)
                customZone(label: "Force", value: getRameurForceValue(), color: .blue)
                customZone(label: "C/M", value: getRameurCMValue(), color: .blue)
                customZone(label: "Temps/500m", value: getRameurTemp500Value(), color: .blue)
                customZone(label: "Programme", value: getRameurProgrammeValue(), color: .blue)
            }
            
            if sportText == "Home trainer" {
                customZone(label: "Puissance", value: getHomeTrainerPuissanceValue(), color: .green)
                customZone(label: "Cadence", value: getHomeTrainerCadenceValue(), color: .green)
                customZone(label: "Niveau", value: getHomeTrainerNiveauValue(), color: .green)
                customZone(label: "Pente", value: getHomeTrainerPenteValue(), color: .green)
                customZone(label: "Plateau", value: getHomeTrainerPlateauValue(), color: .green)
            }
            
            if sportText == "Triathlon" {
                customZone(label: "Km Total", value: triKmText.isEmpty || triKmText == "0" ? "" : triKmText, color: .red)
                customZone(label: "Temps Total", value: triTempsText.isEmpty || triTempsText == "0" ? "" : triTempsText, color: .red)
            }
        }
    }
    
    @ViewBuilder
    func customZone(label: String, value: String, color: Color) -> some View {
        let isStrongColor = [Color.red, Color.green, Color.blue, Color.purple, Color.orange].contains(color)
        
        let backgroundColor: Color = {
            switch color {
            case .red: return Color.red.opacity(0.45)
            case .green: return Color.green.opacity(0.75)
            case .blue: return Color.blue.opacity(0.80)
            case .purple: return Color.purple.opacity(0.80)
            case .orange: return Color.orange.opacity(0.80)
            default: return color
            }
        }()
        
        let textColor: Color = isStrongColor ? .white : color
        let fontWeight: Font.Weight = isStrongColor ? .bold : .medium

        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .frame(width: 80)
                .padding(6)
                .background(backgroundColor)
                .cornerRadius(6)
                .foregroundColor(textColor)
                .font(.system(size: 15, weight: fontWeight))
        }
    }
}

// MARK: - Rectangles équipements
extension AddTrainingModal {
    @ViewBuilder
    func homeTrainerRectangle() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(spacing: 20) {
                Text("Home trainer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, alignment: .leading)

                pickerField(label: "Puissance", selection: $homeTrainerPuissance, options: AddTrainingModal.puissanceOptions)
                pickerField(label: "Cadence", selection: $homeTrainerCadence, options: AddTrainingModal.cadenceOptions)
                pickerField(label: "Niveau", selection: $homeTrainerNiveau, options: AddTrainingModal.niveauOptions)
                pickerField(label: "Pente", selection: $homeTrainerPente, options: AddTrainingModal.penteOptions)
                pickerField(label: "Plateau", selection: $homeTrainerPlateau, options: AddTrainingModal.plateauOptions)

                Spacer()
            }
            .padding(.leading, 20)
        }
        .frame(height: 80)
    }

    @ViewBuilder
    func rameurRectangle() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(spacing: 20) {
                Text("Rameur")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, alignment: .leading)

                pickerField(label: "Watts", selection: $rameurWatts, options: AddTrainingModal.rameurWattsOptions)
                pickerField(label: "Force", selection: $rameurForce, options: AddTrainingModal.rameurForceOptions)
                pickerField(label: "C/M", selection: $rameurCM, options: AddTrainingModal.rameurCMOptions)
                pickerField(label: "Temp/500m", selection: $rameurTemp500, options: AddTrainingModal.rameurTemp500Options)
                pickerField(label: "Programme", selection: $rameurProgramme, options: AddTrainingModal.rameurProgrammeOptions)

                Spacer()
            }
            .padding(.leading, 20)
        }
        .frame(height: 80)
    }

    @ViewBuilder
    func triathlonRectangle() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(alignment: .center, spacing: 10) {
                Text("")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                triathlonBlock(title: "Rameur", kmSelection: $rameurKm, tempsSelection: $rameurTemps)
                triathlonBlock(title: "Home trainer", kmSelection: $homeTrainerTriKm, tempsSelection: $homeTrainerTriTemps)
                triathlonBlock(title: "Tapis", kmSelection: $tapisTriKm, tempsSelection: $tapisTriTemps)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Resultat TRIA")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))

                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .frame(width: 160, height: 70)
                    }
                    .overlay(
                        HStack(spacing: 12) {
                            triathlonResultField(label: "Km", value: triKmText)
                            triathlonResultField(label: "Temps", value: triTempsText)
                        }
                        .padding(.horizontal, 10)
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 120)
    }
    
    @ViewBuilder
    func elliptiqueRectangle() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(spacing: 20) {
                Text("Elliptique")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, alignment: .leading)

                pickerField(label: "Force", selection: $elliptiqueForce, options: AddTrainingModal.elliptiqueForceOptions)
                pickerField(label: "Inclinaison", selection: $elliptiqueIncline, options: AddTrainingModal.elliptiqueInclineOptions)

                Spacer()
            }
            .padding(.leading, 20)
        }
        .frame(height: 80)
    }

    @ViewBuilder
    func genericRectangle(title: String, text: Binding<String>, picker: Binding<Int?>) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(12)

            HStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 120, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pente")
                         // MARK: - PARTIE 3/3 SUITE : COMPOSANTS UI RÉUTILISABLES

                         // Continuez après la Partie 3/3...

                             // Suite de genericRectangle...
                                             Text("Pente:")
                                                 .font(.system(size: 12, weight: .medium))
                                                 .foregroundColor(.white)

                                             Picker("Pente", selection: picker) {
                                                 ForEach(AddTrainingModal.tapisPenteOptions, id: \.1) { option in
                                                     Text(option.0).tag(option.1)
                                                 }
                                             }
                                             .pickerStyle(.menu)
                                             .labelsHidden()
                                             .frame(height: 28)
                                             .padding(.horizontal, 6)
                                             .background(Color.white.opacity(0.2))
                                             .cornerRadius(6)
                                         }

                                         Spacer()
                                     }
                                     .padding(.leading, 20)
                                 }
                                 .frame(height: 80)
                             }
                         }

                         // MARK: - Composants réutilisables
                         extension AddTrainingModal {
                             @ViewBuilder
                             func checkboxButton(title: String, isSelected: Binding<Bool>, opposite: Binding<Bool>) -> some View {
                                 Button(action: {
                                     isSelected.wrappedValue.toggle()
                                     if isSelected.wrappedValue { opposite.wrappedValue = false }
                                 }) {
                                     HStack(spacing: 8) {
                                         ZStack {
                                             RoundedRectangle(cornerRadius: 4)
                                                 .fill(isSelected.wrappedValue ? Color.blue : Color.white.opacity(0.2))
                                                 .frame(width: 28, height: 28)

                                             if isSelected.wrappedValue {
                                                 Image(systemName: "checkmark")
                                                     .font(.system(size: 20, weight: .heavy))
                                                     .foregroundColor(.white)
                                             }
                                         }
                                         .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2))

                                         Text(title)
                                             .font(.system(size: 16, weight: .medium))
                                             .foregroundColor(.white)
                                     }
                                 }
                                 .buttonStyle(.plain)
                             }

                             @ViewBuilder
                             func displayField(label: String, value: String, width: CGFloat) -> some View {
                                 VStack(alignment: .leading, spacing: 4) {
                                     Text(label)
                                         .font(.system(size: 14, weight: .medium))
                                         .foregroundColor(.white)

                                     Text(value)
                                         .frame(width: width, height: 34)
                                         .padding(.horizontal, 8)
                                         .background(Color.white.opacity(0.2))
                                         .cornerRadius(8)
                                         .foregroundColor(.white)
                                         .font(.system(size: 14))
                                 }
                             }
                             
                             @ViewBuilder
                             func inputField(label: String, text: Binding<String>, width: CGFloat, focus: FocusedField, nextFocus: FocusedField) -> some View {
                                 VStack(alignment: .leading, spacing: 4) {
                                     Text(label)
                                         .font(.system(size: 14, weight: .medium))
                                         .foregroundColor(.white)

                                     TextField("", text: text)
                                         .textFieldStyle(.plain)
                                         .frame(width: width)
                                         .padding(8)
                                         .background(Color.white.opacity(0.2))
                                         .cornerRadius(8)
                                         .foregroundColor(.white)
                                         .focused($focusedField, equals: focus)
                                         .onSubmit { focusedField = nextFocus }
                                 }
                             }

                             @ViewBuilder
                             func pickerField(label: String, selection: Binding<Int?>, options: [(String, Int)]) -> some View {
                                 VStack(alignment: .leading, spacing: 4) {
                                     Text(label)
                                         .font(.system(size: 12, weight: .medium))
                                         .foregroundColor(.white)

                                     Picker(label, selection: selection) {
                                         Text("").tag(nil as Int?)
                                         ForEach(options, id: \.1) { option in
                                             Text(option.0).tag(option.1 as Int?)
                                         }
                                     }
                                     .pickerStyle(.menu)
                                     .labelsHidden()
                                     .frame(height: 34)
                                     .padding(.horizontal, 8)
                                     .background(Color.white.opacity(0.2))
                                     .cornerRadius(8)
                                 }
                             }

                             @ViewBuilder
                             func triathlonBlock(title: String, kmSelection: Binding<Int?>, tempsSelection: Binding<Int?>) -> some View {
                                 VStack(alignment: .leading, spacing: 5) {
                                     Text(title)
                                         .foregroundColor(.white)
                                         .font(.system(size: 14))

                                     ZStack {
                                         Rectangle()
                                             .fill(Color.white.opacity(0.2))
                                             .cornerRadius(10)
                                             .frame(width: 220, height: 70)
                                     }
                                     .overlay(
                                         HStack(spacing: 12) {
                                             triathlonPicker(label: "Km", selection: kmSelection, options: AddTrainingModal.triathlonKmOptions)
                                             triathlonPicker(label: "Temps", selection: tempsSelection, options: AddTrainingModal.triathlonTempsOptions)
                                         }
                                         .padding(.horizontal, 15)
                                     )
                                 }
                             }
                             
                             @ViewBuilder
                             func triathlonPicker(label: String, selection: Binding<Int?>, options: [(String, Int?)]) -> some View {
                                 VStack(alignment: .leading, spacing: 6) {
                                     Text(label)
                                         .foregroundColor(.white)
                                         .font(.system(size: 12, weight: .medium))

                                     Picker(label, selection: selection) {
                                         ForEach(options, id: \.1) { option in
                                             Text(option.0).tag(option.1)
                                         }
                                     }
                                     .pickerStyle(.menu)
                                     .labelsHidden()
                                     .frame(width: 80, height: 34)
                                     .background(Color.white.opacity(0.2))
                                     .cornerRadius(8)
                                 }
                             }
                             
                             @ViewBuilder
                             func triathlonResultField(label: String, value: String) -> some View {
                                 VStack(alignment: .leading, spacing: 5) {
                                     Text(label)
                                         .foregroundColor(.red)
                                         .font(.system(size: 16, weight: .bold))
                                         .italic()
                                     
                                     ZStack {
                                         Rectangle()
                                             .fill(Color.white.opacity(0.3))
                                             .cornerRadius(6)
                                             .frame(width: 60, height: 30)
                                        
                                         Text(value.isEmpty || value == "0" ? "" : value)
                                             .foregroundColor(.red)
                                             .font(.system(size: 18, weight: .bold))
                                             .italic()
                                             .frame(width: 50)
                                             .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                     }
                                 }
                             }

            // boutons enregistrer et fermer

                             @ViewBuilder
                             func closeButton() -> some View {
                                 HStack {
                                     Button(action: { saveTraining() }) {
                                         VStack(spacing: 8) {
                                             Image(systemName: "checkmark.circle.fill")
                                                 .font(.system(size: 32))
                                             Text("Enregistrer")
                                                 .font(.system(size: 14, weight: .bold))
                                         }
                                         .foregroundColor(sportText.isEmpty ? .white.opacity(0.4) : .white)
                                         .frame(width: 100, height: 88)
                                         .background(sportText.isEmpty ? Color.gray.opacity(0.2) : Color.green.opacity(0.8))
                                         .cornerRadius(12)
                                         .shadow(color: .black.opacity(sportText.isEmpty ? 0.1 : 0.4), radius: sportText.isEmpty ? 2 : 6, x: 0, y: sportText.isEmpty ? 1 : 3)
                                     }
                                     .buttonStyle(.plain)
                                     .disabled(sportText.isEmpty)
                                     
                                     Button(action: { isPresented = false }) {
                                         VStack(spacing: 8) {
                                             Image(systemName: "xmark.circle.fill")
                                                 .font(.system(size: 32))
                                             Text("Fermer")
                                                 .font(.system(size: 14, weight: .bold))
                                         }
                                         .foregroundColor(.white)
                                         .frame(width: 110, height: 90)
                                         .background(Color.red.opacity(0.5))
                                         .cornerRadius(12)
                                         .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                     }
                                     .buttonStyle(.plain)
                                     
                                     Spacer()
                                     
                                     VStack(spacing: 4) {
                                         Text("Zoom: \(Int(modalScale * 100))%")
                                             .font(.system(size: 10, weight: .medium))
                                             .foregroundColor(.white)
                                         
                                         Slider(value: $modalScale, in: 0.6...1.0, step: 0.05)
                                             .frame(width: 150)
                                             .accentColor(.blue)
                                     }
                                     .padding(12)
                                     .background(Color.black.opacity(0.3))
                                     .cornerRadius(10)
                                 }
                                 .padding(.leading, 4)
                                 .padding(.trailing, 4)
                                 .padding(.bottom, 4)
                             }
                             // fin boutons
                             @ViewBuilder
                             func settingSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: @escaping (Double) -> String) -> some View {
                                 VStack(alignment: .leading, spacing: 2) {
                                     Text(label)
                                         .font(.system(size: 10))
                                         .foregroundColor(.white)
                                     Slider(value: value, in: range, step: step)
                                         .frame(width: 80)
                                     Text(format(value.wrappedValue))
                                         .font(.system(size: 8))
                                         .foregroundColor(.white)
                                 }
                             }
                             
                             @ViewBuilder
                             func colorSlider(label: String, value: Binding<Double>, color: Color) -> some View {
                                 VStack(alignment: .leading, spacing: 2) {
                                     Text(label)
                                         .font(.system(size: 8))
                                         .foregroundColor(color)
                                     Slider(value: value, in: 0...1, step: 0.1)
                                         .frame(width: 80)
                                         .accentColor(color)
                                 }
                             }
                         }

