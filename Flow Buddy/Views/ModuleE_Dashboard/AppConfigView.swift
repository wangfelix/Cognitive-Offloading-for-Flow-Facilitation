import SwiftUI

struct AppConfigView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        Form {
            Section {
                Toggle("Distraction Detection", isOn: $appState.isDistractionDetectionEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            } header: {
                Text("AI Distraction Detection")
            } footer: {
                Text("When enabled, Flow Buddy will periodically analyze your screen to help you stay focused.")
            }
            
            Section {
                Toggle("Automatic Background Research", isOn: $appState.isBackgroundResearchEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            } footer: {
                Text("When enabled, Flow Buddy will automatically generate a research report for every new thought you capture.")
            }
            
            Section {
                Slider(
                    value: intervalSliderBinding,
                    in: 0...Double(availableIntervals.count - 1),
                    step: 1
                ) {
                    Text("Monitoring Interval: \(formatInterval(appState.monitoringInterval))")
                }
            } footer: {
                Text("Shorter intervals provide more accurate detection but may use more battery. Additionally, shorter intervals drastically increase CPU load and can lead to olama server overload.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App Config")
        .padding()
    }
    
    private let availableIntervals: [TimeInterval] = [5, 10, 15, 20, 25, 30, 60]
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        if interval >= 60 {
            return "1 min"
        } else {
            return "\(Int(interval))s"
        }
    }
    
    private var intervalSliderBinding: Binding<Double> {
        Binding<Double>(
            get: {
                Double(availableIntervals.firstIndex(of: appState.monitoringInterval) ?? 3)
            },
            set: {
                let index = Int($0)
                if index >= 0 && index < availableIntervals.count {
                    appState.monitoringInterval = availableIntervals[index]
                }
            }
        )
    }
}
