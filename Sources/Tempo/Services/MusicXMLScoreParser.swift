import Foundation
import ZIPFoundation

enum MusicXMLScoreParser {
    static func parse(url: URL) throws -> ParsedScore {
        let data: Data
        if url.pathExtension.lowercased() == "mxl" {
            data = try musicXMLData(fromMXL: url)
        } else {
            data = try Data(contentsOf: url)
        }
        return try parse(data: data)
    }

    static func parse(data: Data) throws -> ParsedScore {
        let document = try XMLDocument(data: data)
        var divisions = 1.0
        var beatsPerMeasure = 4.0
        var measureStart = 0.0
        var events: [ScoreNoteEvent] = []
        var measureStartBeats: [Int: Double] = [:]
        var measureDurations: [Int: Double] = [:]
        var detectedTempo: Int?

        let measures = try document.nodes(forXPath: "//part[1]/measure")
        for (measureIndex, node) in measures.enumerated() {
            guard let measure = node as? XMLElement else { continue }
            let measureNumber = Int(measure.attribute(forName: "number")?.stringValue ?? "")
                ?? measureIndex + 1
            measureStartBeats[measureNumber] = measureStart

            if let value = firstText(in: measure, xpath: "./attributes/divisions"),
               let parsed = Double(value), parsed > 0 {
                divisions = parsed
            }
            if let beats = firstText(in: measure, xpath: "./attributes/time/beats"),
               let beatType = firstText(in: measure, xpath: "./attributes/time/beat-type"),
               let beatCount = Double(beats),
               let denominator = Double(beatType), denominator > 0 {
                beatsPerMeasure = beatCount * 4 / denominator
            }
            if detectedTempo == nil,
               let sound = try? measure.nodes(forXPath: ".//sound[@tempo]").first as? XMLElement,
               let tempoText = sound.attribute(forName: "tempo")?.stringValue,
               let tempoValue = Double(tempoText) {
                detectedTempo = Int(tempoValue.rounded())
            }

            var cursor = 0.0
            var furthestCursor = 0.0
            var lastNoteStart = 0.0
            var eventIndex = 0
            var pendingGraceGroups: [[Int]] = []

            for child in measure.children ?? [] {
                guard let element = child as? XMLElement else { continue }
                switch element.name {
                case "backup":
                    cursor -= durationValue(in: element) / divisions
                case "forward":
                    cursor += durationValue(in: element) / divisions
                    furthestCursor = max(furthestCursor, cursor)
                case "note":
                    let duration = durationValue(in: element) / divisions
                    let isChord = element.elements(forName: "chord").isEmpty == false
                    let isGrace = element.elements(forName: "grace").isEmpty == false
                    var start = isChord ? lastNoteStart : cursor
                    if !isChord {
                        lastNoteStart = start
                    }

                    if element.elements(forName: "rest").isEmpty,
                       let midiNote = midiNote(in: element) {
                        eventIndex += 1
                        let eventID = element.attribute(forName: "id")?.stringValue
                            ?? element.attribute(forName: "xml:id")?.stringValue
                            ?? "tempo-m\(measureNumber)-n\(eventIndex)"
                        if element.attribute(forName: "id") == nil {
                            element.addAttribute(
                                XMLNode.attribute(
                                    withName: "id",
                                    stringValue: eventID
                                ) as! XMLNode
                            )
                        }

                        if !isGrace, !isChord, !pendingGraceGroups.isEmpty {
                            start = scheduleGraceGroups(
                                pendingGraceGroups,
                                before: measureStart + start,
                                events: &events
                            ) - measureStart
                            lastNoteStart = start
                            pendingGraceGroups.removeAll()
                        }

                        let staff = Int(firstText(in: element, xpath: "./staff") ?? "1") ?? 1
                        let eventArrayIndex = events.count
                        events.append(
                            ScoreNoteEvent(
                                id: eventID,
                                midiNote: midiNote,
                                startBeat: measureStart + start,
                                duration: max(duration, ScoreTimeline.beatEqualityEpsilon),
                                measure: measureNumber,
                                hand: staff == 2 ? .left : .right
                            )
                        )

                        if isGrace {
                            if isChord, !pendingGraceGroups.isEmpty {
                                pendingGraceGroups[pendingGraceGroups.count - 1].append(eventArrayIndex)
                            } else {
                                pendingGraceGroups.append([eventArrayIndex])
                            }
                        }
                    }

                    if !isChord, !isGrace {
                        cursor += duration
                        furthestCursor = max(furthestCursor, cursor)
                    }
                default:
                    break
                }
            }

            if !pendingGraceGroups.isEmpty {
                _ = scheduleGraceGroups(
                    pendingGraceGroups,
                    before: measureStart + cursor,
                    events: &events
                )
            }

            // Use the measure's actual content duration (including rests) rather than
            // padding to the time signature. Padding inflated pickup/anacrusis measures,
            // which shifted every later beat out of sync with the engraved score
            // (breaking note highlighting) and inserted phantom gaps during playback.
            let duration = furthestCursor > 0 ? furthestCursor : beatsPerMeasure
            measureDurations[measureNumber] = duration
            measureStart += duration
        }

        let xmlData = document.xmlData(options: [.nodePrettyPrint])
        guard let xml = String(data: xmlData, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        return ParsedScore(
            xml: xml,
            events: events.sorted {
                $0.startBeat == $1.startBeat
                    ? $0.midiNote < $1.midiNote
                    : $0.startBeat < $1.startBeat
            },
            measureStartBeats: measureStartBeats,
            measureDurations: measureDurations,
            title: firstText(in: document, xpath: "//work-title")
                ?? firstText(in: document, xpath: "//movement-title"),
            composer: composer(in: document),
            tempo: detectedTempo
        )
    }

    private static func firstText(in node: XMLNode, xpath: String) -> String? {
        (try? node.nodes(forXPath: xpath).first?.stringValue)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func composer(in document: XMLDocument) -> String? {
        let creators = (try? document.nodes(forXPath: "//creator")) ?? []
        let composer = creators.first { node in
            (node as? XMLElement)?.attribute(forName: "type")?.stringValue == "composer"
        }
        return composer?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func durationValue(in element: XMLElement) -> Double {
        Double(firstText(in: element, xpath: "./duration") ?? "0") ?? 0
    }

    private static func scheduleGraceGroups(
        _ groups: [[Int]],
        before anchorBeat: Double,
        events: inout [ScoreNoteEvent]
    ) -> Double {
        guard !groups.isEmpty else { return anchorBeat }

        // MusicXML grace notes usually omit duration. Give each engraved grace
        // group a short playback slot so a run is heard and highlighted in order.
        let preferredDuration = min(0.125, 0.5 / Double(groups.count))
        let preferredTotal = preferredDuration * Double(groups.count)
        let groupDuration: Double
        let graceStart: Double
        let regularNoteStart: Double

        if anchorBeat >= preferredTotal {
            groupDuration = preferredDuration
            graceStart = anchorBeat - preferredTotal
            regularNoteStart = anchorBeat
        } else if anchorBeat > 0 {
            groupDuration = anchorBeat / Double(groups.count)
            graceStart = 0
            regularNoteStart = anchorBeat
        } else {
            groupDuration = preferredDuration
            graceStart = 0
            regularNoteStart = preferredTotal
        }

        for (groupOffset, eventIndices) in groups.enumerated() {
            let startBeat = graceStart + Double(groupOffset) * groupDuration
            for eventIndex in eventIndices {
                let event = events[eventIndex]
                events[eventIndex] = ScoreNoteEvent(
                    id: event.id,
                    midiNote: event.midiNote,
                    startBeat: startBeat,
                    duration: groupDuration,
                    measure: event.measure,
                    hand: event.hand
                )
            }
        }

        return regularNoteStart
    }

    private static func midiNote(in element: XMLElement) -> Int? {
        guard
            let step = firstText(in: element, xpath: "./pitch/step"),
            let octaveText = firstText(in: element, xpath: "./pitch/octave"),
            let octave = Int(octaveText)
        else {
            return nil
        }

        let semitone: [String: Int] = [
            "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
        ]
        guard let base = semitone[step] else { return nil }
        let alter = Int(Double(firstText(in: element, xpath: "./pitch/alter") ?? "0") ?? 0)
        return (octave + 1) * 12 + base + alter
    }

    private static func musicXMLData(fromMXL url: URL) throws -> Data {
        let archive = try Archive(url: url, accessMode: .read)
        let containerPath = "META-INF/container.xml"
        guard let containerEntry = archive[containerPath] else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var containerData = Data()
        _ = try archive.extract(containerEntry) { containerData.append($0) }
        let container = try XMLDocument(data: containerData)
        guard
            let rootPath = try container.nodes(
                forXPath: "//*[local-name()='rootfile']/@full-path"
            ).first?.stringValue,
            let scoreEntry = archive[rootPath]
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var scoreData = Data()
        _ = try archive.extract(scoreEntry) { scoreData.append($0) }
        return scoreData
    }
}
