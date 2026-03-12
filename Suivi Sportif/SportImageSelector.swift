import SwiftUI

struct SportImageSelector: View {
    @Binding var selectedSport: String
    
    private let imageSize: CGFloat = 70
    private let spacing: CGFloat = 8
    private let columns: Int = 12
    private let rectangleWidth: CGFloat = 980
    
    private let sportImages: [(imageName: String, sportName: String)] = [
        ("Tous3", "Tous"),
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
        Button(action: {
            selectedSport = sportName
        }) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
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
