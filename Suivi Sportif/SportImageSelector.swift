import SwiftUI

struct SportImageSelector: View {
    @Binding var selectedSport: String
    
    // Configuration des tailles - MODIFIEZ CES VALEURS SELON VOS BESOINS
    private let imageSize: CGFloat = 70  // Taille des images
    private let spacing: CGFloat = 8      // Espacement entre les images
    private let columns: Int = 12         // 👈 12 colonnes = toutes les images sur UNE ligne
    private let rectangleWidth: CGFloat = 980  // LARGEUR DU RECTANGLE (augmentez si nécessaire)
    
    // Mapping entre noms d'images dans Assets et noms de sports
    // Image 1 = nouvelle image "Tous", Images 2-12 = identiques au modal
    private let sportImages: [(imageName: String, sportName: String)] = [
        ("Tous3", "Tous"),                   // ✅ Changé de "Image" à "Tous3"
               ("Marche", "Marche"),
               ("Tapis", "Tapis"),
               ("elliptique", "Elliptique"),
               ("Rameur", "Rameur"),
               ("Home trainer", "Home trainer"),
               ("triathlon", "Triathlon"),
               ("Piste", "Piste"),
               ("Route", "Route"),
               ("VTT", "VTT"),
               ("Piscine", "Piscine"),
               ("Mer", "Mer")                // Image 12
    ]
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(imageSize), spacing: spacing), count: columns)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(sportImages, id: \.sportName) { sport in
                    sportImageButton(imageName: sport.imageName, sportName: sport.sportName)
                }
            }
            .padding(12)
            .frame(width: rectangleWidth)
            .background(Color.white.opacity(0.18))
            .cornerRadius(8)
        }
    }
    
    private func sportImageButton(imageName: String, sportName: String) -> some View {
        Button(action: {
            selectedSport = sportName
        }) {
            ZStack {
                // Image du sport depuis Assets - même style que dans le modal
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)  // 👈 Comme dans le modal
                    .frame(width: imageSize, height: imageSize)
                    .background(Color.white)  // 👈 Fond blanc comme dans le modal
                    .clipShape(RoundedRectangle(cornerRadius: 8))  // 👈 Coins arrondis comme modal
                
                // Indicateur de sélection
                if selectedSport == sportName {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.green, lineWidth: 3)
                        .frame(width: imageSize + 4, height: imageSize + 4)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSport == sportName ? Color.green.opacity(0.2) : Color.clear)
                    .frame(width: imageSize + 4, height: imageSize + 4)
            )
        }
        .buttonStyle(.plain)
        .help(sportName)  // Tooltip au survol
    }
}

// APERÇU POUR TESTER
#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        SportImageSelector(selectedSport: .constant("Marche"))
            .padding()
    }
}

