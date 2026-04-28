import AppKit
import WebKit

final class TransparentWebView: WKWebView, WKNavigationDelegate {
  var onNavigationStarted: (() -> Void)?
  var onNavigationFinished: (() -> Void)?

  init(frame: NSRect) {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    super.init(frame: frame, configuration: configuration)
    navigationDelegate = self
    configureTransparency()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func loadAnimation(_ animationName: String, from animationsDirectory: URL) {
    let fileURL = animationsDirectory.appendingPathComponent(animationName)
    loadFileURL(fileURL, allowingReadAccessTo: animationsDirectory)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    onNavigationStarted?()
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    onNavigationFinished?()
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    onNavigationFinished?()
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    onNavigationFinished?()
  }

  private func configureTransparency() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    layer?.isOpaque = false
    setValue(false, forKey: "drawsBackground")
  }
}
