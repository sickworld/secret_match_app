import SwiftUI
import WebKit

struct AdminBillboardView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool

    @State private var billboardURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let billboardURL {
                BillboardWebView(url: billboardURL)
                    .ignoresSafeArea()
            } else if let errorMessage {
                VStack(spacing: 18) {
                    Text("⚠️")
                        .font(.system(size: 48))
                    Text("Billboard konnte nicht geöffnet werden")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(errorMessage)
                        .foregroundStyle(SecretMatchTheme.muted)
                        .multilineTextAlignment(.center)
                    Button("Erneut versuchen") {
                        loadBillboard()
                    }
                    .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
                }
                .padding(32)
            } else {
                ProgressView("Billboard wird geöffnet …")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .font(.headline)
            }

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.black.opacity(0.72))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.28), lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 12)
            }
            .padding(20)
            .accessibilityLabel("Billboard schließen")
        }
        .statusBarHidden()
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .task {
            loadBillboard()
        }
    }

    private func loadBillboard() {
        billboardURL = nil
        errorMessage = nil

        Task {
            do {
                billboardURL = try await api.createBillboardAccessURL()
            } catch {
                errorMessage = "Bitte Admin-Anmeldung und Netzwerkverbindung prüfen."
            }
        }
    }
}

private struct BillboardWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var retryWorkItem: DispatchWorkItem?

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation?
        ) {
            retryWorkItem?.cancel()
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            scheduleRetry(for: webView)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            scheduleRetry(for: webView)
        }

        private func scheduleRetry(for webView: WKWebView) {
            retryWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak webView] in
                webView?.reload()
            }
            retryWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: workItem)
        }
    }
}
