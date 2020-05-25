import iOSShared
import Foundation
import ServerShared

// CommonCrypto is only available with Xcode 10 for import into Swift; see also https://stackoverflow.com/questions/25248598/importing-commoncrypto-in-a-swift-framework
import CommonCrypto

public struct DropboxHashing: CloudStorageHashing {
    enum DropboxHashingError: Error {
        case errorOpeningInputStream
        case lengthBoundsProblem
    }
    
    public var cloudStorageType: CloudStorageType = .Dropbox
    
    public init() {
    }
    
    public func hash(forURL url: URL) throws -> String {
        return try Self.generateDropbox(fromLocalFile: url)
    }
    
    public func hash(forData data: Data) throws -> String {
        return try Self.generateDropbox(fromData: data)
    }
    
    // From https://stackoverflow.com/questions/25388747/sha256-in-swift
    static func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    private static let dropboxBlockSize = 1024 * 1024 * 4

    // Method: https://www.dropbox.com/developers/reference/content-hash
    static func generateDropbox(fromLocalFile localFile: URL) throws -> String {
        guard let inputStream = InputStream(url: localFile) else {
            logger.error("Error opening input stream: \(localFile)")
            throw DropboxHashingError.errorOpeningInputStream
        }

        var inputBuffer = [UInt8](repeating: 0, count: dropboxBlockSize)
        inputStream.open()
        defer {
            inputStream.close()
        }
        
        var concatenatedSHAs = Data()
        
        while true {
            let length = inputStream.read(&inputBuffer, maxLength: dropboxBlockSize)
            if length == 0 {
                // EOF
                break
            }
            else if length < 0 {
                throw DropboxHashingError.lengthBoundsProblem
            }
            
            let dataBlock = Data(bytes: inputBuffer, count: length)
            let sha = sha256(data: dataBlock)
            concatenatedSHAs.append(sha)
        }
        
        let finalSHA = sha256(data: concatenatedSHAs)
        let hexString = finalSHA.map { String(format: "%02hhx", $0) }.joined()

        return hexString
    }
    
    static func generateDropbox(fromData data: Data) throws -> String {
        var concatenatedSHAs = Data()
        
        var remainingLength = data.count
        if remainingLength == 0 {
            throw DropboxHashingError.lengthBoundsProblem
        }
        
        var startIndex = data.startIndex

        while true {
            let nextBlockSize = min(remainingLength, dropboxBlockSize)
            let endIndex = startIndex.advanced(by: nextBlockSize)
            let range = startIndex..<endIndex
            startIndex = endIndex
            remainingLength -= nextBlockSize

            let sha = sha256(data: data[range])
            concatenatedSHAs.append(sha)
            
            if remainingLength == 0 {
                break
            }
        }
        
        let finalSHA = sha256(data: concatenatedSHAs)
        let hexString = finalSHA.map { String(format: "%02hhx", $0) }.joined()

        return hexString
    }
}
