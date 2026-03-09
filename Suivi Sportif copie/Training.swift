import Foundation
// 🔥 AJOUTEZ CES LIGNES ICI
extension Notification.Name {
    static let trainingsDidUpdate = Notification.Name("trainingsDidUpdate")
}


// MARK: - Données spécifiques par équipement

// Données spécifiques Tapis
struct TapisData: Codable {
    let pente: String?
    let force: String?
}

// Données spécifiques Elliptique
struct ElliptiqueData: Codable {
    let inclinaison: String?
    let watts: String?
}

// Données spécifiques Rameur
struct RameurData: Codable {
    let watts: String?
    let force: String?
    let cM: String?
    let temps500m: String?
}

// Données spécifiques Home Trainer
struct HomeTrainerData: Codable {
    let programme: String?
    let puissance: String?
    let cadence: String?
    let niveau: String?
    let pente: String?
    let plateau: String?
}

// Données Triathlon
struct TriathlonData: Codable {
    let rameurKm: String?
    let rameurTemps: String?
    let homeTrainerKm: String?
    let homeTrainerTemps: String?
    let tapisKm: String?
    let tapisTemps: String?
    let resultatKm: String?
    let resultatTemps: String?
}

// MARK: - Modèle principal Training

struct Training: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: String
    let distance: Double?
    let duration: String
    let averageSpeed: String?
    let calories: Int?
    let aJeun: String?
    let forme: String?
    let maxHeartRate: Int?
    let avgHeartRate: Int?
    let heartRatePercent: String?
    let heartRatePercentAvg: String?
    
    // Données spécifiques par équipement
    let tapisData: TapisData?
    let elliptiqueData: ElliptiqueData?
    let rameurData: RameurData?
    let homeTrainerData: HomeTrainerData?
    let triathlonData: TriathlonData?
    let observations: String
    let plan: String?

    // MARK: - Propriétés calculées
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Initializer principal
    
    init(
        date: Date,
        type: String,
        distance: Double? = nil,
        duration: String,
        averageSpeed: String? = nil,
        calories: Int? = nil,
        aJeun: String? = nil,
        forme: String? = nil,
        maxHeartRate: Int? = nil,
        avgHeartRate: Int? = nil,
        heartRatePercent: String? = nil,
        heartRatePercentAvg: String? = nil,
        tapisData: TapisData? = nil,
        elliptiqueData: ElliptiqueData? = nil,
        rameurData: RameurData? = nil,
        homeTrainerData: HomeTrainerData? = nil,
        triathlonData: TriathlonData? = nil,
        observations: String = "",
        plan: String? = nil

    ) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.distance = distance
        self.duration = duration
        self.averageSpeed = averageSpeed
        self.calories = calories
        self.aJeun = aJeun
        self.forme = forme
        self.maxHeartRate = maxHeartRate
        self.avgHeartRate = avgHeartRate
        self.heartRatePercent = heartRatePercent
        self.heartRatePercentAvg = heartRatePercentAvg
        self.tapisData = tapisData
        self.elliptiqueData = elliptiqueData
        self.rameurData = rameurData
        self.homeTrainerData = homeTrainerData
        self.triathlonData = triathlonData
        self.observations = observations
        self.plan = plan
    }
}

// MARK: - Training Data Manager

class TrainingDataManager {
    static let shared = TrainingDataManager()
    
    private init() {}
    
    // MARK: - Chargement des données
    
    func loadTrainings() -> [Training] {
        // Vérifier si des données existent déjà en UserDefaults
        if let data = UserDefaults.standard.data(forKey: "trainings"),
           let decoded = try? JSONDecoder().decode([Training].self, from: data) {
            print("✅ Chargement depuis UserDefaults: \(decoded.count) entrainements")
            return decoded.sorted { $0.date > $1.date }
        }
        
        // Sinon, charger depuis le CSV
        print("🔍 Chargement initial depuis CSV...")
        let trainings = loadFromCSV()
        
        // Sauvegarder dans UserDefaults pour la prochaine fois
        saveTrainings(trainings)
        
        return trainings
    }
    
    // MARK: - Sauvegarde des données
    
    func saveTrainings(_ trainings: [Training]) {
        if let encoded = try? JSONEncoder().encode(trainings) {
            UserDefaults.standard.set(encoded, forKey: "trainings")
            print("✅ Données sauvegardées: \(trainings.count) entrainements")
        } else {
            print("❌ Erreur lors de l'encodage des entrainements")
        }
    }
    
    // MARK: - Chargement depuis CSV
    
    private func loadFromCSV() -> [Training] {
        print("🔍 Recherche du fichier CSV...")
        
        guard let filePath = Bundle.main.path(forResource: "sports depuis 2016", ofType: "csv") else {
            print("❌ Fichier CSV introuvable dans le bundle")
            return []
        }
        
        print("✅ Fichier trouvé:", filePath)
        
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            print("❌ Impossible de lire le fichier CSV")
            return []
        }
        
        print("✅ Contenu lu, longueur:", content.count, "caractères")
        
        return parseCSV(content: content)
    }
    
    // MARK: - Parsing CSV
    
    private func parseCSV(content: String) -> [Training] {
        var trainings: [Training] = []
        let rows = content.components(separatedBy: "\n")
        
        print("📊 Nombre de lignes:", rows.count)
        
        for (index, row) in rows.enumerated() {
            // Ignorer l'en-tête et les lignes vides
            if index == 0 || row.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            
            let columns = row.components(separatedBy: ";")
            
            guard columns.count >= 34 else {
                print("⚠️ Ligne \(index) ignorée (colonnes insuffisantes):", columns.count)
                continue
            }
            
            // Parser la date avec plusieurs tentatives
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            dateFormatter.dateFormat = "EEEE, MMMM dd, yyyy"
            
            // Remplacer "aout" par "août" pour le parsing (au cas où)
            var dateString = columns[0].trimmingCharacters(in: .whitespaces)
            dateString = dateString.replacingOccurrences(of: "aout", with: "août", options: .caseInsensitive)
            
            var parsedDate: Date? = dateFormatter.date(from: dateString)
            
            // Si ça échoue, essayer avec d (un chiffre au lieu de dd)
            if parsedDate == nil {
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                parsedDate = dateFormatter.date(from: dateString)
            }
            
            // Si ça échoue encore, essayer sans le jour de la semaine
            if parsedDate == nil {
                dateFormatter.dateFormat = "MMMM dd, yyyy"
                let components = dateString.components(separatedBy: ", ")
                if components.count >= 3 {
                    let withoutDay = components[1...].joined(separator: ", ")
                    parsedDate = dateFormatter.date(from: withoutDay)
                }
            }
            
            // Dernier essai avec format court
            if parsedDate == nil {
                dateFormatter.dateFormat = "MMMM d, yyyy"
                let components = dateString.components(separatedBy: ", ")
                if components.count >= 3 {
                    let withoutDay = components[1...].joined(separator: ", ")
                    parsedDate = dateFormatter.date(from: withoutDay)
                }
            }
            
            guard let date = parsedDate else {
                // Debug : afficher les dates qui ne peuvent pas être parsées
                if dateString.contains("août") || dateString.contains("aout") {
                    print("⚠️ Date août non parsée à la ligne \(index):", dateString)
                } else {
                    print("⚠️ Date invalide à la ligne \(index):", dateString)
                }
                continue
            }
            
            // Colonnes 0-11 : Données de base
            let type = columns[1].trimmingCharacters(in: .whitespaces)
            let distanceStr = columns[2].trimmingCharacters(in: .whitespaces)
            let distance = distanceStr.isEmpty ? nil : Double(distanceStr.replacingOccurrences(of: ",", with: "."))
            let duration = columns[3].trimmingCharacters(in: .whitespaces)
            let averageSpeed = columns[4].trimmingCharacters(in: .whitespaces)
            let caloriesStr = columns[5].trimmingCharacters(in: .whitespaces)
            let calories = caloriesStr.isEmpty ? nil : Int(caloriesStr)
            let aJeun = columns[6].trimmingCharacters(in: .whitespaces)
            let forme = columns[7].trimmingCharacters(in: .whitespaces)
            let maxHRStr = columns[8].trimmingCharacters(in: .whitespaces)
            let maxHeartRate = maxHRStr.isEmpty ? nil : Int(maxHRStr)
            let avgHRStr = columns[9].trimmingCharacters(in: .whitespaces)
            let avgHeartRate = avgHRStr.isEmpty ? nil : Int(avgHRStr)
            let heartRatePercent = columns[10].trimmingCharacters(in: .whitespaces)
            let heartRatePercentAvg = columns[11].trimmingCharacters(in: .whitespaces)
            
            // Colonnes 12-13 : Données Tapis
            let tapisPente = columns[12].trimmingCharacters(in: .whitespaces)
            let tapisForce = columns[13].trimmingCharacters(in: .whitespaces)
            let tapisData = (tapisPente.isEmpty && tapisForce.isEmpty) ? nil : TapisData(
                pente: tapisPente.isEmpty ? nil : tapisPente,
                force: tapisForce.isEmpty ? nil : tapisForce
            )
            
            // Colonnes 14-15 : Données Elliptique
            let elliptiqueIncl = columns[14].trimmingCharacters(in: .whitespaces)
            let elliptiqueWatts = columns[15].trimmingCharacters(in: .whitespaces)
            let elliptiqueData = (elliptiqueIncl.isEmpty && elliptiqueWatts.isEmpty) ? nil : ElliptiqueData(
                inclinaison: elliptiqueIncl.isEmpty ? nil : elliptiqueIncl,
                watts: elliptiqueWatts.isEmpty ? nil : elliptiqueWatts
            )
            
            // Colonnes 16-19 : Données Rameur
            let rameurWatts = columns[16].trimmingCharacters(in: .whitespaces)
            let rameurForce = columns[17].trimmingCharacters(in: .whitespaces)
            let rameurCM = columns[18].trimmingCharacters(in: .whitespaces)
            let rameurTemps = columns[19].trimmingCharacters(in: .whitespaces)
            let rameurData = (rameurWatts.isEmpty && rameurForce.isEmpty && rameurCM.isEmpty && rameurTemps.isEmpty) ? nil : RameurData(
                watts: rameurWatts.isEmpty ? nil : rameurWatts,
                force: rameurForce.isEmpty ? nil : rameurForce,
                cM: rameurCM.isEmpty ? nil : rameurCM,
                temps500m: rameurTemps.isEmpty ? nil : rameurTemps
            )
            
            // Colonnes 20-25 : Données Home Trainer
            let htProg = columns[20].trimmingCharacters(in: .whitespaces)
            let htPuiss = columns[21].trimmingCharacters(in: .whitespaces)
            let htCad = columns[22].trimmingCharacters(in: .whitespaces)
            let htNiv = columns[23].trimmingCharacters(in: .whitespaces)
            let htPente = columns[24].trimmingCharacters(in: .whitespaces)
            let htPlateau = columns[25].trimmingCharacters(in: .whitespaces)
            let homeTrainerData = (htProg.isEmpty && htPuiss.isEmpty && htCad.isEmpty && htNiv.isEmpty && htPente.isEmpty && htPlateau.isEmpty) ? nil : HomeTrainerData(
                programme: htProg.isEmpty ? nil : htProg,
                puissance: htPuiss.isEmpty ? nil : htPuiss,
                cadence: htCad.isEmpty ? nil : htCad,
                niveau: htNiv.isEmpty ? nil : htNiv,
                pente: htPente.isEmpty ? nil : htPente,
                plateau: htPlateau.isEmpty ? nil : htPlateau
            )
            
            // Colonnes 26-33 : Données Triathlon
            let triRamKm = columns[26].trimmingCharacters(in: .whitespaces)
            let triRamTemps = columns[27].trimmingCharacters(in: .whitespaces)
            let triHTKm = columns[28].trimmingCharacters(in: .whitespaces)
            let triHTTemps = columns[29].trimmingCharacters(in: .whitespaces)
            let triTapKm = columns[30].trimmingCharacters(in: .whitespaces)
            let triTapTemps = columns[31].trimmingCharacters(in: .whitespaces)
            let triResKm = columns[32].trimmingCharacters(in: .whitespaces)
            let triResTemps = columns[33].trimmingCharacters(in: .whitespaces)
            let triathlonData = (triRamKm.isEmpty && triRamTemps.isEmpty && triHTKm.isEmpty && triHTTemps.isEmpty && triTapKm.isEmpty && triTapTemps.isEmpty && triResKm.isEmpty && triResTemps.isEmpty) ? nil : TriathlonData(
                rameurKm: triRamKm.isEmpty ? nil : triRamKm,
                rameurTemps: triRamTemps.isEmpty ? nil : triRamTemps,
                homeTrainerKm: triHTKm.isEmpty ? nil : triHTKm,
                homeTrainerTemps: triHTTemps.isEmpty ? nil : triHTTemps,
                tapisKm: triTapKm.isEmpty ? nil : triTapKm,
                tapisTemps: triTapTemps.isEmpty ? nil : triTapTemps,
                resultatKm: triResKm.isEmpty ? nil : triResKm,
                resultatTemps: triResTemps.isEmpty ? nil : triResTemps
            )
            
            // Colonne 34 : Observations (si elle existe)
            let observations = columns.count > 34 ? columns[34].trimmingCharacters(in: .whitespaces) : ""

            // Colonne 35 : Plan (si elle existe)
            let plan = columns.count > 35 ? columns[35].trimmingCharacters(in: .whitespaces) : nil

            // Créer l'entrainement
            let training = Training(
                date: date,
                type: type,
                distance: distance,
                duration: duration,
                averageSpeed: averageSpeed.isEmpty ? nil : averageSpeed,
                calories: calories,
                aJeun: aJeun.isEmpty ? nil : aJeun,
                forme: forme.isEmpty ? nil : forme,
                maxHeartRate: maxHeartRate,
                avgHeartRate: avgHeartRate,
                heartRatePercent: heartRatePercent.isEmpty ? nil : heartRatePercent,
                heartRatePercentAvg: heartRatePercentAvg.isEmpty ? nil : heartRatePercentAvg,
                tapisData: tapisData,
                elliptiqueData: elliptiqueData,
                rameurData: rameurData,
                homeTrainerData: homeTrainerData,
                triathlonData: triathlonData,
                observations: observations,
                plan: plan
  )
            
            trainings.append(training)
        }
        
        print("✅ \(trainings.count) entrainements parsés avec succès")
        
        return trainings.sorted { $0.date > $1.date }
    }
    
    // MARK: - Utilitaires
    
    func resetToCSV() {
        UserDefaults.standard.removeObject(forKey: "trainings")
        print("🔄 Cache effacé - les données seront rechargées depuis le CSV")
    }
}

