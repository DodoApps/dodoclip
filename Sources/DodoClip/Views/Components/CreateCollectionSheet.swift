import SwiftUI

/// Sheet for creating a new custom collection
struct CreateCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionName: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColor: String = "#007AFF"
    
    let onCreate: (String, String, String) -> Void
    
    private let availableIcons = [
        "folder", "star", "heart", "bookmark", "tag",
        "flag", "paperclip", "doc", "tray", "archivebox"
    ]
    
    private let availableColors = [
        "#007AFF", "#5AC8FA", "#34C759", "#FF9500",
        "#FF2D55", "#AF52DE", "#FF3B30", "#FFD60A"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(L10n.Collection.create)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Collection.name)
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
                        // Auto-focus the text field when sheet appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }
            }
            
            // Icon selector
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Collection.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedIcon == icon ? .white : Theme.Colors.textSecondary)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Theme.Colors.accent : Theme.Colors.searchBackground)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color selector
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Collection.color)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(availableColors, id: \.self) { colorHex in
                        Button {
                            selectedColor = colorHex
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: selectedColor == colorHex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
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
                
                Button("Create") {
                    if !collectionName.isEmpty {
                        onCreate(collectionName, selectedIcon, selectedColor)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(collectionName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400, height: 450)
        .background(Theme.Colors.panelBackground)
    }
}

#Preview {
    CreateCollectionSheet { name, icon, color in
        print("Create: \(name), \(icon), \(color)")
    }
}
