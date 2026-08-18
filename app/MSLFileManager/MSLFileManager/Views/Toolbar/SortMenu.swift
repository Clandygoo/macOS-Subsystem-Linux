import SwiftUI

struct SortMenu: View {
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    viewModel.toggleSort(for: option)
                } label: {
                    HStack {
                        Text(option.displayName)
                        if viewModel.sortOption == option {
                            Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                        }
                    }
                }
            }

            Divider()

            Button {
                viewModel.showHiddenFiles.toggle()
            } label: {
                HStack {
                    Text("Show Hidden Files")
                    if viewModel.showHiddenFiles {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
