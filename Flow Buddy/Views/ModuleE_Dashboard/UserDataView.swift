import SwiftUI

struct UserDataView: View {
    var body: some View {
        ContentUnavailableView("User Data", systemImage: "person.text.rectangle", description: Text("Provide context for the LLM generation here. (ToDo)"))
            .navigationTitle("User Data")
    }
}
