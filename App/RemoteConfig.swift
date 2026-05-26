import SwiftUI
import WebKit

// Build worker substitutes the URL here automatically. Leave empty by default.
let REMOTE_CONFIG_URL = ""

// MARK: - Launch gate
/// When `REMOTE_CONFIG_URL` is empty the native app shows immediately.
/// Otherwise a full-screen web view is loaded; any failure falls back to native.
struct RootView: View {
    var body: some View {
        if REMOTE_CONFIG_URL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            MainTabView()
        } else {
            RemoteGateView(urlString: REMOTE_CONFIG_URL)
        }
    }
}

private enum GateState { case loading, web, fallback }

private struct RemoteGateView: View {
    let urlString: String
    @StateObject private var loader = WebLoader()

    var body: some View {
        ZStack {
            switch loader.state {
            case .fallback:
                MainTabView()
            case .loading:
                neutralLoading
            case .web:
                EmptyView()
            }

            if loader.state != .fallback {
                RemoteWebView(loader: loader)
                    .opacity(loader.state == .web ? 1 : 0)
                    .ignoresSafeArea()
            }
        }
        .onAppear { loader.start(urlString) }
    }

    private var neutralLoading: some View {
        ZStack {
            Color(hex: "0B0F1A").ignoresSafeArea()
            ProgressView().tint(.white.opacity(0.6))
        }
    }
}

// MARK: - Web loader / navigation delegate
final class WebLoader: NSObject, ObservableObject, WKNavigationDelegate {
    @Published fileprivate var state: GateState = .loading
    private weak var webView: WKWebView?
    private var timeout: DispatchWorkItem?
    private var didDecide = false
    private var pendingURL: URL?
    private var started = false

    func attach(_ webView: WKWebView) {
        self.webView = webView
        if let url = pendingURL { webView.load(URLRequest(url: url)); pendingURL = nil }
    }

    func start(_ urlString: String) {
        guard !started else { return }
        started = true
        guard let url = URL(string: urlString) else { decide(.fallback); return }
        let work = DispatchWorkItem { [weak self] in self?.decide(.fallback) }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
        if let webView { webView.load(URLRequest(url: url)) } else { pendingURL = url }
    }

    private func decide(_ newState: GateState) {
        guard !didDecide else { return }
        didDecide = true
        timeout?.cancel()
        DispatchQueue.main.async { self.state = newState }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame,
           let http = navigationResponse.response as? HTTPURLResponse,
           http.statusCode >= 400 {
            decisionHandler(.cancel)
            decide(.fallback)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        decide(.web)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        decide(.fallback)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        decide(.fallback)
    }
}

// MARK: - WKWebView wrapper
private struct RemoteWebView: UIViewRepresentable {
    let loader: WebLoader

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsInlineMediaPlayback = true
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = loader
        web.uiDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        loader.attach(web)
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    // Open pop-ups (target=_blank) in the same web view.
    final class Coordinator: NSObject, WKUIDelegate {
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url, navigationAction.targetFrame == nil {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
