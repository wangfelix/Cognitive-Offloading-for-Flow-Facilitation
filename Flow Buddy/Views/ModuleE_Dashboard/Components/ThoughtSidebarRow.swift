import SwiftUI

struct ThoughtSidebarRow: View {
    let item: ThoughtItem
    
    var body: some View {
        HStack {
            if !item.hasBeenOpened {
                Image(systemName: "circle.fill").font(.caption2).foregroundColor(.cyan)
            }

            VStack(alignment: .leading) {
                Text(item.text).fontWeight(.medium).lineLimit(1)
                Text(item.categoryRaw).font(.caption).foregroundColor(.secondary)
            }
            .padding(.leading, !item.hasBeenOpened ? 0 : 21)
        }
    }
}
