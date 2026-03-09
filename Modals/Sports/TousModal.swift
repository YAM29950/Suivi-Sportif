import SwiftUI

struct TousModal: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var yearlyStats: [YearlyTotalStats] = []

    struct YearlyTotalStats: Identifiable {
        let id = UUID()
        let year: Int
        let kilometers: Double
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // Même logique de couleur que ContentView
    private func barColor(for stat: YearlyTotalStats) -> Color {
        if stat.year == currentYear { return .cyan }
        if stat.year == 2016 { return Color.white.opacity(0.3) }

        let previous = yearlyStats.first(where: { $0.year == stat.year - 1 })?.kilometers ?? 0
        if stat.kilometers > previous { return .green }
        if stat.kilometers < previous { return .red }
        return Color.white.opacity(0.3)
    }

    private func formattedKm(_ km: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "fr_FR")
        return (formatter.string(from: NSNumber(value: km)) ?? "0") + " Km"
    }

    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Contenu du modal
            VStack(spacing: 20) {

                // ── En-tête ──────────────────────────────────────────────
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.trailing, 8)

                    Image(systemName: "figure.run")
                        .font(.system(size: 30))
                        .foregroundColor(.white)

                    Text("Tous les sports")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { isPresented = false }) {
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

                // ── Graphique Historique Annuel ───────────────────────────
                VStack(spacing: 15) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Historique Annuel")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }

                    if !yearlyStats.isEmpty {
                        let maxKm = yearlyStats.map { $0.kilometers }.max() ?? 1

                        GeometryReader { geometry in
                            let totalWidth   = geometry.size.width - 40
                            let barCount     = CGFloat(yearlyStats.count)
                            let spacing: CGFloat = 8
                            let totalSpacing = spacing * (barCount - 1)
                            let barWidth     = (totalWidth - totalSpacing) / barCount

                            HStack(alignment: .bottom, spacing: spacing) {
                                ForEach(yearlyStats) { stat in
                                    let barHeight  = maxKm > 0 ? (stat.kilometers / maxKm) * 160 : 0
                                    let isCurrent  = stat.year == currentYear
                                    let color      = barColor(for: stat)

                                    VStack(spacing: 4) {
                                        // Valeur au-dessus de la barre — style annotation MarcheModal
                                        Text(isCurrent
                                             ? "\(Int(stat.kilometers)) km ⭐️"
                                             : "\(Int(stat.kilometers)) km")
                                            .font(.system(
                                                size: min(barWidth * 0.18, 11),
                                                weight: .bold
                                            ))
                                            .foregroundColor(isCurrent ? .cyan : .white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 3)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(
                                                        isCurrent ? Color.cyan : Color.clear,
                                                        lineWidth: isCurrent ? 1.5 : 0
                                                    )
                                            )
                                            .minimumScaleFactor(0.4)
                                            .frame(height: 22)

                                        // Barre
                                        ZStack(alignment: .bottom) {
                                            // Barre de fond
                                            Rectangle()
                                                .fill(Color.white.opacity(0.08))
                                                .frame(width: barWidth, height: 160)
                                                .cornerRadius(6)

                                            // Barre colorée
                                            Rectangle()
                                                .fill(color)
                                                .frame(width: barWidth, height: max(barHeight, 5))
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(
                                                            isCurrent ? Color.cyan : Color.clear,
                                                            lineWidth: isCurrent ? 3 : 0
                                                        )
                                                )
                                        }
                                        .frame(height: 160)

                                        // Année en bas
                                        Text(isCurrent ? "\(stat.year) ⭐️" : "\(stat.year)")
                                            .font(.system(
                                                size: min(barWidth * 0.22, 12),
                                                weight: isCurrent ? .black : .bold
                                            ))
                                            .foregroundColor(isCurrent ? .cyan : .yellow)
                                            .minimumScaleFactor(0.4)
                                    }
                                    .frame(maxWidth: barWidth)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 210)

                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 60))
                                    .foregroundColor(.purple.opacity(0.8))
                                Text("Aucune donnée disponible")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding()
                        }
                        .frame(height: 210)
                    }

                    // ── Légende ──────────────────────────────────────────
                    HStack(spacing: 20) {
                        legendItem(color: .green,             label: "Meilleur")
                        legendItem(color: .red,               label: "Moins bien")
                        legendItem(color: .cyan,              label: "Année en cours")
                        legendItem(color: .white.opacity(0.3), label: "Référence")
                    }
                    .padding(.top, 6)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)

                Spacer()
            }
            .padding(24)
            .frame(width: 1000, height: 440)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.7),
                        Color.purple.opacity(0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation }
            )
        }
        .onAppear { loadStats() }
    }

    // ── Légende item ─────────────────────────────────────────────────────
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    // ── Chargement des données ────────────────────────────────────────────
    private func loadStats() {
        let allTrainings = TrainingDataManager.shared.loadTrainings()
        let currentYearValue = Calendar.current.component(.year, from: Date())

        var yearlyData: [Int: Double] = [:]
        for training in allTrainings {
            let year = Calendar.current.component(.year, from: training.date)
            if year >= 2016 && year <= currentYearValue {
                yearlyData[year, default: 0] += training.distance ?? 0
            }
        }

        yearlyStats = yearlyData
            .map { YearlyTotalStats(year: $0.key, kilometers: $0.value) }
            .sorted { $0.year < $1.year }
    }
}

#Preview {
    TousModal(isPresented: .constant(true))
}
