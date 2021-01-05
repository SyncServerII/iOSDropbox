import PersistentValue
import Foundation
import iOSSignIn
import ServerShared
import SwiftyDropbox

// Helper class
public class DropboxSavedCreds : GenericCredentialsCodable, Equatable {
    // Redundant, but for convenience when refereshing access token. This is only optional for testing.
    public let dropboxAccessToken: DropboxAccessToken?
    
    public let cloudStorageType: CloudStorageType?
    
    public let userId: String // account_id in Dropbox terms
    
    public var username: String?
    
    public var uiDisplayName: String?
    
    public let email:String
    
    public var accessToken: String
    
    public var refreshToken: String
    
    public init(cloudStorageType: CloudStorageType, userId: String, username: String?, uiDisplayName: String?, email:String, accessToken: String, refreshToken: String, dropboxAccessToken: DropboxAccessToken?) {
        self.userId = userId
        self.username = username
        self.uiDisplayName = uiDisplayName
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.cloudStorageType = cloudStorageType
        self.dropboxAccessToken = dropboxAccessToken
    }
    
    // Update tokens
    init(creds: DropboxSavedCreds, accessToken: String, refreshToken: String, dropboxAccessToken: DropboxAccessToken) {
            self.userId = creds.userId
            self.username = creds.username
            self.uiDisplayName = creds.uiDisplayName
            self.email = creds.email
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.cloudStorageType = creds.cloudStorageType
            self.dropboxAccessToken = dropboxAccessToken
    }
    
    // [1] Change to using PersistentValue .file to avoid issues with background launches.
    //static private var data = try! PersistentValue<Data>(name: "DropboxSavedCreds.data", storage: .file)
    
    public static func == (lhs: DropboxSavedCreds, rhs: DropboxSavedCreds) -> Bool {
        return lhs.userId == rhs.userId &&
            lhs.username == rhs.username &&
            lhs.uiDisplayName == rhs.uiDisplayName &&
            lhs.email == rhs.email &&
            lhs.accessToken == rhs.accessToken &&
            lhs.refreshToken == rhs.refreshToken
    }
}
