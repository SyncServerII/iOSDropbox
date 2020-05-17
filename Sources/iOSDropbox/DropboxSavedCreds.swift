import PersistentValue
import Foundation
import iOSSignIn

class DropboxSavedCreds : GenericCredentialsCodable, Equatable {
    let userId: String // account_id in Dropbox terms
    
    var username: String?
    
    var uiDisplayName: String?
    
    let email:String
    
    var accessToken: String
    
    init(userId: String, username: String?, uiDisplayName: String?, email:String, accessToken: String) {
        self.userId = userId
        self.username = username
        self.uiDisplayName = uiDisplayName
        self.email = email
        self.accessToken = accessToken
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
