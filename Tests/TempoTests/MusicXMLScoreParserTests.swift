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
                <duration>8</duration><staff>1</staff>
              </note>
              <note>
                <chord/>
                <pitch><step>E</step><octave>4</octave></pitch>
                <duration>8</duration><staff>1</staff>
              </note>
              <backup><duration>8</duration></backup>
              <note>
                <pitch><step>C</step><octave>3</octave></pitch>
                <duration>8</duration><staff>2</staff>
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
        #expect(score.xml.contains("id=\"tempo-m1-n1\""))
        #expect(score.xml.contains("id=\"tempo-m1-n2\""))
        #expect(score.xml.contains("id=\"tempo-m1-n3\""))
    }

    @Test
    func prefersFullMovementTitleOverShortWorkTitle() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <work><work-title>Nocturne</work-title></work>
          <movement-title>Nocturne No. 9 in B major, Op. 32, No. 1</movement-title>
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>1</divisions>
                <time><beats>4</beats><beat-type>4</beat-type></time>
              </attributes>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>4</duration>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))

        #expect(score.title == "Nocturne No. 9 in B major, Op. 32, No. 1")
    }

    @Test
    func combinesWorkAndMovementTitlesWhenNeeded() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <work><work-title>Symphony No. 5</work-title></work>
          <movement-title>Allegro con brio</movement-title>
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>1</divisions>
                <time><beats>4</beats><beat-type>4</beat-type></time>
              </attributes>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>4</duration>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))

        #expect(score.title == "Symphony No. 5 Allegro con brio")
    }

    @Test
    func preservesShortNoteDurations() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>16</divisions>
                <time><beats>4</beats><beat-type>4</beat-type></time>
              </attributes>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>4</duration>
              </note>
              <note>
                <pitch><step>D</step><octave>4</octave></pitch>
                <duration>4</duration>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))

        #expect(score.events.count == 2)
        #expect(score.events[0].duration == 0.25)
        #expect(score.events[1].duration == 0.25)
        #expect(score.events[1].startBeat == 0.25)
    }

    @Test
    func sequencesGraceNotesBeforeTheirAnchorNote() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes><divisions>4</divisions></attributes>
              <note>
                <pitch><step>G</step><octave>4</octave></pitch>
                <duration>8</duration><type>half</type>
              </note>
              <note>
                <grace/>
                <pitch><step>D</step><octave>5</octave></pitch>
                <type>16th</type>
              </note>
              <note>
                <grace/>
                <pitch><step>C</step><octave>5</octave></pitch>
                <type>16th</type>
              </note>
              <note>
                <grace/>
                <pitch><step>B</step><alter>-1</alter><octave>4</octave></pitch>
                <type>16th</type>
              </note>
              <note>
                <pitch><step>C</step><octave>5</octave></pitch>
                <duration>4</duration><type>quarter</type>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))
        let events = score.events

        #expect(events.map(\.midiNote) == [67, 74, 72, 70, 72])
        #expect(events.map(\.startBeat) == [0, 1.625, 1.75, 1.875, 2])
        #expect(events[1...3].allSatisfy { $0.duration == 0.125 })
    }
}
