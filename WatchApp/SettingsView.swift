import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var source = SharedStore.source
    @State private var key = SharedStore.sallyKey

    var body: some View {
        Form {
            Picker("Data", selection: $source) {
                ForEach(DataSource.allCases) { Text($0.rawValue).tag($0) }
            }
            if source == .sally {
                SecureField("Sally API key", text: $key)
                Text("POC only. Production uses A1C account sign-in.").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Section("Alerts") {
                LabeledContent("Rising/falling", value: "±2 mg/dL/min")
                LabeledContent("Spike", value: "+30 in 60 min")
                LabeledContent("Target", value: "70–140")
            }
            Button("Preview complications") { state.showSettings = false; state.showComplications = true }
            Button("Spike recap") { state.showSettings = false; state.showRecap = true }
        }
        .onChange(of: source) { _, v in SharedStore.source = v; Task { await state.refresh() } }
        .onChange(of: key) { _, v in SharedStore.sallyKey = v }
    }
}
