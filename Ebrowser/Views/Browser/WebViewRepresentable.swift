import SwiftUI
import WebKit
import SwiftData

/// WKWebView を SwiftUI で使用するためのラッパー
struct WebViewRepresentable: UIViewRepresentable {

    @Binding var viewModel: BrowserViewModel
    /// ページ読み込み完了時に履歴保存を依頼するコールバック
    var onPageFinished: ((String, String) -> Void)?
    /// 長押しで単語が選択された時のコールバック
    var onWordSelected: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            viewModel: $viewModel,
            onPageFinished: onPageFinished,
            onWordSelected: onWordSelected
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // 長押し単語選択スクリプトを登録
        let script = WKUserScript(
            source: Self.wordSelectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)

        // メモリリークを防ぐため WeakScriptMessageHandler 経由で登録
        config.userContentController.add(
            WeakScriptMessageHandler(delegate: context.coordinator),
            name: "wordSelected"
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        context.coordinator.startObserving(webView: webView)

        if let url = viewModel.currentURL {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let request = viewModel.navigationRequest else { return }

        switch request {
        case .load(let url):
            webView.load(URLRequest(url: url))
        case .back:
            if webView.canGoBack { webView.goBack() }
        case .forward:
            if webView.canGoForward { webView.goForward() }
        case .reload:
            webView.reload()
        }

        DispatchQueue.main.async {
            viewModel.navigationRequest = nil
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving(webView: webView)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "wordSelected")
    }

    // MARK: - 長押し単語選択 JavaScript

    /// タップ位置の英単語を取得して Swift へ送信する JS
    private static let wordSelectionScript = """
    (function() {
        var timer = null;
        var LONG_PRESS_MS = 500;

        document.addEventListener('touchstart', function(e) {
            var touch = e.touches[0];
            timer = setTimeout(function() {
                var word = getWordAt(touch.clientX, touch.clientY);
                if (word) {
                    window.webkit.messageHandlers.wordSelected.postMessage(word);
                }
            }, LONG_PRESS_MS);
        }, { passive: true });

        document.addEventListener('touchend',  function() { clearTimeout(timer); }, { passive: true });
        document.addEventListener('touchmove', function() { clearTimeout(timer); }, { passive: true });

        function getWordAt(x, y) {
            var range;
            if (document.caretRangeFromPoint) {
                range = document.caretRangeFromPoint(x, y);
            } else {
                return null;
            }
            if (!range) return null;

            var node = range.startContainer;
            if (node.nodeType !== Node.TEXT_NODE) return null;

            var text = node.textContent;
            var offset = range.startOffset;

            // 単語の開始・終了インデックスを探す
            var start = offset;
            while (start > 0 && /[a-zA-Z'\\-]/.test(text[start - 1])) { start--; }

            var end = offset;
            while (end < text.length && /[a-zA-Z'\\-]/.test(text[end])) { end++; }

            if (start === end) return null;
            var word = text.substring(start, end);

            // 英字のみで構成された単語のみ返す
            if (!/^[a-zA-Z]/.test(word)) return null;
            return word;
        }
    })();
    """

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

        @Binding var viewModel: BrowserViewModel
        var onPageFinished: ((String, String) -> Void)?
        var onWordSelected: ((String) -> Void)?
        private var progressObservation: NSKeyValueObservation?

        init(
            viewModel: Binding<BrowserViewModel>,
            onPageFinished: ((String, String) -> Void)?,
            onWordSelected: ((String) -> Void)?
        ) {
            _viewModel = viewModel
            self.onPageFinished = onPageFinished
            self.onWordSelected = onWordSelected
        }

        // MARK: KVO

        func startObserving(webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.viewModel.loadingProgress = wv.estimatedProgress
                }
            }
        }

        func stopObserving(webView: WKWebView) {
            progressObservation?.invalidate()
            progressObservation = nil
        }

        // MARK: WKScriptMessageHandler - JS からの単語受信

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "wordSelected",
                  let word = message.body as? String,
                  !word.isEmpty else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onWordSelected?(word)
            }
        }

        // MARK: WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            viewModel.isLoading = true
            viewModel.loadingProgress = 0.0
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            viewModel.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.isLoading = false
            viewModel.loadingProgress = 1.0
            viewModel.canGoBack = webView.canGoBack
            viewModel.canGoForward = webView.canGoForward
            viewModel.pageTitle = webView.title ?? ""

            if let currentURL = webView.url {
                viewModel.currentURL = currentURL
                viewModel.addressText = currentURL.absoluteString
                let title = webView.title ?? currentURL.absoluteString
                onPageFinished?(title, currentURL.absoluteString)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            viewModel.isLoading = false
            viewModel.loadingProgress = 0.0
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            viewModel.isLoading = false
            viewModel.loadingProgress = 0.0
        }
    }
}

// MARK: - WeakScriptMessageHandler

/// WKUserContentController による強参照サイクルを防ぐ弱参照ラッパー
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
