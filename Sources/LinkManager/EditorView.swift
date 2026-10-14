import SwiftUI
import AppKit

struct EditorView: View {
    @ObservedObject var store: LinkStore

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach($store.links) { $link in
                    HStack(spacing: 8) {
                        Image(nsImage: IconProvider.icon(for: link.target, side: 20))
                            .id(store.iconRevision)
                            .frame(width: 20, height: 20)
                        TextField("Title", text: $link.title)
                            .frame(width: 150)
                        TextField("URL, app name or file path", text: $link.target)
                        Button("Choose…") { choose(for: $link) }
                        Button(role: .destructive) {
                            store.links.removeAll { $0.id == link.id }
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
                .onMove { store.links.move(fromOffsets: $0, toOffset: $1) }
            }
            Divider()
            HStack {
                Button { store.links.append(Link()) } label: { Label("Add Link", systemImage: "plus") }
                Spacer()
                Text("Drag rows to reorder. Changes save automatically.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .frame(minWidth: 620, minHeight: 360)
    }

    private func choose(for link: Binding<Link>) {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        link.wrappedValue.target = url.path
        if link.wrappedValue.title.isEmpty {
            link.wrappedValue.title = url.deletingPathExtension().lastPathComponent
        }
    }
}
