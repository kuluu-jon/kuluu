import XCTest
//@testable import Networking
@testable import CryptoSwift

final class NetworkingTests: XCTestCase {
    func testBlowfish() throws {
        let key: [UInt8] = [114, 189, 246, 38, 26, 11, 78, 227, 142, 196, 28, 87, 171, 106, 172, 37]
        let cipher = try Blowfish(key: key, padding: .pkcs7)
        let xl = 123456
        let xr = 654321
        var input = [UInt8](xl.bytes())
        input.append(contentsOf: xr.bytes())
        let ciphertext = try cipher.encrypt(input)
        let plaintext = try cipher.decrypt(ciphertext)
        XCTAssertEqual(plaintext, input)
    }
}
