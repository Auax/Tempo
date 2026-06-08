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
    let playingNotes: [String: PianoHand]
    let feedback: [String: NoteFeedback]

    @State private var svg = ""
    @State private var renderError: String?
    @State private var verovioIDs: [String: String] = [:]

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
                        currentMeasure: currentMeasure,
                        expectedNotes: translatedExpectedNotes,
                        playingNotes: translatedPlayingNotes,
                        feedback: translatedFeedback
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

    private func renderKey(width: CGFloat) -> String {
        "\(score?.xml.hashValue ?? 0)-\(Int(width / 80))-\(Int(zoom * 10))"
    }

    private var translatedExpectedNotes: [String: PianoHand] {
        Dictionary(
            uniqueKeysWithValues: expectedNotes.compactMap { sourceID, hand in
                verovioIDs[sourceID].map { ($0, hand) }
            }
        )
    }

    private var translatedPlayingNotes: [String: PianoHand] {
        Dictionary(
            uniqueKeysWithValues: playingNotes.compactMap { sourceID, hand in
                verovioIDs[sourceID].map { ($0, hand) }
            }
        )
    }

    private var translatedFeedback: [String: NoteFeedback] {
        Dictionary(
            uniqueKeysWithValues: feedback.compactMap { sourceID, noteFeedback in
                verovioIDs[sourceID].map { ($0, noteFeedback) }
            }
        )
    }

    @MainActor
    private func render(width: CGFloat) async {
        svg = ""
        verovioIDs = [:]
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
                let timemap = toolkit.renderToTimemap("{\"includeRests\": false}")
                let idMap = Self.makeVerovioIDMap(
                    toolkit: toolkit,
                    timemap: timemap,
                    score: score
                )
                return RenderResult.success(renderedSVG, idMap)
            }
        }.value

        switch result {
        case .success(let renderedSVG, let idMap):
            svg = renderedSVG
            verovioIDs = idMap
        case .failure(let message):
            renderError = message
        }
    }

    private enum RenderResult: Sendable {
        case success(String, [String: String])
        case failure(String)
    }

    nonisolated static func makeVerovioIDMap(
        toolkit: VerovioToolkit,
        timemap: String,
        score: ParsedScore
    ) -> [String: String] {
        struct RenderedNote {
            let id: String
            let pitch: Int
            let startBeat: Double
        }

        guard
            let timemapData = timemap.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: timemapData)
                as? [[String: Any]]
        else {
            return [:]
        }

        var renderedNotes: [RenderedNote] = []
        for entry in entries {
            guard
                let qstamp = (entry["qstamp"] as? NSNumber)?.doubleValue,
                let noteIDs = entry["on"] as? [String]
            else {
                continue
            }

            for noteID in noteIDs {
                guard
                    let midiData = toolkit.getMIDIValuesForElement(noteID).data(using: .utf8),
                    let midiJSON = try? JSONSerialization.jsonObject(with: midiData)
                        as? [String: Any],
                    let pitch = (midiJSON["pitch"] as? NSNumber)?.intValue
                else {
                    continue
                }
                renderedNotes.append(
                    RenderedNote(id: noteID, pitch: pitch, startBeat: qstamp)
                )
            }
        }

        var availableByPitch = Dictionary(grouping: renderedNotes, by: \.pitch)
        var result: [String: String] = [:]

        for event in score.events {
            guard var candidates = availableByPitch[event.midiNote], !candidates.isEmpty else {
                continue
            }

            // Verovio assigns grace notes special qstamps, while Tempo gives them
            // short synthetic playback slots. Match the closest unused note of the
            // same pitch so regular notes remain exact and grace runs remain ordered.
            let bestIndex = candidates.indices.min {
                let lhsDistance = abs(candidates[$0].startBeat - event.startBeat)
                let rhsDistance = abs(candidates[$1].startBeat - event.startBeat)
                if lhsDistance != rhsDistance {
                    return lhsDistance < rhsDistance
                }
                return candidates[$0].startBeat < candidates[$1].startBeat
            }
            guard let bestIndex else { continue }

            result[event.id] = candidates.remove(at: bestIndex).id
            availableByPitch[event.midiNote] = candidates
        }

        return result
    }

}

private struct SVGScoreWebView: NSViewRepresentable {
    let svg: String
    let currentMeasure: Int
    let expectedNotes: [String: PianoHand]
    let playingNotes: [String: PianoHand]
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
        context.coordinator.playingNotes = playingNotes
        context.coordinator.feedback = feedback

        if context.coordinator.svgHash != svg.hashValue {
            context.coordinator.svgHash = svg.hashValue
            context.coordinator.lastHighlightHash = 0
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
                const animatedNodes = new Set();
                function applyHighlight(node, className) {
                  if (!node) { return; }
                  node.classList.remove(...highlightClasses);
                  node.classList.add(className);
                  node.setAttribute('data-tempo-highlight', '1');
                  animatedNodes.add(node);
                }
                document.querySelectorAll('[data-tempo-highlight]').forEach(function(node) {
                  node.classList.remove(...highlightClasses);
                  node.removeAttribute('data-tempo-highlight');
                });
                Object.entries(payload).forEach(function(entry) {
                  const node = document.querySelector('svg [data-id="' + entry[0] + '"]');
                  if (node) {
                    const chord = node.parentElement?.matches('[data-class="chord"]')
                      ? node.parentElement
                      : null;
                    applyHighlight(chord || node, entry[1]);

                    document.querySelectorAll(
                      'svg [data-class="lineDash"][data-related~="#' + entry[0] + '"]'
                    ).forEach(function(ledgerLine) {
                      applyHighlight(ledgerLine, entry[1]);
                    });
                  }
                });

                if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
                  animatedNodes.forEach(function(node) {
                    node.animate(
                      [{ opacity: 0.68 }, { opacity: 1 }],
                      { duration: 150, easing: 'ease-out' }
                    );
                  });
                }
              }

              function tempoScrollToSystem(measureNumber, candidateIDs, animated) {
                let measure = null;
                for (const id of candidateIDs) {
                  const note = document.querySelector('svg [data-id="' + id + '"]');
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
        var svgHash = 0
        var lastHighlightHash = 0
        var lastScrolledMeasure = 0
        var currentMeasure = 1
        var expectedNotes: [String: PianoHand] = [:]
        var playingNotes: [String: PianoHand] = [:]
        var feedback: [String: NoteFeedback] = [:]

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            lastHighlightHash = 0
            applyHighlights(to: webView)
            scrollToCurrentMeasure(in: webView, animated: false)
        }

        func applyHighlights(to webView: WKWebView) {
            var classes = expectedNotes.mapValues { _ in "tempo-active" }
            for id in playingNotes.keys {
                classes[id] = "tempo-active"
            }
            for (id, noteFeedback) in feedback {
                classes[id] = noteFeedback == .correct
                    ? "tempo-correct"
                    : "tempo-incorrect"
            }

            let hash = classes.hashValue
            guard hash != lastHighlightHash else { return }
            lastHighlightHash = hash

            guard
                let data = try? JSONSerialization.data(withJSONObject: classes),
                let json = String(data: data, encoding: .utf8)
            else {
                return
            }
            webView.evaluateJavaScript("tempoHighlight(\(json));")
        }

        func scrollToCurrentMeasure(in webView: WKWebView, animated: Bool = true) {
            guard currentMeasure != lastScrolledMeasure else { return }
            lastScrolledMeasure = currentMeasure

            let candidateIDs = Array(playingNotes.keys) + Array(expectedNotes.keys)
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
