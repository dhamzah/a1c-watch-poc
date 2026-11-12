import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        NavigationStack {
            GlanceView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { A1CWordmark() }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { state.showSettings = true } label: { Image(systemName: "gearshape").foregroundStyle(A1CColor.ultraWhite) }
                    }
                }
        }
        .sheet(item: $state.activeAlert) { a in AlertCard(alert: a) }
        .sheet(isPresented: $state.showVoice) { VoiceLogView() }
        .sheet(isPresented: $state.showRecap) { RecapView() }
        .sheet(isPresented: $state.showSettings) { SettingsView() }
        .sheet(isPresented: $state.showComplications) { ComplicationsPreview() }
        .task {
            await state.refresh()
        }
    }
}
