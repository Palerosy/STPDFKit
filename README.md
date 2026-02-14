# STPDFKit

SwiftUI-native PDF Editor SDK for iOS.

## Requirements

- iOS 16+
- Xcode 15+
- Swift 5.9+

## Installation

### Swift Package Manager

Add STPDFKit to your project via Xcode:

1. **File > Add Package Dependencies...**
2. Enter: `https://github.com/Palerosy/STPDFKit`
3. Select version `0.1.0` or later

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Palerosy/STPDFKit", from: "0.1.0")
]
```

## Quick Start

```swift
import SwiftUI
import STPDFKit

struct ContentView: View {
    var body: some View {
        STPDFEditorView(
            url: pdfURL,
            title: "My Document"
        )
    }
}
```

## Features

- Full PDF viewing and editing
- 16+ annotation tools (ink, text, shapes, signatures, stamps, photos)
- Page editing (add, delete, rotate, reorder)
- Text search and extraction
- Bookmarks and outline navigation
- Undo/redo support
- 16 languages supported
- Fully customizable appearance and toolbar

## License

Commercial license required. Contact for details.
