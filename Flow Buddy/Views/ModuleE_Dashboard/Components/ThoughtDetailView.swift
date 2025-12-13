import SwiftUI
import LaTeXSwiftUI

struct ThoughtDetailView: View {
    let item: ThoughtItem
    @State private var isAnalyzing = false
    private let researchService = BackgroundResearchService()
    
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
                    
                    if item.inferenceReport == nil {
                        Button("Generate Report") {
                            Task {
                                isAnalyzing = true
                                do {
                                    let result = try await researchService.performResearch(for: item.text)
                                    print("Research Result: \(result)")
                                    
                                    // Save to model
                                    item.inferenceReport = result
                                } catch {
                                    print("Research Failed: \(error)")
                                    // Handle error gracefully
                                }
                                isAnalyzing = false
                            }
                        }
                        .disabled(isAnalyzing)
                        .buttonStyle(.bordered)
                    }
                }
                
                if isAnalyzing {
                    ProgressView("Analyzing...")
                        .padding()
                }
                
                if let result = item.inferenceReport {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Research Report: \(result.topic)")
                            .font(.headline)
                        
                        Text(result.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        LaTeX(result.details)
                            .id(result.details)
                        
                        if !result.actionItems.isEmpty {
                            Divider()
                            Text("Action Items")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            ForEach(result.actionItems, id: \.self) { item in
                                Link(destination: URL(string: item) ?? URL(string: "https://google.com")!) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text(item)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        .onChange(of: item.id) {
            isAnalyzing = false
        }
        
    }
    
}
