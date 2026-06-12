import AppKit
import Foundation
import VerovioToolkit
import WebKit

enum ScorePreviewRenderer {
    private static let renderLock = NSLock()
    private static let previewScale = 42
    private static let previewPageWidth = 1_340
    private static let previewPageHeight = 1_787

    static func renderAndSave(
        xml: String,
        identifier: UUID
    ) async -> URL? {
        let svgData = await Task.detached(priority: .utility) { () -> Data? in
            renderLock.withLock {
                renderSVG(xml: xml)
            }
        }.value
        guard let svgData else { return nil }
        return await saveThumbnail(svgData: svgData, identifier: identifier)
    }

    static func renderAndSave(
        scorePath: String,
        identifier: UUID
    ) async -> URL? {
        let svgData = await Task.detached(priority: .utility) { () -> Data? in
            guard
                let parsed = try? MusicXMLScoreParser.parse(
                    url: URL(fileURLWithPath: scorePath)
                )
            else {
                return nil
            }

            return renderLock.withLock {
                renderSVG(xml: parsed.xml)
            }
        }.value
        guard let svgData else { return nil }
        return await saveThumbnail(svgData: svgData, identifier: identifier)
    }

    nonisolated private static func renderSVG(xml: String) -> Data? {
        guard
            let resourcePath = VerovioResources.bundle.url(
                forResource: "data",
                withExtension: nil
            )?.path
        else {
            return nil
        }

        let toolkit = VerovioToolkit(resourcePath)
        let options: [String: Any] = [
            "adjustPageHeight": false,
            "breaks": "auto",
            "footer": "none",
            "header": "none",
            "pageHeight": previewPageHeight,
            "pageMarginBottom": 48,
            "pageMarginLeft": 52,
            "pageMarginRight": 52,
            "pageMarginTop": 48,
            "pageWidth": previewPageWidth,
            "scale": previewScale,
            "svgHtml5": true,
            "svgViewBox": true
        ]
        guard
            let optionsData = try? JSONSerialization.data(withJSONObject: options),
            let optionsJSON = String(data: optionsData, encoding: .utf8)
        else {
            return nil
        }

        _ = toolkit.setOptions(optionsJSON)
        _ = toolkit.setInputFrom("musicxml")
        guard toolkit.loadData(xml) else { return nil }

        let svg = toolkit.renderToSVG(1, false)
        guard !svg.isEmpty else { return nil }
        return svg.data(using: .utf8)
    }

    private static func saveThumbnail(
        svgData: Data,
        identifier: UUID
    ) async -> URL? {
        guard
            let svg = String(data: svgData, encoding: .utf8),
            let pngURL = previewURL(identifier: identifier),
            let image = await WebScorePreviewRenderer.image(svg: svg),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }

        do {
            try pngData.write(to: pngURL, options: .atomic)
            return pngURL
        } catch {
            return nil
        }
    }

    nonisolated private static func previewDirectory() -> URL? {
        let fileManager = FileManager.default
        guard
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        let directory = applicationSupport
            .appendingPathComponent("Tempo", isDirectory: true)
            .appendingPathComponent("ScorePreviews", isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory
        } catch {
            return nil
        }
    }

    nonisolated private static func previewURL(identifier: UUID) -> URL? {
        previewDirectory()?.appendingPathComponent(
            "\(identifier.uuidString)-preview-v5.png"
        )
    }
}

@MainActor
private enum WebScorePreviewRenderer {
    static func image(svg: String) async -> NSImage? {
        let size = CGSize(width: 720, height: 960)
        let webView = WKWebView(frame: CGRect(origin: .zero, size: size))
        let delegate = PreviewNavigationDelegate()
        webView.navigationDelegate = delegate

        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name="color-scheme" content="light">
            <style>
              html, body {
                width: 100%;
                height: 100%;
                margin: 0;
                overflow: hidden;
                background: white;
              }
              .crop {
                width: 100%;
                height: 100%;
                overflow: hidden;
              }
              svg {
                display: block;
                width: 100%;
                height: 100%;
                color: #151515;
              }
              svg path, svg ellipse, svg polygon, svg polyline, svg rect {
                fill: #151515;
                stroke: #151515;
              }
            </style>
          </head>
          <body><div class="crop">\(svg)</div></body>
        </html>
        """

        guard await delegate.load(html: html, in: webView) else { return nil }
        return await withCheckedContinuation { continuation in
            let configuration = WKSnapshotConfiguration()
            configuration.rect = CGRect(origin: .zero, size: size)
            configuration.snapshotWidth = NSNumber(value: Double(size.width))
            webView.takeSnapshot(with: configuration) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

@MainActor
private final class PreviewNavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?

    func load(html: String, in webView: WKWebView) async -> Bool {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume(returning: true)
        continuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        continuation?.resume(returning: false)
        continuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        continuation?.resume(returning: false)
        continuation = nil
    }
}
