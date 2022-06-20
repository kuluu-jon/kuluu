import XCTest
@testable import kuluu_ffxi_emulator

final class FFXIEmulatorTests: XCTestCase {
    func testLoadEntitiesForZone() async throws {
        do {
            let entities = try await loadZoneDescriptorMap()
            XCTAssertFalse(entities.isEmpty)
        } catch {
            XCTFail((error as NSError).description)
//            XCTFail(error.localizedDescription)
        }
    }
}
