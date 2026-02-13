import SwiftUI
import PDFKit

/// View for placing a free text annotation on the PDF
struct STTextInputOverlay: View {
    
    let onSubmit: (_ text: String, _ screenPoint: CGPoint) -> Void
    let onCancel: () -> Void
    
    @State private var text = ""
    @State private var tapLocation: CGPoint? = nil
    @State private var isEditing = false
    
    var body: some View {
        ZStack {
            // Tap capture layer
            if !isEditing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        tapLocation = location
                        isEditing = true
                    }
            }
            
            // Text input popup
            if isEditing, let location = tapLocation {
                VStack(spacing: 8) {
                    TextField("Enter text...", text: $text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 250)
                        .lineLimit(1...5)
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            text = ""
                            isEditing = false
                            tapLocation = nil
                            onCancel()
                        }
                        .foregroundColor(.secondary)
                        
                        Button("Add") {
                            if !text.isEmpty {
                                onSubmit(text, location)
                            }
                            text = ""
                            isEditing = false
                            tapLocation = nil
                        }
                        .fontWeight(.semibold)
                        .disabled(text.isEmpty)
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)
                .position(x: min(max(location.x, 140), UIScreen.main.bounds.width - 140),
                          y: max(location.y - 80, 80))
            }
        }
    }
}
