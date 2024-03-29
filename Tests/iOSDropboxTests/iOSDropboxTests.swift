import XCTest
@testable import iOSDropbox
import SwiftyDropbox

class iOSDropboxTests: XCTestCase {
    func testDropboxIconURL() {
        guard let _ = DropboxIcon.fileURL else {
            XCTFail()
            return
        }
    }
    
    func testDropboxIconImage() {
        guard let _ = DropboxIcon.image else {
            XCTFail()
            return
        }
    }
    
    func testDropboxSavedCreds() throws {
        let creds = DropboxSavedCreds(cloudStorageType: .Dropbox, userId: "user", username: "username", uiDisplayName: "displayName", email: "email", accessToken: "token", refreshToken: "refresh", dropboxAccessToken: nil)
        let data = try creds.toData()
        let creds2 = try DropboxSavedCreds.fromData(data)
        XCTAssert(creds == creds2)
    }
}
