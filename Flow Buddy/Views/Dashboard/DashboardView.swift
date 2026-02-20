import SwiftUI
import SwiftData

enum AppMode {
    case dashboard
    case settings
}

enum SettingsSelection: Hashable {
    case userData
    case appConfig
}

// Define selection type for the Sidebar
enum DashboardSelection: Hashable {
    case analytics
    case thought(ThoughtItem)
    
    static func == (lhs: DashboardSelection, rhs: DashboardSelection) -> Bool {
        switch (lhs, rhs) {
        case (.analytics, .analytics): return true
        case (.thought(let t1), .thought(let t2)): return t1.id == t2.id
        default: return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .analytics:
            hasher.combine(0)
        case .thought(let item):
            hasher.combine(1)
            hasher.combine(item.id)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Query(sort: \ThoughtItem.timestamp, order: .reverse) var thoughts: [ThoughtItem]
    
    @State private var selection: DashboardSelection? = .analytics
    @State private var settingsSelection: SettingsSelection? = .userData
    @State private var currentMode: AppMode = .dashboard
    
    var body: some View {
        Group {
            if !appState.isSessionActive && appState.sessionEndTime == nil {
                // MARK: - Splash Screen
                splashScreenView
            } else {
                // MARK: - Main Dashboard
                mainDashboardView
            }
        }
    }
    
    // MARK: - Splash Screen
    
    private var splashScreenView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.cyan)
                
                Text("Flow Buddy")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                
                Text("Offload your cognitive load and stay focused")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Text("This application is designed to help you get into a flow state during knowledge work by offloading your cognitive load. If you experience any mind wandering, distractions, or thoughts not related to your current task at hand, Flow Buddy will help you capture them and keep you focused.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            
            // Keyboard Shortcut Tutorial
            VStack(spacing: 12) {
                Text("Triggering the Capture Interface")
                    .font(.headline)
                    .foregroundColor(.primary)
                

                HStack (spacing: 12) {
                    VStack(spacing: 12) {
                        Text("Press this shortcut anytime to quickly capture a thought.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            KeyCapView(symbol: "⇧")
                            KeyCapView(symbol: "⌘")
                            KeyCapView(symbol: ".")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.highlightColor).opacity(0.1))
                    )

                    
                    VStack(spacing: 12) {
                        Text("Or, click on the bubble to trigger the interface.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundStyle(.primary.opacity(0.8)) // Slightly softer icon
                            .padding(16)
                            .contentShape(Circle()) // Ensures the tap area is the whole circle, not just the icon
                            .background {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.4))
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.highlightColor).opacity(0.1))
                    )

                    
                }
                .frame(maxWidth: 600)
                .fixedSize(horizontal: true, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(16)
            
            Button(action: { appState.startSession() }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    Text("Start Session")
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(Color.cyan)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .padding(.top, 30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Main Dashboard View
    
    private var mainDashboardView: some View {
        NavigationSplitView {
            if currentMode == .dashboard {
                List(selection: $selection) {
                    Section("Analytics") {
                        NavigationLink(value: DashboardSelection.analytics) {
                            AnalyticsSidebarRow(appState: appState)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Section("Inbox") {
                        ForEach(thoughts) { item in
                            NavigationLink(value: DashboardSelection.thought(item)) {
                                ThoughtSidebarRow(item: item)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
                .frame(minWidth: 250)
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem {
                        Button(action: { appState.isCaptureInterfaceOpen.toggle() }) {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
            } else {
                List(selection: $settingsSelection) {
                    Section("Settings") {
                        NavigationLink(value: SettingsSelection.userData) {
                            Label("User Data", systemImage: "person.circle")
                        }
                        NavigationLink(value: SettingsSelection.appConfig) {
                            Label("App Config", systemImage: "gearshape.2")
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 250)
                .navigationTitle("Settings")
            }
        } detail: {
            Group {
                if currentMode == .dashboard {
                    switch selection {
                    case .analytics:
                        AnalyticsDetailView(appState: appState)
                            .background(Color.blue.opacity(0.3))
                    case .thought(let item):
                        ThoughtDetailView(item: item)
                    case nil:
                        Text("Select an item in Flow Buddy")
                            .foregroundColor(.secondary)
                    }
                } else {
                    switch settingsSelection {
                    case .userData:
                        UserDataView()
                    case .appConfig:
                        AppConfigView(appState: appState)
                    case nil:
                        Text("Select a setting")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Spacer()
                }
                if appState.isSessionActive {
                    ToolbarItem {
                        Button(action: {
                            appState.stopSession()
                            selection = .analytics
                            currentMode = .dashboard
                        }) {
                            Label("Stop Session", systemImage: "stop.circle")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                }
                ToolbarItem {
                    Spacer()
                }
                 ToolbarItem {
                     Button(action: {
                         withAnimation {
                             currentMode = (currentMode == .dashboard) ? .settings : .dashboard
                         }
                     }) {
                         Label("Settings", systemImage: (currentMode == .dashboard) ? "gear" : "xmark.circle")
                     }
                 }
            }
        }
        .onChange(of: selection) { _, newSelection in
            if case .thought(let item) = newSelection {
                item.hasBeenOpened = true
            }
        }
    }
}

// MARK: - KeyCap View for Keyboard Shortcuts

struct KeyCapView: View {
    let symbol: String
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .frame(minWidth: 36, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
    }
}
