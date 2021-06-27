import Foundation
import iOSSignIn
import ServerShared
import SwiftyDropbox
import iOSShared

public class DropboxCredentials : GenericCredentials, CustomDebugStringConvertible {
    enum DropboxCredentialsError: Error {
        case noCredentials
        case noRefreshToken
        case errorWhenRefreshing
    }
    
    var savedCreds:DropboxSavedCreds!
    var accessToken:String! {
        return savedCreds.accessToken
    }
    
    // Helper
    public init(savedCreds:DropboxSavedCreds) {
        self.savedCreds = savedCreds
    }
    
    public var emailAddress: String! {
        return savedCreds.emailAddress
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
        return savedCreds.emailAddress
    }
    
    public var debugDescription: String {
        return "Dropbox: accessToken: \(String(describing: accessToken)); userId: \(userId)"
    }

    public var httpRequestHeaders:[String:String] {
        var result = [String:String]()
        result[ServerConstants.XTokenTypeKey] = AuthTokenType.DropboxToken.rawValue
        result[ServerConstants.HTTPOAuth2AccessTokenKey] = savedCreds.accessToken
        result[ServerConstants.HTTPAccountIdKey] = savedCreds.userId
        result[ServerConstants.httpRequestRefreshToken] = savedCreds.refreshToken
        return result
    }

    func callCompletion(error:Error?, completion: @escaping (Error?) ->()) {
        DispatchQueue.main.async {
            completion(error)
        }
    }
    
    /// Calls the completion handler on the main queue. On a nil return self has been updated with new creds, as has DropboxSyncServerSignIn.
    public func refreshCredentials(completion: @escaping (Error?) ->()) {
        guard let savedCreds = savedCreds,
            let dropboxAccessToken = savedCreds.dropboxAccessToken else {
            logger.error("DropboxCredentialsError.noCredentials")
            callCompletion(error: DropboxCredentialsError.noCredentials, completion: completion)
            return
        }
        
        DropboxOAuthManager.sharedOAuthManager.refreshAccessToken(dropboxAccessToken, scopes: DropboxSyncServerSignIn.scopes, queue: DispatchQueue.main) { [weak self] result in
            guard let self = self else {
                logger.error("DropboxCredentialsError: No self!")
                return
            }
            
            switch result {
            case .success(let dropboxAccessToken):
                guard let refreshToken = dropboxAccessToken.refreshToken else {
                    logger.error("DropboxCredentialsError.noRefreshToken")
                    self.callCompletion(error: DropboxCredentialsError.noRefreshToken, completion: completion)
                    return
                }
                
                self.savedCreds = DropboxSavedCreds(creds: savedCreds, accessToken: dropboxAccessToken.accessToken, refreshToken: refreshToken, dropboxAccessToken: dropboxAccessToken)
                DropboxSyncServerSignIn.savedCreds = self.savedCreds
                self.callCompletion(error: nil, completion: completion)
                
            case .error(let error, let errorString):
                logger.error("\(error); \(String(describing: errorString))")
                self.callCompletion(error: DropboxCredentialsError.errorWhenRefreshing, completion: completion)
                
            default:
                logger.error("DropboxCredentialsError.errorWhenRefreshing")
                self.callCompletion(error: DropboxCredentialsError.errorWhenRefreshing, completion: completion)
            }
        }
    }
}
