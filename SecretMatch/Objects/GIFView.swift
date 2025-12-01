import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isUserInteractionEnabled = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            print("❌ GIF \(name).gif nicht gefunden")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let base64 = data.base64EncodedString()
            let html = """
            <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { margin: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
                        img { max-width: 100%; height: auto; }
                    </style>
                </head>
                <body>
                    <img src="data:image/gif;base64,\(base64)" />
                </body>
            </html>
            """
            uiView.loadHTMLString(html, baseURL: nil)
        } catch {
            print("❌ Fehler beim Laden von \(name).gif: \(error.localizedDescription)")
        }
    }
}
