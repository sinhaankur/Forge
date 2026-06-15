import SwiftUI
import SwiftData

/// "Care" hub — groups Skincare and Nutrition so the tab bar stays at a clean 5
/// tabs (Today · Fitness · Sleep · Care · Progress). A simple segmented switch.
struct CareView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case nutrition = "Nutrition"
        case skincare = "Skincare"
        var id: String { rawValue }
    }
    @State private var tab: Tab = .nutrition

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 4)

                switch tab {
                case .nutrition: NutritionView().toolbar(.hidden, for: .navigationBar)
                case .skincare:  RoutineListView(kind: .skincare).toolbar(.hidden, for: .navigationBar)
                }
            }
            .background(GlowTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}
