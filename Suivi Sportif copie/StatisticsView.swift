import SwiftUI
import Charts
import SDWebImageSwiftUI

struct StatisticsView: View {
    @State private var zoom = false
    @State private var allTrainings: [Training] = []
    @State private var selectedPeriod: Period = .all
    @State private var selectedChart: ChartType = .distance
    @State private var selectedChartStyle: ChartStyle = .bar
    @State private var selectedSport: String = "Tous"
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = 0
    
    enum Period: String, CaseIterable {
        case week = "7 jours"
        case month = "30 jours"
        case threeMonths = "3 mois"
        case year = "1 an"
        case all = "Tout"
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case distance = "Distance"
        case calories = "Calories"
        case duration = "Durée"
    }
    
    enum ChartStyle: String, CaseIterable {
        case bar = "Barres"
        case stackedBar = "Barres empilées"
        case line = "Ligne"
        
        var icon: String {
            switch self {
            case .bar: return "chart.bar.fill"
            case .stackedBar: return "square.stack.fill"
            case .line: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var availableYears: [Int] {
        let years = Set(allTrainings.map { Calendar.current.component(.year, from: $0.date) })
        return [0] + years.sorted(by: >)
    }
    
    var availableMonths: [(value: Int, name: String)] {
        let monthNames = ["Tous", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                         "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
        return Array(0...12).map { (value: $0, name: monthNames[$0]) }
    }
    
    var filteredTrainings: [Training] {
        var trainings = allTrainings
        
        if selectedSport != "Tous" {
            trainings = trainings.filter { $0.type == selectedSport }
        }
        
        if selectedYear != 0 {
            trainings = trainings.filter {
                Calendar.current.component(.year, from: $0.date) == selectedYear
            }
        }
        
        if selectedMonth != 0 {
            trainings = trainings.filter {
                Calendar.current.component(.month, from: $0.date) == selectedMonth
            }
        }
        
        if selectedMonth == 0 && selectedYear == 0, let days = selectedPeriod.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            trainings = trainings.filter { $0.date >= cutoffDate }
        }
        
        return trainings
    }
    
    var globalStats: (count: Int, totalKm: Double, totalCalories: Int, totalMinutes: Int, avgCalories: Int, currentStreak: Int) {
        let count = filteredTrainings.count
        
        let distances = filteredTrainings.compactMap { $0.distance }
        let totalKm = distances.reduce(0, +)
        
        let cals = filteredTrainings.compactMap { $0.calories }
        let totalCalories = cals.reduce(0, +)
        
        var totalMinutes = 0
        for training in filteredTrainings {
            totalMinutes += durationToMinutes(training.duration)
        }
        
        let avgCalories = count == 0 ? 0 : totalCalories / count
        let streak = calculateStreak()
        
        return (count, totalKm, totalCalories, totalMinutes, avgCalories, streak)
    }
    
    var sportBreakdown: [(sport: String, count: Int, distance: Double, time: Int)] {
        let grouped = Dictionary(grouping: filteredTrainings) { $0.type }
        var results: [(sport: String, count: Int, distance: Double, time: Int)] = []
        
        for (sport, trainings) in grouped {
            let count = trainings.count
            
            let distances = trainings.compactMap { $0.distance }
            let totalDistance = distances.reduce(0, +)
            
            var totalTime = 0
            for t in trainings {
                totalTime += durationToMinutes(t.duration)
            }
            
            results.append((sport, count, totalDistance, totalTime))
        }
        
        results.sort { $0.count > $1.count }
        return results
    }
    
    var records: (maxDistance: Double, maxCalories: Int, maxDuration: String, bestSpeed: String) {
        let distances = filteredTrainings.compactMap { $0.distance }
        let maxDist = distances.max() ?? 0
        
        let cals = filteredTrainings.compactMap { $0.calories }
        let maxCal = cals.max() ?? 0
        
        var maxDur = "0:00"
        var maxMinutes = 0
        for training in filteredTrainings {
            let mins = durationToMinutes(training.duration)
            if mins > maxMinutes {
                maxMinutes = mins
                maxDur = training.duration
            }
        }
        
        let speeds = filteredTrainings.compactMap { $0.averageSpeed }
        let bestSpd = speeds.max() ?? ""
        
        return (maxDist, maxCal, maxDur, bestSpd)
    }
    
    var monthlyData: [(month: String, distance: Double, calories: Int, duration: Int)] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: filteredTrainings) { training -> String in
            let components = calendar.dateComponents([.year, .month], from: training.date)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateFormat = "MMM yyyy"
            
            if let date = calendar.date(from: components) {
                return formatter.string(from: date)
            } else {
                return formatter.string(from: training.date)
            }
        }
        
        var results: [(month: String, distance: Double, calories: Int, duration: Int)] = []
        
        for (month, trainings) in grouped {
            let distances = trainings.compactMap { $0.distance }
            let totalDistance = distances.reduce(0, +)
            
            let cals = trainings.compactMap { $0.calories }
            let totalCalories = cals.reduce(0, +)
            
            var totalDuration = 0
            for t in trainings {
                totalDuration += durationToMinutes(t.duration)
            }
            
            results.append((month, totalDistance, totalCalories, totalDuration))
        }
        
        results.sort { $0.month < $1.month }
        return results
    }
    
    var stackedMonthlyData: [(month: String, sport: String, distance: Double, calories: Int, duration: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMM yyyy"
        
        let grouped = Dictionary(grouping: filteredTrainings) { training -> String in
            let components = calendar.dateComponents([.year, .month], from: training.date)
            if let date = calendar.date(from: components) {
                return formatter.string(from: date) + "_" + training.type
            }
            return formatter.string(from: training.date) + "_" + training.type
        }
        
        var results: [(month: String, sport: String, distance: Double, calories: Int, duration: Int)] = []
        
        for (key, trainings) in grouped {
            let parts = key.components(separatedBy: "_")
            guard parts.count == 2 else { continue }
            
            let month = parts[0]
            let sport = parts[1]
            
            let distances = trainings.compactMap { $0.distance }
            let totalDistance = distances.reduce(0, +)
            
            let cals = trainings.compactMap { $0.calories }
            let totalCalories = cals.reduce(0, +)
            
            var totalDuration = 0
            for t in trainings {
                totalDuration += durationToMinutes(t.duration)
            }
            
            results.append((month, sport, totalDistance, totalCalories, totalDuration))
        }
        
        let sportOrder = ["Marche", "Tapis", "Elliptique", "Rameur", "Home trainer",
                         "Triathlon", "Piste", "Route", "VTT", "Piscine", "Mer", "Course"]
        
        results.sort { item1, item2 in
            if item1.month != item2.month {
                return item1.month < item2.month
            }
            let index1 = sportOrder.firstIndex(of: item1.sport) ?? 999
            let index2 = sportOrder.firstIndex(of: item2.sport) ?? 999
            return index1 < index2
        }
        
        return results
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                Image("fondtriathlon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .opacity(0.25)
                    .scaleEffect(zoom ? 1.3 : 1.1)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: zoom)
                    .onAppear { zoom = true }
                    .padding(.bottom, 20)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                mainContent
            }
        }
        .onAppear { loadTrainings() }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 6) {
                monthYearSelector
                gifAndSportWithoutFrame
                globalStatsSection
                chartsSection
                sportBreakdownSection
                recordsSection
            }
            .padding(.leading, 8)
            .padding(.trailing, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var gifAndSportWithoutFrame: some View {
        HStack(spacing: 10) {
            AnimatedGifViewStats()
                .padding(.leading, 60)
                .offset(y: 20)
            
            SportImageSelector(selectedSport: $selectedSport)
                .padding(.leading, 40)
            
            Spacer()
        }
        .padding(.top, -22)
    }
    
    private var monthYearSelector: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Année")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Menu {
                    ForEach(availableYears, id: \.self) { year in
                        Button(action: {
                            selectedYear = year
                            if year != 0 {
                                selectedPeriod = .all
                            }
                        }) {
                            Text(year == 0 ? "Toutes" : "\(year)")
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedYear == 0 ? "Toutes" : "\(selectedYear)")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 140)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Mois")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Menu {
                    ForEach(availableMonths, id: \.value) { month in
                        Button(action: {
                            selectedMonth = month.value
                            if month.value != 0 {
                                selectedPeriod = .all
                            }
                        }) {
                            Text(month.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(availableMonths.first(where: { $0.value == selectedMonth })?.name ?? "Tous")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 140)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Text("Statistiques")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 200)
                .padding(.trailing, 5)

            Spacer()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Période rapide")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Button(action: {
                            selectedPeriod = period
                            selectedYear = 0
                            selectedMonth = 0
                        }) {
                            Text(period.rawValue)
                                .font(.system(size: 12, weight: selectedPeriod == period ? .bold : .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedPeriod == period ? Color.white.opacity(0.3) : Color.white.opacity(0.12))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Button(action: {
                selectedYear = 0
                selectedMonth = 0
                selectedPeriod = .all
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                    Text("Reset")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 1240)
        .padding(.horizontal, 8)
        .padding(12)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
    
    private var globalStatsSection: some View {
        VStack(spacing: 15) {
            Text("Vue d'ensemble")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.fixed(390), spacing: 14),
                GridItem(.fixed(390), spacing: 14),
                GridItem(.fixed(390), spacing: 14)
                ], spacing: 14) {
                StatCard(icon: "figure.run", label: "Entraînements", value: "\(globalStats.count)", color: .red)
                StatCard(icon: "location.fill", label: "Distance totale", value: formatDistance(globalStats.totalKm), color: .green)
                StatCard(icon: "flame.fill", label: "Calories totales", value: formatNumber(globalStats.totalCalories), color: .orange)
                StatCard(icon: "clock.fill", label: "Temps total", value: "\(globalStats.totalMinutes / 60)h \(globalStats.totalMinutes % 60)m", color: .purple)
                StatCard(icon: "chart.bar.fill", label: "Moy. calories", value: formatNumber(globalStats.avgCalories), color: .pink)
                StatCard(icon: "flame.fill", label: "Série actuelle", value: "\(globalStats.currentStreak) jours", color: .red)
            }
        }
        .frame(maxWidth: 1240)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
        .padding(.top, -22)
    }
    
    private var chartsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Évolution")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // ── MODIFICATION : GIF animé selon le sport sélectionné ──
                if selectedSport == "Marche",
                   let gifURL = Bundle.main.url(forResource: "marcheur", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Tapis",
                          let gifURL = Bundle.main.url(forResource: "tapis2", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Rameur",
                          let gifURL = Bundle.main.url(forResource: "rameur", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Home trainer",
                          let gifURL = Bundle.main.url(forResource: "home", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Triathlon",
                          let gifURL = Bundle.main.url(forResource: "triathlon3", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Piste",
                          let gifURL = Bundle.main.url(forResource: "piste", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Route",
                          let gifURL = Bundle.main.url(forResource: "velo2", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "VTT",
                          let gifURL = Bundle.main.url(forResource: "vtt", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Piscine",
                          let gifURL = Bundle.main.url(forResource: "Piscine", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport == "Mer",
                          let gifURL = Bundle.main.url(forResource: "mer1", withExtension: "gif") {
                    AnimatedImage(url: gifURL)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 80)
                } else if selectedSport != "Tous" {
                    Image(sportImageName(for: selectedSport))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 60)
                } else {
                    Image("Tous3")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 60)
                }
                // ── FIN MODIFICATION ──
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(ChartStyle.allCases, id: \.self) { style in
                        Button(action: {
                            selectedChartStyle = style
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 14))
                                Text(style.rawValue)
                                    .font(.system(size: 12, weight: selectedChartStyle == style ? .bold : .regular))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedChartStyle == style ? Color.blue.opacity(0.4) : Color.white.opacity(0.12))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer().frame(width: 20)
                
                Picker("", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            
            if selectedChartStyle == .stackedBar && selectedSport != "Tous" {
                Text("⚠️ Les barres empilées ne sont pas disponibles avec un filtre sport")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 8)
            }
            
            if monthlyData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 40)
            } else {
                chartContent
            }
        }
        .frame(maxWidth: 1220)
        .padding(.horizontal, 8)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var chartContent: some View {
        switch selectedChartStyle {
        case .bar:
            barChart
        case .stackedBar:
            if selectedSport != "Tous" {
                barChart
            } else if stackedMonthlyData.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 40)
            } else {
                stackedBarChart
            }
        case .line:
            lineChart
        }
    }
    
    private var barChart: some View {
        Chart {
            ForEach(monthlyData, id: \.month) { data in
                BarMark(
                    x: .value("Mois", data.month),
                    y: .value("Valeur", chartValue(for: data))
                )
                .foregroundStyle(chartColor)
                .annotation(position: .top) {
                    Text(formattedChartValue(for: data))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    private var stackedBarChart: some View {
        Chart {
            ForEach(Array(stackedMonthlyData.enumerated()), id: \.offset) { index, data in
                BarMark(
                    x: .value("Mois", data.month),
                    y: .value("Valeur", stackedChartValue(for: data))
                )
                .foregroundStyle(by: .value("Sport", data.sport))
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .chartForegroundStyleScale { sport in
            sportColor(for: sport)
        }
        .chartLegend {
            HStack(spacing: 15) {
                ForEach(Array(Set(stackedMonthlyData.map { $0.sport })).sorted(), id: \.self) { sport in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sportColor(for: sport))
                            .frame(width: 12, height: 12)
                        Text(sport)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var lineChart: some View {
        Chart {
            ForEach(monthlyData, id: \.month) { data in
                LineMark(
                    x: .value("Mois", data.month),
                    y: .value("Valeur", chartValue(for: data))
                )
                .foregroundStyle(chartColor)
                .symbol(Circle())
                
                PointMark(
                    x: .value("Mois", data.month),
                    y: .value("Valeur", chartValue(for: data))
                )
                .foregroundStyle(chartColor)
                .annotation(position: .top) {
                    Text(formattedChartValue(for: data))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    private var sportBreakdownSection: some View {
        VStack(spacing: 15) {
            Text("Répartition par sport")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if sportBreakdown.isEmpty {
                Text("Aucune donnée disponible")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(sportBreakdown, id: \.sport) { item in
                        sportBreakdownRow(item)
                    }
                }
            }
        }
        .frame(maxWidth: 1220)
        .padding(.horizontal, 8)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
    
    private func sportBreakdownRow(_ item: (sport: String, count: Int, distance: Double, time: Int)) -> some View {
        let hours = item.time / 60
        let minutes = item.time % 60
        let distanceStr = formatDistanceValue(item.distance)
        let totalCount = globalStats.count
        let percentage = totalCount > 0 ? Int(Double(item.count) / Double(totalCount) * 100) : 0
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.sport)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(item.count) séances · \(distanceStr) km · \(hours)h\(minutes)m")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Text("\(percentage)%")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: 1200)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var recordsSection: some View {
        VStack(spacing: 15) {
            Text("🏆 Records")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RecordCard(icon: "location.fill", label: "Distance max", value: formatDistance(records.maxDistance))
                RecordCard(icon: "flame.fill", label: "Calories max", value: formatNumber(records.maxCalories))
                RecordCard(icon: "clock.fill", label: "Durée max", value: records.maxDuration)
                RecordCard(icon: "speedometer", label: "Meilleure vitesse", value: records.bestSpeed)
            }
        }
        .frame(maxWidth: 1240)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
    
    private func chartValue(for data: (month: String, distance: Double, calories: Int, duration: Int)) -> Double {
        switch selectedChart {
        case .distance: return data.distance
        case .calories: return Double(data.calories)
        case .duration: return Double(data.duration)
        }
    }
    
    private func stackedChartValue(for data: (month: String, sport: String, distance: Double, calories: Int, duration: Int)) -> Double {
        switch selectedChart {
        case .distance: return data.distance
        case .calories: return Double(data.calories)
        case .duration: return Double(data.duration)
        }
    }
    
    private func formattedChartValue(for data: (month: String, distance: Double, calories: Int, duration: Int)) -> String {
        switch selectedChart {
        case .distance:
            return formatDistanceValue(data.distance)
        case .calories:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = " "
            return formatter.string(from: NSNumber(value: data.calories)) ?? "\(data.calories)"
        case .duration:
            let hours = data.duration / 60
            let mins = data.duration % 60
            return hours > 0 ? "\(hours)h\(mins)m" : "\(mins)m"
        }
    }
    
    private var chartColor: Color {
        switch selectedChart {
        case .distance: return .green
        case .calories: return .orange
        case .duration: return .purple
        }
    }
    
    private func sportColor(for sport: String) -> Color {
        let sportColors: [(sport: String, color: Color)] = [
            ("Marche", .cyan),
            ("Tapis", .pink),
            ("Elliptique", .green),
            ("Rameur", .red),
            ("Home trainer", .orange),
            ("Triathlon", .blue),
            ("Piste", .purple),
            ("Route", .yellow),
            ("VTT", .mint),
            ("Piscine", .teal),
            ("Mer", .indigo),
            ("Course", .gray)
        ]
        
        if let entry = sportColors.first(where: { $0.sport == sport }) {
            return entry.color
        }
        return .gray
    }
    
    private func sportImageName(for sport: String) -> String {
        switch sport {
        case "Tous": return "Tous3"
        case "Marche": return "Marche"
        case "Tapis": return "Tapis"
        case "Elliptique": return "elliptique"
        case "Rameur": return "Rameur"
        case "Home trainer": return "Home trainer"
        case "Triathlon": return "Triathlon"
        case "Piste": return "Piste"
        case "Route": return "Route"
        case "VTT": return "VTT"
        case "Piscine": return "Piscine"
        case "Mer": return "Mer"
        case "Course": return "Coureur 3 copie"
        default: return "Tous3"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        if let formatted = formatter.string(from: NSNumber(value: distance)) {
            return "\(formatted) km"
        }
        return "\(Int(distance.rounded())) km"
    }
    
    private func formatDistanceValue(_ distance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: distance)) ?? "\(Int(distance.rounded()))"
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func loadTrainings() {
        if let data = UserDefaults.standard.data(forKey: "trainings"),
           let decoded = try? JSONDecoder().decode([Training].self, from: data) {
            allTrainings = decoded.sorted { $0.date > $1.date }
        }
    }
    
    private func durationToMinutes(_ duration: String) -> Int {
        let components = duration.components(separatedBy: ":")
        guard components.count >= 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else { return 0 }
        return hours * 60 + minutes
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        
        let sorted = allTrainings.sorted(by: { t1, t2 in
            return t1.date > t2.date
        })
        
        guard let mostRecent = sorted.first else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let recentDay = calendar.startOfDay(for: mostRecent.date)
        
        let comp1 = calendar.dateComponents([.day], from: recentDay, to: today)
        let daysSince = comp1.day ?? 0
        
        if daysSince > 1 {
            return 0
        }
        
        var streak = 0
        var currentDate = recentDay
        
        for training in sorted {
            let trainingDay = calendar.startOfDay(for: training.date)
            let comp2 = calendar.dateComponents([.day], from: trainingDay, to: currentDate)
            let diff = comp2.day ?? 0
            
            if diff <= 1 {
                let sameDay = (trainingDay == currentDate)
                let firstEntry = (streak == 0)
                
                if !sameDay || firstEntry {
                    streak += 1
                }
                currentDate = trainingDay
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - AnimatedGifViewStats
struct AnimatedGifViewStats: View {
    var body: some View {
        if let gifURL = Bundle.main.url(forResource: "cycle", withExtension: "gif") {
            AnimatedImage(url: gifURL)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 160)
                .cornerRadius(8)
        } else {
            VStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                Text("GIF non trouvé")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 110, height: 180)
        }
    }
}

// MARK: - StatCard
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - RecordCard
struct RecordCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    StatisticsView()
}
