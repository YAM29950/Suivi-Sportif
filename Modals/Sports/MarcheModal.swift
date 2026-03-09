import SwiftUI
import Charts

struct MarcheModal: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var yearlyStats: [YearlyWalkingStats] = []
    
    struct YearlyWalkingStats: Identifiable {
        let id = UUID()
        let year: Int
        let kilometers: Double
    }
    
    // ✅ AJOUT : propriété pour l'année en cours
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Contenu du modal
            VStack(spacing: 20) {
                // En-tête
                HStack {
                    // Icône de déplacement
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 8)
                    
                    Image(systemName: "figure.walk")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text("Marche")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Bouton Quitter
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Quitter")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)
                
                // Contenu principal du modal
                VStack(spacing: 15) {
                    Text("Statistiques de marche")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Graphique en barres
                    if !yearlyStats.isEmpty {
                        Chart(yearlyStats) { stat in
                            BarMark(
                                x: .value("Année", String(stat.year)),
                                y: .value("Kilomètres", stat.kilometers)
                            )
                            // ✅ MODIFIÉ : cyan pour l'année en cours, vert pour les autres
                            .foregroundStyle(
                                stat.year == currentYear
                                    ? LinearGradient(
                                        colors: [Color.cyan.opacity(0.9), Color.cyan.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                      )
                                    : LinearGradient(
                                        colors: [Color.green.opacity(0.8), Color.green.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                      )
                            )
                            .cornerRadius(4)
                            // ✅ MODIFIÉ : annotation avec ⭐️ et bordure cyan pour l'année en cours
                            .annotation(position: .top) {
                                Text(stat.year == currentYear
                                     ? "\(Int(stat.kilometers)) km ⭐️"
                                     : "\(Int(stat.kilometers)) km")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(stat.year == currentYear ? .cyan : .white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                stat.year == currentYear ? Color.cyan : Color.clear,
                                                lineWidth: stat.year == currentYear ? 1.5 : 0
                                            )
                                    )
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel()
                                    .foregroundStyle(.white)
                                    .font(.system(size: 12))
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(
                                        // ✅ AJOUT : label de l'année en cours en cyan
                                        value.as(String.self) == String(currentYear)
                                            ? AnyShapeStyle(Color.cyan)
                                            : AnyShapeStyle(Color.white)
                                    )
                                    .font(
                                        value.as(String.self) == String(currentYear)
                                            ? .system(size: 12, weight: .black)
                                            : .system(size: 12, weight: .semibold)
                                    )
                            }
                        }
                        .frame(height: 280)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                            
                            VStack(spacing: 12) {
                                Image(systemName: "figure.walk.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green.opacity(0.8))
                                
                                Text("Aucune donnée de marche disponible")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                        }
                        .frame(height: 280)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 900, height: 480)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        // Optionnel : réinitialiser la position ou conserver l'offset
                        // dragOffset = .zero
                    }
            )
        }
        .onAppear {
            loadWalkingStats()
        }
    }
    
    private func loadWalkingStats() {
        // Charger tous les entraînements
        let allTrainings = TrainingDataManager.shared.loadTrainings()
        
        // Filtrer uniquement les marches
        let walkingTrainings = allTrainings.filter { $0.type == "Marche" }
        
        // ✅ MODIFIÉ : on inclut maintenant l'année en cours (plus seulement previousYear)
        let currentYearValue = Calendar.current.component(.year, from: Date())
        
        // Grouper par année et calculer les totaux
        var yearlyData: [Int: Double] = [:]
        
        for training in walkingTrainings {
            let year = Calendar.current.component(.year, from: training.date)
            // Inclure de 2016 jusqu'à l'année en cours (incluse)
            if year >= 2016 && year <= currentYearValue {
                yearlyData[year, default: 0] += training.distance ?? 0
            }
        }
        
        // Convertir en tableau et trier par année
        yearlyStats = yearlyData.map { YearlyWalkingStats(year: $0.key, kilometers: $0.value) }
            .sorted { $0.year < $1.year }
    }
}

#Preview {
    MarcheModal(isPresented: .constant(true))
}
