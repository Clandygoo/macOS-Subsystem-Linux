import SwiftUI

struct ViewModePicker: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ViewModePickerContent(state: state)
    }
}

struct ViewModePickerContent: View {
    @ObservedObject var state: AppState

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
