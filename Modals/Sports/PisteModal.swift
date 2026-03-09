import SwiftUI
import Charts

struct PisteModal: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var yearlyStats: [YearlyPisteStats] = []
    
    struct YearlyPisteStats: Identifiable {
        let id = UUID()
        let year: Int
        let kilometers: Double
    }
    
    // ✅ AJOUT 1
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { isPresented = false }
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "hand.draw.fill").font(.system(size: 16)).foregroundColor(.white.opacity(0.6)).padding(.trailing, 8)
                    Image(systemName: "bicycle.circle").font(.system(size: 30)).foregroundColor(.white)
                    Text("Vélo Piste").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                            Text("Quitter").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.red.opacity(0.7)).cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)
                
                VStack(spacing: 15) {
                    Text("Statistiques Vélo Piste").font(.system(size: 20, weight: .semibold)).foregroundColor(.white.opacity(0.9))
                    
                    if !yearlyStats.isEmpty {
                        Chart(yearlyStats) { stat in
                            BarMark(x: .value("Année", String(stat.year)), y: .value("Kilomètres", stat.kilometers))
                            // ✅ AJOUT 2 : cyan pour l'année en cours, red pour les autres
                            .foregroundStyle(
                                stat.year == currentYear
                                    ? LinearGradient(colors: [Color.cyan.opacity(0.9), Color.cyan.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(4)
                            // ✅ AJOUT 3
                            .annotation(position: .top) {
                                Text(stat.year == currentYear ? "\(Int(stat.kilometers)) km ⭐️" : "\(Int(stat.kilometers)) km")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(stat.year == currentYear ? .cyan : .white)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Color.black.opacity(0.6)).cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(stat.year == currentYear ? Color.cyan : Color.clear, lineWidth: stat.year == currentYear ? 1.5 : 0))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel().foregroundStyle(.white).font(.system(size: 12))
                            }
                        }
                        // ✅ AJOUT 4
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel()
                                    .foregroundStyle(value.as(String.self) == String(currentYear) ? AnyShapeStyle(Color.cyan) : AnyShapeStyle(Color.white))
                                    .font(value.as(String.self) == String(currentYear) ? .system(size: 12, weight: .black) : .system(size: 12, weight: .semibold))
                            }
                        }
                        .frame(height: 200).padding().background(Color.white.opacity(0.1)).cornerRadius(12)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15))
                            VStack(spacing: 12) {
                                Image(systemName: "bicycle.circle.fill").font(.system(size: 60)).foregroundColor(.red.opacity(0.8))
                                Text("Aucune donnée de vélo piste disponible").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                        }
                        .frame(height: 200)
                    }
                }
                Spacer()
            }
            .padding(24).frame(width: 900, height: 420)
            .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.6), Color.red.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(20).shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(DragGesture().onChanged { value in dragOffset = value.translation })
        }
        .onAppear { loadPisteStats() }
    }
    
    private func loadPisteStats() {
        let allTrainings = TrainingDataManager.shared.loadTrainings()
        let pisteTrainings = allTrainings.filter { $0.type == "Piste" }
        // ✅ AJOUT 5
        let currentYearValue = Calendar.current.component(.year, from: Date())
        var yearlyData: [Int: Double] = [:]
        for training in pisteTrainings {
            let year = Calendar.current.component(.year, from: training.date)
            if year >= 2016 && year <= currentYearValue { yearlyData[year, default: 0] += training.distance ?? 0 }
        }
        yearlyStats = yearlyData.map { YearlyPisteStats(year: $0.key, kilometers: $0.value) }.sorted { $0.year < $1.year }
    }
}

#Preview { PisteModal(isPresented: .constant(true)) }
