import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Sports partagés

struct SportsList {
    static let all = ["Tous", "Marche", "Tapis", "Elliptique", "Rameur",
                      "Home trainer", "Triathlon", "Piste", "Route", "VTT", "Piscine", "Mer"]
}

// MARK: - Générateur PDF

struct PDFGenerator {

    private static let bleuFonce = NSColor(red: 0.10, green: 0.23, blue: 0.36, alpha: 1)
    private static let bleuMoyen = NSColor(red: 0.18, green: 0.43, blue: 0.64, alpha: 1)
    private static let bleuClair = NSColor(red: 0.84, green: 0.91, blue: 0.97, alpha: 1)
    private static let grisClair = NSColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1)

    private static let pageWidth:  CGFloat = 842
    private static let pageHeight: CGFloat = 595
    private static let margin:     CGFloat = 30
    private static let rowH:       CGFloat = 22
    private static let headerH:    CGFloat = 30

    private static let colW: [CGFloat] = [80, 70, 65, 75, 65, 110, 50, 197]
    private static let colTitles = ["Date", "Sport", "Distance", "Durée", "Calories",
                                    "Fréq. card.", "Forme", "Observations"]

    // ── Filtre + écriture ─────────────────────────────────────────────────────
    static func generate(from allTrainings: [Training], sport: String,
                         from startDate: Date, to endDate: Date, to url: URL) -> Bool {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        let filtered = allTrainings
            .filter { t in
                let matchSport = sport == "Tous" || t.type == sport
                let matchDate  = t.date >= startDate && t.date <= endOfDay
                return matchSport && matchDate
            }
            .sorted { $0.date > $1.date }

        let rowsPerPage = Int((pageHeight - margin * 2 - headerH - 80) / rowH)
        let pageCount   = max(1, Int(ceil(Double(filtered.count) / Double(rowsPerPage))))

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let ctx = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return false }

        for pageIdx in 0..<pageCount {
            let slice = Array(filtered.dropFirst(pageIdx * rowsPerPage).prefix(rowsPerPage))
            renderPage(ctx: ctx, mediaBox: &mediaBox, trainings: slice,
                       pageIdx: pageIdx, pageCount: pageCount,
                       allFiltered: filtered, sport: sport,
                       startDate: startDate, endDate: endDate,
                       isFirst: pageIdx == 0)
        }
        ctx.closePDF()
        return true
    }

    static func count(from trainings: [Training], sport: String,
                      from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return trainings.filter { t in
            let matchSport = sport == "Tous" || t.type == sport
            let matchDate  = t.date >= startDate && t.date <= endOfDay
            return matchSport && matchDate
        }.count
    }

    // ── Rendu d'une page ──────────────────────────────────────────────────────
    private static func renderPage(ctx: CGContext, mediaBox: inout CGRect,
                                   trainings: [Training], pageIdx: Int, pageCount: Int,
                                   allFiltered: [Training], sport: String,
                                   startDate: Date, endDate: Date, isFirst: Bool) {
        ctx.beginPDFPage(nil)
        let savedNSCtx = NSGraphicsContext.current
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        var y = pageHeight - margin

        if isFirst {
            // Bandeau titre
            ctx.setFillColor(bleuFonce.cgColor)
            ctx.fill(CGRect(x: margin, y: y - 44, width: pageWidth - margin * 2, height: 44))

            let sportLabel = sport == "Tous" ? "Tous sports" : sport
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 18), .foregroundColor: NSColor.white
            ]
            NSAttributedString(string: "📋  Entraînements — \(sportLabel)", attributes: titleAttrs)
                .draw(at: CGPoint(x: margin + 10, y: y - 34))
            y -= 50

            // Ligne de stats
            let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"
            let totalKm  = allFiltered.compactMap { $0.distance }.reduce(0, +)
            let totalCal = allFiltered.compactMap { $0.calories }.reduce(0, +)
            let statsText = "Sport : \(sportLabel)  ·  Période : \(df.string(from: startDate)) → \(df.string(from: endDate))" +
                            "  ·  \(allFiltered.count) séances  ·  \(String(format: "%.1f", totalKm)) km  ·  \(totalCal) kcal"
            let statsAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10), .foregroundColor: bleuMoyen
            ]
            NSAttributedString(string: statsText, attributes: statsAttrs)
                .draw(at: CGPoint(x: margin, y: y - 14))
            y -= 24

            ctx.setStrokeColor(bleuMoyen.cgColor); ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: margin, y: y))
            ctx.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            ctx.strokePath()
            y -= 10
        }

        drawTableHeader(ctx: ctx, y: y)
        y -= headerH

        for (i, training) in trainings.enumerated() {
            drawRow(ctx: ctx, training: training, y: y, bg: i % 2 == 0 ? NSColor.white : grisClair)
            y -= rowH
        }

        // Pied de page
        let footerY: CGFloat = margin - 10
        ctx.setStrokeColor(bleuClair.cgColor); ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: footerY + 12))
        ctx.addLine(to: CGPoint(x: pageWidth - margin, y: footerY + 12))
        ctx.strokePath()
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7), .foregroundColor: NSColor.gray
        ]
        NSAttributedString(
            string: "Généré le \(dateStr)  ·  Page \(pageIdx + 1) / \(pageCount)  ·  Suivi Sportif",
            attributes: footerAttrs
        ).draw(at: CGPoint(x: margin, y: footerY))

        NSGraphicsContext.current = savedNSCtx
        NSGraphicsContext.restoreGraphicsState()
        ctx.endPDFPage()
    }

    private static func drawTableHeader(ctx: CGContext, y: CGFloat) {
        var x = margin
        for (i, title) in colTitles.enumerated() {
            ctx.setFillColor(bleuFonce.cgColor)
            ctx.fill(CGRect(x: x, y: y - headerH, width: colW[i], height: headerH))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 9), .foregroundColor: NSColor.white
            ]
            let str = NSAttributedString(string: title, attributes: attrs)
            str.draw(at: CGPoint(x: x + (colW[i] - str.size().width) / 2, y: y - headerH + 9))
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor); ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: x + colW[i], y: y - headerH))
            ctx.addLine(to: CGPoint(x: x + colW[i], y: y)); ctx.strokePath()
            x += colW[i]
        }
    }

    private static func drawRow(ctx: CGContext, training: Training, y: CGFloat, bg: NSColor) {
        let totalW = colW.reduce(0, +)
        ctx.setFillColor(bg.cgColor)
        ctx.fill(CGRect(x: margin, y: y - rowH, width: totalW, height: rowH))
        ctx.setStrokeColor(bleuClair.cgColor); ctx.setLineWidth(0.4)
        ctx.move(to: CGPoint(x: margin, y: y - rowH))
        ctx.addLine(to: CGPoint(x: margin + totalW, y: y - rowH)); ctx.strokePath()

        let values: [String] = [
            training.shortFormattedDate, training.type,
            training.distance.map { String(format: "%.1f km", $0) } ?? "—",
            training.duration.isEmpty ? "—" : training.duration,
            training.calories.map { "\($0) kcal" } ?? "—",
            heartRateText(training), training.forme ?? "—",
            String(training.observations.prefix(60)) + (training.observations.count > 60 ? "…" : "")
        ]
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8), .foregroundColor: bleuFonce
        ]
        var x = margin
        for (i, val) in values.enumerated() {
            let str  = NSAttributedString(string: val, attributes: attrs)
            let xPos = i == values.count - 1 ? x + 4 : x + max(2, (colW[i] - str.size().width) / 2)
            str.draw(at: CGPoint(x: xPos, y: y - rowH + 7))
            x += colW[i]
        }
    }

    private static func heartRateText(_ t: Training) -> String {
        var parts: [String] = []
        if let avg = t.avgHeartRate { parts.append("moy \(avg)") }
        if let max = t.maxHeartRate { parts.append("max \(max)") }
        return parts.isEmpty ? "—" : parts.joined(separator: " / ")
    }
}

// MARK: - Générateur CSV

struct CSVGenerator {

    static func generate(from trainings: [Training], sport: String,
                         from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        let filtered = trainings
            .filter { t in
                let matchSport = sport == "Tous" || t.type == sport
                let matchDate  = t.date >= startDate && t.date <= endOfDay
                return matchSport && matchDate
            }
            .sorted { $0.date > $1.date }

        var lines: [String] = [
            "Date;Sport;Distance (km);Durée;Calories;FC moy;FC max;Forme;Observations"
        ]
        let df = DateFormatter(); df.dateFormat = "dd/MM/yyyy"

        for t in filtered {
            let row = [
                df.string(from: t.date), escape(t.type),
                t.distance.map { String(format: "%.2f", $0) } ?? "",
                escape(t.duration),
                t.calories.map { "\($0)" } ?? "",
                t.avgHeartRate.map { "\($0)" } ?? "",
                t.maxHeartRate.map { "\($0)" } ?? "",
                escape(t.forme ?? ""), escape(t.observations)
            ].joined(separator: ";")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        guard s.contains(";") || s.contains("\"") || s.contains("\n") else { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func count(from trainings: [Training], sport: String,
                      from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return trainings.filter { t in
            let matchSport = sport == "Tous" || t.type == sport
            let matchDate  = t.date >= startDate && t.date <= endOfDay
            return matchSport && matchDate
        }.count
    }
}

// MARK: - Vue principale

struct PDFExportView: View {
    let trainings: [Training]
    var onRetourMenu: (() -> Void)? = nil

    // ── États PDF ─────────────────────────────────────────────────────────────
    @State private var pdfDone      = false
    @State private var pdfGenerating = false
    @State private var pdfURL: URL?
    @State private var pdfError: String?
    @State private var pdfSport     = "Tous"
    @State private var pdfStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var pdfEndDate: Date   = Date()

    // ── États CSV ─────────────────────────────────────────────────────────────
    @State private var csvDone       = false
    @State private var csvGenerating = false
    @State private var csvURL: URL?
    @State private var csvError: String?
    @State private var csvSport      = "Tous"
    @State private var csvStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var csvEndDate: Date   = Date()

    // ── Compteurs ─────────────────────────────────────────────────────────────
    private var pdfCount: Int {
        PDFGenerator.count(from: trainings, sport: pdfSport, from: pdfStartDate, to: pdfEndDate)
    }
    private var csvCount: Int {
        CSVGenerator.count(from: trainings, sport: csvSport, from: csvStartDate, to: csvEndDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Boutons navigation ────────────────────────────────────────
                HStack(spacing: 10) {
                    Button { onRetourMenu?() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                            Text("Menu").font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.white.opacity(0.18))
                        .foregroundColor(.white).cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button { onRetourMenu?() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill").font(.system(size: 13))
                            Text("Retour au menu").font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.orange.opacity(0.35))
                        .foregroundColor(.white).cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                // ════════════════════════════════════════════════════════════
                // BLOC PDF
                // ════════════════════════════════════════════════════════════
                exportCard(accentColor: .blue) {
                    VStack(spacing: 16) {

                        // Titre
                        HStack(spacing: 10) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 26)).foregroundColor(.blue)
                            Text("Export PDF")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            countBadge(pdfCount, color: .blue)
                        }

                        Divider().background(Color.white.opacity(0.2))

                        // Sélection sport
                        sportPicker(selected: $pdfSport) {
                            pdfDone = false; pdfError = nil
                        }

                        Divider().background(Color.white.opacity(0.15))

                        // Sélection période + bouton
                        periodePicker(startDate: $pdfStartDate, endDate: $pdfEndDate) {
                            pdfDone = false; pdfError = nil
                        } shortcut: { days, months, years in
                            setRange(days: days, months: months, years: years,
                                     start: &pdfStartDate, end: &pdfEndDate)
                            pdfDone = false; pdfError = nil
                        } all: {
                            setRangeAll(start: &pdfStartDate, end: &pdfEndDate)
                            pdfDone = false; pdfError = nil
                        } actionButton: {
                            Button { exportPDF() } label: {
                                Label("Générer le PDF", systemImage: "arrow.down.doc.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 22).padding(.vertical, 10)
                                    .background(pdfGenerating || pdfCount == 0 ? Color.gray : Color.blue)
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .disabled(pdfCount == 0 || pdfGenerating)
                        }

                        // Résumé
                        resumeBanner(count: pdfCount, sport: pdfSport,
                                     start: pdfStartDate, end: pdfEndDate)

                        // Statuts
                        if let err = pdfError { errorBanner(err) }
                        if pdfDone, let url = pdfURL {
                            successBanner(path: url.lastPathComponent) {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                        if pdfGenerating {
                            ProgressView("Génération du PDF…")
                                .progressViewStyle(.circular).foregroundColor(.white)
                        }

                        HStack {
                            Text("Enregistré dans ~/Téléchargements")
                                .font(.caption2).foregroundColor(.white.opacity(0.35))
                            Spacer()
                        }
                    }
                    .padding(18)
                }

                // ════════════════════════════════════════════════════════════
                // BLOC CSV
                // ════════════════════════════════════════════════════════════
                exportCard(accentColor: .green) {
                    VStack(spacing: 16) {

                        // Titre
                        HStack(spacing: 10) {
                            Image(systemName: "tablecells.fill")
                                .font(.system(size: 26)).foregroundColor(.green)
                            Text("Export CSV")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            Spacer()
                            countBadge(csvCount, color: .green)
                        }

                        Divider().background(Color.white.opacity(0.2))

                        // Sélection sport
                        sportPicker(selected: $csvSport) {
                            csvDone = false; csvError = nil
                        }

                        Divider().background(Color.white.opacity(0.15))

                        // Sélection période + bouton
                        periodePicker(startDate: $csvStartDate, endDate: $csvEndDate) {
                            csvDone = false; csvError = nil
                        } shortcut: { days, months, years in
                            setRange(days: days, months: months, years: years,
                                     start: &csvStartDate, end: &csvEndDate)
                            csvDone = false; csvError = nil
                        } all: {
                            setRangeAll(start: &csvStartDate, end: &csvEndDate)
                            csvDone = false; csvError = nil
                        } actionButton: {
                            Button { exportCSV() } label: {
                                Label("Générer le CSV", systemImage: "arrow.down.doc")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 22).padding(.vertical, 10)
                                    .background(csvGenerating || csvCount == 0 ? Color.gray : Color.green)
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .disabled(csvCount == 0 || csvGenerating)
                        }

                        // Résumé
                        resumeBanner(count: csvCount, sport: csvSport,
                                     start: csvStartDate, end: csvEndDate)

                        // Statuts
                        if let err = csvError { errorBanner(err) }
                        if csvDone, let url = csvURL {
                            successBanner(path: url.lastPathComponent) {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                        if csvGenerating {
                            ProgressView("Génération du CSV…")
                                .progressViewStyle(.circular).foregroundColor(.white)
                        }

                        HStack {
                            Text("Enregistré dans ~/Téléchargements")
                                .font(.caption2).foregroundColor(.white.opacity(0.35))
                            Spacer()
                        }
                    }
                    .padding(18)
                }

            }
            .padding(20)
        }
    }

    // MARK: - Composants réutilisables

    @ViewBuilder
    private func exportCard<Content: View>(accentColor: Color,
                                           @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.09))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor.opacity(0.35), lineWidth: 1))
            content()
        }
    }

    @ViewBuilder
    private func countBadge(_ n: Int, color: Color) -> some View {
        Text("\(n) séance\(n > 1 ? "s" : "")")
            .font(.caption).foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.3)).cornerRadius(6)
    }

    @ViewBuilder
    private func sportPicker(selected: Binding<String>, onChange: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sport", systemImage: "figure.run")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SportsList.all, id: \.self) { sport in
                    Button {
                        selected.wrappedValue = sport
                        onChange()
                    } label: {
                        Text(sport)
                            .font(.system(size: 12,
                                          weight: selected.wrappedValue == sport ? .bold : .regular))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(selected.wrappedValue == sport
                                ? Color.white.opacity(0.30) : Color.white.opacity(0.10))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(selected.wrappedValue == sport
                                    ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func periodePicker(startDate: Binding<Date>, endDate: Binding<Date>,
                                onChange: @escaping () -> Void,
                                shortcut: @escaping (Int, Int, Int) -> Void,
                                all: @escaping () -> Void,
                                actionButton: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Période", systemImage: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                // Du
                HStack(spacing: 6) {
                    Text("Du").font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    DatePicker("", selection: startDate, in: ...endDate.wrappedValue,
                               displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden()
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                        .onChange(of: startDate.wrappedValue) { _ in onChange() }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.white.opacity(0.10)).cornerRadius(9)

                // Au
                HStack(spacing: 6) {
                    Text("Au").font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    DatePicker("", selection: endDate, in: startDate.wrappedValue...,
                               displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden()
                        .environment(\.locale, Locale(identifier: "fr_FR"))
                        .onChange(of: endDate.wrappedValue) { _ in onChange() }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.white.opacity(0.10)).cornerRadius(9)

                // Bouton générer juste après Au, même espacement
                actionButton()

                Spacer()
            }

            // Raccourcis
            HStack(spacing: 6) {
                Text("Raccourcis :").font(.caption2).foregroundColor(.white.opacity(0.45))
                shortcutBtn("7 j")    { shortcut(7, 0, 0) }
                shortcutBtn("1 mois") { shortcut(0, 1, 0) }
                shortcutBtn("3 mois") { shortcut(0, 3, 0) }
                shortcutBtn("6 mois") { shortcut(0, 6, 0) }
                shortcutBtn("1 an")   { shortcut(0, 0, 1) }
                shortcutBtn("Tout")   { all() }
            }
        }
    }

    @ViewBuilder
    private func resumeBanner(count: Int, sport: String, start: Date, end: Date) -> some View {
        let df = DateFormatter()
        let _  = { df.dateFormat = "dd/MM/yyyy" }()
        HStack(spacing: 8) {
            Image(systemName: count > 0 ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundColor(count > 0 ? .green : .orange)
            Text(count > 0
                ? "\(count) séance\(count > 1 ? "s" : "") · \(sport) · du \(df.string(from: start)) au \(df.string(from: end))"
                : "Aucune séance pour cette sélection")
                .font(.caption)
                .foregroundColor(count > 0 ? .white.opacity(0.8) : .orange)
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.07)).cornerRadius(8)
    }

    @ViewBuilder
    private func errorBanner(_ msg: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(msg).foregroundColor(.red).font(.caption)
        }
        .padding(8).background(Color.red.opacity(0.15)).cornerRadius(8)
    }

    @ViewBuilder
    private func successBanner(path: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Label("Fichier enregistré !", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green).font(.system(size: 13, weight: .semibold))
            Text(path).font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
            Button(action: action) {
                Label("Voir dans le Finder", systemImage: "folder")
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white).cornerRadius(7)
            }
            .buttonStyle(.plain)
        }
        .padding(8).background(Color.green.opacity(0.12)).cornerRadius(8)
    }

    private func shortcutBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white).cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Raccourcis période

    private func setRange(days: Int, months: Int, years: Int,
                           start: inout Date, end: inout Date) {
        let cal = Calendar.current
        end = Date()
        if days   > 0 { start = cal.date(byAdding: .day,   value: -days,   to: end) ?? end }
        if months > 0 { start = cal.date(byAdding: .month, value: -months, to: end) ?? end }
        if years  > 0 { start = cal.date(byAdding: .year,  value: -years,  to: end) ?? end }
    }

    private func setRangeAll(start: inout Date, end: inout Date) {
        start = trainings.map { $0.date }.min() ?? Date()
        end   = Date()
    }

    // MARK: - Export PDF

    private func exportPDF() {
        pdfDone = false; pdfError = nil; pdfURL = nil; pdfGenerating = true
        let snapshot = trainings
        let sport    = pdfSport
        let start    = pdfStartDate
        let end      = pdfEndDate
        DispatchQueue.global(qos: .userInitiated).async {
            let dl       = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let fmt      = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let safeSport = sport.replacingOccurrences(of: " ", with: "_")
            let url      = dl.appendingPathComponent("entrainements_\(safeSport)_\(fmt.string(from: Date())).pdf")
            let ok       = PDFGenerator.generate(from: snapshot, sport: sport,
                                                  from: start, to: end, to: url)
            DispatchQueue.main.async {
                pdfGenerating = false
                if ok { pdfDone = true; pdfURL = url }
                else  { pdfError = "Impossible de créer le PDF." }
            }
        }
    }

    // MARK: - Export CSV

    private func exportCSV() {
        csvDone = false; csvError = nil; csvURL = nil; csvGenerating = true
        let snapshot = trainings
        let sport    = csvSport
        let start    = csvStartDate
        let end      = csvEndDate
        DispatchQueue.global(qos: .userInitiated).async {
            let dl        = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let fmt       = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let safeSport = sport.replacingOccurrences(of: " ", with: "_")
            let url       = dl.appendingPathComponent("entrainements_\(safeSport)_\(fmt.string(from: Date())).csv")
            let content   = CSVGenerator.generate(from: snapshot, sport: sport, from: start, to: end)
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { csvGenerating = false; csvDone = true; csvURL = url }
            } catch {
                DispatchQueue.main.async {
                    csvGenerating = false
                    csvError = "Erreur : \(error.localizedDescription)"
                }
            }
        }
    }
}
