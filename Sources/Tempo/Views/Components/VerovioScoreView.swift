import SwiftUI
import VerovioToolkit
import WebKit

struct VerovioScoreView: View {
    private static let renderLock = NSLock()

    let score: ParsedScore?
    let errorMessage: String?
    let currentMeasure: Int
    let zoom: Double
    let expectedNotes: [String: PianoHand]
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
                        .tint(.tempoPurple)
                        .foregroundStyle(.black)
                } else {
                    SVGScoreWebView(
                        svg: svg,
                        expectedNotes: translatedExpectedNotes,
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
            Self.renderLock.lock()
            defer { Self.renderLock.unlock() }

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
            let renderedSVG = toolkit.renderToSVG(1, false)
            guard !renderedSVG.isEmpty else {
                return RenderResult.failure("Verovio returned an empty score.")
            }
            _ = toolkit.renderToMIDI()
            let idMap = Self.makeVerovioIDMap(toolkit: toolkit, score: score)
            return RenderResult.success(renderedSVG, idMap)
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

    nonisolated private static func makeVerovioIDMap(
        toolkit: VerovioToolkit,
        score: ParsedScore
    ) -> [String: String] {
        var result: [String: String] = [:]
        let tempo = max(score.tempo ?? 120, 1)
        let grouped = Dictionary(grouping: score.events, by: \.startBeat)

        for (beat, events) in grouped {
            let milliseconds = Int(beat * 60_000 / Double(tempo))
            guard
                let elementsData = toolkit.getElementsAtTime(milliseconds).data(using: .utf8),
                let elementsJSON = try? JSONSerialization.jsonObject(with: elementsData)
                    as? [String: Any],
                let noteIDs = elementsJSON["notes"] as? [String]
            else {
                continue
            }

            var availableByPitch: [Int: [String]] = [:]
            for noteID in noteIDs {
                guard
                    let midiData = toolkit.getMIDIValuesForElement(noteID).data(using: .utf8),
                    let midiJSON = try? JSONSerialization.jsonObject(with: midiData)
                        as? [String: Any],
                    let pitch = midiJSON["pitch"] as? Int
                else {
                    continue
                }
                availableByPitch[pitch, default: []].append(noteID)
            }

            for event in events {
                guard var candidates = availableByPitch[event.midiNote], !candidates.isEmpty else {
                    continue
                }
                result[event.id] = candidates.removeFirst()
                availableByPitch[event.midiNote] = candidates
            }
        }
        return result
    }
}

private struct SVGScoreWebView: NSViewRepresentable {
    let svg: String
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
        context.coordinator.expectedNotes = expectedNotes
        context.coordinator.feedback = feedback

        if context.coordinator.svgHash != svg.hashValue {
            context.coordinator.svgHash = svg.hashValue
            webView.loadHTMLString(Self.html(svg: svg), baseURL: nil)
        } else {
            context.coordinator.applyHighlights(to: webView)
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
              body { color: #151515; }
              svg { display: block; width: 100%; height: auto; color: #151515 !important; }
              svg .page-margin { fill: #fff !important; }
              svg g, svg .definition-scale { color: #151515 !important; }
              svg use, svg text { fill: #151515 !important; color: #151515 !important; }
              .tempo-right use, .tempo-right path, .tempo-right text {
                fill: #7844f5 !important; stroke: #7844f5 !important;
              }
              .tempo-left use, .tempo-left path, .tempo-left text {
                fill: #08a8c2 !important; stroke: #08a8c2 !important;
              }
              .tempo-correct use, .tempo-correct path, .tempo-correct text {
                fill: #35b95c !important; stroke: #35b95c !important;
              }
              .tempo-incorrect use, .tempo-incorrect path, .tempo-incorrect text {
                fill: #e84a52 !important; stroke: #e84a52 !important;
              }
            </style>
            <script>
              function tempoHighlight(payload) {
                document.querySelectorAll('[data-tempo-highlight]').forEach(function(node) {
                  node.classList.remove('tempo-right', 'tempo-left', 'tempo-correct', 'tempo-incorrect');
                  node.removeAttribute('data-tempo-highlight');
                });
                Object.entries(payload).forEach(function(entry) {
                  const node = document.getElementById(entry[0]);
                  if (node) {
                    node.classList.add(entry[1]);
                    node.setAttribute('data-tempo-highlight', '1');
                  }
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
        var expectedNotes: [String: PianoHand] = [:]
        var feedback: [String: NoteFeedback] = [:]

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            applyHighlights(to: webView)
        }

        func applyHighlights(to webView: WKWebView) {
            var classes = expectedNotes.mapValues {
                $0 == .right ? "tempo-right" : "tempo-left"
            }
            for (id, noteFeedback) in feedback {
                classes[id] = noteFeedback == .correct
                    ? "tempo-correct"
                    : "tempo-incorrect"
            }
            guard
                let data = try? JSONSerialization.data(withJSONObject: classes),
                let json = String(data: data, encoding: .utf8)
            else {
                return
            }
            webView.evaluateJavaScript("tempoHighlight(\(json));")
        }
    }
}
