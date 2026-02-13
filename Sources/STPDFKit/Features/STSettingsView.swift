import SwiftUI

/// Viewer settings panel
struct STSettingsView: View {

    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                Section("Display") {
                    Label("Scroll Direction", systemImage: "arrow.up.arrow.down")
                    Label("Page Mode", systemImage: "doc.on.doc")
                }

                Section("View") {
                    Label("Page Shadows", systemImage: "shadow")
                    Label("Background Color", systemImage: "paintpalette")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
