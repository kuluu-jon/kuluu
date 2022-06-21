import XCTest
<<<<<<< Updated upstream
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
=======
@testable import noesis_scene_generator

final class noesis_scene_generatorTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(noesis_scene_generator().text, "Hello, World!")
>>>>>>> Stashed changes
    }
}
