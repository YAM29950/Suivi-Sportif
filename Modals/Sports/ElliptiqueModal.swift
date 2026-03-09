import SwiftUI
import Charts

struct ElliptiqueModal: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var yearlyStats: [YearlyElliptiqueStats] = []
    
    struct YearlyElliptiqueStats: Identifiable {
        let id = UUID()
        let year: Int
        let kilometers: Double
    }
    
    // ✅ AJOUT 1 : propriété pour l'année en cours
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
                    
                    Image(systemName: "figure.elliptical")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text("Elliptique")
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
                    Text("Statistiques Elliptique")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Graphique en barres
                    if !yearlyStats.isEmpty {
                        Chart(yearlyStats) { stat in
                            BarMark(
                                x: .value("Année", String(stat.year)),
                                y: .value("Kilomètres", stat.kilometers)
                            )
                            // ✅ AJOUT 2 : blanc pour l'année en cours (cyan déjà utilisé comme base),
                            //              cyan pour les autres années
                            .foregroundStyle(
                                stat.year == currentYear
                                    ? LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                      )
                                    : LinearGradient(
                                        colors: [Color.cyan.opacity(0.8), Color.cyan.opacity(0.5)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                      )
                            )
                            .cornerRadius(4)
                            // ✅ AJOUT 3 : annotation avec ⭐️ et bordure blanche pour l'année en cours
                            .annotation(position: .top) {
                                Text(stat.year == currentYear
                                     ? "\(Int(stat.kilometers)) km ⭐️"
                                     : "\(Int(stat.kilometers)) km")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(stat.year == currentYear ? .white : .white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        stat.year == currentYear
                                            ? Color.cyan.opacity(0.8)
                                            : Color.black.opacity(0.6)
                                    )
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                stat.year == currentYear ? Color.white : Color.clear,
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
                        // ✅ AJOUT 4 : label de l'année en cours en blanc gras sur l'axe X
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(
                                        value.as(String.self) == String(currentYear)
                                            ? AnyShapeStyle(Color.white)
                                            : AnyShapeStyle(Color.white.opacity(0.7))
                                    )
                                    .font(
                                        value.as(String.self) == String(currentYear)
                                            ? .system(size: 12, weight: .black)
                                            : .system(size: 12, weight: .semibold)
                                    )
                            }
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                            
                            VStack(spacing: 12) {
                                Image(systemName: "figure.elliptical.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.cyan.opacity(0.8))
                                
                                Text("Aucune donnée d'elliptique disponible")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                        }
                        .frame(height: 200)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 900, height: 420)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.cyan.opacity(0.3)]),
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
            loadElliptiqueStats()
        }
    }
    
    private func loadElliptiqueStats() {
        // Charger tous les entraînements
        let allTrainings = TrainingDataManager.shared.loadTrainings()
        
        // Filtrer uniquement les elliptiques
        let elliptiqueTrainings = allTrainings.filter { $0.type == "Elliptique" }
        
        // ✅ AJOUT 5 : on inclut maintenant l'année en cours (plus seulement previousYear)
        let currentYearValue = Calendar.current.component(.year, from: Date())
        
        // Grouper par année et calculer les totaux
        var yearlyData: [Int: Double] = [:]
        
        for training in elliptiqueTrainings {
            let year = Calendar.current.component(.year, from: training.date)
            // Inclure de 2016 jusqu'à l'année en cours (incluse)
            if year >= 2016 && year <= currentYearValue {
                yearlyData[year, default: 0] += training.distance ?? 0
            }
        }
        
        // Convertir en tableau et trier par année
        yearlyStats = yearlyData.map { YearlyElliptiqueStats(year: $0.key, kilometers: $0.value) }
            .sorted { $0.year < $1.year }
    }
}

#Preview {
    ElliptiqueModal(isPresented: .constant(true))
}
