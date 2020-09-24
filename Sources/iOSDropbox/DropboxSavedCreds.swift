import PersistentValue
import Foundation
import iOSSignIn
import ServerShared

// Helper class
public class DropboxSavedCreds : GenericCredentialsCodable, Equatable {
    public let cloudStorageType: CloudStorageType?
    
    public let userId: String // account_id in Dropbox terms
    
    public var username: String?
    
    public var uiDisplayName: String?
    
    public let email:String
    
    public var accessToken: String
    
    public init(cloudStorageType: CloudStorageType, userId: String, username: String?, uiDisplayName: String?, email:String, accessToken: String) {
        self.userId = userId
        self.username = username
        self.uiDisplayName = uiDisplayName
        self.email = email
        self.accessToken = accessToken
        self.cloudStorageType = cloudStorageType
    }
    
    // [1] Change to using PersistentValue .file to avoid issues with background launches.
    //static private var data = try! PersistentValue<Data>(name: "DropboxSavedCreds.data", storage: .file)
    
    public static func == (lhs: DropboxSavedCreds, rhs: DropboxSavedCreds) -> Bool {
        return lhs.userId == rhs.userId &&
            lhs.username == rhs.username &&
            lhs.uiDisplayName == rhs.uiDisplayName &&
            lhs.email == rhs.email &&
            lhs.accessToken == rhs.accessToken
    }
}
