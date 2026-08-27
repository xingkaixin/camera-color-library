import ColorKit
import SwiftUI

@main
struct ColorLibraryApp: App {
    @State private var library: LibraryStore

    init() {
        var directory = URL.documentsDirectory.appendingPathComponent("ColorLibrary", isDirectory: true)
        #if DEBUG
        if let testSession = ProcessInfo.processInfo.environment["COLOR_LIBRARY_TEST_SESSION"],
           let id = UUID(uuidString: testSession) {
            directory = URL.documentsDirectory.appendingPathComponent("UITests/" + id.uuidString)
        }
        #endif
        _library = State(initialValue: LibraryStore(directory: directory))
    }

    var body: some Scene {
        WindowGroup {
            LibraryHomeView()
                .environment(library)
                .tint(Theme.olive)
                .preferredColorScheme(.light)
        }
    }
}
