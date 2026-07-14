import XCTest
import Foundation
@testable import ElectraKit

final class DeviceSummarizeTests: XCTestCase {
    func test_summarizeCountsStructure() {
        let json = """
        {"name": "Bass", "version": 2, "projectId": "p1",
         "pages": [{"id": 1}, {"id": 2}],
         "devices": [{"name": "Synth"}, {"name": "Drum"}],
         "controls": [{"id": 1}, {"id": 2}, {"id": 3}]}
        """
        let s = E1Device.summarize(text: json)
        XCTAssertNotEqual(s, nil)
        XCTAssertEqual(s?.name, "Bass")
        XCTAssertEqual(s?.version, 2)
        XCTAssertEqual(s?.pages, 2)
        XCTAssertEqual(s?.controls, 3)
        XCTAssertEqual(s?.devices, 2)
        XCTAssertEqual(s?.deviceNames, ["Synth", "Drum"])
    }

    func test_summarizeUnnamedFallback() {
        let s = E1Device.summarize(text: "{\"controls\": []}")
        XCTAssertEqual(s?.name, "(unnamed)")
        XCTAssertEqual(s?.controls, 0)
    }

    func test_summarizeRejectsNonObject() {
        XCTAssertEqual(E1Device.summarize(text: "[1,2,3]"), nil)
        XCTAssertEqual(E1Device.summarize(text: "garbage"), nil)
    }
}
