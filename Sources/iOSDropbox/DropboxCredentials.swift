import Foundation
import iOSSignIn
import ServerShared

public class DropboxCredentials : GenericCredentials, CustomDebugStringConvertible {
    var savedCreds:DropboxSavedCreds!
    var accessToken:String! {
        return savedCreds.accessToken
    }
    
    // Helper
    public init(savedCreds:DropboxSavedCreds) {
        self.savedCreds = savedCreds
    }
    
    /// A unique identifier for the user. For Dropbox this is their account_id.
    public var userId:String {
        return savedCreds.userId
    }

    /// This is sent to the server as a human-readable means to identify the user.
    public var username:String? {
        return savedCreds.username
    }

    /// A name suitable for identifying the user via the UI. If available this should be the users email. Otherwise, it could be the same as the username.
    public var uiDisplayName:String? {
        return savedCreds.email
    }
    
    public var debugDescription: String {
        return "Dropbox: accessToken: \(String(describing: accessToken)); userId: \(userId)"
    }

    public var httpRequestHeaders:[String:String] {
        var result = [String:String]()
        result[ServerConstants.XTokenTypeKey] = AuthTokenType.DropboxToken.rawValue
        result[ServerConstants.HTTPOAuth2AccessTokenKey] = accessToken
        result[ServerConstants.HTTPAccountIdKey] = savedCreds.userId
        result[ServerConstants.httpRequestRefreshToken] = savedCreds.userId
        return result
    }

    /// Dropbox doesn't have a creds refresh.
    public func refreshCredentials(completion: @escaping (Error?) ->()) {
        // Dropbox access tokens live until the user revokes them, so no need to refresh. See https://www.dropboxforum.com/t5/API-support/API-v2-access-token-validity/td-p/215123
        // 12/24/20; That's no longer true. But this method isn't used any more on the client.
        completion(GenericCredentialsError.noRefreshAvailable)
    }
}
