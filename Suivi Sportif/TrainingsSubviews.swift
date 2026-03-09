import SwiftUI

struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct HeaderTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 16)
    }
}

struct SideMenu: View {
    let dismiss: DismissAction
    @Binding var showAddModal: Bool
    @Binding var showQuitAlert: Bool

    var body: some View {
        VStack(spacing: 20) {

            menuButton("house.fill", "Menu") { dismiss() }

            menuButton("plus.circle.fill", "Ajouter") {
                showAddModal = true
            }

            Spacer()

            menuButton("xmark.circle.fill", "Quitter") {
                showQuitAlert = true
            }
        }
        .frame(width: 100)
        .padding(.top, 20)
    }

    private func menuButton(
        _ icon: String,
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24))
                Text(title).font(.system(size: 12))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Rechercher…", text: $text)
        }
        .padding(8)
        .background(Color.white.opacity(0.18))
        .cornerRadius(8)
        .foregroundColor(.white)
        .frame(width: 260)
    }
}

struct SportPicker: View {
    let sports: [String]
    @Binding var selectedSport: String

    var body: some View {
        Picker("Sport", selection: $selectedSport) {
            ForEach(sports, id: \.self) {
                Text($0)
            }
        }
        .pickerStyle(.menu)
        .padding(6)
        .background(Color.white.opacity(0.18))
        .cornerRadius(8)
    }
}

