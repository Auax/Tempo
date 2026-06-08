import Foundation
import Testing
import VerovioToolkit
@testable import Tempo

struct VerovioSourceIDTests {
    @Test
    func preservesInjectedIDsForRepeatedPitchesAndChords() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <part-list><score-part id="P1"><part-name>Piano</part-name></score-part></part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>1</divisions>
                <time><beats>3</beats><beat-type>4</beat-type></time>
                <staves>2</staves>
              </attributes>
              <note>
                <pitch><step>F</step><octave>5</octave></pitch>
                <duration>1</duration><type>quarter</type><staff>1</staff>
              </note>
              <backup><duration>1</duration></backup>
              <note>
                <pitch><step>A</step><octave>3</octave></pitch>
                <duration>1</duration><type>quarter</type><staff>2</staff>
              </note>
              <note>
                <chord/>
                <pitch><step>D</step><octave>4</octave></pitch>
                <duration>1</duration><type>quarter</type><staff>2</staff>
              </note>
              <note>
                <pitch><step>C</step><alter>-1</alter><octave>4</octave></pitch>
                <duration>1</duration><type>quarter</type><staff>2</staff>
              </note>
              <note>
                <chord/>
                <pitch><step>D</step><octave>4</octave></pitch>
                <duration>1</duration><type>quarter</type><staff>2</staff>
              </note>
            </measure>
          </part>
        </score-partwise>
        """

        let score = try MusicXMLScoreParser.parse(data: Data(xml.utf8))
        let resourcePath = try #require(
            VerovioResources.bundle.url(forResource: "data", withExtension: nil)?.path
        )
        let toolkit = VerovioToolkit(resourcePath)
        _ = toolkit.setOptions("{\"svgHtml5\":true}")
        _ = toolkit.setInputFrom("musicxml")
        #expect(toolkit.loadData(score.xml))

        let svg = toolkit.renderToSVG(1, false)

        for event in score.events {
            #expect(svg.contains("data-id=\"\(event.id)\""))
        }
    }
}
