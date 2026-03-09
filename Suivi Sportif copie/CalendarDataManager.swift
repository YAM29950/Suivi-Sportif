import Foundation

// Structure pour les données d'un jour
struct DayInfo: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let fete: String
    let dicton: String
    
    enum CodingKeys: String, CodingKey {
        case date, fete, dicton
    }
}

// Gestionnaire pour charger les données du calendrier
class CalendarDataManager {
    static let shared = CalendarDataManager()
    
    private init() {}
    
    // Charge toutes les données du CSV
    func loadCalendarData() -> [DayInfo] {
        guard let url = Bundle.main.url(forResource: "calendrier_2026", withExtension: "csv") else {
            print("❌ Fichier calendrier_2026.csv introuvable")
            return []
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            // Ignorer la première ligne (en-têtes)
            let dataLines = Array(lines.dropFirst())
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            
            var calendarData: [DayInfo] = []
            
            for line in dataLines {
                let columns = line.components(separatedBy: ",")
                
                // 🔥 CORRECTION : Votre CSV a ce format :
                // Jour, Date(numéro), Mois(nom), Fête, Événement/Dicton
                guard columns.count >= 5 else { continue }
                
                let dayNumber = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let monthName = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let fete = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                let dicton = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Convertir le nom du mois en numéro
                let monthNumber = monthNameToNumber(monthName)
                
                // Créer la date
                var dateComponents = DateComponents()
                dateComponents.year = 2026
                dateComponents.month = monthNumber
                dateComponents.day = Int(dayNumber) ?? 1
                
                guard let date = Calendar.current.date(from: dateComponents) else {
                    continue
                }
                
                let dayInfo = DayInfo(
                    date: date,
                    fete: fete.isEmpty ? "Aucune fête" : fete,
                    dicton: dicton.isEmpty ? "Aucun dicton pour aujourd'hui" : dicton
                )
                calendarData.append(dayInfo)
            }
            
            print("✅ \(calendarData.count) jours chargés depuis calendrier_2026.csv")
            return calendarData
            
        } catch {
            print("❌ Erreur lors de la lecture du CSV: \(error)")
            return []
        }
    }
    
    // Convertir nom de mois → numéro
    private func monthNameToNumber(_ monthName: String) -> Int {
        let months = [
            "Janvier": 1, "Février": 2, "Mars": 3, "Avril": 4,
            "Mai": 5, "Juin": 6, "Juillet": 7, "Août": 8,
            "Septembre": 9, "Octobre": 10, "Novembre": 11, "Décembre": 12
        ]
        return months[monthName] ?? 1
    }
    
    // Récupère les infos du jour actuel
    func getTodayInfo() -> DayInfo? {
        let allDays = loadCalendarData()
        let calendar = Calendar.current
        let today = Date()
        
        let result = allDays.first { dayInfo in
            calendar.isDate(dayInfo.date, inSameDayAs: today)
        }
        
        if let info = result {
            print("✅ Info trouvée pour aujourd'hui: \(info.fete) - \(info.dicton)")
        } else {
            print("❌ Aucune info trouvée pour aujourd'hui")
        }
        
        return result
    }
}
