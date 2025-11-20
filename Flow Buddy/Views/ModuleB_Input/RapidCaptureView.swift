import SwiftUI
import SwiftData

struct RapidCaptureView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.and.scribble")
                .font(.title2)
                .foregroundColor(.secondary)
            
            TextField("Offload thought...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.title2)
                .focused($isFocused) // Binds focus to state
                .onSubmit { submitThought() }
            
            Button(action: { }) {
                Image(systemName: "mic.fill")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(20)
        .glassEffect(in: Capsule())
        .shadow(radius: 10)
        .frame(width: 600)
        .onAppear {
            // Force focus when window appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        // Listen for Escape key
        .background(
            Button("") {
                appState.isCaptureInterfaceOpen = false
            }
            .keyboardShortcut(.escape, modifiers: [])
            .hidden()
        )
        .padding(35)
    }
    
    func submitThought() {
        guard !inputText.isEmpty else { return }
        let category: ThoughtCategory = inputText.lowercased().contains("remind") ? .reminder : .research
        modelContext.insert(ThoughtItem(text: inputText, category: category))
        inputText = ""
        appState.isCaptureInterfaceOpen = false
    }
}

