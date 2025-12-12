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
        NavigationSplitView {
            if currentMode == .dashboard {
                List(selection: $selection) {
                    Section("Analytics") {
                        NavigationLink(value: DashboardSelection.analytics) {
                            AnalyticsSidebarRow(appState: appState)
                        }
                    }
                    
                    Section("Inbox") {
                        ForEach(thoughts) { item in
                            NavigationLink(value: DashboardSelection.thought(item)) {
                                ThoughtSidebarRow(item: item)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 250)
                .navigationTitle("")
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
