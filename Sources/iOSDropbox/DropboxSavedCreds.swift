import PersistentValue
import Foundation
import iOSSignIn
import ServerShared

class DropboxSavedCreds : GenericCredentialsCodable, Equatable {
    let cloudStorageType: CloudStorageType?
    
    let userId: String // account_id in Dropbox terms
    
    var username: String?
    
    var uiDisplayName: String?
    
    let email:String
    
    var accessToken: String
    
    init(cloudStorageType: CloudStorageType, userId: String, username: String?, uiDisplayName: String?, email:String, accessToken: String) {
        self.userId = userId
        self.username = username
        self.uiDisplayName = uiDisplayName
        self.email = email
        self.accessToken = accessToken
        self.cloudStorageType = cloudStorageType
    }
    
    // [1] Change to using PersistentValue .file to avoid issues with background launches.
    //static private var data = try! PersistentValue<Data>(name: "DropboxSavedCreds.data", storage: .file)
    
    static func == (lhs: DropboxSavedCreds, rhs: DropboxSavedCreds) -> Bool {
        return lhs.userId == rhs.userId &&
            lhs.username == rhs.username &&
            lhs.uiDisplayName == rhs.uiDisplayName &&
            lhs.email == rhs.email &&
            lhs.accessToken == rhs.accessToken
    }
}
