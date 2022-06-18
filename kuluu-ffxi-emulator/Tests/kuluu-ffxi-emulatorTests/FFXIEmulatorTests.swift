import XCTest
@testable import kuluu_ffxi_emulator

final class FFXIEmulatorTests: XCTestCase {
    func testLoadEntitiesForZone() async throws {
        let entities = try await loadEntitiesForZone(id: 0)
        XCTAssertFalse(entities.isEmpty)
    }
}
