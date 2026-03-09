import SwiftUI
import UniformTypeIdentifiers

struct UserProfileModal: View {
    @Binding var isPresented: Bool
    
    // États persistants avec @AppStorage
    @AppStorage("userNom") private var nomText = ""
    @AppStorage("userPrenom") private var prenomText = ""
    @AppStorage("userBirthDay") private var selectedDay: Int = 0
    @AppStorage("userBirthMonth") private var selectedMonth: Int = 0
    @AppStorage("userBirthYear") private var selectedYear: Int = 0
    @AppStorage("userPoids") private var poidsText = ""
    @AppStorage("userTaille") private var tailleText = ""
    @AppStorage("userFCRepos") private var fcReposText = ""
    
    // Pour le texte défilant
    @State private var scrollOffset: CGFloat = 0
    
    // Affichage des sliders image
    @State private var showImageSliders: Bool = false
    
    // États pour l'image de profil
    @State private var profileImage: NSImage? = nil
    @State private var imageWidth: CGFloat = 150
    @State private var imageHeight: CGFloat = 150
    @State private var imageContrast: Double = 1.0
    @AppStorage("profileImageData") private var imageData: Data = Data()
    @AppStorage("profileImageWidth") private var savedImageWidth: Double = 150
    @AppStorage("profileImageHeight") private var savedImageHeight: Double = 150
    @AppStorage("profileImageContrast") private var savedImageContrast: Double = 1.0
    @AppStorage("profileRectWidth") private var savedRectWidth: Double = 280
    @AppStorage("profileRectHeight") private var savedRectHeight: Double = 200
    
    @State private var rectWidth: CGFloat = 280
    @State private var rectHeight: CGFloat = 200
    
    // Année en cours
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    // Formatage de la date pour le texte défilant
    private var formattedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: Date()).capitalized
    }
    
    // Convertir les Int stockés en Int? pour les Pickers
    private var selectedDayBinding: Binding<Int?> {
        Binding(
            get: { selectedDay == 0 ? nil : selectedDay },
            set: { selectedDay = $0 ?? 0 }
        )
    }
    
    private var selectedMonthBinding: Binding<Int?> {
        Binding(
            get: { selectedMonth == 0 ? nil : selectedMonth },
            set: { selectedMonth = $0 ?? 0 }
        )
    }
    
    private var selectedYearBinding: Binding<Int?> {
        Binding(
            get: { selectedYear == 0 ? nil : selectedYear },
            set: { selectedYear = $0 ?? 0 }
        )
    }
    
    // Calcul de l'âge
    private var calculatedAge: Int {
        guard selectedDay > 0, selectedMonth > 0, selectedYear > 0 else { return 0 }
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = selectedYear
        dateComponents.month = selectedMonth
        dateComponents.day = selectedDay
        guard let birthDate = calendar.date(from: dateComponents) else { return 0 }
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Calcul de la FC Max (220 - âge)
    private var calculatedFCMax: Int {
        return max(0, 220 - calculatedAge)
    }
    
    // Noms des mois en français
    private var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.monthSymbols.map { $0.capitalized }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: true) {
                        HStack(alignment: .top, spacing: 18) {
                            leftColumn()
                                .padding(.leading, 10)
                            rightColumn()
                        }
                        .padding(.top, 10)
                        .padding(.leading, 10)
                        .padding(.bottom, 20)
                    }
                }
                .frame(
                    width: min(geometry.size.width - 10, 780),
                    height: min(geometry.size.height - 40, showImageSliders ? 760 : 620)
                )
                .animation(.easeInOut(duration: 0.3), value: showImageSliders)
                .background(Color.gray.opacity(0.95))
                .cornerRadius(20)
                .shadow(radius: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear { loadProfileImage() }
        .onChange(of: imageWidth)   { newValue in savedImageWidth = newValue }
        .onChange(of: imageHeight)  { newValue in savedImageHeight = newValue }
        .onChange(of: imageContrast){ newValue in savedImageContrast = newValue }
        .onChange(of: rectWidth)    { newValue in savedRectWidth = newValue }
        .onChange(of: rectHeight)   { newValue in savedRectHeight = newValue }
    }
    
    // MARK: - Gestion de l'image
    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .heif]
        panel.message = "Choisissez une photo de profil"
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            if let image = NSImage(contentsOf: url) {
                profileImage = image
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    imageData = pngData
                }
            }
        }
    }
    
    func loadProfileImage() {
        if !imageData.isEmpty { profileImage = NSImage(data: imageData) }
        imageWidth = savedImageWidth
        imageHeight = savedImageHeight
        imageContrast = savedImageContrast
        rectWidth = savedRectWidth
        rectHeight = savedRectHeight
    }
    
    // MARK: - Colonne gauche
    @ViewBuilder
    func leftColumn() -> some View {
        VStack(spacing: 0) {
            
            // Texte défilant
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                GeometryReader { geo in
                    let repeatedText = String(repeating: formattedDateText + "   •   ", count: 3)
                    Text(repeatedText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                        .fixedSize()
                        .position(x: geo.size.width / 2 + scrollOffset, y: geo.size.height / 2)
                        .onAppear {
                            scrollOffset = 0
                            withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
                                scrollOffset = -geo.size.width
                            }
                        }
                }
                .clipped()
            }
            .frame(width: 300, height: 40)
            
            Spacer().frame(height: 15)
            
            // Âge calculé
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                VStack(spacing: 12) {
                    Text("Âge").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    Text(calculatedAge > 0 ? "\(calculatedAge) ans" : "-")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.yellow)
                }
                .padding()
            }
            .frame(width: 220, height: 100)
            
            Spacer().frame(height: 20)
            
            // Zone image de profil
            VStack(spacing: 10) {
                ZStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                    if let image = profileImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageWidth, height: imageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .contrast(imageContrast)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Aucune photo")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: rectWidth, height: rectHeight)
                .clipped()
                Button(action: { selectImage() }) {
                    HStack { Image(systemName: "photo.fill"); Text("Choisir une photo") }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 35)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(8)
                }.buttonStyle(.plain)
                
                if profileImage == nil {
                    // Fermer quand pas de photo
                    Button(action: { isPresented = false }) {
                        HStack { Image(systemName: "xmark.circle.fill"); Text("Fermer") }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 35)
                            .background(Color.red.opacity(0.25))
                            .cornerRadius(8)
                    }.buttonStyle(.plain)
                }
                
                if profileImage != nil {
                    // Fermer + Supprimer côte à côte
                    HStack(spacing: 8) {
                        Button(action: { isPresented = false }) {
                            HStack { Image(systemName: "xmark.circle.fill"); Text("Fermer") }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 150, height: 35)
                                .background(Color.red.opacity(0.25))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                        
                        Button(action: {
                            profileImage = nil
                            imageData = Data()
                            showImageSliders = false
                        }) {
                            HStack { Image(systemName: "trash.fill"); Text("Supprimer") }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 118, height: 35)
                                .background(Color.red.opacity(0.6))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                    
                    // Bouton réglages photo
                    Button(action: { withAnimation { showImageSliders.toggle() } }) {
                        HStack {
                            Image(systemName: showImageSliders ? "chevron.up" : "sliders.horizontal")
                            Text(showImageSliders ? "Masquer les réglages" : "Réglages photo")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 35)
                        .background(Color.purple.opacity(0.5))
                        .cornerRadius(8)
                    }.buttonStyle(.plain)
                    
                    // Sliders conditionnels
                    if showImageSliders {
                        VStack(spacing: 8) {
                            VStack(spacing: 2) {
                                Text("Largeur image: \(Int(imageWidth))").font(.system(size: 10)).foregroundColor(.white)
                                Slider(value: $imageWidth, in: 80...300, step: 5).frame(width: 260).accentColor(.blue)
                            }
                            VStack(spacing: 2) {
                                Text("Hauteur image: \(Int(imageHeight))").font(.system(size: 10)).foregroundColor(.white)
                                Slider(value: $imageHeight, in: 80...200, step: 5).frame(width: 260).accentColor(.blue)
                            }
                            VStack(spacing: 2) {
                                Text("Contraste: \(String(format: "%.1f", imageContrast))").font(.system(size: 10)).foregroundColor(.white)
                                Slider(value: $imageContrast, in: 0.5...2.0, step: 0.1).frame(width: 260).accentColor(.blue)
                            }
                            Divider().background(Color.white.opacity(0.3)).padding(.horizontal, 10)
                            VStack(spacing: 2) {
                                Text("Largeur rectangle: \(Int(rectWidth))").font(.system(size: 10)).foregroundColor(.white)
                                Slider(value: $rectWidth, in: 100...400, step: 10).frame(width: 260).accentColor(.green)
                            }
                            VStack(spacing: 2) {
                                Text("Hauteur rectangle: \(Int(rectHeight))").font(.system(size: 10)).foregroundColor(.white)
                                Slider(value: $rectHeight, in: 80...350, step: 10).frame(width: 260).accentColor(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    // MARK: - Colonne droite
    @ViewBuilder
    func rightColumn() -> some View {
        VStack(spacing: 15) {
            // Titre
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.3)).cornerRadius(12)
                Text("Profil Utilisateur").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            }
            .frame(width: 400, height: 60)
            
            // Identité
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.3)).cornerRadius(12)
                VStack(spacing: 15) {
                    Text("Identité").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
                    HStack(spacing: 20) {
                        dataField(label: "Nom", text: $nomText, width: 140)
                        dataField(label: "Prénom", text: $prenomText, width: 140)
                        Spacer()
                    }.padding(.horizontal, 20)
                }.padding(.vertical, 15)
            }.frame(width: 400, height: 120)
            
            // Date de naissance
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.3)).cornerRadius(12)
                VStack(spacing: 15) {
                    Text("Date de naissance").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
                    HStack(spacing: 15) {
                        VStack(spacing: 4) {
                            Text("Jour").font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                            Picker("Jour", selection: selectedDayBinding) {
                                Text("").tag(nil as Int?)
                                ForEach(1...31, id: \.self) { Text("\($0)").tag($0 as Int?) }
                            }.pickerStyle(.menu).labelsHidden()
                                .frame(width: 60, height: 34).background(Color.white.opacity(0.2)).cornerRadius(8)
                        }
                        VStack(spacing: 4) {
                            Text("Mois").font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                            Picker("Mois", selection: selectedMonthBinding) {
                                Text("").tag(nil as Int?)
                                ForEach(1...12, id: \.self) { Text(monthNames[$0-1]).tag($0 as Int?) }
                            }.pickerStyle(.menu).labelsHidden()
                                .frame(width: 120, height: 34).background(Color.white.opacity(0.2)).cornerRadius(8)
                        }
                        VStack(spacing: 4) {
                            Text("Année").font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                            Picker("Année", selection: selectedYearBinding) {
                                Text("").tag(nil as Int?)
                                ForEach((1960...currentYear).reversed(), id: \.self) { Text("\($0)").tag($0 as Int?) }
                            }.pickerStyle(.menu).labelsHidden()
                                .frame(width: 80, height: 34).background(Color.white.opacity(0.2)).cornerRadius(8)
                        }
                        Spacer()
                    }.padding(.horizontal, 20)
                }.padding(.vertical, 15)
            }.frame(width: 400, height: 120)
            
            // Mesures physiques
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.3)).cornerRadius(12)
                VStack(spacing: 15) {
                    Text("Mesures physiques").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
                    HStack(spacing: 20) {
                        dataField(label: "Poids (kg)", text: $poidsText, width: 100)
                        dataField(label: "Taille (cm)", text: $tailleText, width: 100)
                        Spacer()
                    }.padding(.horizontal, 20)
                }.padding(.vertical, 15)
            }.frame(width: 400, height: 120)
            
            // Fréquences cardiaques
            ZStack {
                Rectangle().fill(Color.blue.opacity(0.3)).cornerRadius(12)
                VStack(spacing: 15) {
                    Text("Fréquences cardiaques").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
                    HStack(spacing: 20) {
                        displayField(label: "FC Max (220 - âge)", value: calculatedAge > 0 ? "\(calculatedFCMax) bpm" : "-", width: 140)
                        dataField(label: "FC Repos (bpm)", text: $fcReposText, width: 100)
                        Spacer()
                    }.padding(.horizontal, 20)
                }.padding(.vertical, 15)
            }.frame(width: 400, height: 120)
            
            Spacer()
        }.padding(.trailing, 10)
    }
    
    // MARK: - Composants réutilisables
    @ViewBuilder
    func dataField(label: String, text: Binding<String>, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .frame(width: width).padding(8)
                .background(Color.white.opacity(0.2)).cornerRadius(8)
                .foregroundColor(.white).font(.system(size: 14))
        }
    }
    
    @ViewBuilder
    func displayField(label: String, value: String, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
            Text(value)
                .frame(width: width, height: 34).padding(.horizontal, 8)
                .background(Color.white.opacity(0.2)).cornerRadius(8)
                .foregroundColor(.yellow).font(.system(size: 14, weight: .bold))
        }
    }
}
