
import Foundation

// Structure pour un dicton
struct Dicton {
    let jour: Int
    let mois: String
    let texte: String
}

// Manager pour gérer les dictons
class DictonsDataManager {
    static let shared = DictonsDataManager()
    private var dictons: [Dicton] = []
    
    private init() {
        loadDictons()
    }
    
    // Charger les dictons depuis le fichier CSV
    private func loadDictons() {
        guard let fileURL = Bundle.main.url(forResource: "Dictons", withExtension: "csv") else {
            print("❌ Fichier Dictons.csv introuvable")
            return
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            // Ignorer la première ligne (en-têtes)
            for line in lines.dropFirst() {
                guard !line.isEmpty else { continue }
                
                // Séparer par point-virgule
                let components = line.components(separatedBy: ";")
                
                guard components.count >= 3,
                      let jour = Int(components[0].trimmingCharacters(in: .whitespaces)) else {
                    continue
                }
                
                let mois = components[1].trimmingCharacters(in: .whitespaces)
                let texte = components[2].trimmingCharacters(in: .whitespaces)
                
                dictons.append(Dicton(jour: jour, mois: mois, texte: texte))
            }
            
            print("✅ \(dictons.count) dictons chargés")
            
        } catch {
            print("❌ Erreur lors du chargement des dictons: \(error)")
        }
    }
    
    // Obtenir le dicton du jour
    func getDictonDuJour() -> String {
        let calendar = Calendar.current
        let now = Date()
        let jour = calendar.component(.day, from: now)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "MMMM"
        let moisComplet = dateFormatter.string(from: now)
        
        // Trouver le dicton correspondant
        if let dicton = dictons.first(where: { $0.jour == jour && $0.mois.lowercased() == moisComplet.lowercased() }) {
            return dicton.texte
        }
        
        return "Aucun dicton pour aujourd'hui"
    }
    
    // Obtenir le dicton pour une date spécifique
    func getDicton(jour: Int, mois: String) -> String? {
        if let dicton = dictons.first(where: { $0.jour == jour && $0.mois.lowercased() == mois.lowercased() }) {
            return dicton.texte
        }
        return nil
    }
}

