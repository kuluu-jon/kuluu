import XCTest
@testable import zone_metadata_generator

final class zone_metadata_generatorTests: XCTestCase {
    func testLoadEntitiesForZone() async throws {
        do {
            let entities = try await loadZoneDescriptorMap()
            print(entities)
            XCTAssertFalse(entities.isEmpty)
        } catch {
            XCTFail((error as NSError).description)
            //            XCTFail(error.localizedDescription)
        }
    }
}
