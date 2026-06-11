import SwiftUI
import VerovioToolkit
import WebKit

struct VerovioScoreView: View {
    nonisolated private static let renderLock = NSLock()

    let score: ParsedScore?
    let errorMessage: String?
    let currentMeasure: Int
    let zoom: Double
    let expectedNotes: [String: PianoHand]
    let feedback: [String: NoteFeedback]

    @State private var svg = ""
    @State private var renderError: String?
    @State private var documentID = 0

    private struct RenderKey: Hashable {
        let scoreID: ParsedScore.ID?
        let widthBucket: Int
        let zoomStep: Int
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white

                if let message = errorMessage ?? renderError {
                    ContentUnavailableView(
                        "Score Unavailable",
                        systemImage: "music.note.slash",
                        description: Text(message)
                    )
                    .foregroundStyle(.black)
                } else if score == nil {
                    ContentUnavailableView(
                        "No Score Selected",
                        systemImage: "music.note.list",
                        description: Text("Import a MusicXML score to begin.")
                    )
                    .foregroundStyle(.black)
                } else if svg.isEmpty {
                    ProgressView("Engraving score…")
                        .controlSize(.large)
                        .tint(.tempoBlue)
                        .foregroundStyle(.black)
                } else {
                    SVGScoreWebView(
                        svg: svg,
                        documentID: documentID,
                        currentMeasure: currentMeasure,
                        expectedNotes: expectedNotes,
                        feedback: feedback
                    )
                }
            }
            .task(id: renderKey(width: proxy.size.width)) {
                await render(width: proxy.size.width)
            }
        }
        .background(Color.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sheet music rendered by Verovio")
        .accessibilityValue("Current measure \(currentMeasure)")
    }

    private func renderKey(width: CGFloat) -> RenderKey {
        RenderKey(
            scoreID: score?.id,
            widthBucket: Int(width / 80),
            zoomStep: Int(zoom * 10)
        )
    }

    @MainActor
    private func render(width: CGFloat) async {
        svg = ""
        renderError = nil
        guard let score else { return }
        guard let resourcePath = VerovioResources.bundle.url(
            forResource: "data",
            withExtension: nil
        )?.path else {
            renderError = "The Verovio resources could not be found."
            return
        }

        let pageWidth = max(1_250, Int(width * 2.1))
        let scale = max(28, Int(40 * zoom))
        let result = await Task.detached(priority: .userInitiated) {
            Self.renderLock.withLock {
                let toolkit = VerovioToolkit(resourcePath)
                let options: [String: Any] = [
                    "adjustPageHeight": true,
                    "breaks": "auto",
                    "footer": "none",
                    "header": "none",
                    "pageHeight": 1_450,
                    "pageMarginBottom": 45,
                    "pageMarginLeft": 50,
                    "pageMarginRight": 50,
                    "pageMarginTop": 42,
                    "pageWidth": pageWidth,
                    "scale": scale,
                    "svgHtml5": true,
                    "svgViewBox": true
                ]
                guard
                    let optionsData = try? JSONSerialization.data(withJSONObject: options),
                    let optionsJSON = String(data: optionsData, encoding: .utf8)
                else {
                    return RenderResult.failure("Could not configure Verovio.")
                }

                _ = toolkit.setOptions(optionsJSON)
                _ = toolkit.setInputFrom("musicxml")
                guard toolkit.loadData(score.xml) else {
                    let log = toolkit.getLog()
                    return RenderResult.failure(
                        log.isEmpty ? "Verovio could not read this score." : log
                    )
                }
                let pageCount = toolkit.getPageCount()
                let renderedPages = (1...max(pageCount, 1)).compactMap { pageNumber in
                    let page = toolkit.renderToSVG(pageNumber, false)
                    return page.isEmpty ? nil : page
                }
                guard !renderedPages.isEmpty else {
                    return RenderResult.failure("Verovio returned an empty score.")
                }
                let renderedSVG = renderedPages.joined(separator: "\n")
                return RenderResult.success(renderedSVG)
            }
        }.value

        switch result {
        case .success(let renderedSVG):
            documentID &+= 1
            svg = renderedSVG
        case .failure(let message):
            renderError = message
        }
    }

    private enum RenderResult: Sendable {
        case success(String)
        case failure(String)
    }

}

private struct SVGScoreWebView: NSViewRepresentable {
    let svg: String
    let documentID: Int
    let currentMeasure: Int
    let expectedNotes: [String: PianoHand]
    let feedback: [String: NoteFeedback]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.enclosingScrollView?.drawsBackground = false
        webView.enclosingScrollView?.hasHorizontalScroller = false
        webView.enclosingScrollView?.hasVerticalScroller = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.currentMeasure = currentMeasure
        context.coordinator.expectedNotes = expectedNotes
        context.coordinator.feedback = feedback

        if context.coordinator.documentID != documentID {
            context.coordinator.prepareForDocument(documentID)
            context.coordinator.lastScrolledMeasure = 0
            webView.loadHTMLString(Self.html(svg: svg), baseURL: nil)
        } else {
            context.coordinator.applyHighlights(to: webView)
            context.coordinator.scrollToCurrentMeasure(in: webView)
        }
    }

    private static func html(svg: String) -> String {
        """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              html, body { margin: 0; padding: 0; background: #fff; overflow-x: hidden; }
              body { color: #151515; padding-bottom: 24px; }
              svg { display: block; width: 100%; height: auto; color: #151515 !important; }
              body > svg + svg { margin-top: 24px; }
              svg .page-margin {
                fill: #151515 !important;
                stroke: #151515 !important;
              }
              svg g, svg .definition-scale { color: #151515 !important; }
              svg use, svg text { fill: #151515 !important; color: #151515 !important; }
              .tempo-active { --tempo-highlight-color: #f5a623; }
              .tempo-correct { --tempo-highlight-color: #35b95c; }
              .tempo-incorrect { --tempo-highlight-color: #e84a52; }
              [data-tempo-highlight] use,
              [data-tempo-highlight] path,
              [data-tempo-highlight] text,
              [data-tempo-highlight] rect,
              [data-tempo-highlight] ellipse,
              [data-tempo-highlight] circle,
              [data-tempo-highlight] line,
              [data-tempo-highlight] polygon,
              [data-tempo-highlight] polyline {
                fill: var(--tempo-highlight-color) !important;
                stroke: var(--tempo-highlight-color) !important;
                color: var(--tempo-highlight-color) !important;
              }
            </style>
            <script>
              function tempoHighlight(payload) {
                const highlightClasses = [
                  'tempo-active',
                  'tempo-correct',
                  'tempo-incorrect'
                ];
                const previousNodes = window.tempoHighlightedNodes || new Set();
                previousNodes.forEach(function(node) {
                  node.classList.remove(...highlightClasses);
                  node.removeAttribute('data-tempo-highlight');
                });

                const highlightedNodes = new Set();
                const nodeCache = window.tempoHighlightNodeCache || new Map();
                window.tempoHighlightNodeCache = nodeCache;

                function nodesForID(id) {
                  if (nodeCache.has(id)) { return nodeCache.get(id); }
                  const nodes = [];
                  const note = document.querySelector('svg [data-id="' + id + '"]');
                  if (note) {
                    const chord = note.parentElement?.matches('[data-class="chord"]')
                      ? note.parentElement
                      : null;
                    nodes.push(chord || note);
                    document.querySelectorAll(
                      'svg [data-class="lineDash"][data-related~="#' + id + '"]'
                    ).forEach(function(ledgerLine) {
                      nodes.push(ledgerLine);
                    });
                  }
                  nodeCache.set(id, nodes);
                  return nodes;
                }

                function applyHighlight(node, className) {
                  if (!node) { return; }
                  node.classList.remove(...highlightClasses);
                  node.classList.add(className);
                  node.setAttribute('data-tempo-highlight', '1');
                  highlightedNodes.add(node);
                }

                Object.entries(payload).forEach(function(entry) {
                  nodesForID(entry[0]).forEach(function(node) {
                    applyHighlight(node, entry[1]);
                  });
                });
                window.tempoHighlightedNodes = highlightedNodes;
              }

              function tempoScrollToSystem(measureNumber, candidateIDs, animated) {
                let measure = null;
                for (const id of candidateIDs) {
                  const note = (window.tempoHighlightNodeCache?.get(id) || [])[0]
                    || document.querySelector('svg [data-id="' + id + '"]');
                  if (note) {
                    measure = note.closest('[data-class="measure"]');
                    break;
                  }
                }

                if (!measure) {
                  const measures = document.querySelectorAll('svg [data-class="measure"]');
                  measure = measures[Math.max(0, measureNumber - 1)] || null;
                }
                if (!measure) { return; }

                const system = measure.closest('[data-class="system"]') || measure;
                const systemID = system.getAttribute('data-id')
                  || 'system-' + Array.from(
                    document.querySelectorAll('svg [data-class="system"]')
                  ).indexOf(system);
                if (window.tempoCurrentSystemID === systemID) { return; }
                window.tempoCurrentSystemID = systemID;

                const top = system.getBoundingClientRect().top
                  + window.scrollY
                  - window.innerHeight * 0.25;
                window.scrollTo({
                  top: Math.max(0, top),
                  behavior: animated ? 'smooth' : 'auto'
                });
              }
            </script>
          </head>
          <body>\(svg)</body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private struct PendingHighlight {
            let documentID: Int
            let script: String
        }

        var documentID = -1
        var lastHighlightClasses: [String: String] = [:]
        var lastScrolledMeasure = 0
        var currentMeasure = 1
        var expectedNotes: [String: PianoHand] = [:]
        var feedback: [String: NoteFeedback] = [:]
        private var pendingHighlight: PendingHighlight?
        private var isApplyingHighlight = false

        func prepareForDocument(_ documentID: Int) {
            self.documentID = documentID
            lastHighlightClasses = [:]
            pendingHighlight = nil
            isApplyingHighlight = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            lastHighlightClasses = [:]
            applyHighlights(to: webView)
            scrollToCurrentMeasure(in: webView, animated: false)
        }

        func applyHighlights(to webView: WKWebView) {
            var classes = expectedNotes.mapValues { _ in "tempo-active" }
            for (id, noteFeedback) in feedback {
                classes[id] = noteFeedback == .correct
                    ? "tempo-correct"
                    : "tempo-incorrect"
            }

            guard classes != lastHighlightClasses else { return }
            lastHighlightClasses = classes

            guard
                let data = try? JSONSerialization.data(withJSONObject: classes),
                let json = String(data: data, encoding: .utf8)
            else {
                return
            }
            pendingHighlight = PendingHighlight(
                documentID: documentID,
                script: "tempoHighlight(\(json));"
            )
            applyPendingHighlight(to: webView)
        }

        private func applyPendingHighlight(to webView: WKWebView) {
            guard !isApplyingHighlight, let pendingHighlight else { return }
            self.pendingHighlight = nil
            isApplyingHighlight = true

            webView.evaluateJavaScript(pendingHighlight.script) { [weak self, weak webView] _, _ in
                guard let self else { return }
                guard pendingHighlight.documentID == self.documentID else { return }
                self.isApplyingHighlight = false
                if let webView {
                    self.applyPendingHighlight(to: webView)
                }
            }
        }

        func scrollToCurrentMeasure(in webView: WKWebView, animated: Bool = true) {
            guard currentMeasure != lastScrolledMeasure else { return }
            lastScrolledMeasure = currentMeasure

            let candidateIDs = Array(expectedNotes.keys)
            guard
                let data = try? JSONSerialization.data(withJSONObject: candidateIDs),
                let json = String(data: data, encoding: .utf8)
            else {
                return
            }
            webView.evaluateJavaScript(
                "tempoScrollToSystem(\(currentMeasure), \(json), \(animated));"
            )
        }
    }
}

#if DEBUG
#Preview("Rendered Score") {
    VerovioScoreView(
        score: PreviewFixtures.parsedScore,
        errorMessage: nil,
        currentMeasure: 1,
        zoom: 1,
        expectedNotes: ["preview-note-c4": .right],
        feedback: ["preview-note-c4": .correct]
    )
    .frame(width: 900, height: 620)
}
#endif
