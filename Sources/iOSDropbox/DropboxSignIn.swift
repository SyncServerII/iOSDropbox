//
//  DropboxSignIn.swift
//  SyncServer
//
//  Created by Christopher Prince on 12/5/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import Foundation
import SwiftyDropbox
import PersistentValue
import iOSSignIn
import ServerShared
import iOSShared

public class DropboxSyncServerSignIn : GenericSignIn {
    public var signInName = "Dropbox"
    
    private var stickySignIn = false
    private var dropboxAccessToken:DropboxAccessToken?
    
    public var delegate:GenericSignInDelegate?
    private var signInOutButton:DropboxSignInButton?
    
    static private let credentialsData = try! PersistentValue<Data>(name: "DropboxSignIn.data", storage: .keyChain)
    
    public init(appKey: String) {
        DropboxClientsManager.setupWithAppKey(appKey)
    }
    
    static var savedCreds:DropboxSavedCreds? {
        set {
            let data = try? newValue?.toData()
#if DEBUG
            if let data = data {
                let string = String(data: data, encoding: .utf8)
                logger.debug("savedCreds: \(String(describing: string))")
            }
#endif
            Self.credentialsData.value = data
        }
        
        get {
            guard let data = Self.credentialsData.value,
                let savedCreds = try? DropboxSavedCreds.fromData(data) else {
                return nil
            }
            return savedCreds
        }
    }
    
    public var credentials:GenericCredentials? {
        if let savedCreds = Self.savedCreds {
            return DropboxCredentials(savedCreds: savedCreds)
        }
        else {
            return nil
        }
    }
    
    public let userType:UserType = .owning
    public let cloudStorageType: CloudStorageType? = .Dropbox
    
    public func appLaunchSetup(userSignedIn: Bool, withLaunchOptions options:[UIApplication.LaunchOptionsKey : Any]?) {

        if userSignedIn {
            if let creds = credentials {
                creds.refreshCredentials { [weak self] error in
                    guard let self = self else {
                        return
                    }
                    
                    if let error = error {
                        logger.error("appLaunchSetup: \(error)")
                        // I'm not going to sign the user out. This could just be a network error.
                        return
                    }

                    self.stickySignIn = true
                    self.delegate?.haveCredentials(self, credentials: creds)
                    self.autoSignIn()
                }
            }
            else {
                // Doesn't seem much point in keeping the user with signed-in status if we don't have creds.
                signUserOut()
            }
        }
    }
    
    public func networkChangedState(networkIsOnline: Bool) {
        if stickySignIn && networkIsOnline && credentials == nil {
            logger.info("DropboxSignIn: Trying autoSignIn...")
            autoSignIn()
        }
    }
    
    private func autoSignIn() {
        self.completeSignInProcess(autoSignIn: true)
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return DropboxClientsManager.handleRedirectURL(url) {[weak self] dropboxOAuthResult in
            guard let self = self else { return }
            guard let dropboxOAuthResult = dropboxOAuthResult else {
                logger.error("Error: Nil dropboxOAuthResult")
                self.signUserOut()
                return
            }
            
            switch dropboxOAuthResult {
            case .success(let dropboxAccessToken):
                logger.info("Success! User is logged into Dropbox!")
                logger.info("Dropbox: access token: \(dropboxAccessToken.accessToken)")
                logger.info("Dropbox: uid: \(dropboxAccessToken.uid)")
                logger.info("Dropbox: refresh token: \(String(describing: dropboxAccessToken.refreshToken))")
                
                self.dropboxAccessToken = dropboxAccessToken
                
                guard let refreshToken = dropboxAccessToken.refreshToken else {
                    logger.info("Authorization flow: No refresh token obtained!")
                    self.signUserOut(cancelOnly: false)
                    return
                }
                
                // It seems we have to save the access and refresh tokens in the keychain, redundantly with Dropbox. I can't see a way to access them.
                self.getCurrentAccountInfo(accessToken: dropboxAccessToken.accessToken, refreshToken: refreshToken, dropboxAccessToken: dropboxAccessToken)
                
            case .cancel:
                logger.info("Authorization flow was manually canceled by user!")
                self.signUserOut(cancelOnly: true)
                
            case .error(let oauth2Error, let description):
                logger.error("Error: \(String(describing: description)); oauth2Error: \(oauth2Error)")
                // This stemmed from an explicit sign-in request. It didn't complete successfully. Seems ok to sign out.
                self.signUserOut()
            }
        }
    }

    private func getCurrentAccountInfo(accessToken: String, refreshToken: String, dropboxAccessToken: DropboxAccessToken) {
        if let client = DropboxClientsManager.authorizedClient {
            client.users.getCurrentAccount().response {[unowned self] (response: Users.FullAccount?, error) in
                
                logger.info("Dropbox: getCurrentAccountInfo: response?.accountId: \(String(describing: response?.accountId))")
                
                // NOTE: This ^^^^ is *not* the same as the uid obtained when first signed in.
                
                if let usersFullAccount = response, error == nil {
                    Self.savedCreds = DropboxSavedCreds(cloudStorageType: .Dropbox, userId: usersFullAccount.accountId, username: usersFullAccount.name.displayName, uiDisplayName: usersFullAccount.name.displayName, email: usersFullAccount.email, accessToken: accessToken, refreshToken: refreshToken, dropboxAccessToken: dropboxAccessToken)
                    self.completeSignInProcess(autoSignIn: false)
                } else {
                    // This stemmed from an explicit sign-in request.
                    self.signUserOut()
                    logger.error("Problem with getCurrentAccount: \(String(describing: error))")
                }
            }
        }
    }
    
    /// If the parameter is be given, it needs to have a key "viewController" and value, a `UIViewController` conforming object. If this is not given, the top-appearing view controller will be used later by iOSDropbox, if one is present. A view controller is used for at least presenting error messages.
    @discardableResult
    public func signInButton(configuration:[String:Any]?) -> UIView? {
        if signInOutButton == nil {
            let vc = configuration?["viewController"] as? UIViewController
            
            do {
                signInOutButton = try DropboxSignInButton(vc: vc, signIn: self)
                signInOutButton?.delegate = self
            } catch let error {
                logger.error("\(error)")
                return nil
            }
        }
        
        return signInOutButton
    }
    
    public var userIsSignedIn: Bool {
        return stickySignIn
    }

    public func signUserOut() {
        signUserOut(cancelOnly: false)
    }
    
    private func signUserOut(cancelOnly: Bool) {
        DispatchQueue.main.async {
            self.stickySignIn = false
            
            // I don't think this actually revokes the access token. Just clears it locally. Yes. Looking at their code, it just clears the keychain.
            DropboxClientsManager.unlinkClients()
            
            Self.savedCreds = nil
            
            self.signInOutButton?.buttonShowing = .signIn
            
            if cancelOnly {
                self.delegate?.signInCancelled(self)
            }
            else {
                self.delegate?.userIsSignedOut(self)
            }
        }
    }
    
    fileprivate func completeSignInProcess(autoSignIn:Bool) {
        DispatchQueue.main.async {
            self.signInOutButton?.buttonShowing = .signOut
            self.stickySignIn = true
            self.delegate?.signInCompleted(self, autoSignIn: autoSignIn)
        }
    }
    
    static var scopes:[String] {
        // See https://dropbox.tech/developers/migrating-app-permissions-and-access-tokens
        return [
            "account_info.read",
            "files.metadata.read",
            "files.content.read",
            "files.content.write",
            
            // Needed for endpoint on server: https://www.dropbox.com/developers/documentation/http/documentation#users-get_account
            "sharing.read",
            
            // Needed for endpoint on server: https://www.dropbox.com/developers/documentation/http/documentation#file_requests-delete
            "file_requests.write"
        ]
    }
}

extension DropboxSyncServerSignIn: DropboxButtonDelegate {
    func signIn(_ button: DropboxSignInButton, vc: UIViewController?) {
        delegate?.signInStarted(self)

        // New: OAuth 2 code flow with PKCE that grants a short-lived token with scopes.
        
        var controller:UIViewController?
        if let vc = vc {
            controller = vc
        }
        else {
            controller = UIViewController.getTop()
        }
        
        let scopeRequest = ScopeRequest(scopeType: .user, scopes: Self.scopes, includeGrantedScopes: false)
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: controller,
            loadingStatusDelegate: nil,
            openURL: { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            },
            scopeRequest: scopeRequest
        )
    }
    
    func signOut(_ button: DropboxSignInButton) {
        signUserOut()
    }
}
