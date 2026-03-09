import SwiftUI
import SDWebImageSwiftUI

struct HeartRateModal: View {
    @Binding var isPresented: Bool
    @State private var selectedTab = 0
    
    // Récupération des données du profil
    @AppStorage("userBirthDay") private var birthDay: Int = 0
    @AppStorage("userBirthMonth") private var birthMonth: Int = 0
    @AppStorage("userBirthYear") private var birthYear: Int = 0
    @AppStorage("userFCRepos") private var fcReposText = ""
    
    // Champs pour l'onglet Fc
    @State private var fcMax: String = ""
    @State private var fcRepos: String = ""
    @State private var percentage: String = "résultst"
    
    // Pour le déplacement
    @State private var dragOffset: CGSize = .zero
    @State private var currentPosition: CGSize = .zero
    
    // Calcul de l'âge
    private var calculatedAge: Int {
        guard birthDay > 0, birthMonth > 0, birthYear > 0 else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        
        var dateComponents = DateComponents()
        dateComponents.year = birthYear
        dateComponents.month = birthMonth
        dateComponents.day = birthDay
        
        guard let birthDate = calendar.date(from: dateComponents) else { return 0 }
        
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    // Calcul de la FC Max (220 - âge)
    private var calculatedFCMax: String {
        let age = calculatedAge
        return age > 0 ? "\(220 - age)" : ""
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 0) {
                // En-tête (zone de déplacement)
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.trailing, 5)
                    
                    Text("Fréquence Cardiaque")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.blue.opacity(0.4))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = CGSize(
                                width: currentPosition.width + value.translation.width,
                                height: currentPosition.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            currentPosition = dragOffset
                        }
                )
                
                // Onglets
                HStack(spacing: 0) {
                    TabButton(title: "Fc ％", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Fc Age", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    TabButton(title: "Calculer ❤️", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .background(Color.gray.opacity(0.3))
                
                // Contenu des onglets
                ZStack {
                    if selectedTab == 0 {
                        FcTab(
                            fcMax: fcMax,
                            fcRepos: fcRepos,
                            percentage: $percentage
                        )
                        .transition(.opacity)
                    } else if selectedTab == 1 {
                        FcAgeTab()
                            .transition(.opacity)
                    } else {
                        Page3Tab()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .frame(height: 520)
            }
            .frame(width: 600)
            .background(
                Color.white.opacity(0.95)
            )
            .cornerRadius(16)
            .shadow(radius: 20)
            .offset(x: dragOffset.width, y: dragOffset.height)
        }
        .onAppear {
            // Initialiser avec les valeurs du profil
            fcMax = calculatedFCMax
            fcRepos = fcReposText
        }
    }
}

// MARK: - Composant Bouton d'Onglet avec effet 3D relief
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .black : .gray.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.95),
                                    Color.gray.opacity(0.15)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.2)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                )
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(isSelected ? 0.8 : 0.3))
                        .frame(height: 2)
                        .offset(y: -7),
                    alignment: .top
                )
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(isSelected ? 0.2 : 0.1))
                        .frame(height: 2)
                        .offset(y: 7),
                    alignment: .bottom
                )
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(isSelected ? 0.5 : 0.2))
                        .frame(width: 1),
                    alignment: .leading
                )
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 1),
                    alignment: .trailing
                )
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: -1, y: -1)
                .shadow(color: Color.white.opacity(0.5), radius: 2, x: 1, y: 1)
                .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: 3, x: 0, y: 2)
                .offset(y: isSelected ? -2 : 0)
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
    }
}

// MARK: - Onglet 1: Fc
struct FcTab: View {
    let fcMax: String
    let fcRepos: String
    @Binding var percentage: String
    
    private var calculatedFC: String {
        guard let fcMaxVal = Double(fcMax),
              let fcReposVal = Double(fcRepos),
              let percentVal = Double(percentage) else {
            return "Manque %"
        }
        let result = (percentVal / 100 * (fcMaxVal - fcReposVal)) + fcReposVal
        return String(format: "%.0f", result)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fc max")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(fcMax.isEmpty ? "Non défini" : fcMax)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(width: 80)
                            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                    }
                    .padding()
                    .frame(width: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fc repos")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(fcRepos.isEmpty ? "Non défini" : fcRepos)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(width: 80)
                            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                    }
                    .padding()
                    .frame(width: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Picker("", selection: $percentage) {
                            Text("50").tag("50")
                            Text("60").tag("60")
                            Text("70").tag("70")
                            Text("80").tag("80")
                            Text("90").tag("90")
                            Text("100").tag("100")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 84, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: -2, y: -2)
                                .shadow(color: .white.opacity(0.7), radius: 2, x: 2, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .colorScheme(.light)
                    }
                    .padding()
                    .frame(width: 140)
                    .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                    .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
            
            Image("image fc")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 550, maxHeight: 550, alignment: .bottomLeading)
                .opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            VStack(spacing: 10) {
                Text("Résultat du calcul")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("(% × (FC Max - FC Repos)) + FC Repos = FC")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    Text("FC =")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    VStack(spacing: 5) {
                        if calculatedFC == "Manque %" {
                            Text(calculatedFC)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        Text(calculatedFC == "Manque %" ? "" : calculatedFC)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            )
                    }
                    
                    Text("bpm")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(width: 320)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 4)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Onglet 2: Fc Age
struct FcAgeTab: View {
    @State private var age: String = ""
    @State private var selectedPercentage: String = ""
    
    @AppStorage("userFCRepos") private var fcReposText = ""
    
    private var calculatedFCMax: String {
        guard let ageValue = Int(age), ageValue > 0 else { return "" }
        return "\(220 - ageValue)"
    }
    
    private var calculatedFCSansFCR: String {
        guard let fcMaxValue = Double(calculatedFCMax),
              let percentValue = Double(selectedPercentage) else { return "" }
        let result = (percentValue * fcMaxValue) / 100
        return String(format: "%.0f", result)
    }
    
    private var calculatedFCAvecFCR: String {
        guard let fcMaxValue = Double(calculatedFCMax),
              let fcReposValue = Double(fcReposText),
              let percentValue = Double(selectedPercentage) else { return "" }
        let result = (percentValue / 100 * (fcMaxValue - fcReposValue)) + fcReposValue
        return String(format: "%.0f", result)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("balon")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 550, maxHeight: 550)
                .opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 15) {
                    
                    ZStack(alignment: .top) {
                        VStack(spacing: 8) {
                            Spacer().frame(height: 10)
                            
                            ZStack {
                                TextField("", text: $age)
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .frame(height: 35)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                
                                if age.isEmpty {
                                    Text("Votre texte ici")
                                        .font(.system(size: 16))
                                        .italic()
                                        .foregroundColor(.red)
                                        .allowsHitTesting(false)
                                }
                            }
                            
                            Spacer().frame(height: 10)
                        }
                        .padding(.horizontal)
                        .frame(width: 180)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                        
                        Text("- Age -")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                            )
                            .offset(y: -12)
                    }
                    
                    ZStack(alignment: .top) {
                        VStack(spacing: 8) {
                            Spacer().frame(height: 10)
                            
                            Text(calculatedFCMax.isEmpty ? "" : calculatedFCMax)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 35)
                                .background(Color.white)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            Spacer().frame(height: 10)
                        }
                        .padding(.horizontal)
                        .frame(width: 180)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                        
                        Text("- FC max -")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                            )
                            .offset(y: -12)
                    }
                    
                    ZStack(alignment: .top) {
                        VStack(spacing: 8) {
                            Spacer().frame(height: 10)
                            
                            Picker("", selection: $selectedPercentage) {
                                Text("50").tag("50")
                                Text("60").tag("60")
                                Text("70").tag("70")
                                Text("80").tag("80")
                                Text("90").tag("90")
                                Text("100").tag("100")
                            }
                            .pickerStyle(.menu)
                            .frame(height: 35)
                            .frame(width: 85)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .colorScheme(.light)
                            
                            Spacer().frame(height: 10)
                        }
                        .padding(.horizontal)
                        .frame(width: 180)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                        
                        Text("- % -")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                            )
                            .offset(y: -12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                Spacer()
            }
            
            if !selectedPercentage.isEmpty {
                HStack(alignment: .bottom, spacing: 20) {
                    if let url = Bundle.main.url(forResource: "vtt", withExtension: "gif") {
                        AnimatedImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .offset(x: 72)
                            .transition(.opacity)
                    }
                    
                    VStack(alignment: .trailing, spacing: 20) {
                        ZStack(alignment: .top) {
                            VStack(spacing: 15) {
                                Spacer().frame(height: 10)
                                
                                HStack(spacing: 15) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("FC")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(calculatedFCSansFCR.isEmpty ? "" : calculatedFCSansFCR)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 30)
                                            .background(Color.yellow.opacity(0.8))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.9), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                            .frame(width: 100)
                            .background(Color.gray.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                            )
                            
                            Text("Sans FCR*")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                                )
                                .offset(y: -12)
                                .offset(x: 12)
                        }
                        
                        ZStack(alignment: .top) {
                            VStack(spacing: 15) {
                                Spacer().frame(height: 10)
                                
                                HStack(spacing: 15) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("FC")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(calculatedFCAvecFCR.isEmpty ? "" : calculatedFCAvecFCR)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 30)
                                            .background(Color.yellow.opacity(0.8))
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.9), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                            .frame(width: 100)
                            .background(Color.gray.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                            )
                            
                            Text("Avec FCR*")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                                )
                                .offset(y: -12)
                                .offset(x: 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Onglet 3: Calcul (zones d'entraînement)
struct Page3Tab: View {
    @State private var fcMax: String = ""
    @State private var fcRepos: String = ""

    // Calcul automatique de la FC Réserve (FC max - FC repos)
    private var calculatedFCReserve: String {
        guard let fcMaxValue = Double(fcMax),
              let fcReposValue = Double(fcRepos) else { return "" }
        let result = fcMaxValue - fcReposValue
        return String(format: "%.0f", result)
    }

    // ─── Zones Z1 à Z5 (Formule Karvonen) ───────────────────────────────────

    // Z1 – Echauffement  50 % à 60 %
    private var z1Min: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.50) + fcReposValue)
    }
    private var z1Max: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.60) + fcReposValue)
    }

    // Z2 – Endurance fondamentale Facile  60 % à 70 %
    private var z2Min: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.60) + fcReposValue)
    }
    private var z2Max: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.70) + fcReposValue)
    }

    // Z3 – Résistance douce Aérobie  70 % à 80 %
    private var z3Min: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.70) + fcReposValue)
    }
    private var z3Max: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.80) + fcReposValue)
    }

    // Z4 – Résistance dure Seuil  80 % à 90 %
    private var z4Min: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.80) + fcReposValue)
    }
    private var z4Max: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.90) + fcReposValue)
    }

    // Z5 – VMA Maximum  90 % à 100 %
    private var z5Min: String {
        guard let fcReserve = Double(calculatedFCReserve),
              let fcReposValue = Double(fcRepos) else { return "" }
        return String(format: "%.0f", (fcReserve * 0.90) + fcReposValue)
    }
    private var z5Max: String {
        guard let fcMax = Double(fcMax) else { return "" }
        return String(format: "%.0f", fcMax)
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 15) {
                    Spacer().frame(height: 30)
                    
                    // Ligne 1: FC max
                    HStack(spacing: 10) {
                        Text("FC max")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .italic()
                            .frame(width: 280, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        TextField("", text: $fcMax)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(width: 60)
                            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                        
                        if fcMax.isEmpty {
                            Text("👈 A renseigner")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .italic()
                        }
                        
                        Spacer()
                    }
                    
                    // Ligne 2: FC repos
                    HStack(spacing: 10) {
                        Text("FC repos")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .italic()
                            .frame(width: 280, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        TextField("", text: $fcRepos)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(width: 60)
                            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                        
                        if fcRepos.isEmpty {
                            Text("👈 A renseigner")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .italic()
                        }
                        
                        Spacer()
                    }
                    
                    // Ligne 3: FC Réserve
                    HStack(spacing: 10) {
                        Text("FC Réserve")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .italic()
                            .frame(width: 280, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        Text(calculatedFCReserve)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .frame(width: 40)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: -2, y: -2)
                                    .shadow(color: .white.opacity(0.7), radius: 2, x: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                    
                    Spacer().frame(height: 10)
                    
                    // ── 5 zones Z1–Z5 ──────────────────────────────────────────
                    trainingZoneRow(
                        label: "Z1",
                        labelColor: .green,
                        title: "Echauffement  50 % à 60 %",
                        min: z1Min, max: z1Max
                    )
                    trainingZoneRow(
                        label: "Z2",
                        labelColor: .blue,
                        title: "Endurance fondamentale Facile  60 % à 70 %",
                        min: z2Min, max: z2Max
                    )
                    trainingZoneRow(
                        label: "Z3",
                        labelColor: Color(red: 1.0, green: 0.6, blue: 0.0),
                        title: "Résistance douce Aérobie  70 % à 80 %",
                        min: z3Min, max: z3Max
                    )
                    trainingZoneRow(
                        label: "Z4",
                        labelColor: .orange,
                        title: "Résistance dure Seuil  80 % à 90 %",
                        min: z4Min, max: z4Max
                    )
                    trainingZoneRow(
                        label: "Z5",
                        labelColor: .red,
                        title: "VMA Maximum  90 % à 100 %",
                        min: z5Min, max: z5Max
                    )
                    
                    Spacer()
                }
                .padding()
                
                // GIF animé "cardio" positionné à droite
                if !fcMax.isEmpty && !fcRepos.isEmpty {
                    if let url = Bundle.main.url(forResource: "cardio2", withExtension: "gif") {
                        AnimatedImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .padding(.top, 50)
                            .padding(.trailing, 6)
                            .transition(.opacity)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func trainingZoneRow(label: String, labelColor: Color, title: String, min: String, max: String) -> some View {
        HStack(spacing: 10) {
            // Badge de zone coloré
            Text(label)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(labelColor)
                .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .italic()
                .frame(width: 340, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(labelColor.opacity(0.6), lineWidth: 2)
                )
            
            Text(min)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(width: 60)
                .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                .cornerRadius(6)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
            
            Text(max)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(width: 60)
                .background(Color(red: 0.93, green: 0.93, blue: 0.93))
                .cornerRadius(6)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 3, y: 3)
                .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var showModal = true
        
        var body: some View {
            ZStack {
                Color.blue.opacity(0.3)
                    .ignoresSafeArea()
                
                Button("Ouvrir Modal") {
                    showModal = true
                }
                
                if showModal {
                    HeartRateModal(isPresented: $showModal)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
