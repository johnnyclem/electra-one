import Testing
@testable import ElectraKit

@Suite struct DeviceSummarizeTests {
    @Test func summarizeCountsStructure() {
        let json = """
        {"name": "Bass", "version": 2, "projectId": "p1",
         "pages": [{"id": 1}, {"id": 2}],
         "devices": [{"name": "Synth"}, {"name": "Drum"}],
         "controls": [{"id": 1}, {"id": 2}, {"id": 3}]}
        """
        let s = E1Device.summarize(text: json)
        #expect(s != nil)
        #expect(s?.name == "Bass")
        #expect(s?.version == 2)
        #expect(s?.pages == 2)
        #expect(s?.controls == 3)
        #expect(s?.devices == 2)
        #expect(s?.deviceNames == ["Synth", "Drum"])
    }

    @Test func summarizeUnnamedFallback() {
        let s = E1Device.summarize(text: "{\"controls\": []}")
        #expect(s?.name == "(unnamed)")
        #expect(s?.controls == 0)
    }

    @Test func summarizeRejectsNonObject() {
        #expect(E1Device.summarize(text: "[1,2,3]") == nil)
        #expect(E1Device.summarize(text: "garbage") == nil)
    }
}
