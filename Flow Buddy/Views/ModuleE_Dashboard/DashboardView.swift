import SwiftUI
import SwiftData

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
    
    var body: some View {
        NavigationSplitView {
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
            .listStyle(.sidebar) // This gives the proper transparent sidebar look
            .navigationTitle("Flow Buddy")
            .toolbar {
                ToolbarItem {
                    Button(action: { appState.isCaptureInterfaceOpen.toggle() }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
        } detail: {
            switch selection {
            case .analytics:
                AnalyticsDetailView(appState: appState)
            case .thought(let item):
                ThoughtDetailView(item: item)
            case nil:
                Text("Select an item to view details")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Sidebar Components

struct AnalyticsSidebarRow: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Flow Score").font(.caption)
                Text("\(Int(appState.flowScore))").font(.title2).bold().foregroundColor(.cyan)
            }
            Spacer()
            // Simple graph
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<8) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cyan.opacity(0.6))
                        .frame(width: 4, height: CGFloat.random(in: 10...20))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThoughtSidebarRow: View {
    let item: ThoughtItem
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill").font(.caption2).foregroundColor(.cyan)
            VStack(alignment: .leading) {
                Text(item.text).fontWeight(.medium).lineLimit(1)
                Text(item.categoryRaw).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Detail Views

struct AnalyticsDetailView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Today's Flow")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(Int(appState.flowScore))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                    Text("Excellent focus level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.title2)
                        .bold()
                    
                    Text("Detailed usage graphs and reports will appear here.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ThoughtDetailView: View {
    let item: ThoughtItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(item.categoryRaw.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .cornerRadius(6)
                    Spacer()
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(item.text)
                    .font(.title)
                    .textSelection(.enabled)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Actions")
                        .font(.headline)
                    
                    Button("Generate Report") {
                        // Placeholder for agent action
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
