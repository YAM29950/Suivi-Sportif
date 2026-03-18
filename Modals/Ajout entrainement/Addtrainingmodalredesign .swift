import SwiftUI

// ============================================================
// MARK: - DESIGN SYSTEM
// Copiez ce fichier dans votre projet Xcode.
// Il remplace le style visuel du modal sans toucher à la logique.
// ============================================================

// MARK: - Tokens de couleur
extension Color {
    static let dsBackground   = Color(red: 0.06, green: 0.08, blue: 0.14)   // Fond principal
    static let dsCard         = Color(red: 0.09, green: 0.12, blue: 0.20)   // Cartes
    static let dsCardBorder   = Color.white.opacity(0.07)
    static let dsSurface      = Color.white.opacity(0.05)                    // Champs de saisie
    static let dsSurfaceHover = Color.white.opacity(0.09)
    static let dsAccent       = Color(red: 0.22, green: 0.72, blue: 1.00)   // Cyan vif
    static let dsAccentGlow   = Color(red: 0.22, green: 0.72, blue: 1.00).opacity(0.18)
    static let dsGreen        = Color(red: 0.29, green: 0.86, blue: 0.50)
    static let dsGreenGlow    = Color(red: 0.29, green: 0.86, blue: 0.50).opacity(0.18)
    static let dsOrange       = Color(red: 0.98, green: 0.57, blue: 0.24)
    static let dsRed          = Color(red: 0.97, green: 0.44, blue: 0.44)
    static let dsPurple       = Color(red: 0.75, green: 0.52, blue: 0.99)
    static let dsYellow       = Color(red: 0.99, green: 0.80, blue: 0.20)
    static let dsText         = Color.white
    static let dsTextDim      = Color.white.opacity(0.55)
    static let dsTextFaint    = Color.white.opacity(0.28)
}

// MARK: - Style de carte panneau (remplace Rectangle bleu opacity 0.3)
struct DSCard: ViewModifier {
    var accent: Color = .dsCardBorder
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.dsCard)
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent, lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func dsCard(accent: Color = .dsCardBorder) -> some View {
        modifier(DSCard(accent: accent))
    }
}

// MARK: - Champ de saisie stylisé
struct DSTextField: View {
    let label: String
    @Binding var text: String
    var width: CGFloat = 70
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.dsTextFaint)
                .tracking(1.2)

            TextField(placeholder, text: $text)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.dsText)
                .textFieldStyle(.plain)
                .frame(width: width, height: 32)
                .padding(.horizontal, 10)
                .background(Color.dsSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.dsCardBorder, lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Champ display (lecture seule, valeur calculée)
struct DSDisplayField: View {
    let label: String
    let value: String
    var width: CGFloat = 80
    var accentColor: Color = .dsAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.dsTextFaint)
                .tracking(1.2)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(value.isEmpty ? .dsTextFaint : accentColor)
                .frame(width: width, height: 32)
                .background(accentColor.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Picker stylisé générique
struct DSPickerField<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [(String, T)]
    var width: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.dsTextFaint)
                .tracking(1.2)

            Picker(label, selection: $selection) {
                ForEach(options, id: \.1) { opt in
                    Text(opt.0).tag(opt.1)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: width, height: 32)
            .background(Color.dsSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.dsCardBorder, lineWidth: 1)
            )
            .cornerRadius(8)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }
}

// MARK: - Bouton d'activité redesigné
struct DSActivityButton: View {
    let emoji: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Color.dsAccent.opacity(0.18) : Color.dsSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isActive ? Color.dsAccent.opacity(0.6) : Color.dsCardBorder, lineWidth: 1)
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: isActive ? Color.dsAccent.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)

                    Text(emoji)
                        .font(.system(size: 22))
                }

                Text(label.uppercased())
                    .font(.system(size: 7.5, weight: .bold, design: .rounded))
                    .foregroundColor(isActive ? .dsAccent : .dsTextFaint)
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 54)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Séparateur vertical
struct DSVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsCardBorder)
            .frame(width: 1, height: 48)
            .padding(.horizontal, 4)
    }
}

// MARK: - Checkbox modernisée
struct DSCheckbox: View {
    let title: String
    @Binding var isSelected: Bool
    var accentColor: Color = .dsAccent
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? accentColor : Color.dsSurface)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? accentColor : Color.dsCardBorder, lineWidth: 1.5)
                        )
                        .shadow(color: isSelected ? accentColor.opacity(0.4) : .clear, radius: 5)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.black)
                    }
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? accentColor : .dsTextDim)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Étoiles de forme redesignées
struct DSStarRating: View {
    @Binding var value: Int?

    var body: some View {
        HStack(spacing: 6) {
            ForEach([15, 30, 45, 60, 75], id: \.self) { v in
                let idx = v / 15
                let isLit = (value ?? 0) >= v
                Text("★")
                    .font(.system(size: 20))
                    .foregroundColor(isLit ? .dsYellow : .dsTextFaint)
                    .shadow(color: isLit ? Color.dsYellow.opacity(0.6) : .clear, radius: 4)
                    .scaleEffect(isLit ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2), value: isLit)
                    .onTapGesture { value = v }
                    .help("\(idx) étoile\(idx > 1 ? "s" : "")")
            }
        }
    }
}

// MARK: - Bouton principal (Enregistrer)
struct DSSaveButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Enregistrer")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(isEnabled ? .black : .dsTextFaint)
            .frame(width: 150, height: 48)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient(
                            colors: [.dsGreen, .dsAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.dsSurface
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? .clear : Color.dsCardBorder, lineWidth: 1)
            )
            .cornerRadius(14)
            .shadow(color: isEnabled ? Color.dsGreen.opacity(0.35) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Bouton Fermer
struct DSCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                Text("Fermer")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(.dsRed)
            .frame(width: 120, height: 48)
            .background(Color.dsRed.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dsRed.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Badge de valeur (2ème ligne zones équipement)
struct DSEquipBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.dsTextFaint)
                .tracking(1.0)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(value.isEmpty ? .dsTextFaint : color)
                .frame(width: 80, height: 32)
                .background(color.opacity(value.isEmpty ? 0.04 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(value.isEmpty ? 0.1 : 0.35), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Tag de section (titre panneau équipement)
struct DSSectionTag: View {
    let title: String
    var color: Color = .dsAccent

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.8), radius: 3)

            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(color)
                .tracking(1.2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.10))
        .overlay(
            Capsule().stroke(color.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - En-tête ticker animé
struct DSTicker: View {
    let text: String
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let repeated = String(repeating: text + "   •   ", count: 4)
            Text(repeated)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.dsYellow)
                .lineLimit(1)
                .fixedSize()
                .offset(x: offset)
                .onAppear {
                    offset = 0
                    withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                        offset = -geo.size.width * 1.2
                    }
                }
        }
        .clipped()
    }
}

// MARK: - Fond principal du modal
struct DSModalBackground: View {
    var body: some View {
        ZStack {
            // Fond de base
            Color.dsBackground

            // Grain subtil simulé via pattern
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.32).opacity(0.6),
                    Color.dsBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Halo cyan coin haut gauche
            RadialGradient(
                colors: [Color.dsAccent.opacity(0.06), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )

            // Halo vert coin bas droit
            RadialGradient(
                colors: [Color.dsGreen.opacity(0.04), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
        }
    }
}

// MARK: - Slider de zoom
struct DSZoomSlider: View {
    @Binding var scale: Double

    var body: some View {
        HStack(spacing: 10) {
            Text("ZOOM")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.dsTextFaint)
                .tracking(1.2)

            Slider(value: $scale, in: 0.6...1.0, step: 0.05)
                .frame(width: 130)
                .accentColor(.dsAccent)

            Text("\(Int(scale * 100))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.dsAccent)
                .frame(width: 36, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.dsSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dsCardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// ============================================================
// MARK: - APERÇU DU RÉSULTAT (Preview)
// ============================================================

struct DesignSystemPreview: View {
    @State private var aJeunOui = false
    @State private var aJeunNon = false
    @State private var forme: Int? = nil
    @State private var km = ""
    @State private var scale = 1.0
    @State private var activeActivity = ""

    let activities: [(String, String)] = [
        ("🚶", "Marche"), ("🏃", "Tapis"), ("🔄", "Elliptique"),
        ("🚣", "Rameur"), ("🚴", "Home trainer"), ("🏅", "Triathlon"),
        ("🏟️", "Piste"), ("🛣️", "Route"), ("⛰️", "VTT"),
        ("🏊", "Piscine"), ("🌊", "Mer")
    ]

    var body: some View {
        ZStack {
            DSModalBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Ticker header ──────────────────────────────────
                ZStack {
                    Color.dsAccent.opacity(0.05)
                        .overlay(Rectangle().stroke(Color.dsCardBorder, lineWidth: 0).frame(height: 1), alignment: .bottom)

                    DSTicker(text: "Samedi 21 Février 2026")
                }
                .frame(height: 40)
                .clipped()

                // ── Corps ──────────────────────────────────────────
                HStack(alignment: .top, spacing: 0) {

                    // Colonne gauche
                    VStack(spacing: 14) {
                        // Mini calendrier placeholder
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "chevron.left").foregroundColor(.dsTextDim).font(.system(size: 13))
                                Spacer()
                                Text("Février 2026")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.dsText)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.dsTextDim).font(.system(size: 13))
                            }
                            .padding(.horizontal, 12)

                            // Jours de la semaine
                            HStack(spacing: 0) {
                                ForEach(["L","Ma","Me","J","V","S","D"], id: \.self) { d in
                                    Text(d)
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.dsTextFaint)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 8)

                            // Grille des jours (illustrative)
                            let days = Array(1...28)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 3) {
                                ForEach([0,1,2,3,4], id: \.self) { _ in // 5 empty (Samedi)
                                    Color.clear.frame(height: 26)
                                }
                                ForEach(days, id: \.self) { d in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(d == 21 ? Color.dsAccent : (d == 14 ? Color.dsGreen.opacity(0.18) : Color.clear))
                                            .shadow(color: d == 21 ? Color.dsAccent.opacity(0.5) : .clear, radius: 5)

                                        Text("\(d)")
                                            .font(.system(size: 11, weight: d == 21 ? .black : .regular, design: .monospaced))
                                            .foregroundColor(d == 21 ? .black : (d == 14 ? .dsGreen : .dsTextDim))
                                    }
                                    .frame(height: 26)
                                    .overlay(alignment: .bottom) {
                                        if [3, 5, 8, 10, 14, 17, 19].contains(d) && d != 21 {
                                            Circle().fill(Color.dsGreen).frame(width: 3, height: 3).offset(y: -1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 10)
                        }
                        .dsCard()
                        .frame(width: 240)

                        // A jeun + Forme
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("À JEUN")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.dsTextFaint)
                                    .tracking(1.2)
                                HStack(spacing: 10) {
                                    DSCheckbox(title: "Oui", isSelected: $aJeunOui) {
                                        aJeunOui.toggle(); if aJeunOui { aJeunNon = false }
                                    }
                                    DSCheckbox(title: "Non", isSelected: $aJeunNon) {
                                        aJeunNon.toggle(); if aJeunNon { aJeunOui = false }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("FORME")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.dsTextFaint)
                                    .tracking(1.2)
                                DSStarRating(value: $forme)
                            }
                        }
                        .padding(14)
                        .dsCard()
                        .frame(width: 240)

                        Spacer()
                    }
                    .padding(16)

                    // Séparateur
                    Rectangle()
                        .fill(Color.dsCardBorder)
                        .frame(width: 1)
                        .padding(.vertical, 10)

                    // Colonne droite
                    VStack(spacing: 10) {

                        // ── Boutons activité ───────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(activities, id: \.1) { act in
                                    DSActivityButton(
                                        emoji: act.0,
                                        label: act.1,
                                        isActive: activeActivity == act.1
                                    ) { activeActivity = act.1 }
                                }
                                DSVerticalDivider()
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 72)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .dsCard()

                        // ── Données principales ────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                DSTextField(label: "Km", text: $km, width: 52)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("TEMPS")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.dsTextFaint)
                                        .tracking(1.2)
                                    Picker("", selection: .constant(60)) {
                                        Text("0:30").tag(30)
                                        Text("1:00").tag(60)
                                        Text("1:30").tag(90)
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .frame(width: 76, height: 32)
                                    .background(Color.dsSurface)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsCardBorder, lineWidth: 1))
                                }

                                DSDisplayField(label: "Moyenne", value: "12 km/h", width: 86)
                                DSTextField(label: "Calories", text: .constant(""), width: 58)
                                DSTextField(label: "FC Max", text: .constant("165"), width: 52)
                                DSTextField(label: "FC Moy", text: .constant("148"), width: 52)
                                DSDisplayField(label: "% FC Max", value: "87%", width: 64, accentColor: .dsOrange)
                                DSDisplayField(label: "% FC Moy", value: "78%", width: 64, accentColor: .dsGreen)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("PLAN")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.dsTextFaint)
                                        .tracking(1.2)
                                    Picker("", selection: .constant("")) {
                                        Text("—").tag("")
                                        Text("M / FORCE + Endurance Z2").tag("M / FORCE + Endurance Z2")
                                        Text("M / HIIT Lipolytique").tag("M / HIIT Lipolytique")
                                        Text("J / TAPIS 12%").tag("J / TAPIS 12% + Endurance Z2")
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .frame(width: 170, height: 32)
                                    .background(Color.dsSurface)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsPurple.opacity(0.3), lineWidth: 1))
                                }

                                DSTextField(label: "Observations", text: .constant(""), width: 160)
                            }
                            .padding(.horizontal, 14)
                        }
                        .frame(height: 70)
                        .padding(.vertical, 10)
                        .dsCard()

                        // ── Panneau équipement (exemple Home trainer) ──
                        HStack(spacing: 16) {
                            DSSectionTag(title: "Home trainer", color: .dsAccent)

                            DSEquipBadge(label: "Puissance", value: "120W", color: .dsAccent)
                            DSEquipBadge(label: "Cadence", value: "80", color: .dsGreen)
                            DSEquipBadge(label: "Niveau", value: "3", color: .dsYellow)
                            DSEquipBadge(label: "Pente", value: "2%", color: .dsOrange)
                            DSEquipBadge(label: "Plateau", value: "42", color: .dsPurple)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .dsCard(accent: Color.dsAccent.opacity(0.18))

                        // ── Zone de sortie personnalisée ────────────
                        VStack(spacing: 10) {
                            // Barre top verte
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, .dsGreen, .clear], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 1.5)

                            HStack {
                                Text("Home trainer")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundColor(.dsText)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text("⚙ Réglages")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.dsOrange)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.dsOrange.opacity(0.10))
                                        .overlay(Capsule().stroke(Color.dsOrange.opacity(0.3), lineWidth: 1))
                                        .clipShape(Capsule())

                                    Text("✕")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.dsTextDim)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.dsSurface)
                                        .overlay(Capsule().stroke(Color.dsCardBorder, lineWidth: 1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 14)

                            // Zones de valeurs
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    let zones: [(String, String)] = [
                                        ("Date", "21/02/2026"), ("À jeun", "Non"), ("Forme", "⭐⭐⭐"),
                                        ("Km", "25"), ("Temps", "1:10"), ("Moyenne", "21 km/h"),
                                        ("Calories", "480"), ("FC Max", "165"), ("FC Moy", "148"),
                                        ("% FC Max", "87%"), ("% FC Moy", "78%"),
                                        ("Plan", "M / FORCE + Endurance Z2"), ("Observations", "Bonne séance")
                                    ]
                                    ForEach(zones, id: \.0) { z in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(z.0.uppercased())
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(.dsTextFaint)
                                                .tracking(0.8)
                                            Text(z.1)
                                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.dsGreen)
                                                .frame(minWidth: 40, alignment: .leading)
                                                .padding(.horizontal, 8).padding(.vertical, 5)
                                                .background(Color.dsGreen.opacity(0.07))
                                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.dsGreen.opacity(0.2), lineWidth: 1))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                            }
                            .padding(.bottom, 8)
                        }
                        .background(Color.dsCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.dsGreen.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(16)

                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }

                // ── Footer ─────────────────────────────────────────
                Divider()
                    .background(Color.dsCardBorder)

                HStack(spacing: 12) {
                    DSSaveButton(isEnabled: true) { }
                    DSCloseButton { }
                    Spacer()
                    DSZoomSlider(scale: $scale)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.dsBackground.opacity(0.8))
            }
        }
        .frame(width: 1100, height: 640)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.dsCardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 40, y: 20)
    }
}

// MARK: - Preview Xcode
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DesignSystemPreview()
            .padding(30)
    }
}
