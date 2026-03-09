import SwiftUI
import SDWebImageSwiftUI

struct TrainingsListView: View {
    private let columnWidths: [CGFloat] = [160, 140, 60, 100, 100, 90, 60, 80, 200]
    
    @State private var allTrainings: [Training] = []
    @State private var filteredTrainings: [Training] = []
    @State private var selectedSport: String = "Tous"
    @State private var startDate: Date = {
        var components = DateComponents()
        components.year = 2016
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var endDate: Date = Date()
    @State private var sortColumn: SortColumn = .date
    @State private var sortAscending: Bool = false
    @State private var showDeleteAlert = false
    @State private var lastDeletedTraining: Training? = nil
    @State private var zoom = false
    @State private var selectedTraining: Training? = nil
    @State private var showDetail = false
    
    enum SortColumn { case date, sport, distance, duration, calories }
    
    var sports: [String] {
        ["Tous"] + Set(allTrainings.map { $0.type }).sorted()
    }
    
    var statistics: (count: Int, totalKm: Double, totalCalories: Int, avgCalories: Int) {
        let count = filteredTrainings.count
        let totalKm = filteredTrainings.compactMap { $0.distance }.reduce(0, +)
        let totalCalories = filteredTrainings.compactMap { $0.calories }.reduce(0, +)
        return (count, totalKm, totalCalories, count == 0 ? 0 : totalCalories / count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                Image("background")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .opacity(0.25)
                    .scaleEffect(zoom ? 1.3 : 1.1)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: zoom)
                    .onAppear { zoom = true }
                    .padding(.top, 450)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("Mes Entrainements")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    mainContent
                }
            }
            .onAppear { loadTrainings() }
            .onChange(of: selectedSport) { _ in filterTrainings() }
            .onChange(of: startDate) { _ in filterTrainings() }
            .onChange(of: endDate) { _ in filterTrainings() }
            .onChange(of: sortColumn) { _ in sortTrainings() }
            .onChange(of: sortAscending) { _ in sortTrainings() }
            .alert("Voulez-vous vraiment supprimer le dernier entrainement ?", isPresented: $showDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    deleteLastTraining()
                }
            } message: {
                Text("Cette action peut être annulée avec le bouton Restaurer.")
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if allTrainings.isEmpty {
                Spacer()
                Text("Aucun entrainement pour le moment")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 18))
                Spacer()
            } else {
                filtersAndStatsSection
                tableHeader
                    .padding(.horizontal, 10)
                Divider().background(Color.white)
                    .padding(.horizontal, 10)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredTrainings.enumerated()), id: \.element.id) { index, training in
                            NavigationLink(destination: TrainingDetailView(training: training)) {
                                trainingRow(training, index: index)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                            Divider().background(Color.white.opacity(0.3))
                                .padding(.horizontal, 10)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var filtersAndStatsSection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 12) {
                Button(action: { showDeleteAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                        Text("Supprimer le dernier")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.35))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(allTrainings.isEmpty)
                .opacity(allTrainings.isEmpty ? 0.5 : 1)
                
                Button(action: { restoreLastTraining() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 14))
                        Text("Restaurer le dernier")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.35))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(lastDeletedTraining == nil)
                .opacity(lastDeletedTraining == nil ? 0.5 : 1)
                
                Button(action: { reloadFromCSV() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 14))
                        Text("Recharger CSV")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.35))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                AnimatedGifView()
                SportImageSelector(selectedSport: $selectedSport)
                Spacer()
            }
            .padding(.top, 6)
            
            HStack(spacing: 8) {
                Text("Du:")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                MonthYearPicker(selection: $startDate, isEndDate: false)  // Début du mois
                Spacer().frame(width: 20)
                Text("Au:")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                MonthYearPicker(selection: $endDate, isEndDate: true)  // FIN du mois
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 30) {
                SportImageBox(selectedSport: selectedSport)
                StatBox(icon: "list.bullet", label: "Entrainements", value: formattedWithSeparator(statistics.count))
                StatBox(icon: "location.fill", label: "Total Km", value: formattedWithSeparator(Int(statistics.totalKm)))
                StatBox(icon: "chart.bar.fill", label: "Moy. Calories", value: formattedWithSeparator(statistics.avgCalories))
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(6)
        .padding(.bottom, 8)
        .padding(.horizontal, 10)
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 10)
            SortableHeader(title: "Date", width: columnWidths[0], column: .date, currentSort: $sortColumn, ascending: $sortAscending)
            VerticalDivider()
            SortableHeader(title: "Sport", width: columnWidths[1], column: .sport, currentSort: $sortColumn, ascending: $sortAscending)
            VerticalDivider()
            SortableHeader(title: "Km", width: columnWidths[2], column: .distance, currentSort: $sortColumn, ascending: $sortAscending)
            VerticalDivider()
            TableHeader(title: "Temps", width: columnWidths[3])
            VerticalDivider()
            TableHeader(title: "Moyenne", width: columnWidths[4])
            VerticalDivider()
            SortableHeader(title: "Calories", width: columnWidths[5], column: .calories, currentSort: $sortColumn, ascending: $sortAscending)
            VerticalDivider()
            TableHeader(title: "À jeun", width: columnWidths[6])
            VerticalDivider()
            TableHeader(title: "Forme ⭐️", width: columnWidths[7])
            VerticalDivider()
            TableHeader(title: "Observations", width: columnWidths[8])
            VerticalDivider()
            TableHeader(title: "Détails →", width: 80)
            Spacer(minLength: 0)
        }
        .frame(height: 44)
        .background(Color.white.opacity(0.50))
    }
    
    private func trainingRow(_ training: Training, index: Int) -> some View {
        return HStack(spacing: 0) {
            Spacer().frame(width: 10)
            TableCell(text: training.formattedDate, width: columnWidths[0], alignment: .leading)
            VerticalDivider()
            TableCell(text: training.type, width: columnWidths[1])
            VerticalDivider()
            TableCell(text: formatted(training.distance), width: columnWidths[2])
            VerticalDivider()
            TableCell(text: normalizeTime(training.duration), width: columnWidths[3])
            VerticalDivider()
            TableCell(text: normalizeSpeed(training.averageSpeed), width: columnWidths[4])
            VerticalDivider()
            TableCell(text: formatted(training.calories), width: columnWidths[5])
            VerticalDivider()
            TableCell(text: training.aJeun ?? "", width: columnWidths[6])
            VerticalDivider()
            TableCell(text: training.forme ?? "", width: columnWidths[7])
            VerticalDivider()
            TableCell(text: String(training.observations.prefix(20)) + (training.observations.count > 20 ? "..." : ""), width: columnWidths[8], alignment: .leading)
            VerticalDivider()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 80)
            Spacer(minLength: 0)
        }
        .background(Color.white.opacity(0.50))
        .contentShape(Rectangle())
    }
    
    private func normalizeTime(_ time: String) -> String {
        let trimmed = time.trimmingCharacters(in: .whitespaces)
        if trimmed.contains("h") {
            let parts = trimmed.components(separatedBy: "h")
            if parts.count == 2, let hours = Int(parts[0]) {
                let mins = parts[1].replacingOccurrences(of: "min", with: "").trimmingCharacters(in: .whitespaces)
                return "\(hours):\(mins.isEmpty || mins == "00" ? "00" : mins)"
            }
        }
        return trimmed
    }
    
    private func normalizeSpeed(_ speed: String?) -> String {
        guard let speed = speed else { return "" }
        let trimmed = speed.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(".00") {
            return trimmed.replacingOccurrences(of: ".00", with: "")
        }
        return trimmed
    }
    
    private func formatted(_ value: Double?) -> String {
        guard let v = value else { return "" }
        return String(format: "%.1f", v)
    }
    
    private func formatted(_ value: Int?) -> String {
        guard let v = value else { return "" }
        return "\(v)"
    }
    
    private func formattedWithSeparator(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private func loadTrainings() {
        allTrainings = TrainingDataManager.shared.loadTrainings()
        filterTrainings()
    }
    
    private func filterTrainings() {
        filteredTrainings = allTrainings
            .filter { selectedSport == "Tous" || $0.type == selectedSport }
            .filter { $0.date >= startDate && $0.date <= endDate }
        sortTrainings()
    }
    
    private func sortTrainings() {
        filteredTrainings.sort { t1, t2 in
            let result: Bool = {
                switch sortColumn {
                case .date: return t1.date < t2.date
                case .sport: return t1.type < t2.type
                case .distance: return (t1.distance ?? 0) < (t2.distance ?? 0)
                case .duration: return t1.duration < t2.duration
                case .calories: return (t1.calories ?? 0) < (t2.calories ?? 0)
                }
            }()
            return sortAscending ? result : !result
        }
    }
    
    private func deleteLastTraining() {
        guard let lastTraining = allTrainings.sorted(by: { $0.date > $1.date }).first else { return }
        lastDeletedTraining = lastTraining
        allTrainings.removeAll { $0.id == lastTraining.id }
        saveTrainings()
        filterTrainings()
        NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
    }
    
    private func restoreLastTraining() {
        guard let training = lastDeletedTraining else { return }
        allTrainings.append(training)
        saveTrainings()
        lastDeletedTraining = nil
        filterTrainings()
        NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
    }
    
    private func saveTrainings() {
        TrainingDataManager.shared.saveTrainings(allTrainings)
    }
    
    private func reloadFromCSV() {
        TrainingDataManager.shared.resetToCSV()
        loadTrainings()
        NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
    }
}

// MonthYearPicker - Composant pour sélectionner mois et année
struct MonthYearPicker: View {
    @Binding var selection: Date
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    let isEndDate: Bool  // NOUVEAU paramètre
    
    private let months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                          "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
    private let years = Array(2016...2040)
    
    init(selection: Binding<Date>, isEndDate: Bool = false) {  // MODIFIÉ
        self._selection = selection
        self.isEndDate = isEndDate
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selection.wrappedValue)
        self._selectedMonth = State(initialValue: components.month ?? 1)
        self._selectedYear = State(initialValue: components.year ?? 2026)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $selectedMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(months[month - 1])
                        .font(.system(size: 16))
                        .tag(month)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: selectedMonth) { _ in updateDate() }
            
            Picker("", selection: $selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text("\(year)")
                        .font(.system(size: 16))
                        .tag(year)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 90)
            .onChange(of: selectedYear) { _ in updateDate() }
        }
    }
    
    private func updateDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        
        if isEndDate {
            // Pour la date de fin, aller à la fin du mois
            components.day = 1
            if let firstOfMonth = Calendar.current.date(from: components),
               let lastOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) {
                // Mettre l'heure à 23:59:59
                var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: lastOfMonth)
                endComponents.hour = 23
                endComponents.minute = 59
                endComponents.second = 59
                if let endDate = Calendar.current.date(from: endComponents) {
                    selection = endDate
                }
            }
        } else {
            // Pour la date de début, premier jour du mois à 00:00:00
            components.day = 1
            if let newDate = Calendar.current.date(from: components) {
                selection = newDate
            }
        }
    }
}

// AnimatedGifView
struct AnimatedGifView: View {
    var body: some View {
        if let gifURL = Bundle.main.url(forResource: "tous", withExtension: "gif") {
            AnimatedImage(url: gifURL)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 180)
                .cornerRadius(8)
        } else {
            // Utiliser l'image statique Tous3 depuis Assets
            Image("Tous3")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 180)
                .cornerRadius(8)
        }
    }
}

struct StatBox: View {
    let icon: String
    let label: String
    let value: String
    
    var iconColor: Color {
        switch icon {
        case "list.bullet": return Color(red: 79/255, green: 172/255, blue: 254/255)
        case "location.fill": return Color(red: 67/255, green: 233/255, blue: 123/255)
        case "chart.bar.fill": return Color(red: 255/255, green: 89/255, blue: 94/255)
        default: return .white
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(iconColor)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(10)
        .frame(width: 120, height: 100)
        .background(Color.white.opacity(0.12))
        .cornerRadius(10)
    }
}

struct SportImageBox: View {
    let selectedSport: String
    
    var sportImageName: String {
        switch selectedSport {
        case "Tous": return "Tous3"
        case "Marche": return "Marche"
        case "Tapis": return "tapis2"
        case "Elliptique": return "elliptique"
        case "Home trainer": return "Home trainer"
        case "triathlon": return "Triathlon"
        case "Piste": return "Piste"
        case "Route": return "velo2"
        case "VTT": return "cycle"
        case "Course": return "joggeur"
        default: return "Tous3"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Piscine → GIF Piscine
            if selectedSport == "Piscine" {
                if let gifURL = Bundle.main.url(forResource: "Piscine", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .cornerRadius(6)
                }
                
            // MARK: - Mer → GIF mer1
            } else if selectedSport == "Mer" {
                if let gifURL = Bundle.main.url(forResource: "mer1", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .cornerRadius(6)
                }
                
            // MARK: - Rameur → GIF rameur3
            } else if selectedSport == "Rameur" {
                if let gifURL = Bundle.main.url(forResource: "rameur", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Home trainer → GIF home
            } else if selectedSport == "Home trainer" {
                if let gifURL = Bundle.main.url(forResource: "home", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Tapis → GIF tapis2
            } else if selectedSport == "Tapis" {
                if let gifURL = Bundle.main.url(forResource: "tapis2", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Marche → GIF marcheur
            } else if selectedSport == "Marche" {
                if let gifURL = Bundle.main.url(forResource: "marcheur", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Piste → GIF piste
            } else if selectedSport == "Piste" {
                if let gifURL = Bundle.main.url(forResource: "piste", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - VTT → GIF vtt2
            } else if selectedSport == "VTT" {
                if let gifURL = Bundle.main.url(forResource: "vtt", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Route → GIF cycle
            } else if selectedSport == "Route" {
                if let gifURL = Bundle.main.url(forResource: "cycle", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - triathlon → GIF triathlon2
            } else if selectedSport == "Triathlon" {
                if let gifURL = Bundle.main.url(forResource: "triathlon3", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                        .cornerRadius(6)
                }
                
            // MARK: - Images statiques
            } else {
                Image(sportImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        height: (selectedSport == "Tous" || selectedSport == "Triathlon") ? 150 : 80
                    )
                    .cornerRadius(6)
            }
        }
        .padding(.trailing, 10)
        .padding(
            .vertical,
            (selectedSport == "Piscine" || selectedSport == "Mer" || selectedSport == "Rameur" || selectedSport == "Home trainer" || selectedSport == "Tapis" || selectedSport == "Marche" || selectedSport == "Piste" || selectedSport == "VTT" || selectedSport == "Route" || selectedSport == "triathlon") ? 5 : 10
        )
        .frame(
            width: {
                if selectedSport == "Piscine" || selectedSport == "Mer" || selectedSport == "Rameur" || selectedSport == "Home trainer" || selectedSport == "Tapis" || selectedSport == "Marche" || selectedSport == "Piste" || selectedSport == "VTT" || selectedSport == "Route" || selectedSport == "triathlon" {
                    return 160
                } else if selectedSport == "Tous" || selectedSport == "Triathlon" {
                    return 120
                } else {
                    return 80
                }
            }(),
            height: {
                if selectedSport == "Piscine" || selectedSport == "Mer" {
                    return 150
                } else if selectedSport == "Tous" || selectedSport == "Triathlon" || selectedSport == "Rameur" || selectedSport == "Home trainer" || selectedSport == "Tapis" || selectedSport == "Marche" || selectedSport == "Piste" || selectedSport == "VTT" || selectedSport == "Route" || selectedSport == "triathlon" {
                    return 120
                } else {
                    return 80
                }
            }()
        )
    }
}

struct VerticalDivider: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1)
    }
}

struct TableHeader: View {
    let title: String
    let width: CGFloat
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, alignment: .center)
            .padding(.vertical, 6)
    }
}

struct SortableHeader: View {
    let title: String
    let width: CGFloat
    let column: TrainingsListView.SortColumn
    @Binding var currentSort: TrainingsListView.SortColumn
    @Binding var ascending: Bool
    
    var body: some View {
        Button(action: {
            if currentSort == column { ascending.toggle() } else { currentSort = column; ascending = true }
        }) {
            HStack(spacing: 6) {
                Text(title).font(.system(size: 14, weight: .bold))
                if currentSort == column {
                    Image(systemName: ascending ? "arrow.up" : "arrow.down").font(.system(size: 10))
                }
            }
            .foregroundColor(.white)
            .frame(width: width, alignment: .center)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

struct TableCell: View {
    let text: String
    let width: CGFloat
    var alignment: Alignment = .center
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, alignment: alignment)
            .padding(.vertical, 6)
    }
}

#Preview {
    TrainingsListView()
}

