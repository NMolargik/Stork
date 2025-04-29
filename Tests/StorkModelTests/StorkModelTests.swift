import XCTest
import OSLog
import SkipFoundation
@testable import StorkModel

let logger: Logger = Logger(subsystem: "StorkModel", category: "Tests")

@available(macOS 13, *)
final class StorkModelTests: XCTestCase {
    func testStorkModel() throws {
        logger.log("running testStorkModel")
        XCTAssertEqual(1 + 2, 3, "basic test")
        
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("StorkModel", testData.testModuleName)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
