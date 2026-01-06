import SwiftUI

struct AnalyticsSidebarRow: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            Image(systemName: "house")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(appState.isSessionActive ? .green : .secondary)
            
            VStack(alignment: .leading) {
                Text(appState.isSessionActive ? "Session Active" : "Session Overview")
                    .font(.title3)
                    .bold()
                    .foregroundColor(appState.isSessionActive ? .green : .secondary)
            }
            Spacer()
            if appState.isSessionActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
}
