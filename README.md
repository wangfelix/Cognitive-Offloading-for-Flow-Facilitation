# Flow Buddy

> **Agentic Cognitive Offloading for Flow Facilitation in Knowledge Work**

Flow Buddy is a minimal, unobtrusive macOS menu-bar application that enables rapid capture of distracting thoughts during knowledge work and autonomously processes them into structured reminders or research tasks augmented with LLM-generated reports.
It is designed to support *flow experiences*, which describe a state of complete immersion and effortless concentration, by reducing the cognitive burden of task-unrelated thoughts without disrupting ongoing work.

---

## Motivation

Knowledge workers frequently experience distracting thoughts that fragment attention and disrupt flow states. While cognitive offloading (externalizing thoughts to free working memory) is a known strategy, conventional methods such as opening a notes app or typing out detailed reminders introduce friction that can itself break flow.

Flow Buddy addresses this by providing:

- **Frictionless capture**: A Spotlight-like input bar invoked via a global shortcut, instantly dismissed after submission.
- **Agentic processing**: Captured thoughts are autonomously classified as *reminders* or *research items* and, for research items, enriched with LLM-generated reports—all without further user involvement.
- **Two-phase design**: Minimal interaction during focused work; rich review after the session ends.

---

## Features

### Capture Phase (During Work)

| Component | Description |
|---|---|
| **Rapid Capture Bar** | A floating text field (⇧⌘.) for externalizing thoughts. Appears centered on the active screen and auto-dismisses on submit, restoring focus to the previous application. |
| **Floating Bubble** | A persistent, translucent brain icon that floats above all windows and desktops. Click to open the capture bar. |
| **Auto-Classification** | Each thought is classified as *Reminder* or *Research* via LLM inference (with keyword-based fallback). Users can also manually select a category. |
| **Background Research** | Research items trigger asynchronous LLM-generated reports containing a summary, detailed explanation (with LaTeX support), and relevant links. |

### Review Phase (Post-Session)

| Component | Description |
|---|---|
| **Dashboard** | A sidebar–detail layout listing all offloaded items chronologically with category indicators and read/unread status. |
| **Research Reports** | Full LLM-generated reports rendered with LaTeX support for mathematical content and clickable action-item links. |
| **Session End Screen** | Displays session duration, total offloaded items, and a consolidated reminder list to surface delayed intentions at the right moment. |
| **Session Management** | Start/stop sessions from the dashboard; all items are cleared on session finish. |

---

## Architecture

```
Flow Buddy/
├── App/
│   ├── AppDelegate.swift        # Window management, status bar, global shortcut
│   └── AppState.swift           # Shared observable state, session & monitoring logic
├── Models/
│   ├── ThoughtItem.swift        # SwiftData model for offloaded thoughts
│   ├── ThoughtCategory.swift    # Enum: Auto, Research, Reminder
│   └── InferenceResponse.swift  # Struct for LLM report output
├── Services/
│   ├── BackgroundResearchService.swift   # LLM report generation (Blablador API)
│   ├── ReminderDetectionService.swift    # LLM-based reminder vs. research classification
│   └── ScreenAnalysisService.swift       # Vision-based screen context analysis (Ollama)
├── Views/
│   ├── Bubble/
│   │   └── BubbleView.swift              # Floating bubble with intervention UI
│   ├── RapidCaptureBar/
│   │   └── RapidCaptureView.swift        # Spotlight-like capture interface
│   └── Dashboard/
│       ├── DashboardView.swift           # Main dashboard with sidebar navigation
│       ├── AppConfigView.swift           # App settings
│       ├── UserDataView.swift            # User data settings
│       └── Components/
│           ├── AnalyticsDetailView.swift  # Session timer & post-session summary
│           ├── AnalyticsSidebarRow.swift  # Sidebar row for analytics
│           ├── ThoughtDetailView.swift    # Thought detail with LaTeX report rendering
│           └── ThoughtSidebarRow.swift    # Sidebar row for thought items
├── Types/
│   └── BlabladorTypes.swift     # Request/response types for the Blablador API
├── Utilities/
│   ├── FloatingPanel.swift      # Custom NSPanel subclass for floating windows
│   └── GlassEffectFallback.swift # macOS version-safe glass effect modifier
└── Flow_BuddyApp.swift          # App entry point
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | SwiftUI |
| **Data Persistence** | SwiftData (on-device) |
| **LLM Inference** | [Helmholtz Blablador API](https://helmholtz-blablador.fz-juelich.de) (EU-hosted) |
| **Classification Model** | `alias-fast` via Blablador |
| **Report Generation Model** | `alias-large` (Qwen3-VL-32B-Instruct-FP8) via Blablador |
| **Screen Analysis** | Ollama (local, `llama3.2-vision:11b`) |
| **Screen Capture** | ScreenCaptureKit |
| **Global Shortcuts** | Carbon EventHotKey API |
| **LaTeX Rendering** | [LaTeXSwiftUI](https://github.com/colinc86/LaTeXSwiftUI) |

---

## Requirements

- **macOS 14.6** or later
- **Xcode 15+** (for building from source)
- An API token for the [Helmholtz Blablador](https://helmholtz-blablador.fz-juelich.de) service (for classification and report generation)
- *(Optional)* [Ollama](https://ollama.com) running locally with the `llama3.2-vision:11b` model (for screen analysis / distraction detection)

---

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/wangfelix/Cognitive-Offloading-for-Flow-Facilitation.git
   cd Cognitive-Offloading-for-Flow-Facilitation
   ```

2. **Open in Xcode**
   ```bash
   open "Flow Buddy.xcodeproj"
   ```

3. **Configure API credentials**
   Insert your Blablador API keys into the `apiToken` constants in:
   - `Services/BackgroundResearchService.swift`
   - `Services/ReminderDetectionService.swift`

4. **Build & Run**
   Select the `Flow Buddy` scheme and run (⌘R). The app will appear as a menu-bar icon (🌬️).

5. **Grant permissions**
   On first launch, macOS will prompt for **Screen Recording** permission (required for the screen analysis feature).

---

## Usage

| Action | How |
|---|---|
| Open capture bar | Press **⇧⌘.** or click the floating bubble |
| Submit a thought | Type and press **Enter** |
| Dismiss without saving | Press **Escape** |
| Open dashboard | Click *Open Dashboard* on the capture bar, or via the menu-bar icon |
| Start a session | Click *Start Session* on the dashboard splash screen |
| Stop a session | Click *Stop Session* in the dashboard toolbar |

---

## Data Privacy

Flow Buddy is designed with responsible data handling in mind:

- **All offloaded items are stored locally** on-device via SwiftData. No user data is persisted externally.
- **Only the text of the offloaded thought** is transmitted to the LLM service for classification and report generation. No screenshots, application metadata, or contextual information is shared.
- The LLM inference service ([Helmholtz Blablador](https://helmholtz-blablador.fz-juelich.de)) is operated by Forschungszentrum Jülich and hosted **within the European Union**.
- Screen analysis via Ollama runs **entirely locally**.


---

## License

This project is part of academic research. Please refer to the repository for license details.
