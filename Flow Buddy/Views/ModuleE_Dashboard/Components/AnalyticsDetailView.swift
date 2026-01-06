import SwiftUI
import SwiftData

struct AnalyticsDetailView: View {
    @ObservedObject var appState: AppState
    @Query var thoughts: [ThoughtItem]
    @Environment(\.modelContext) private var modelContext
    
    @State private var sessionTimer: Timer? = nil
    @State private var elapsedTime: TimeInterval = 0
    
    private var reminderItems: [ThoughtItem] {
        thoughts.filter { $0.category == .reminder }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if appState.isSessionActive {
                    // MARK: - Ongoing Session View
                    ongoingSessionView
                } else if appState.sessionEndTime != nil {
                    // MARK: - Session Ended View
                    sessionEndedView
                } else {
                    // MARK: - No Session (shouldn't normally appear, splash screen handles this)
                    Text("No active session")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear { startTimerIfNeeded() }
        .onDisappear { stopTimer() }
        .onChange(of: appState.isSessionActive) { _, isActive in
            if isActive {
                startTimerIfNeeded()
            } else {
                stopTimer()
            }
        }
    }
    
    // MARK: - Ongoing Session View
    
    private var ongoingSessionView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Session in Progress")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formattedElapsedTime)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Divider()
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Text("Offloaded Elements")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(thoughts.count)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Text("To stop the session, click the button below")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { appState.stopSession() }) {
                    Label("Stop Session", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
    
    // MARK: - Session Ended View
    
    private var sessionEndedView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Session Complete")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            .padding(.top, 40)
            
            if let startTime = appState.sessionStartTime, let endTime = appState.sessionEndTime {
                VStack(spacing: 12) {
                    HStack {
                        Text("Started:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(startTime, style: .time)
                            .bold()
                    }
                    HStack {
                        Text("Ended:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(endTime, style: .time)
                            .bold()
                    }
                    HStack {
                        Text("Duration:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(endTime.timeIntervalSince(startTime)))
                            .bold()
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Text("Offloaded Elements")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(thoughts.count)")
                        .font(.title)
                        .bold()
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Reminders Section
            if !reminderItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Reminders")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("\(reminderItems.count)")
                            .font(.title)
                            .bold()
                            .foregroundColor(.orange)
                    }
                    
                    ForEach(reminderItems, id: \.id) { reminder in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.text)
                                    .font(.body)
                                    .lineLimit(2)
                                Text(reminder.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Text("The session has ended. You can now browse your offloaded tasks and take screenshots of them, if you want.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                
                
                Button(action: { finishAndClear() }) {
                    Label("Finish", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Text("After clicking Finish, all offloaded items will be deleted.")
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    // MARK: - Timer Logic
    
    private func startTimerIfNeeded() {
        guard appState.isSessionActive, let startTime = appState.sessionStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private var formattedElapsedTime: String {
        formatDuration(elapsedTime)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Finish Action
    
    private func finishAndClear() {
        // Delete all thoughts
        for thought in thoughts {
            modelContext.delete(thought)
        }
        try? modelContext.save()
        
        // Reset session state
        appState.finishSession()
    }
}
