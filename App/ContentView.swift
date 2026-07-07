import SwiftUI

struct ContentView: View {
    @State private var auth = AuthModel()

    var body: some View {
        Group {
            switch auth.phase {
            case .loading:
                LoadingView()
            case .signedOut, .awaitingCode:
                LoginView(auth: auth)
            case .signedIn:
                SessionHomeView(auth: auth)
            }
        }
        .animation(.smooth, value: auth.phase)
        .tint(.accentColor)
    }
}

private struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ProgressView()
        }
    }
}
