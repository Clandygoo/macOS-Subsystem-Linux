import SwiftUI

struct ViewModePicker: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Picker("View Mode", selection: $state.selectedViewMode) {
            ForEach(ViewMode.allCases) { mode in
                Button {
                    state.selectedViewMode = mode
                } label: {
                    Label(mode.displayName, systemImage: mode.iconName)
                }
                .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
    }
}
