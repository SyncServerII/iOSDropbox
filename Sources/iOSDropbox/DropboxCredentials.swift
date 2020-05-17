import Foundation
import iOSSignIn
import ServerShared

public class DropboxCredentials : GenericCredentials {
    var savedCreds:DropboxSavedCreds!
    var accessToken:String!
    
    init(savedCreds:DropboxSavedCreds, accessToken:String) {
        self.savedCreds = savedCreds
        self.accessToken = accessToken
    }
    
    /// A unique identifier for the user. E.g., for Google this is their `sub`.
    public var userId:String {
        return savedCreds.uid
    }

    /// This is sent to the server as a human-readable means to identify the user.
    public var username:String? {
        return savedCreds.displayName
    }

    /// A name suitable for identifying the user via the UI. If available this should be the users email. Otherwise, it could be the same as the username.
    public var uiDisplayName:String? {
        return savedCreds.email
    }

    public var httpRequestHeaders:[String:String] {
        var result = [String:String]()
        result[ServerConstants.XTokenTypeKey] = AuthTokenType.DropboxToken.rawValue
        result[ServerConstants.HTTPOAuth2AccessTokenKey] = accessToken
        result[ServerConstants.HTTPAccountIdKey] = savedCreds.accountId
        return result
    }

    /// Dropbox doesn't have a creds refresh.
    public func refreshCredentials(completion: @escaping (Error?) ->()) {
        // Dropbox access tokens live until the user revokes them, so no need to refresh. See https://www.dropboxforum.com/t5/API-support/API-v2-access-token-validity/td-p/215123
        completion(GenericCredentialsError.noRefreshAvailable)
    }
}