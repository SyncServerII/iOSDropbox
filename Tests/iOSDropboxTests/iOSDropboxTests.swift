import XCTest
@testable import iOSDropbox

final class iOSDropboxTests: XCTestCase {
    func testDropboxIcon() {
        guard let _ = DropboxIcon()?.image else {
            XCTFail()
            return
        }
    }
}
