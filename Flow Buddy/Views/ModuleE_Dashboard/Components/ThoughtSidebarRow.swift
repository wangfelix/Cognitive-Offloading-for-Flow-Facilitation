import SwiftUI

struct ThoughtSidebarRow: View {
    let item: ThoughtItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.text).fontWeight(.medium).lineLimit(1)
                Text(item.categoryRaw).font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, !item.hasBeenOpened ? 0 : 0)
            .padding(.trailing, !item.hasBeenOpened ? 0 : 21)
            
            if !item.hasBeenOpened {
                Image(systemName: "circle.fill").font(.caption2).foregroundColor(.cyan)
            }
            
        }
    }
}
