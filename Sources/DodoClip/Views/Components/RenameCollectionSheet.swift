import SwiftUI

/// Sheet for renaming a collection
struct RenameCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName: String
    
    let originalName: String
    let onRename: (String) -> Void
    
    init(originalName: String, onRename: @escaping (String) -> Void) {
        self.originalName = originalName
        self.onRename = onRename
        _collectionName = State(initialValue: originalName)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Rename Collection")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Collection Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                TextField("Enter name", text: $collectionName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(10)
                    .background(Theme.Colors.searchBackground)
                    .cornerRadius(6)
                    .onAppear {
                        // Auto-focus the text field and select all text when sheet appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button("Rename") {
                    if !collectionName.isEmpty && collectionName != originalName {
                        onRename(collectionName)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(collectionName.isEmpty || collectionName == originalName)
            }
        }
        .padding(24)
        .frame(width: 350, height: 180)
        .background(Theme.Colors.panelBackground)
    }
}

#Preview {
    RenameCollectionSheet(originalName: "My Collection") { newName in
        print("Rename to: \(newName)")
    }
}
