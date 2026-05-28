import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            BoardView()
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    var body: some View {
        List {
            Label("Projects", systemImage: "folder")
        }
        .listStyle(.sidebar)
        .navigationTitle("aria")
    }
}

// MARK: - Board
struct BoardView: View {
    let columns = ColumnID.allCases

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(columns, id: \.self) { col in
                    ColumnView(columnId: col)
                }
            }
            .padding()
        }
        .navigationTitle("Board")
    }
}

// MARK: - Column
struct ColumnView: View {
    let columnId: ColumnID

    var title: String {
        columnId.rawValue
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 8)

            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(minWidth: 240, maxWidth: 240, minHeight: 400)
                .overlay(alignment: .top) {
                    Text("No tickets")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding(.top, 16)
                }
        }
    }
}
