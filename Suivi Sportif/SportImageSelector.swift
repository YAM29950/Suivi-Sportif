import SwiftUI

struct SportImageSelector: View {
    @Binding var selectedSport: String
    
    private let imageSize: CGFloat = 80       // largeur
    private let imageSizeHeight: CGFloat = 90  // ← hauteur (augmenter cette valeur)
    private let spacing: CGFloat = 8
    private let columns: Int = 12
    private let rectangleWidth: CGFloat = 1100
    
    
    private let sportImages: [(imageName: String, sportName: String)] = [
        ("Menu", "Tous"),
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
        ("Mer", "Mer")
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
        
        let imageWidth: CGFloat = {
            switch imageName {
            case "Rameur": return imageSize + 2
            case "Home trainer": return imageSize + 10
            case "elliptique": return imageSize + 10
            case "VTT": return imageSize + 10
            case "Piste": return imageSize + 10
            default: return imageSize
            }
        }()
        let imageHeight: CGFloat = {
            switch imageName {
            case "Rameur": return imageSize + 2
            case "Home trainer": return imageSize + 6
            case "elliptique": return imageSize + 6
            case "VTT": return imageSize + 6
            case "Piste": return imageSize + 6
            default: return imageSize
            }
        }()
        
        return Button(action: {
            selectedSport = sportName
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: imageSize, height: imageSizeHeight)  // ← ici
                
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth, height: imageHeight)
            }
            .frame(width: imageSize, height: imageSizeHeight)  // ← et ici
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Group {
                    if selectedSport == sportName {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.green, lineWidth: 3)
                            .frame(width: imageSize + 4, height: imageSize + 4)
                    }
                }
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSport == sportName ? Color.green.opacity(0.2) : Color.clear)
                    .frame(width: imageSize + 4, height: imageSize + 4)
            )
        }
        .buttonStyle(.plain)
        .help(sportName)
    }
}

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
