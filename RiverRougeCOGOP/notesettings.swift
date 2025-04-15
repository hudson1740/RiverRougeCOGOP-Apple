import SwiftUI

struct NoteSettings: View {
    @Binding var useRandomColors: Bool
    @Binding var staticColor: Color
    @Environment(\.dismiss) var dismiss
    
    private let availableColors: [(name: String, color: Color)] = [
        ("Red", .red),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", Color(hex: "800080")),
        ("Pink", Color(hex: "FF33FF")),
        ("Gray", .gray)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Appearance")) {
                    Toggle("Use Random Background Colors", isOn: $useRandomColors)
                    
                    if !useRandomColors {
                        Picker("Static Color", selection: $staticColor) {
                            ForEach(availableColors, id: \.color) { colorOption in
                                HStack {
                                    Circle()
                                        .fill(colorOption.color)
                                        .frame(width: 20, height: 20)
                                    Text(colorOption.name)
                                }
                                .tag(colorOption.color)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Note Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct NoteSettings_Previews: PreviewProvider {
    static var previews: some View {
        NoteSettings(useRandomColors: .constant(true), staticColor: .constant(.blue))
    }
}
