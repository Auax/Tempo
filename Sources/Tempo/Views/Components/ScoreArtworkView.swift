import AppKit
import SwiftUI
import VerovioToolkit

struct ScoreArtworkView: View {
    let title: String
    let composer: String
    let artwork: ScoreArtwork
    var difficulty: String? = nil
    var genre: String? = nil
    var scoreXML: String? = nil
    var scorePath: String? = nil
    var overrideImage: NSImage? = nil

    private var textColor: Color {
        artwork.usesDarkText ? Color(red: 0.10, green: 0.12, blue: 0.16) : .white
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch artwork.textAlignment {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch artwork.textAlignment {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }

    private var multilineAlignment: TextAlignment {
        switch artwork.textAlignment {
        case .leading:
            .leading
        case .center:
            .center
        case .trailing:
            .trailing
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                artworkBackground
                    .offset(
                        x: proxy.size.width * artwork.imageOffsetX * 0.16,
                        y: proxy.size.height * artwork.imageOffsetY * 0.12
                    )

                Color.black.opacity(artwork.overlayOpacity)

                VStack(alignment: horizontalAlignment, spacing: 0) {
                    Spacer(minLength: proxy.size.height * 0.12)

                    VStack(alignment: horizontalAlignment, spacing: proxy.size.width * 0.035) {
                        Text(title.isEmpty ? "Untitled Score" : title)
                            .font(
                                .system(
                                    size: proxy.size.width * 0.118 * artwork.titleScale,
                                    weight: .semibold,
                                    design: .serif
                                )
                            )
                            .lineLimit(3)
                            .minimumScaleFactor(0.62)

                        Rectangle()
                            .fill(textColor.opacity(0.72))
                            .frame(width: proxy.size.width * 0.12, height: 1)

                        Text(composer.isEmpty ? "Unknown composer" : composer)
                            .font(.system(size: proxy.size.width * 0.048, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .opacity(0.82)
                    }
                    .multilineTextAlignment(multilineAlignment)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)

                    Spacer(minLength: 12)

                    ScoreArtworkExcerpt(
                        scoreXML: scoreXML,
                        scorePath: scorePath,
                        usesDarkInk: artwork.usesDarkText
                    )
                    .frame(height: proxy.size.height * 0.25)

                    if let metadataText {
                        Text(metadataText)
                            .font(.system(size: proxy.size.width * 0.036, weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(proxy.size.width * 0.002)
                            .lineLimit(1)
                            .opacity(0.76)
                            .padding(.top, proxy.size.width * 0.035)
                            .frame(maxWidth: .infinity, alignment: frameAlignment)
                    }
                }
                .foregroundStyle(textColor)
                .padding(proxy.size.width * 0.09)
            }
        }
        .aspectRatio(0.78, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
    }

    private var metadataText: String? {
        let values: [String] = [difficulty, genre].compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        return values.isEmpty ? nil : values.joined(separator: "  •  ")
    }

    @ViewBuilder
    private var artworkBackground: some View {
        if let image = overrideImage ?? ScoreArtworkImageLoader.image(for: artwork) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [.tempoBlue, Color(red: 0.08, green: 0.14, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct ScoreArtworkExcerpt: View {
    let scoreXML: String?
    let scorePath: String?
    let usesDarkInk: Bool

    @State private var image: NSImage?

    private var renderKey: String {
        if let scorePath {
            return scorePath
        }
        return scoreXML.map { String($0.hashValue) } ?? "none"
    }

    var body: some View {
        Group {
            if let image {
                if usesDarkInk {
                    excerptImage(image)
                } else {
                    excerptImage(image)
                        .colorInvert()
                }
            } else {
                Color.clear
            }
        }
        .task(id: renderKey) {
            image = await ScoreArtworkExcerptRenderer.image(
                xml: resolvedXML,
                scorePath: scorePath,
                cacheKey: renderKey
            )
        }
    }

    private var resolvedXML: String? {
        scoreXML
    }

    private func excerptImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .opacity(0.88)
    }
}

private enum ScoreArtworkExcerptRenderer {
    nonisolated private static let renderLock = NSLock()
    private static let cache = NSCache<NSString, NSImage>()

    static func image(
        xml: String?,
        scorePath: String?,
        cacheKey: String
    ) async -> NSImage? {
        if let cached = cache.object(forKey: cacheKey as NSString) {
            return cached
        }

        let rendered: NSImage? = await Task.detached(priority: .utility) { () -> NSImage? in
            let resolvedXML: String?
            if let xml, !xml.isEmpty {
                resolvedXML = xml
            } else if let scorePath {
                resolvedXML = try? MusicXMLScoreParser.parse(
                    url: URL(fileURLWithPath: scorePath)
                ).xml
            } else {
                resolvedXML = nil
            }

            guard let resolvedXML else { return nil }
            return renderLock.withLock {
                render(xml: resolvedXML)
            }
        }.value

        if let rendered {
            cache.setObject(rendered, forKey: cacheKey as NSString)
        }
        return rendered
    }

    nonisolated private static func render(xml: String) -> NSImage? {
        guard let resourcePath = VerovioResources.bundle.url(
            forResource: "data",
            withExtension: nil
        )?.path else {
            return nil
        }

        let toolkit = VerovioToolkit(resourcePath)
        let options: [String: Any] = [
            "adjustPageHeight": false,
            "breaks": "auto",
            "footer": "none",
            "header": "none",
            "pageHeight": 520,
            "pageMarginBottom": 12,
            "pageMarginLeft": 20,
            "pageMarginRight": 20,
            "pageMarginTop": 12,
            "pageWidth": 1_600,
            "scale": 34,
            "svgHtml5": true,
            "svgViewBox": true
        ]
        guard
            let data = try? JSONSerialization.data(withJSONObject: options),
            let optionsJSON = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        _ = toolkit.setOptions(optionsJSON)
        _ = toolkit.setInputFrom("musicxml")
        guard toolkit.loadData(xml) else { return nil }
        let svg = toolkit.renderToSVG(1, false)
        guard let svgData = svg.data(using: .utf8) else { return nil }
        return NSImage(data: svgData)
    }
}

enum ScoreArtworkImageLoader {
    static func image(for artwork: ScoreArtwork) -> NSImage? {
        if let path = artwork.customImagePath,
           let customImage = NSImage(contentsOfFile: path) {
            return customImage
        }

        return image(for: artwork.preset)
    }

    static func image(for preset: ScoreArtworkPreset) -> NSImage? {
        let name = preset.resourceName
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle.main
#endif
        let url = bundle.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "ArtworkPresets"
        ) ?? bundle.url(forResource: name, withExtension: "png")

        return url.flatMap(NSImage.init(contentsOf:))
    }
}
