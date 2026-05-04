import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        versionInfo
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
        }
    }
    
    @ViewBuilder
    var versionInfo: some View {
        Text(Bundle.main.fullVersionString)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}


#Preview {
    SettingsView()
}
