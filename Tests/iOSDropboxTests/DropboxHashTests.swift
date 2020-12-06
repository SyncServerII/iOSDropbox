
import XCTest
@testable import iOSDropbox

class DropboxHashTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHashFromJPGFile() throws {
        // See https://stackoverflow.com/questions/47177036/use-resources-in-unit-tests-with-swift-package-manager
        guard let imageFile = Bundle.module.url(forResource: "Cat", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let knownCorrectHash = "d342f6ab222c322e5fccf148435ef32bd676d7ce0baa72ea88593ef93bef8ac2"
                
        let hash = try DropboxHashing.generateDropbox(fromLocalFile: imageFile)
        XCTAssert(knownCorrectHash == hash)
    }
    
    func testHashFromMovFile() throws {
        guard let movFile = Bundle.module.url(forResource: "Cat", withExtension: "mov") else {
            XCTFail()
            return
        }

        let knownCorrectHash = "8de78010c152c2d44ae50e05ecfacc48976c6bc155ab532a895ac1abfc1c542d"
                
        let hash = try DropboxHashing.generateDropbox(fromLocalFile: movFile)
        // print("hash: \(hash)")
        XCTAssert(knownCorrectHash == hash)
    }
}
