import SwiftUI

struct ViewModePicker: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Picker("View Mode", selection: Binding(
            get: { state.selectedViewMode },
            set: { state.selectedViewMode = $0 }
        )) {
            ForEach(ViewMode.allCases) { mode in
                Label(mode.displayName, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
    }
}
