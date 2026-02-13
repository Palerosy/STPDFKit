import SwiftUI

/// Bottom toolbar with page navigation and feature buttons
struct STBottomBar: View {

    @ObservedObject var viewModel: STPDFEditorViewModel
    @ObservedObject var bookmarkManager: STBookmarkManager

    var body: some View {
        HStack {
            Spacer()

            // Thumbnails
            if viewModel.configuration.showThumbnails {
                bottomButton(icon: "rectangle.grid.2x2", label: "Pages") {
                    viewModel.viewerViewModel.isThumbnailGridVisible = true
                }
            }

            Spacer()

            // Bookmarks
            if viewModel.configuration.showBookmarks {
                bottomButton(
                    icon: bookmarkManager.isBookmarked(viewModel.viewerViewModel.currentPageIndex)
                        ? "bookmark.fill" : "bookmark",
                    label: "Bookmark"
                ) {
                    bookmarkManager.toggleBookmark(viewModel.viewerViewModel.currentPageIndex)
                }
            }

            Spacer()

            // Search
            if viewModel.configuration.showSearch {
                bottomButton(icon: "magnifyingglass", label: "Search") {
                    viewModel.viewerViewModel.isSearchVisible = true
                }
            }

            Spacer()

            // Settings
            if viewModel.configuration.showSettings {
                bottomButton(icon: "gearshape", label: "Settings") {
                    viewModel.viewerViewModel.isSettingsVisible = true
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }

    private func bottomButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(.accentColor)
        }
    }
}
