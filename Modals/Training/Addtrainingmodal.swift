import SwiftUI
import Combine

// MARK: - DESIGN TOKENS
private enum DS {
    enum Color {
        static let bg         = SwiftUI.Color(red: 0.18, green: 0.22, blue: 0.32)
        static let surface    = SwiftUI.Color.white.opacity(0.14)
        static let surfaceHi  = SwiftUI.Color.white.opacity(0.22)
        static let border     = SwiftUI.Color.white.opacity(0.26)
        static let borderHi   = SwiftUI.Color.white.opacity(0.42)
        static let text       = SwiftUI.Color.white
        static let textSub    = SwiftUI.Color.white.opacity(0.82)
        static let textMuted  = SwiftUI.Color.white.opacity(0.58)
        static let blue       = SwiftUI.Color(red: 0.42, green: 0.74, blue: 1.00)
        static let green      = SwiftUI.Color(red: 0.28, green: 0.96, blue: 0.68)
        static let orange     = SwiftUI.Color(red: 1.00, green: 0.74, blue: 0.36)
        static let red        = SwiftUI.Color(red: 1.00, green: 0.50, blue: 0.54)
        static let purple     = SwiftUI.Color(red: 0.78, green: 0.58, blue: 1.00)
        static let teal       = SwiftUI.Color(red: 0.30, green: 0.92, blue: 0.92)
    }
    enum Radius {
        static let sm: CGFloat =  8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    enum Space {
        static let xs: CGFloat =  4
        static let sm: CGFloat =  8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
}

// MARK: - MODÈLES DE CONFIGURATION ÉQUIPEMENTS

struct HomeTrainerConfig {
    var puissance: Int? = nil
    var cadence: Int?   = nil
    var niveau: Int?    = nil
    var pente: Int?     = nil
    var plateau: Int?   = nil
}

struct RameurConfig {
    var watts: Int?      = nil
    var force: Int?      = nil
    var cm: Int?         = nil
    var temp500: Int?    = nil
    var programme: Int?  = nil
}

struct ElliptiqueConfig {
    var force: Int?    = nil
    var incline: Int?  = nil
}

struct TriathlonConfig {
    var rameurKm: Int?         = nil
    var rameurTemps: Int?      = nil
    var homeTrainerKm: Int?    = nil
    var homeTrainerTemps: Int? = nil
    var tapisKm: Int?          = nil
    var tapisTemps: Int?       = nil

    var totalKm:    Int { (rameurKm ?? 0) + (homeTrainerKm ?? 0) + (tapisKm ?? 0) }
    var totalTemps: Int { (rameurTemps ?? 0) + (homeTrainerTemps ?? 0) + (tapisTemps ?? 0) }
}

enum AJeunState { case none, oui, non }

// MARK: - VIEWMODEL

class TrainingFormViewModel: ObservableObject {
    @Published var selectedDate   = Date()
    @Published var selectedMinutes: Int? = nil
    @Published var selectedForme: Int?  = nil
    @Published var kmText          = ""
    @Published var calorieText     = ""
    @Published var fcMaxText       = ""
    @Published var fcMoyenneText   = ""
    @Published var observationsText = ""
    @Published var selectedPlan: String? = nil
    @Published var aJeun: AJeunState = .none
    @Published var sportText       = ""

    @Published var homeTrainer = HomeTrainerConfig()
    @Published var rameur      = RameurConfig()
    @Published var elliptique  = ElliptiqueConfig()
    @Published var triathlon   = TriathlonConfig()
    @Published var tapisPicker: Int? = nil

    @Published var customTexts: [String] = Array(repeating: "", count: 13)
    @Published var hasClickedCalendar   = false
    @Published var showCustomSettings   = false
    @Published var isInitialLoad        = true
    @Published var customTextWidths: [CGFloat] = [80,24,80,22,32,48,32,32,36,40,40,200,150]

    @Published var showHomeTrainer   = false
    @Published var showRameur        = false
    @Published var showElliptique    = false
    @Published var showTapis         = false
    @Published var showTriathlon     = false

    @AppStorage("customFontSize")       var fontSize:         Double = 14
    @AppStorage("customFontWeight")     var fontWeightRaw:    Double = 400
    @AppStorage("customSpacing")        var spacing:          Double = 12
    @AppStorage("customLeadingPadding") var leadingPadding:   Double = 20
    @AppStorage("sportTextWidth")       var sportTextWidth:   Double = 150
    @AppStorage("customTextColorRed")   var colorRed:         Double = 1.0
    @AppStorage("customTextColorGreen") var colorGreen:       Double = 1.0
    @AppStorage("customTextColorBlue")  var colorBlue:        Double = 1.0
    @AppStorage("settingsSaved")        var settingsSaved:    Bool   = false
    @AppStorage("modalOffsetX")         var savedOffsetX:     Double = 0
    @AppStorage("modalOffsetY")         var savedOffsetY:     Double = 0
    @AppStorage("userFCRepos")          var fcReposProfile:   String = ""
    @AppStorage("userBirthDay")         var birthDay:         Int    = 0
    @AppStorage("userBirthMonth")       var birthMonth:       Int    = 0
    @AppStorage("userBirthYear")        var birthYear:        Int    = 0

    var textColor: Color { Color(red: colorRed, green: colorGreen, blue: colorBlue) }

    var fontWeight: Font.Weight {
        switch fontWeightRaw {
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

    var fontWeightLabel: String {
        switch fontWeightRaw {
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

    var calculatedMoyenne: String {
        guard let km = Double(kmText), let min = selectedMinutes,
              km > 0, min > 0 else { return "" }
        return String(format: "%.0f", km / (Double(min) / 60.0))
    }

    var calculatedAge: Int {
        guard birthDay > 0, birthMonth > 0, birthYear > 0 else { return 0 }
        var dc = DateComponents()
        dc.year = birthYear; dc.month = birthMonth; dc.day = birthDay
        guard let birth = Calendar.current.date(from: dc) else { return 0 }
        return Calendar.current.dateComponents([.year], from: birth, to: Date()).year ?? 0
    }

    var fcMaxProfile: Int { max(0, 220 - calculatedAge) }

    var calculatedFCMaxPercent: String {
        guard let repos = Double(fcReposProfile),
              let fcMax = Double(fcMaxText),
              fcMaxProfile > 0, fcMax > repos else { return "" }
        return String(format: "%.0f", ((fcMax - repos) / (Double(fcMaxProfile) - repos)) * 100)
    }

    var calculatedFCMoyPercent: String {
        guard let repos = Double(fcReposProfile),
              let fcMoy = Double(fcMoyenneText),
              fcMaxProfile > 0, fcMoy > repos else { return "" }
        return String(format: "%.0f", ((fcMoy - repos) / (Double(fcMaxProfile) - repos)) * 100)
    }

    var aJeunString: String {
        switch aJeun { case .oui: return "Oui"; case .non: return "Non"; case .none: return "" }
    }

    var formeStars: String {
        guard let f = selectedForme else { return "" }
        return String(repeating: "⭐️", count: f / 15)
    }

    func formatMinutes(_ minutes: Int?) -> String {
        guard let m = minutes else { return "" }
        let h = m / 60; let mins = m % 60
        return h > 0 ? "\(h):\(String(format:"%02d",mins))" : "0:\(String(format:"%02d",mins))"
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: date)
    }

    func getValueForZone(_ i: Int) -> String {
        switch i {
        case 0:  return formatDate(selectedDate)
        case 1:  return aJeunString
        case 2:  return formeStars
        case 3:  return kmText
        case 4:  return formatMinutes(selectedMinutes)
        case 5:  return calculatedMoyenne.isEmpty ? "" : "\(calculatedMoyenne) km/h"
        case 6:  return calorieText
        case 7:  return fcMaxText
        case 8:  return fcMoyenneText
        case 9:  return calculatedFCMaxPercent.isEmpty ? "" : "\(calculatedFCMaxPercent)%"
        case 10: return calculatedFCMoyPercent.isEmpty ? "" : "\(calculatedFCMoyPercent)%"
        case 11: return selectedPlan ?? ""
        case 12: return observationsText
        default: return ""
        }
    }

    func getZoneName(_ i: Int) -> String {
        ["Date","À jeun","Forme","Km","Temps","Moyenne","Calories",
         "FC Max","FC Moy","% FC Max","% FC Moy","Plan","Observations"][safe: i] ?? "Zone \(i+1)"
    }

    func updateCustomZone(_ i: Int) {
        guard i < customTexts.count else { return }
        customTexts[i] = getValueForZone(i)
    }

    func autoFillAllZones() {
        for i in 0..<13 { customTexts[i] = getValueForZone(i) }
    }

    func resetAll() {
        selectedDate = Date(); selectedMinutes = nil; selectedForme = nil
        kmText = ""; calorieText = ""; fcMaxText = ""; fcMoyenneText = ""
        observationsText = ""; selectedPlan = nil; aJeun = .none; sportText = ""
        homeTrainer = HomeTrainerConfig(); rameur = RameurConfig()
        elliptique = ElliptiqueConfig(); triathlon = TriathlonConfig()
        tapisPicker = nil
        showHomeTrainer = false; showRameur = false; showElliptique = false
        showTapis = false; showTriathlon = false
        customTexts = Array(repeating: "", count: 13)
        hasClickedCalendar = false
        isInitialLoad = true
    }

    var rameurTemp500Str: String {
        guard let t = rameur.temp500 else { return "" }
        return "\(t/60):\(String(format:"%02d",t%60))"
    }
    var rameurProgrammeStr: String {
        guard let p = rameur.programme else { return "" }
        return [1:"PdP", 2:"Endurance", 3:"Interval"][p] ?? ""
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - CONSTANTES
extension AddTrainingModal {
    static let puissanceOptions = [
        ("60",60),("70",70),("80",80),("90",90),("100",100),
        ("110",110),("120",120),("130",130),("140",140),("150",150),
        ("160",160),("170",170),("180",180),("190",190),("200",200)
    ]
    static let cadenceOptions = [
        ("50",50),("60",60),("70",70),("80",80),("90",90),
        ("100",100),("110",110),("120",120),("130",130)
    ]
    static let niveauOptions  = [("1",1),("2",2),("3",3),("4",4),("5",5)]
    static let penteOptions   = [("0%",0),("1%",1),("2%",2),("3%",3),("4%",4),("5%",5)]
    static let plateauOptions = [("30",30),("42",42),("53",53)]

    static let rameurWattsOptions = (5...20).map { ("\($0*10)",$0*10) }
    static let rameurForceOptions = (1...9).map { ("\($0)",$0) }
    static let rameurCMOptions    = (18...24).map { ("\($0)",$0) }
    static let rameurTemp500Options = [("1:30",90),("1:45",105),("2:00",120)]
    static let rameurProgrammeOptions = [("PdP",1),("Endurance",2),("Interval",3)]

    static let elliptiqueForceOptions   = (1...10).map { ("\($0)",$0) }
    static let elliptiqueInclineOptions = (0...10).map { ("\($0)",$0) }

    static let tapisPenteOptions: [(String, Int?)] = [("",nil)] +
        ([-3,-2,-1,1,2,3,4,5,6,7,8,9,10,11,12]).map { ("\($0)",$0) }

    static let triathlonKmOptions: [(String, Int?)] = [
        ("", nil), ("1", 1), ("2", 2), ("3", 3), ("4", 4), ("5", 5),
        ("6", 6), ("8", 8), ("9", 9), ("10", 10), ("11", 11), ("12", 12),
        ("13", 13), ("14", 14), ("15", 15), ("16", 16), ("17", 17), ("18", 18),
        ("19", 19), ("20", 20), ("21", 21), ("22", 22), ("23", 23), ("24", 24), ("25", 25)
    ]

    static let triathlonTempsOptions: [(String, Int?)] = [("", nil), ("0:10", 10),("0:15", 15), ("0:20", 20), ("0:30", 30)]

    static let planOptions: [(String, String)] = [
        ("",""),
        ("S1 M","S1 M"),("S1 J","S1 J"),("S1 S","S1 S"),
        ("S2 M","S2 M"),("S2 J","S2 J"),("S2 S","S2 S"),
        ("S3 M","S3 M"),("S3 J","S3 J"),("S3 S","S3 S"),
        ("S4 M","S4 M"),("S4 J","S4 J"),("S4 S","S4 S"),
        ("S5 M","S5 M"),("S5 J","S5 J"),("S5 S","S5 S"),
        ("S6 M","S6 M"),("S6 J","S6 J"),("S6 S","S6 S"),
        ("S7 M","S7 M"),("S7 J","S7 J"),("S7 S","S7 S"),
        ("S8 M","S8 M"),("S8 J","S8 J"),("S8 S","S8 S"),
    ]
}

// MARK: - VUE PRINCIPALE

struct AddTrainingModal: View {
    @Binding var isPresented: Bool
    @StateObject private var form = TrainingFormViewModel()

    @State private var modalOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var modalScale: Double = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var showSaveSettingsAlert = false

    enum FocusedField: Hashable {
        case km, calories, fcMax, fcMoy, observations
    }
    @FocusState private var focusedField: FocusedField?

    private var showCustomRectangle: Bool { form.hasClickedCalendar }

    private var shouldShowSecondLine: Bool {
        ["Tapis","Elliptique","Rameur","Home trainer","Triathlon"].contains(form.sportText)
    }

    private var formattedDateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM yyyy"
        return f.string(from: Date()).capitalized
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.60)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            GeometryReader { geo in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: DS.Space.lg) {
                        leftColumn()
                        rightColumn()
                    }
                    .padding(.top, DS.Space.lg)
                    .padding(.horizontal, DS.Space.lg)

                    Spacer()
                    bottomBar()
                        .padding(.horizontal, DS.Space.lg)
                        .padding(.bottom, DS.Space.lg)
                }
                .frame(width: min(geo.size.width - 20, 1400), height: 670)
                .background(modalBackground())
                .cornerRadius(DS.Radius.xl)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.xl)
                    .stroke(DS.Color.borderHi, lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
                .scaleEffect(modalScale)
                .offset(modalOffset)
                .gesture(
                    DragGesture()
                        .onChanged { g in
                            isDragging = true
                            modalOffset = CGSize(
                                width:  form.savedOffsetX + g.translation.width,
                                height: form.savedOffsetY + g.translation.height)
                        }
                        .onEnded { g in
                            isDragging = false
                            form.savedOffsetX += g.translation.width
                            form.savedOffsetY += g.translation.height
                        }
                )
                .padding(.trailing, DS.Space.md)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .onAppear { handleAppear() }
        .onChange(of: form.selectedDate) { _ in handleDateChange() }
        .onChange(of: form.aJeun)              { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(1) }
        .onChange(of: form.selectedForme)      { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(2) }
        .onChange(of: form.kmText)             { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(3) }
        .onChange(of: form.selectedMinutes)    { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(4) }
        .onChange(of: form.calculatedMoyenne)  { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(5) }
        .onChange(of: form.calorieText)        { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(6) }
        .onChange(of: form.fcMaxText)          { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(7) }
        .onChange(of: form.fcMoyenneText)      { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(8) }
        .onChange(of: form.calculatedFCMaxPercent) { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(9) }
        .onChange(of: form.calculatedFCMoyPercent) { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(10) }
        .onChange(of: form.selectedPlan)       { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(11) }
        .onChange(of: form.observationsText)   { _ in guard form.hasClickedCalendar else { return }; form.updateCustomZone(12) }
    }

    @ViewBuilder
    private func modalBackground() -> some View {
        ZStack {
            DS.Color.bg
            LinearGradient(
                colors: [
                    DS.Color.blue.opacity(0.12),
                    Color.clear,
                    DS.Color.purple.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - LOGIQUE

extension AddTrainingModal {
    func handleAppear() {
        form.resetAll()
        modalOffset = CGSize(width: form.savedOffsetX, height: form.savedOffsetY)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            form.isInitialLoad = false
        }
    }

    func handleDateChange() {
        guard !form.isInitialLoad else { return }
        if !form.hasClickedCalendar {
            form.hasClickedCalendar = true
            form.autoFillAllZones()
        } else {
            form.updateCustomZone(0)
        }
    }

    func saveTraining() {
        guard !form.sportText.isEmpty else { return }

        var finalTapis: TapisData? = nil
        if form.tapisPicker != nil {
            finalTapis = TapisData(pente: form.tapisPicker.map { "\($0)" }, force: nil)
        }

        var finalElliptique: ElliptiqueData? = nil
        if form.elliptique.force != nil || form.elliptique.incline != nil {
            finalElliptique = ElliptiqueData(
                inclinaison: form.elliptique.incline.map { "\($0)" },
                watts: form.elliptique.force.map { "\($0)" }
            )
        }

        var finalRameur: RameurData? = nil
        if form.rameur.watts != nil || form.rameur.force != nil {
            finalRameur = RameurData(
                watts: form.rameur.watts.map { "\($0)" },
                force: form.rameur.force.map { "\($0)" },
                cM: form.rameur.cm.map { "\($0)" },
                temps500m: form.rameur.temp500.map { "\($0/60):\(String(format:"%02d",$0%60))" }
            )
        }

        var finalHomeTrainer: HomeTrainerData? = nil
        if form.homeTrainer.puissance != nil || form.homeTrainer.niveau != nil {
            finalHomeTrainer = HomeTrainerData(
                programme: form.rameurProgrammeStr,
                puissance: form.homeTrainer.puissance.map { "\($0)" },
                cadence: form.homeTrainer.cadence.map { "\($0)" },
                niveau: form.homeTrainer.niveau.map { "\($0)" },
                pente: form.homeTrainer.pente.map { "\($0)" },
                plateau: form.homeTrainer.plateau.map { "\($0)" }
            )
        }

        var finalTriathlon: TriathlonData? = nil
        let tri = form.triathlon
        if tri.rameurKm != nil || tri.homeTrainerKm != nil || tri.tapisKm != nil {
            finalTriathlon = TriathlonData(
                rameurKm: tri.rameurKm.map { "\($0)" },
                rameurTemps: tri.rameurTemps.map { "\($0)" },
                homeTrainerKm: tri.homeTrainerKm.map { "\($0)" },
                homeTrainerTemps: tri.homeTrainerTemps.map { "\($0)" },
                tapisKm: tri.tapisKm.map { "\($0)" },
                tapisTemps: tri.tapisTemps.map { "\($0)" },
                resultatKm: tri.totalKm > 0 ? "\(tri.totalKm)" : nil,
                resultatTemps: tri.totalTemps > 0 ? "\(tri.totalTemps)" : nil
            )
        }

        let training = Training(
            date: form.selectedDate,
            type: form.sportText,
            distance: Double(form.kmText),
            duration: form.formatMinutes(form.selectedMinutes),
            averageSpeed: form.calculatedMoyenne.isEmpty ? nil : "\(form.calculatedMoyenne) km/h",
            calories: Int(form.calorieText),
            aJeun: form.aJeunString.isEmpty ? nil : form.aJeunString,
            forme: form.formeStars.isEmpty ? nil : form.formeStars,
            maxHeartRate: Int(form.fcMaxText),
            avgHeartRate: Int(form.fcMoyenneText),
            heartRatePercent: form.calculatedFCMaxPercent.isEmpty ? nil : form.calculatedFCMaxPercent,
            heartRatePercentAvg: form.calculatedFCMoyPercent.isEmpty ? nil : form.calculatedFCMoyPercent,
            tapisData: finalTapis,
            elliptiqueData: finalElliptique,
            rameurData: finalRameur,
            homeTrainerData: finalHomeTrainer,
            triathlonData: finalTriathlon,
            observations: form.observationsText,
            plan: form.selectedPlan
        )

        var all: [Training] = []
        if let data = UserDefaults.standard.data(forKey: "trainings"),
           let decoded = try? JSONDecoder().decode([Training].self, from: data) {
            all = decoded
        }
        all.append(training)
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: "trainings")
            NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
            isPresented = false
        }
    }

    private var rameurProgrammeStr: String { form.rameurProgrammeStr }
    private var rameurTemp500Str:   String { form.rameurTemp500Str }
}

// MARK: - COLONNE GAUCHE

extension AddTrainingModal {
    @ViewBuilder
    func leftColumn() -> some View {
        VStack(spacing: DS.Space.md) {
            dateBanner()
                .frame(width: 250, height: 38)

            CalendarGridView(selectedDate: $form.selectedDate)
                .frame(width: 250, height: 248)
                .glassCard()

            formeForcesPanel()
                .frame(width: 250)
        }
    }

    @ViewBuilder
    private func dateBanner() -> some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .fill(DS.Color.blue.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.md)
                        .stroke(DS.Color.blue.opacity(0.3), lineWidth: 1))
                let repeated = String(repeating: formattedDateText + "   ·   ", count: 4)
                Text(repeated)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Color.blue)
                    .lineLimit(1)
                    .fixedSize()
                    .position(x: geo.size.width / 2 + scrollOffset, y: geo.size.height / 2)
                    .onAppear {
                        scrollOffset = 0
                        withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                            scrollOffset = -geo.size.width
                        }
                    }
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func formeForcesPanel() -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                sectionLabel("À jeun", icon: "sunrise.fill", color: DS.Color.orange)
                HStack(spacing: DS.Space.md) {
                    toggleChip(label: "Oui",
                               isOn: form.aJeun == .oui,
                               color: DS.Color.green) {
                        form.aJeun = form.aJeun == .oui ? .none : .oui
                    }
                    toggleChip(label: "Non",
                               isOn: form.aJeun == .non,
                               color: DS.Color.red) {
                        form.aJeun = form.aJeun == .non ? .none : .non
                    }
                }
            }

            Divider().background(DS.Color.border)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                sectionLabel("Forme", icon: "star.fill", color: DS.Color.orange)
                Picker("Forme", selection: $form.selectedForme) {
                    Text("—").tag(nil as Int?)
                    Text("⭐️").tag(15 as Int?)
                    Text("⭐️⭐️").tag(30 as Int?)
                    Text("⭐️⭐️⭐️").tag(45 as Int?)
                    Text("⭐️⭐️⭐️⭐️").tag(60 as Int?)
                    Text("⭐️⭐️⭐️⭐️⭐️").tag(75 as Int?)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(height: 32)
                .padding(.horizontal, DS.Space.sm)
                .background(DS.Color.surface)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(DS.Color.border, lineWidth: 1))
            }
        }
        .padding(DS.Space.md)
        .glassCard()
    }
}

// MARK: - CALENDRIER  ← LE FIX EST ICI

extension AddTrainingModal {
    @ViewBuilder
    func customCalendar() -> some View {
        // ════════════════════════════════════════════════════════
        // CALENDRIER AVEC TIMEZONE PARIS — FIX DÉFINITIF
        // ════════════════════════════════════════════════════════
        CalendarGridView(selectedDate: $form.selectedDate)
    }
}

// Vue séparée pour éviter les problèmes de return dans @ViewBuilder
private struct CalendarGridView: View {
    @Binding var selectedDate: Date

    // Calcul du calendrier dans une struct séparée = pas de souci de type
    private var calData: (cal: Calendar, today: Date, monthStart: Date, monthDays: Int, emptyDays: Int)? {
        let parisTimeZone = TimeZone(identifier: "Europe/Paris") ?? TimeZone.current

        var cal = Calendar(identifier: .gregorian)
        cal.locale      = Locale(identifier: "fr_FR")
        cal.timeZone    = parisTimeZone
        cal.firstWeekday = 2

        var comps    = cal.dateComponents(in: parisTimeZone, from: selectedDate)
        comps.day    = 1
        comps.hour   = 12
        comps.minute = 0
        comps.second = 0

        guard let monthStart = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: monthStart)
        else { return nil }

        let firstWeekday = cal.component(.weekday, from: monthStart)
        let emptyDays    = (firstWeekday + 5) % 7   // Dim=6 Lun=0 Mar=1 ...

        return (cal, Date(), monthStart, range.count, emptyDays)
    }

    var body: some View {
        if let d = calData {
            calendarContent(
                cal:        d.cal,
                today:      d.today,
                monthStart: d.monthStart,
                monthDays:  d.monthDays,
                emptyDays:  d.emptyDays
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func calendarContent(
        cal: Calendar,
        today: Date,
        monthStart: Date,
        monthDays: Int,
        emptyDays: Int
    ) -> some View {
        let weekDayLabels = ["L", "Ma", "Me", "J", "V", "S", "D"]

        VStack(spacing: DS.Space.sm) {
            // En-tête navigation mois
            HStack {
                Button {
                    if let d = cal.date(byAdding: .month, value: -1, to: selectedDate) {
                        selectedDate = d
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DS.Color.textSub)
                        .frame(width: 28, height: 28)
                        .background(DS.Color.surface)
                        .cornerRadius(DS.Radius.sm)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString(from: selectedDate, cal: cal))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Color.text)

                Spacer()

                Button {
                    if let d = cal.date(byAdding: .month, value: 1, to: selectedDate) {
                        selectedDate = d
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DS.Color.textSub)
                        .frame(width: 28, height: 28)
                        .background(DS.Color.surface)
                        .cornerRadius(DS.Radius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.top, DS.Space.sm)

            // Entêtes jours de la semaine
            HStack(spacing: 0) {
                ForEach(weekDayLabels, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DS.Color.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, DS.Space.sm)

            // Grille des jours
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                spacing: 4
            ) {
                // Cases vides avant le 1er du mois
                ForEach(0..<emptyDays, id: \.self) { _ in
                    Color.clear.frame(height: 28)
                }

                // Jours du mois
                ForEach(1...monthDays, id: \.self) { day in
                    if let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) {
                        let isToday    = cal.isDate(date, inSameDayAs: today)
                        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)

                        Button {
                            selectedDate = date
                        } label: {
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(DS.Color.blue)
                                        .frame(width: 28, height: 28)
                                } else if isSelected {
                                    Circle()
                                        .fill(DS.Color.blue.opacity(0.25))
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().stroke(DS.Color.blue.opacity(0.6), lineWidth: 1))
                                }
                                Text("\(day)")
                                    .font(.system(size: 13, weight: (isToday || isSelected) ? .bold : .regular))
                                    .foregroundColor(isToday ? .white : (isSelected ? DS.Color.blue : DS.Color.text))
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .buttonStyle(.plain)
                        .id("day-\(day)-\(selectedDate)")
                    }
                }
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.bottom, DS.Space.sm)
        }
        // Force reconstruction complète quand mois/année change
        .id("\(cal.component(.year, from: selectedDate))-\(cal.component(.month, from: selectedDate))")
    }

    private func monthYearString(from date: Date, cal: Calendar) -> String {
        let f = DateFormatter()
        f.locale   = Locale(identifier: "fr_FR")
        f.timeZone = cal.timeZone
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date).capitalized
    }
}

// MARK: - COLONNE DROITE

extension AddTrainingModal {
    @ViewBuilder
    func rightColumn() -> some View {
        VStack(spacing: DS.Space.sm) {
            activityButtonsRow()
            mainDataRow()
            if form.showHomeTrainer  { homeTrainerRectangle() }
            if form.showRameur       { rameurRectangle() }
            if showCustomRectangle   { customTextRectangle() }
            if form.showTriathlon    { triathlonRectangle() }
            if form.showTapis        { tapisRectangle() }
            if form.showElliptique   { elliptiqueRectangle() }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - ACTIVITÉS

extension AddTrainingModal {
    @ViewBuilder
    func activityButtonsRow() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.sm) {
                sportButton(image: "Marche", sport: "Marche", isActive: form.sportText == "Marche") {
                    form.sportText = "Marche"
                }
                separator()
                sportButton(image: "Tapis", sport: "Tapis", isActive: form.showTapis) {
                    form.showTapis.toggle()
                    if form.showTapis { form.sportText = "Tapis" }
                }
                sportButton(image: "elliptique", sport: "Elliptique", isActive: form.showElliptique) {
                    form.showElliptique.toggle()
                    if form.showElliptique { form.sportText = "Elliptique" }
                }
                separator()
                sportButton(image: "Rameur", sport: "Rameur", isActive: form.showRameur) {
                    form.showRameur.toggle()
                    if form.showRameur { form.sportText = "Rameur" }
                }
                separator()
                sportButton(image: "Home trainer", sport: "Home trainer", isActive: form.showHomeTrainer) {
                    form.showHomeTrainer.toggle()
                    if form.showHomeTrainer { form.sportText = "Home trainer" }
                }
                sportButton(image: "triathlon", sport: "Triathlon", isActive: form.showTriathlon) {
                    form.showTriathlon.toggle()
                    if form.showTriathlon { form.sportText = "Triathlon" }
                }
                separator()
                sportButton(image: "Piste", sport: "Piste", isActive: form.sportText == "Piste") {
                    form.sportText = "Piste"
                }
                sportButton(image: "Route", sport: "Route", isActive: form.sportText == "Route") {
                    form.sportText = "Route"
                }
                sportButton(image: "VTT", sport: "VTT", isActive: form.sportText == "VTT") {
                    form.sportText = "VTT"
                }
                separator()
                sportButton(image: "Piscine", sport: "Piscine", isActive: form.sportText == "Piscine") {
                    form.sportText = "Piscine"
                }
                sportButton(image: "Mer", sport: "Mer", isActive: form.sportText == "Mer") {
                    form.sportText = "Mer"
                }
            }
            .padding(.horizontal, DS.Space.md)
        }
        .frame(height: 90)
        .glassCard()
    }

    @ViewBuilder
    private func sportButton(image: String, sport: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? DS.Color.blue : Color.clear, lineWidth: 2.5)
                    )
                    .shadow(color: isActive ? DS.Color.blue.opacity(0.5) : .clear, radius: 6)
                if isActive {
                    Circle()
                        .fill(DS.Color.blue)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(DS.Color.bg, lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }

    @ViewBuilder
    private func separator() -> some View {
        Rectangle()
            .fill(DS.Color.border)
            .frame(width: 1, height: 50)
            .padding(.horizontal, 2)
    }
}

// MARK: - DONNÉES PRINCIPALES

extension AddTrainingModal {
    @ViewBuilder
    func mainDataRow() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: DS.Space.sm) {
                metricCard(emoji: "🏃", label: "Activité", accentColor: DS.Color.green) {
                    compactInput(label: "Km", text: $form.kmText, width: 52, focus: .km, next: .calories)
                    compactTimePicker()
                    compactDisplay(label: "Vitesse",
                                   value: form.calculatedMoyenne.isEmpty ? nil : "\(form.calculatedMoyenne) km/h",
                                   width: 86, color: DS.Color.green)
                }
                metricCard(emoji: "🔥", label: "Énergie", accentColor: DS.Color.orange) {
                    compactInput(label: "Calories", text: $form.calorieText, width: 64, focus: .calories, next: .fcMax)
                }
                metricCard(emoji: "❤️", label: "Cardiaque", accentColor: DS.Color.red) {
                    compactInput(label: "FC Max", text: $form.fcMaxText, width: 52, focus: .fcMax, next: .fcMoy)
                    compactInput(label: "FC Moy", text: $form.fcMoyenneText, width: 52, focus: .fcMoy, next: .observations)
                    compactDisplay(label: "% Max",
                                   value: form.calculatedFCMaxPercent.isEmpty ? nil : "\(form.calculatedFCMaxPercent)%",
                                   width: 54, color: DS.Color.red)
                    compactDisplay(label: "% Moy",
                                   value: form.calculatedFCMoyPercent.isEmpty ? nil : "\(form.calculatedFCMoyPercent)%",
                                   width: 54, color: DS.Color.red)
                }
                metricCard(emoji: "📋", label: "Plan & Notes", accentColor: DS.Color.purple) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Plan")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DS.Color.textSub)
                        Picker("Plan", selection: $form.selectedPlan) {
                            ForEach(AddTrainingModal.planOptions, id: \.0) { opt in
                                Text(opt.1).tag(opt.0 as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 160, height: 28)
                        .padding(.horizontal, DS.Space.sm)
                        .background(DS.Color.surface)
                        .cornerRadius(DS.Radius.sm)
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(DS.Color.border, lineWidth: 1))
                    }
                    compactInput(label: "Notes", text: $form.observationsText, width: 180, focus: .observations, next: .km)
                }
            }
            .padding(DS.Space.sm)
        }
        .frame(height: 100)
        .glassCard()
    }

    @ViewBuilder
    func metricCard<Content: View>(emoji: String, label: String, accentColor: Color,
                                   @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DS.Space.xs) {
                Text(emoji).font(.system(size: 11))
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .tracking(0.8)
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(0.12))
            .cornerRadius(DS.Radius.sm, corners: [.topLeft, .topRight])

            HStack(spacing: DS.Space.sm) {
                content()
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.sm)
            .background(accentColor.opacity(0.06))
            .cornerRadius(DS.Radius.sm, corners: [.bottomLeft, .bottomRight])
        }
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
            .stroke(accentColor.opacity(0.25), lineWidth: 1))
    }

    @ViewBuilder
    func compactInput(label: String, text: Binding<String>, width: CGFloat,
                      focus: FocusedField, next: FocusedField) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DS.Color.textSub)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .frame(width: width, height: 28)
                .padding(.horizontal, 6)
                .background(DS.Color.surfaceHi)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(DS.Color.border, lineWidth: 1))
                .foregroundColor(DS.Color.text)
                .font(.system(size: 13, weight: .semibold))
                .focused($focusedField, equals: focus)
                .onSubmit { focusedField = next }
        }
    }

    @ViewBuilder
    func compactDisplay(label: String, value: String?, width: CGFloat, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DS.Color.textSub)
            Text(value ?? "—")
                .frame(width: width, height: 28)
                .padding(.horizontal, 6)
                .background(value != nil ? color.opacity(0.12) : DS.Color.surface)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(value != nil ? color.opacity(0.35) : DS.Color.border, lineWidth: 1))
                .foregroundColor(value != nil ? color : DS.Color.textMuted)
                .font(.system(size: 13, weight: .bold))
        }
    }

    @ViewBuilder
    func compactTimePicker() -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Temps")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DS.Color.textSub)
            Picker("", selection: $form.selectedMinutes) {
                Text("—").tag(nil as Int?)
                Text("0:15").tag(15 as Int?); Text("0:30").tag(30 as Int?)
                Text("0:45").tag(45 as Int?); Text("1:00").tag(60 as Int?)
                Text("1:10").tag(70 as Int?); Text("1:15").tag(75 as Int?)
                Text("1:30").tag(90 as Int?); Text("1:45").tag(105 as Int?)
                Text("2:00").tag(120 as Int?)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 72, height: 28)
            .padding(.horizontal, 6)
            .background(DS.Color.surfaceHi)
            .cornerRadius(DS.Radius.sm)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                .stroke(DS.Color.border, lineWidth: 1))
        }
    }
}

// MARK: - RECTANGLES ÉQUIPEMENTS

extension AddTrainingModal {
    @ViewBuilder
    func homeTrainerRectangle() -> some View {
        equipmentPanel(title: "Home Trainer", icon: "bicycle", color: DS.Color.green) {
            pickerField(label: "Puissance", sel: $form.homeTrainer.puissance, opts: AddTrainingModal.puissanceOptions)
            pickerField(label: "Cadence",   sel: $form.homeTrainer.cadence,   opts: AddTrainingModal.cadenceOptions)
            pickerField(label: "Niveau",    sel: $form.homeTrainer.niveau,    opts: AddTrainingModal.niveauOptions)
            pickerField(label: "Pente",     sel: $form.homeTrainer.pente,     opts: AddTrainingModal.penteOptions)
            pickerField(label: "Plateau",   sel: $form.homeTrainer.plateau,   opts: AddTrainingModal.plateauOptions)
        }
    }

    @ViewBuilder
    func rameurRectangle() -> some View {
        equipmentPanel(title: "Rameur", icon: "figure.rower", color: DS.Color.teal) {
            pickerField(label: "Watts",      sel: $form.rameur.watts,     opts: AddTrainingModal.rameurWattsOptions)
            pickerField(label: "Force",      sel: $form.rameur.force,     opts: AddTrainingModal.rameurForceOptions)
            pickerField(label: "C/M",        sel: $form.rameur.cm,        opts: AddTrainingModal.rameurCMOptions)
            pickerField(label: "Temps/500m", sel: $form.rameur.temp500,   opts: AddTrainingModal.rameurTemp500Options)
            pickerField(label: "Programme",  sel: $form.rameur.programme, opts: AddTrainingModal.rameurProgrammeOptions)
        }
    }

    @ViewBuilder
    func elliptiqueRectangle() -> some View {
        equipmentPanel(title: "Elliptique", icon: "figure.cross.training", color: DS.Color.purple) {
            pickerField(label: "Force",       sel: $form.elliptique.force,   opts: AddTrainingModal.elliptiqueForceOptions)
            pickerField(label: "Inclinaison", sel: $form.elliptique.incline, opts: AddTrainingModal.elliptiqueInclineOptions)
        }
    }

    @ViewBuilder
    func tapisRectangle() -> some View {
        equipmentPanel(title: "Tapis", icon: "figure.walk", color: DS.Color.orange) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pente").font(.system(size: 11, weight: .medium)).foregroundColor(DS.Color.textSub)
                Picker("Pente", selection: $form.tapisPicker) {
                    ForEach(AddTrainingModal.tapisPenteOptions, id: \.0) { opt in
                        Text(opt.0).tag(opt.1)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(height: 28)
                .padding(.horizontal, 6)
                .background(DS.Color.surfaceHi)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(DS.Color.border, lineWidth: 1))
            }
        }
    }

    @ViewBuilder
    func triathlonRectangle() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(DS.Color.surface)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Color.red.opacity(0.3), lineWidth: 1))
            HStack(alignment: .center, spacing: DS.Space.lg) {
                triathlonBlock(title: "Rameur",
                               km: $form.triathlon.rameurKm,
                               temps: $form.triathlon.rameurTemps)
                triathlonBlock(title: "Home trainer",
                               km: $form.triathlon.homeTrainerKm,
                               temps: $form.triathlon.homeTrainerTemps)
                triathlonBlock(title: "Tapis",
                               km: $form.triathlon.tapisKm,
                               temps: $form.triathlon.tapisTemps)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered").foregroundColor(DS.Color.red).font(.system(size: 12))
                        Text("Total TRIA").font(.system(size: 13, weight: .bold)).foregroundColor(DS.Color.red)
                    }
                    HStack(spacing: DS.Space.md) {
                        triathlonTotalBadge(label: "Km",
                            value: form.triathlon.totalKm > 0 ? "\(form.triathlon.totalKm)" : nil)
                        triathlonTotalBadge(label: "Temps",
                            value: form.triathlon.totalTemps > 0 ? "\(form.triathlon.totalTemps)" : nil)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, DS.Space.xl)
        }
        .frame(height: 110)
    }

    @ViewBuilder
    private func equipmentPanel<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(DS.Color.surface)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(color.opacity(0.25), lineWidth: 1))
            HStack(spacing: DS.Space.xl) {
                Label(title, systemImage: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 130, alignment: .leading)
                content()
                Spacer()
            }
            .padding(.horizontal, DS.Space.xl)
        }
        .frame(height: 74)
    }

    @ViewBuilder
    func pickerField(label: String, sel: Binding<Int?>, opts: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.Color.textSub)
            Picker("", selection: sel) {
                Text("—").tag(nil as Int?)
                ForEach(opts, id: \.1) { opt in
                    Text(opt.0).tag(opt.1 as Int?)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(height: 28)
            .padding(.horizontal, 6)
            .background(DS.Color.surfaceHi)
            .cornerRadius(DS.Radius.sm)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                .stroke(DS.Color.border, lineWidth: 1))
        }
    }

    @ViewBuilder
    private func triathlonBlock(title: String, km: Binding<Int?>, temps: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(DS.Color.textSub)
            HStack(spacing: DS.Space.sm) {
                triathlonPicker(label: "Km",    selection: km,    options: AddTrainingModal.triathlonKmOptions)
                triathlonPicker(label: "Temps", selection: temps, options: AddTrainingModal.triathlonTempsOptions)
            }
        }
        .padding(DS.Space.sm)
        .background(DS.Color.surfaceHi)
        .cornerRadius(DS.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.Color.borderHi, lineWidth: 1))
    }

    @ViewBuilder
    func triathlonPicker(label: String, selection: Binding<Int?>, options: [(String, Int?)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).foregroundColor(DS.Color.textMuted).font(.system(size: 10, weight: .medium))
            Picker(label, selection: selection) {
                ForEach(options, id: \.1) { option in
                    Text(option.0).tag(option.1)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 72, height: 26)
            .background(DS.Color.surface)
            .cornerRadius(DS.Radius.sm)
        }
    }

    @ViewBuilder
    private func triathlonTotalBadge(label: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(DS.Color.textMuted)
            Text(value ?? "—")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(value != nil ? DS.Color.red : DS.Color.textMuted)
                .frame(width: 60, height: 32)
                .background(value != nil ? DS.Color.red.opacity(0.15) : DS.Color.surface)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(value != nil ? DS.Color.red.opacity(0.4) : DS.Color.border, lineWidth: 1))
        }
    }
}

// MARK: - RECTANGLE PERSONNALISÉ

extension AddTrainingModal {
    @ViewBuilder
    func customTextRectangle() -> some View {
        VStack(spacing: DS.Space.sm) {
            customTextHeader()
            if form.showCustomSettings { customSettingsPanel() }
            customTextZones()
        }
        .padding(DS.Space.md)
        .glassCard()
        .frame(height: form.showCustomSettings ? 330 : 210)
        .alert("Sauvegarder ces réglages ?", isPresented: $showSaveSettingsAlert) {
            Button("Oui") { form.settingsSaved = true; form.showCustomSettings = false }
            Button("Non", role: .cancel) { form.showCustomSettings = false }
        } message: {
            Text("Voulez-vous conserver ces réglages pour les prochaines sessions ?")
        }
    }

    @ViewBuilder
    private func customTextHeader() -> some View {
        HStack(spacing: DS.Space.md) {
            TextField("Sport / Activité", text: $form.sportText)
                .textFieldStyle(.plain)
                .frame(width: CGFloat(form.sportTextWidth))
                .padding(DS.Space.sm)
                .background(DS.Color.surfaceHi)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(DS.Color.border, lineWidth: 1))
                .foregroundColor(form.textColor)
                .font(.system(size: CGFloat(form.fontSize), weight: form.fontWeight))

            Spacer()

            Button {
                if form.showCustomSettings { showSaveSettingsAlert = true }
                else { form.showCustomSettings = true }
            } label: {
                Label(form.showCustomSettings ? "Valider" : "Réglages",
                      systemImage: form.showCustomSettings ? "checkmark.circle.fill" : "slider.horizontal.3")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, DS.Space.md)
                    .padding(.vertical, 6)
                    .background(form.showCustomSettings ? DS.Color.green.opacity(0.7) : DS.Color.orange.opacity(0.7))
                    .cornerRadius(DS.Radius.sm)
            }
            .buttonStyle(.plain)

            Button {
                form.customTexts = Array(repeating: "", count: 13)
                form.sportText = ""
                form.hasClickedCalendar = false
            } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundColor(DS.Color.textSub)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func customSettingsPanel() -> some View {
        VStack(spacing: DS.Space.sm) {
            HStack(spacing: DS.Space.lg) {
                miniSlider(label: "Police",     val: $form.fontSize,       range: 10...24, step: 1) { "\(Int($0))pt" }
                miniSlider(label: "Graisse",    val: $form.fontWeightRaw,  range: 100...900, step: 100) { _ in form.fontWeightLabel }
                miniSlider(label: "Espacement", val: $form.spacing,        range: 4...30, step: 2) { "\(Int($0))px" }
                miniSlider(label: "Marge",      val: $form.leadingPadding, range: 0...50, step: 5) { "\(Int($0))px" }
                Spacer()
            }
            HStack(spacing: DS.Space.lg) {
                Text("Couleur texte").font(.system(size: 10)).foregroundColor(DS.Color.textSub)
                colorSlider(label: "R", val: $form.colorRed,   c: .red)
                colorSlider(label: "V", val: $form.colorGreen, c: .green)
                colorSlider(label: "B", val: $form.colorBlue,  c: .blue)
                RoundedRectangle(cornerRadius: 4)
                    .fill(form.textColor)
                    .frame(width: 36, height: 20)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(DS.Color.borderHi, lineWidth: 1))
                Spacer()
            }
        }
        .padding(DS.Space.md)
        .background(Color.black.opacity(0.25))
        .cornerRadius(DS.Radius.sm)
    }

    @ViewBuilder
    func customTextZones() -> some View {
        VStack(spacing: DS.Space.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CGFloat(form.spacing)) {
                    ForEach(0..<13, id: \.self) { i in customTextZone(index: i) }
                }
                .padding(.leading, CGFloat(form.leadingPadding))
                .padding(.trailing, DS.Space.xl)
            }
            if shouldShowSecondLine {
                Divider().background(DS.Color.border)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CGFloat(form.spacing)) {
                        secondLineZones()
                    }
                    .padding(.leading, CGFloat(form.leadingPadding))
                    .padding(.trailing, DS.Space.xl)
                }
            }
        }
        .frame(height: form.showCustomSettings ? 130 : 100)
    }

    @ViewBuilder
    func customTextZone(index: Int) -> some View {
        if index < form.customTextWidths.count && index < form.customTexts.count {
            let w = form.customTextWidths[index]
            VStack(alignment: .leading, spacing: 3) {
                Text(form.getZoneName(index))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DS.Color.textMuted)
                TextField("", text: $form.customTexts[index])
                    .textFieldStyle(.plain)
                    .frame(width: w)
                    .padding(5)
                    .background(DS.Color.surfaceHi)
                    .cornerRadius(DS.Radius.sm)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.border, lineWidth: 1))
                    .foregroundColor(form.textColor)
                    .font(.system(size: CGFloat(form.fontSize), weight: form.fontWeight))
                if form.showCustomSettings {
                    let minW: CGFloat = (index == 1 || index == 3 || index == 6) ? 30 : 40
                    let maxW: CGFloat = (index == 11 || index == 12) ? 250 : 150
                    Slider(value: $form.customTextWidths[index], in: minW...maxW, step: 10)
                        .frame(width: w)
                        .accentColor(DS.Color.blue.opacity(0.7))
                    Text("\(Int(w))px").font(.system(size: 8)).foregroundColor(DS.Color.textMuted)
                }
            }
        }
    }

    @ViewBuilder
    func secondLineZones() -> some View {
        Group {
            if form.sportText == "Tapis" {
                equipBadge(label: "Pente", value: form.tapisPicker.map { "\($0)%" }, color: DS.Color.orange)
            }
            if form.sportText == "Elliptique" {
                equipBadge(label: "Force",       value: form.elliptique.force.map { "\($0)" },  color: DS.Color.purple)
                equipBadge(label: "Inclinaison", value: form.elliptique.incline.map { "\($0)" }, color: DS.Color.purple)
            }
            if form.sportText == "Rameur" {
                equipBadge(label: "Watts",     value: form.rameur.watts.map { "\($0)W" },   color: DS.Color.teal)
                equipBadge(label: "Force",     value: form.rameur.force.map { "\($0)" },     color: DS.Color.teal)
                equipBadge(label: "C/M",       value: form.rameur.cm.map { "\($0)" },        color: DS.Color.teal)
                equipBadge(label: "Temp/500m", value: form.rameur.temp500 != nil ? form.rameurTemp500Str : nil, color: DS.Color.teal)
                equipBadge(label: "Programme", value: form.rameur.programme != nil ? form.rameurProgrammeStr : nil, color: DS.Color.teal)
            }
            if form.sportText == "Home trainer" {
                equipBadge(label: "Puissance", value: form.homeTrainer.puissance.map { "\($0)W" }, color: DS.Color.green)
                equipBadge(label: "Cadence",   value: form.homeTrainer.cadence.map { "\($0)" },    color: DS.Color.green)
                equipBadge(label: "Niveau",    value: form.homeTrainer.niveau.map { "\($0)" },     color: DS.Color.green)
                equipBadge(label: "Pente",     value: form.homeTrainer.pente.map { "\($0)%" },     color: DS.Color.green)
                equipBadge(label: "Plateau",   value: form.homeTrainer.plateau.map { "\($0)" },    color: DS.Color.green)
            }
            if form.sportText == "Triathlon" {
                let t = form.triathlon
                equipBadge(label: "Km Total",    value: t.totalKm > 0 ? "\(t.totalKm)" : nil,          color: DS.Color.red)
                equipBadge(label: "Temps Total", value: t.totalTemps > 0 ? "\(t.totalTemps) min" : nil, color: DS.Color.red)
            }
        }
    }

    @ViewBuilder
    func equipBadge(label: String, value: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(DS.Color.textMuted)
            Text(value ?? "—")
                .frame(width: 80)
                .padding(.vertical, 5)
                .background(value != nil ? color.opacity(0.18) : DS.Color.surface)
                .cornerRadius(DS.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(value != nil ? color.opacity(0.4) : DS.Color.border, lineWidth: 1))
                .foregroundColor(value != nil ? color : DS.Color.textMuted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - BARRE BAS

extension AddTrainingModal {
    @ViewBuilder
    func bottomBar() -> some View {
        HStack(spacing: DS.Space.md) {
            Button(action: saveTraining) {
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Enregistrer").font(.system(size: 14, weight: .bold))
                        if form.sportText.isEmpty {
                            Text("Sélectionnez un sport").font(.system(size: 10)).opacity(0.7)
                        }
                    }
                }
                .foregroundColor(form.sportText.isEmpty ? DS.Color.textMuted : .black)
                .padding(.horizontal, DS.Space.xl)
                .frame(height: 52)
                .background(form.sportText.isEmpty ? DS.Color.surface : DS.Color.green)
                .cornerRadius(DS.Radius.md)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(form.sportText.isEmpty ? DS.Color.border : DS.Color.green.opacity(0.6), lineWidth: 1))
                .shadow(color: form.sportText.isEmpty ? .clear : DS.Color.green.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(form.sportText.isEmpty)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: form.sportText.isEmpty)

            Button(action: { isPresented = false }) {
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                    Text("Fermer").font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(DS.Color.text)
                .padding(.horizontal, DS.Space.lg)
                .frame(height: 52)
                .background(DS.Color.red.opacity(0.18))
                .cornerRadius(DS.Radius.md)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Color.red.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "magnifyingglass").font(.system(size: 10)).foregroundColor(DS.Color.textMuted)
                    Text("Zoom \(Int(modalScale * 100))%").font(.system(size: 11, weight: .medium)).foregroundColor(DS.Color.textSub)
                }
                Slider(value: $modalScale, in: 0.6...1.0, step: 0.05)
                    .frame(width: 130)
                    .accentColor(DS.Color.blue)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)
            .background(DS.Color.surface)
            .cornerRadius(DS.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.Color.border, lineWidth: 1))
        }
    }
}

// MARK: - COMPOSANTS UTILITAIRES

extension AddTrainingModal {
    @ViewBuilder
    func sectionLabel(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
    }

    @ViewBuilder
    func toggleChip(label: String, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs) {
                ZStack {
                    Circle()
                        .fill(isOn ? color : DS.Color.surface)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(isOn ? color : DS.Color.borderHi, lineWidth: 1.5))
                    if isOn {
                        Image(systemName: "checkmark").font(.system(size: 9, weight: .black)).foregroundColor(.black)
                    }
                }
                Text(label)
                    .font(.system(size: 13, weight: isOn ? .semibold : .regular))
                    .foregroundColor(isOn ? color : DS.Color.textSub)
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, 6)
            .background(isOn ? color.opacity(0.12) : DS.Color.surface)
            .cornerRadius(DS.Radius.xl)
            .overlay(Capsule().stroke(isOn ? color.opacity(0.5) : DS.Color.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
    }

    @ViewBuilder
    func miniSlider(label: String, val: Binding<Double>, range: ClosedRange<Double>, step: Double,
                    format: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(DS.Color.textSub)
            Slider(value: val, in: range, step: step).frame(width: 80).accentColor(DS.Color.blue)
            Text(format(val.wrappedValue)).font(.system(size: 9)).foregroundColor(DS.Color.textMuted)
        }
    }

    @ViewBuilder
    func colorSlider(label: String, val: Binding<Double>, c: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 9)).foregroundColor(c)
            Slider(value: val, in: 0...1, step: 0.1).frame(width: 70).accentColor(c)
        }
    }
}

// MARK: - ROUNDED CORNERS HELPER

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomLeft  = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let all: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCornersShape: Shape {
    var radius: CGFloat
    var corners: RectCorner
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl: CGFloat = corners.contains(.topLeft)     ? radius : 0
        let tr: CGFloat = corners.contains(.topRight)    ? radius : 0
        let bl: CGFloat = corners.contains(.bottomLeft)  ? radius : 0
        let br: CGFloat = corners.contains(.bottomRight) ? radius : 0
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornersShape(radius: radius, corners: corners))
    }
}

// MARK: - GLASS CARD

private extension View {
    func glassCard() -> some View {
        self
            .background(DS.Color.surface)
            .cornerRadius(DS.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(DS.Color.border, lineWidth: 1))
    }
}
