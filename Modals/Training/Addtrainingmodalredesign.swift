import SwiftUI

// ✅ Wrapper qui relie ContentView à votre modal existant
struct Addtrainingmodalredesign: View {
    @Binding var isPresented: Bool

    var body: some View {
        AddTrainingModal(isPresented: $isPresented)
    }
}
