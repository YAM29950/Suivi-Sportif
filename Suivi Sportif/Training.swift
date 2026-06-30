import Foundation

// MARK: - Notification

extension Notification.Name {
    static let trainingsDidUpdate = Notification.Name("trainingsDidUpdate")
}

// MARK: - Données spécifiques par équipement

struct TapisData: Codable {
    let pente: String?
    let force: String?
}

struct ElliptiqueData: Codable {
    let inclinaison: String?
    let watts: String?
}

struct RameurData: Codable {
    let watts: String?
    let force: String?
    let cM: String?
    let temps500m: String?
}

struct HomeTrainerData: Codable {
    let programme: String?
    let puissance: String?
    let cadence: String?
    let niveau: String?
    let pente: String?
    let plateau: String?
}

// Données Triathlon — elliptiqueKm/elliptiqueTemps optionnels pour
// rester compatibles avec les données JSON/CSV déjà enregistrées.
struct TriathlonData: Codable {
    let rameurKm: String?
    let rameurTemps: String?
    let homeTrainerKm: String?
    let homeTrainerTemps: String?
    let elliptiqueKm: String?       // ← NOUVEAU
    let elliptiqueTemps: String?    // ← NOUVEAU
    let tapisKm: String?
    let tapisTemps: String?
    let resultatKm: String?
    let resultatTemps: String?

    // Décodage rétro-compatible : les anciennes entrées JSON qui
    // n'ont pas ces clés les recevront simplement comme nil.
    enum CodingKeys: String, CodingKey {
        case rameurKm, rameurTemps
        case homeTrainerKm, homeTrainerTemps
        case elliptiqueKm, elliptiqueTemps
        case tapisKm, tapisTemps
        case resultatKm, resultatTemps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rameurKm       = try c.decodeIfPresent(String.self, forKey: .rameurKm)
        rameurTemps    = try c.decodeIfPresent(String.self, forKey: .rameurTemps)
        homeTrainerKm  = try c.decodeIfPresent(String.self, forKey: .homeTrainerKm)
        homeTrainerTemps = try c.decodeIfPresent(String.self, forKey: .homeTrainerTemps)
        elliptiqueKm   = try c.decodeIfPresent(String.self, forKey: .elliptiqueKm)
        elliptiqueTemps = try c.decodeIfPresent(String.self, forKey: .elliptiqueTemps)
        tapisKm        = try c.decodeIfPresent(String.self, forKey: .tapisKm)
        tapisTemps     = try c.decodeIfPresent(String.self, forKey: .tapisTemps)
        resultatKm     = try c.decodeIfPresent(String.self, forKey: .resultatKm)
        resultatTemps  = try c.decodeIfPresent(String.self, forKey: .resultatTemps)
    }

    // Initialiseur memberwise pour AddTrainingModal
    init(
        rameurKm: String?        = nil,
        rameurTemps: String?     = nil,
        homeTrainerKm: String?   = nil,
        homeTrainerTemps: String? = nil,
        elliptiqueKm: String?    = nil,
        elliptiqueTemps: String? = nil,
        tapisKm: String?         = nil,
        tapisTemps: String?      = nil,
        resultatKm: String?      = nil,
        resultatTemps: String?   = nil
    ) {
        self.rameurKm        = rameurKm
        self.rameurTemps     = rameurTemps
        self.homeTrainerKm   = homeTrainerKm
        self.homeTrainerTemps = homeTrainerTemps
        self.elliptiqueKm    = elliptiqueKm
        self.elliptiqueTemps = elliptiqueTemps
        self.tapisKm         = tapisKm
        self.tapisTemps      = tapisTemps
        self.resultatKm      = resultatKm
        self.resultatTemps   = resultatTemps
    }
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
    let tapisData: TapisData?
    let elliptiqueData: ElliptiqueData?
    let rameurData: RameurData?
    let homeTrainerData: HomeTrainerData?
    let triathlonData: TriathlonData?
    let observations: String
    let plan: String?

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

    init(
        date: Date,
        type: String,
        distance: Double?        = nil,
        duration: String,
        averageSpeed: String?    = nil,
        calories: Int?           = nil,
        aJeun: String?           = nil,
        forme: String?           = nil,
        maxHeartRate: Int?       = nil,
        avgHeartRate: Int?       = nil,
        heartRatePercent: String? = nil,
        heartRatePercentAvg: String? = nil,
        tapisData: TapisData?        = nil,
        elliptiqueData: ElliptiqueData? = nil,
        rameurData: RameurData?      = nil,
        homeTrainerData: HomeTrainerData? = nil,
        triathlonData: TriathlonData? = nil,
        observations: String     = "",
        plan: String?            = nil
    ) {
        self.id                 = UUID()
        self.date               = date
        self.type               = type
        self.distance           = distance
        self.duration           = duration
        self.averageSpeed       = averageSpeed
        self.calories           = calories
        self.aJeun              = aJeun
        self.forme              = forme
        self.maxHeartRate       = maxHeartRate
        self.avgHeartRate       = avgHeartRate
        self.heartRatePercent   = heartRatePercent
        self.heartRatePercentAvg = heartRatePercentAvg
        self.tapisData          = tapisData
        self.elliptiqueData     = elliptiqueData
        self.rameurData         = rameurData
        self.homeTrainerData    = homeTrainerData
        self.triathlonData      = triathlonData
        self.observations       = observations
        self.plan               = plan
    }
}

// MARK: - Training Data Manager

class TrainingDataManager {
    static let shared = TrainingDataManager()

    private let migrationKey = "trainingsDidMigrateToJSON"

    private var jsonFileURL: URL {
        let realHome = String(cString: getpwuid(getuid())!.pointee.pw_dir)
        return URL(fileURLWithPath: realHome)
            .appendingPathComponent("Library/CloudStorage/Dropbox/trainings.json")
    }

    private init() {}

    // MARK: - Chargement

    func loadTrainings() -> [Training] {
        if !UserDefaults.standard.bool(forKey: migrationKey),
           let data = UserDefaults.standard.data(forKey: "trainings"),
           let decoded = try? JSONDecoder().decode([Training].self, from: data) {
            print("🔄 Migration UserDefaults → JSON file: \(decoded.count) entrainements")
            let sorted = decoded.sorted { $0.date > $1.date }
            saveTrainings(sorted)
            UserDefaults.standard.removeObject(forKey: "trainings")
            UserDefaults.standard.set(true, forKey: migrationKey)
            return sorted
        }

        if FileManager.default.fileExists(atPath: jsonFileURL.path) {
            do {
                let data = try Data(contentsOf: jsonFileURL)
                let decoded = try JSONDecoder().decode([Training].self, from: data)
                print("✅ Chargement depuis JSON file: \(decoded.count) entrainements")
                return decoded.sorted { $0.date > $1.date }
            } catch {
                print("❌ Erreur lecture JSON file: \(error)")
            }
        }

        print("🔍 Chargement initial depuis CSV...")
        let trainings = loadFromCSV()
        saveTrainings(trainings)
        UserDefaults.standard.set(true, forKey: migrationKey)
        return trainings
    }

    // MARK: - Sauvegarde

    func saveTrainings(_ trainings: [Training]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(trainings)
            try data.write(to: jsonFileURL, options: .atomic)
            print("✅ Données sauvegardées: \(trainings.count) entrainements")
        } catch {
            print("❌ Erreur sauvegarde JSON file: \(error)")
        }
    }

    // MARK: - Ajout

    func addTraining(_ training: Training) {
        var all = loadTrainings()
        all.append(training)
        saveTrainings(all)
        NotificationCenter.default.post(name: .trainingsDidUpdate, object: nil)
    }

    // MARK: - Chargement CSV

    private func loadFromCSV() -> [Training] {
        print("🔍 Recherche du fichier CSV...")
        guard let filePath = Bundle.main.path(forResource: "sports depuis 2016", ofType: "csv") else {
            print("❌ Fichier CSV introuvable"); return []
        }
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            print("❌ Impossible de lire le CSV"); return []
        }
        return parseCSV(content: content)
    }

    // MARK: - Parsing CSV

    private func parseCSV(content: String) -> [Training] {
        var trainings: [Training] = []
        let rows = content.components(separatedBy: "\n")
        print("📊 Nombre de lignes:", rows.count)

        for (index, row) in rows.enumerated() {
            if index == 0 || row.trimmingCharacters(in: .whitespaces).isEmpty { continue }

            let columns = row.components(separatedBy: ";")
            guard columns.count >= 34 else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            dateFormatter.dateFormat = "EEEE, MMMM dd, yyyy"

            var dateString = columns[0].trimmingCharacters(in: .whitespaces)
            dateString = dateString.replacingOccurrences(of: "aout", with: "août", options: .caseInsensitive)

            var parsedDate: Date? = dateFormatter.date(from: dateString)
            if parsedDate == nil {
                dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                parsedDate = dateFormatter.date(from: dateString)
            }
            if parsedDate == nil {
                dateFormatter.dateFormat = "MMMM dd, yyyy"
                let comps = dateString.components(separatedBy: ", ")
                if comps.count >= 3 { parsedDate = dateFormatter.date(from: comps[1...].joined(separator: ", ")) }
            }
            if parsedDate == nil {
                dateFormatter.dateFormat = "MMMM d, yyyy"
                let comps = dateString.components(separatedBy: ", ")
                if comps.count >= 3 { parsedDate = dateFormatter.date(from: comps[1...].joined(separator: ", ")) }
            }
            guard let date = parsedDate else { continue }

            let type         = columns[1].trimmingCharacters(in: .whitespaces)
            let distanceStr  = columns[2].trimmingCharacters(in: .whitespaces)
            let distance     = distanceStr.isEmpty ? nil : Double(distanceStr.replacingOccurrences(of: ",", with: "."))
            let duration     = columns[3].trimmingCharacters(in: .whitespaces)
            let averageSpeed = columns[4].trimmingCharacters(in: .whitespaces)
            let calories     = Int(columns[5].trimmingCharacters(in: .whitespaces))
            let aJeun        = columns[6].trimmingCharacters(in: .whitespaces)
            let forme        = columns[7].trimmingCharacters(in: .whitespaces)
            let maxHeartRate = Int(columns[8].trimmingCharacters(in: .whitespaces))
            let avgHeartRate = Int(columns[9].trimmingCharacters(in: .whitespaces))
            let hrPct        = columns[10].trimmingCharacters(in: .whitespaces)
            let hrPctAvg     = columns[11].trimmingCharacters(in: .whitespaces)

            let tapisPente   = columns[12].trimmingCharacters(in: .whitespaces)
            let tapisForce   = columns[13].trimmingCharacters(in: .whitespaces)
            let tapisData    = (tapisPente.isEmpty && tapisForce.isEmpty) ? nil :
                TapisData(pente: tapisPente.isEmpty ? nil : tapisPente,
                          force: tapisForce.isEmpty ? nil : tapisForce)

            let ellIncl      = columns[14].trimmingCharacters(in: .whitespaces)
            let ellWatts     = columns[15].trimmingCharacters(in: .whitespaces)
            let elliptiqueData = (ellIncl.isEmpty && ellWatts.isEmpty) ? nil :
                ElliptiqueData(inclinaison: ellIncl.isEmpty ? nil : ellIncl,
                               watts: ellWatts.isEmpty ? nil : ellWatts)

            let ramWatts     = columns[16].trimmingCharacters(in: .whitespaces)
            let ramForce     = columns[17].trimmingCharacters(in: .whitespaces)
            let ramCM        = columns[18].trimmingCharacters(in: .whitespaces)
            let ramTemps     = columns[19].trimmingCharacters(in: .whitespaces)
            let rameurData   = (ramWatts.isEmpty && ramForce.isEmpty && ramCM.isEmpty && ramTemps.isEmpty) ? nil :
                RameurData(watts: ramWatts.isEmpty ? nil : ramWatts,
                           force: ramForce.isEmpty ? nil : ramForce,
                           cM: ramCM.isEmpty ? nil : ramCM,
                           temps500m: ramTemps.isEmpty ? nil : ramTemps)

            let htProg       = columns[20].trimmingCharacters(in: .whitespaces)
            let htPuiss      = columns[21].trimmingCharacters(in: .whitespaces)
            let htCad        = columns[22].trimmingCharacters(in: .whitespaces)
            let htNiv        = columns[23].trimmingCharacters(in: .whitespaces)
            let htPente      = columns[24].trimmingCharacters(in: .whitespaces)
            let htPlateau    = columns[25].trimmingCharacters(in: .whitespaces)
            let homeTrainerData = (htProg.isEmpty && htPuiss.isEmpty && htCad.isEmpty &&
                                   htNiv.isEmpty && htPente.isEmpty && htPlateau.isEmpty) ? nil :
                HomeTrainerData(programme: htProg.isEmpty ? nil : htProg,
                                puissance: htPuiss.isEmpty ? nil : htPuiss,
                                cadence: htCad.isEmpty ? nil : htCad,
                                niveau: htNiv.isEmpty ? nil : htNiv,
                                pente: htPente.isEmpty ? nil : htPente,
                                plateau: htPlateau.isEmpty ? nil : htPlateau)

            // Colonnes 26-33 : triathlon (CSV historique sans elliptique)
            let triRamKm     = columns[26].trimmingCharacters(in: .whitespaces)
            let triRamTemps  = columns[27].trimmingCharacters(in: .whitespaces)
            let triHTKm      = columns[28].trimmingCharacters(in: .whitespaces)
            let triHTTemps   = columns[29].trimmingCharacters(in: .whitespaces)
            let triTapKm     = columns[30].trimmingCharacters(in: .whitespaces)
            let triTapTemps  = columns[31].trimmingCharacters(in: .whitespaces)
            let triResKm     = columns[32].trimmingCharacters(in: .whitespaces)
            let triResTemps  = columns[33].trimmingCharacters(in: .whitespaces)
            // Colonnes 34-35 : elliptique triathlon (nouvelles colonnes CSV, optionnelles)
            let triEllKm     = columns.count > 35 ? columns[34].trimmingCharacters(in: .whitespaces) : ""
            let triEllTemps  = columns.count > 36 ? columns[35].trimmingCharacters(in: .whitespaces) : ""

            let triathlonData = (triRamKm.isEmpty && triRamTemps.isEmpty &&
                                 triHTKm.isEmpty && triHTTemps.isEmpty &&
                                 triTapKm.isEmpty && triTapTemps.isEmpty &&
                                 triResKm.isEmpty && triResTemps.isEmpty &&
                                 triEllKm.isEmpty && triEllTemps.isEmpty) ? nil :
                TriathlonData(
                    rameurKm:        triRamKm.isEmpty   ? nil : triRamKm,
                    rameurTemps:     triRamTemps.isEmpty ? nil : triRamTemps,
                    homeTrainerKm:   triHTKm.isEmpty    ? nil : triHTKm,
                    homeTrainerTemps: triHTTemps.isEmpty ? nil : triHTTemps,
                    elliptiqueKm:    triEllKm.isEmpty   ? nil : triEllKm,
                    elliptiqueTemps: triEllTemps.isEmpty ? nil : triEllTemps,
                    tapisKm:         triTapKm.isEmpty   ? nil : triTapKm,
                    tapisTemps:      triTapTemps.isEmpty ? nil : triTapTemps,
                    resultatKm:      triResKm.isEmpty   ? nil : triResKm,
                    resultatTemps:   triResTemps.isEmpty ? nil : triResTemps
                )

            let observations = columns.count > 36 ? columns[36].trimmingCharacters(in: .whitespaces) : ""
            let plan         = columns.count > 37 ? columns[37].trimmingCharacters(in: .whitespaces) : nil

            trainings.append(Training(
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
                heartRatePercent: hrPct.isEmpty ? nil : hrPct,
                heartRatePercentAvg: hrPctAvg.isEmpty ? nil : hrPctAvg,
                tapisData: tapisData,
                elliptiqueData: elliptiqueData,
                rameurData: rameurData,
                homeTrainerData: homeTrainerData,
                triathlonData: triathlonData,
                observations: observations,
                plan: plan.map { $0.isEmpty ? nil : $0 } ?? nil
            ))
        }

        print("✅ \(trainings.count) entrainements parsés")
        return trainings.sorted { $0.date > $1.date }
    }
}
