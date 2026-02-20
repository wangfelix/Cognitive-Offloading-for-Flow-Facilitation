import SwiftUI
import SwiftData

struct BubbleView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    // Hover state for interaction
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .bottom) {
            // Intervention Box (Module D)
            if let distraction = appState.currentDistraction {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Distraction Detected")
                            .font(.headline)
                    }
                    
                    Text("Are you using \(distraction)?")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true) // Prevents text cutoff
                        .padding(.bottom, 6)
                    
                    HStack {
                        Button("It's Work") { appState.resolveDistraction(isTaskRelated: true) }.controlSize(.large)
                        Button("Research for Me") {
                            let task = ThoughtItem(text: "Agent: Research \(distraction)", category: .research)
                            modelContext.insert(task)
                            appState.resolveDistraction(isTaskRelated: false)
                        }.controlSize(.large)
                    }
                }
                .padding()
                //.background(Material.thick) // Better contrast
                .glassEffectWithFallback(in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .frame(width: 250) // Give it enough width
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // The Bubble Icon
            // We use a ZStack in the background to layer "Physical Blur" + "Pigment"
            Image(systemName: "brain.head.profile")
                .font(.system(size: 24))
                .foregroundStyle(.primary.opacity(0.8)) // Slightly softer icon
                .padding(16)
                .contentShape(Circle()) // Ensures the tap area is the whole circle, not just the icon
                .background {
                    ZStack {
                        // LAYER 1: The Heavy Lifting (Blur & Refraction)
                        // We use a Shape (Circle) with glassEffect so it clips correctly
                        Circle()
                            .circleGlassEffectWithFallback()
                        
                        // LAYER 2: The "Pigment" (The Fix)
                        // We overlay a low-opacity solid color.
                        // This gives the glass "body" even on dark backgrounds.
                        Circle()
                            .fill(Color.blue.opacity(isHovering ? 0.4 : 0.02))
                            .stroke(Color.white.opacity(0.2), lineWidth: 1) // Optional: adds a "rim light"
                    }
                }
                //.glassEffect(.regular.tint(.blue).interactive())
                // Handle Hover for interactivity visualization
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = hovering
                    }
                }
                .onTapGesture {
                    appState.isCaptureInterfaceOpen.toggle()
                }
    
        }
        .padding()
    }
}

