import SwiftUI

struct AddTrainingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showQuitAlert = false
    
    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            HStack(spacing: 10) {
                sideMenu
                mainContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
        .alert("Êtes-vous sûr de vouloir quitter l'application ?",
               isPresented: $showQuitAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Quitter", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text("Vous perdrez votre navigation actuelle.")
        }
    }
    
    // MARK: - Side menu
    private var sideMenu: some View {
        VStack(spacing: 20) {
            Button(action: { dismiss() }) {
                VStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                    Text("Menu")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.18))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: TrainingsListView()) {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 24))
                    Text("Mes Entr.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.18))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text("Ajouter")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.4))
            .frame(width: 80, height: 80)
            .background(Color.green.opacity(0.15))
            .cornerRadius(12)
            
            NavigationLink(destination: StatisticsView()) {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24))
                    Text("Stats")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.purple.opacity(0.25))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { showQuitAlert = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                    Text("Quitter")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.red.opacity(0.25))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 20)
        .frame(width: 100)
    }
    
    // MARK: - Main content
    private var mainContent: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Page Ajouter")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Utilisez le bouton Ajouter du menu principal")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AddTrainingView()
        .frame(minWidth: 800, minHeight: 600)
}

