import Foundation
import Testing
@testable import Tempo

struct MusicXMLScoreParserTests {
    @Test
    func parsesTimelineHandsAndStableIDs() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <work><work-title>Test Piece</work-title></work>
          <identification><creator type="composer">Test Composer</creator></identification>
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>2</divisions>
                <time><beats>4</beats><beat-type>4</beat-type></time>
                <staves>2</staves>
              </attributes>
              <direction><sound tempo="72"/></direction>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>2</duration><staff>1</staff>
              </note>
              <note>
                <chord/>
                <pitch><step>E</step><octave>4</octave></pitch>
                <duration>2</duration><staff>1</staff>
              </note>
              <backup><duration>2</duration></backup>
              <note>
                <pitch><step>C</step><octave>3</octave></pitch>
                <duration>2</duration><staff>2</staff>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))

        #expect(score.title == "Test Piece")
        #expect(score.composer == "Test Composer")
        #expect(score.tempo == 72)
        #expect(score.events.count == 3)
        #expect(score.events.map(\.midiNote) == [48, 60, 64])
        #expect(score.events.allSatisfy { $0.startBeat == 0 })
        #expect(score.events.first?.hand == .left)
        #expect(score.events.last?.hand == .right)
        #expect(score.measureDurations[1] == 4)
        #expect(score.xml.contains("tempo-m1-n1"))
        #expect(score.xml.contains("tempo-m1-n2"))
        #expect(score.xml.contains("tempo-m1-n3"))
    }
}
