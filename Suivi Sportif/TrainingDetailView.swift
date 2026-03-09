import SwiftUI

struct TrainingDetailView: View {
    let training: Training
    @Environment(\.dismiss) private var dismiss
    
    // Récupération des données du profil utilisateur
    @AppStorage("userBirthDay") private var selectedDay: Int = 0
    @AppStorage("userBirthMonth") private var selectedMonth: Int = 0
    @AppStorage("userBirthYear") private var selectedYear: Int = 0
    @AppStorage("userFCRepos") private var fcReposText = ""
    
    // Calcul de l'âge
    private var calculatedAge: Int {
        guard selectedDay > 0, selectedMonth > 0, selectedYear > 0 else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth
        dateComponents.day = selectedDay
        
        guard let birthDate = calendar.date(from: dateComponents) else { return 0 }
        
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    // Calcul de la FC Max (220 - âge)
    private var calculatedFCMax: Int {
        return max(0, 220 - calculatedAge)
    }
    
    // Récupération de la FC Repos
    private var fcRepos: Int {
        let cleaned = fcReposText.trimmingCharacters(in: .whitespaces)
        return Int(cleaned) ?? 50
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // En-tête
                    headerSection
                    
                    // Informations de base
                    basicInfoSection
                    
                    // Plan d'entraînement
                    planSection
                    
                    // Fréquence cardiaque
                    heartRateSection
                    
                    // Données spécifiques selon le type d'équipement
                    equipmentSpecificSection
                    
                    // Observations
                    observationsSection
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // IMAGE ET TEXTE
                       HStack(spacing: 20) {
                           Spacer().frame(width: 4)

                // IMAGE DU SPORT À GAUCHE
                Image(getSportImageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Spacer().frame(width: 30)
                
                // TEXTE AU CENTRE/DROITE
                VStack(spacing: 10) {
                    Text(training.type)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(training.formattedDate)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            
            // BOUTON RETOUR SOUS L'IMAGE
            HStack {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Informations générales")
            
            HStack(spacing: 30) {
                InfoCard(icon: "location.fill", label: "Distance", value: formatted(training.distance, unit: " km"))
                InfoCard(icon: "clock.fill", label: "Durée", value: training.duration)
                InfoCard(icon: "speedometer", label: "Vitesse moy.", value: training.averageSpeed ?? "-")
            }
            
            HStack(spacing: 30) {
                InfoCard(icon: "flame.fill", label: "Calories", value: formatted(training.calories))
                InfoCard(icon: "moon.fill", label: "À jeun", value: training.aJeun ?? "-")
                InfoCard(icon: "star.fill", label: "Forme", value: training.forme ?? "-")
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var planSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Plan d'entraînement")
            
            if let plan = training.plan, !plan.isEmpty {
                Text(plan)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
            } else {
                Text("Aucun plan défini")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            }
        }
        .padding()
        .background(Color.cyan.opacity(0.15))
        .cornerRadius(16)
    }
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Fréquence cardiaque")
            
            HStack(spacing: 30) {
                InfoCard(icon: "heart.fill", label: "FC Max", value: formatted(training.maxHeartRate, unit: " bpm"))
                InfoCard(icon: "heart.fill", label: "FC Moy", value: formatted(training.avgHeartRate, unit: " bpm"))
            }
            
            HStack(spacing: 30) {
                InfoCard(icon: "percent", label: "% FC Max", value: getHeartRatePercent(csvValue: training.heartRatePercent, heartRate: training.maxHeartRate))
                InfoCard(icon: "percent", label: "% FC Moy", value: getHeartRatePercent(csvValue: training.heartRatePercentAvg, heartRate: training.avgHeartRate))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var equipmentSpecificSection: some View {
        // Afficher les données spécifiques selon le type d'équipement
        if training.type.contains("Tapis"), let data = training.tapisData {
            tapisSection(data)
        }
        
        if training.type.contains("Elliptique") || training.type.contains("elliptique"), let data = training.elliptiqueData {
            elliptiqueSection(data)
        }
        
        if training.type.contains("Rameur"), let data = training.rameurData {
            rameurSection(data)
        }
        
        if training.type.contains("Home trainer") || training.type.contains("home trainer"), let data = training.homeTrainerData {
            homeTrainerSection(data)
        }
        
        if training.type.contains("Triathlon") || training.type.contains("triathlon"), let data = training.triathlonData {
            triathlonSection(data)
        }
    }
    
    private func tapisSection(_ data: TapisData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Données Tapis")
            
            HStack(spacing: 30) {
                InfoCard(icon: "arrow.up.right", label: "Pente", value: data.pente ?? "-")
                InfoCard(icon: "bolt.fill", label: "Force", value: data.force ?? "-")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func elliptiqueSection(_ data: ElliptiqueData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Données Elliptique")
            
            HStack(spacing: 30) {
                InfoCard(icon: "angle", label: "Inclinaison", value: data.inclinaison ?? "-")
                InfoCard(icon: "bolt.fill", label: "Watts", value: data.watts ?? "-")
            }
        }
        .padding()
        .background(Color.purple.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func rameurSection(_ data: RameurData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Données Rameur")
            
            HStack(spacing: 30) {
                InfoCard(icon: "bolt.fill", label: "Force", value: data.force ?? "-")
                InfoCard(icon: "gauge", label: "C/M", value: data.cM ?? "-")
                InfoCard(icon: "timer", label: "Temps/500m", value: data.temps500m ?? "-")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func homeTrainerSection(_ data: HomeTrainerData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Données Home Trainer")
            
            VStack(spacing: 15) {
                HStack(spacing: 30) {
                    InfoCard(icon: "doc.text", label: "Programme", value: data.programme ?? "-")
                    InfoCard(icon: "bolt.fill", label: "Puissance", value: data.puissance ?? "-")
                    InfoCard(icon: "metronome", label: "Cadence", value: data.cadence ?? "-")
                }
                
                HStack(spacing: 30) {
                    InfoCard(icon: "gauge", label: "Niveau", value: data.niveau ?? "-")
                    InfoCard(icon: "arrow.up.right", label: "Pente", value: data.pente ?? "-")
                    InfoCard(icon: "mountain.2", label: "Plateau", value: data.plateau ?? "-")
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func triathlonSection(_ data: TriathlonData) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("Données Triathlon")
            
            VStack(spacing: 20) {
                // Rameur
                VStack(alignment: .leading, spacing: 10) {
                    Text("🚣 Rameur")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 20) {
                        InfoCard(icon: "location.fill", label: "Km", value: data.rameurKm ?? "-")
                        InfoCard(icon: "clock.fill", label: "Temps", value: data.rameurTemps ?? "-")
                    }
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                // Home Trainer
                VStack(alignment: .leading, spacing: 10) {
                    Text("🚴 Home Trainer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 20) {
                        InfoCard(icon: "location.fill", label: "Km", value: data.homeTrainerKm ?? "-")
                        InfoCard(icon: "clock.fill", label: "Temps", value: data.homeTrainerTemps ?? "-")
                    }
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                // Tapis
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏃 Tapis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 20) {
                        InfoCard(icon: "location.fill", label: "Km", value: data.tapisKm ?? "-")
                        InfoCard(icon: "clock.fill", label: "Temps", value: data.tapisTemps ?? "-")
                    }
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                // Résultat Total
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏆 Résultat Total")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.yellow)
                    HStack(spacing: 20) {
                        InfoCard(icon: "location.fill", label: "Km", value: data.resultatKm ?? "-")
                        InfoCard(icon: "clock.fill", label: "Temps", value: data.resultatTemps ?? "-")
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .cornerRadius(16)
    }
    
    private var observationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Observations")
            
            if training.observations.isEmpty {
                Text("Aucune observation")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            } else {
                Text(training.observations)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
    
    private func getSportImageName() -> String {
        let type = training.type.lowercased()
        
        // Mapping basé sur votre SportImageSelector
        if type.contains("marche") { return "Marche" }
        if type.contains("tapis") { return "Tapis" }
        if type.contains("elliptique") { return "elliptique" }
        if type.contains("rameur") { return "Rameur" }
        if type.contains("home trainer") { return "Home trainer" }
        if type.contains("triathlon") { return "triathlon" }
        if type.contains("piste") { return "Piste" }
        if type.contains("route") { return "Route" }
        if type.contains("vtt") { return "VTT" }
        if type.contains("piscine") { return "Piscine" }
        if type.contains("mer") { return "Mer" }
        
        // Par défaut
        return "Tous3"
    }
    
    private func getHeartRatePercent(csvValue: String?, heartRate: Int?) -> String {
        // Si on a une valeur dans le CSV, on l'utilise
        if let csvValue = csvValue, !csvValue.isEmpty, csvValue != "-" {
            let cleanValue = csvValue.replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            if let number = Double(cleanValue), number > 0 {
                return String(format: "%.0f%%", number)
            }
        }
        
        // Sinon, on calcule avec la formule de Karvonen
        // % = (FC - FC Repos) / (FC Max théorique - FC Repos) × 100
        guard let hr = heartRate, hr > 0 else { return "-" }
        guard calculatedFCMax > 0, fcRepos > 0 else { return "-" }
        
        // FCr (Fréquence Cardiaque de Réserve) = FC Max - FC Repos
        let fcReserve = Double(calculatedFCMax - fcRepos)
        guard fcReserve > 0 else { return "-" }
        
        // Pourcentage = (FC actuelle - FC Repos) / FCr × 100
        let percent = (Double(hr - fcRepos) / fcReserve) * 100.0
        
        // S'assurer que le pourcentage est entre 0 et 100
        let clampedPercent = max(0, min(100, percent))
        
        return String(format: "%.0f%%", clampedPercent)
    }
    
    private func formatted(_ value: Double?, unit: String = "") -> String {
        guard let v = value else { return "-" }
        return String(format: "%.1f", v) + unit
    }
    
    private func formatted(_ value: Int?, unit: String = "") -> String {
        guard let v = value else { return "-" }
        return "\(v)" + unit
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    private var backgroundColor: Color {
        // Vérifier si c'est une carte de fréquence cardiaque en pourcentage
        guard (label == "% FC Moy" || label == "% FC Max"), value != "-" else {
            return Color.white.opacity(0.15)
        }
        
        // Nettoyer la valeur (enlever %, espaces, etc.)
        let cleanValue = value.replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        
        guard let percent = Double(cleanValue) else {
            return Color.white.opacity(0.15)
        }
        
        // Zones d'intensité basées sur le pourcentage de FC Max
        if percent < 70 {
            return Color.green.opacity(0.6)  // Zone de récupération
        } else if percent >= 70 && percent < 75 {
            return Color.yellow.opacity(0.6)  // Zone d'endurance légère
        } else if percent >= 75 && percent < 85 {
            return Color.orange.opacity(0.6)  // Zone d'endurance modérée
        } else {
            return Color.red.opacity(0.6)  // Zone intense
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        TrainingDetailView(training: Training(
            date: Date(),
            type: "Home trainer",
            distance: 35,
            duration: "1:30",
            averageSpeed: "25 km/h",
            calories: 450,
            aJeun: "Oui",
            forme: "⭐️⭐️⭐️",
            maxHeartRate: 155,
            avgHeartRate: 135,
            heartRatePercent: "85",
            heartRatePercentAvg: "54",
            tapisData: nil,
            elliptiqueData: nil,
            rameurData: nil,
            homeTrainerData: HomeTrainerData(
                programme: "Endurance",
                puissance: "150W",
                cadence: "90",
                niveau: "5",
                pente: "2%",
                plateau: "53"
            ),
            triathlonData: nil,
            observations: "Bonne séance",
            plan: "M / FORCE + Endurance Z2"
        ))
    }
}

