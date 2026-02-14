import SwiftUI

/// Viewer settings panel
struct STSettingsView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(STStrings.display) {
                    Label(STStrings.scrollDirection, systemImage: "arrow.up.arrow.down")
                    Label(STStrings.pageMode, systemImage: "doc.on.doc")
                }

                Section(STStrings.view) {
                    Label(STStrings.pageShadows, systemImage: "shadow")
                    Label(STStrings.backgroundColor, systemImage: "paintpalette")
                }
            }
            .navigationTitle(STStrings.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(STStrings.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}
