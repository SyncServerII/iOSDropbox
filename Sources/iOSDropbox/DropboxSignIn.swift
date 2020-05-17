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
    
    private var savedCreds:DropboxSavedCreds? {
        set {
            Self.credentialsData.value = try? newValue?.toData()
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
        if let savedCreds = savedCreds {
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
                stickySignIn = true
                delegate?.haveCredentials(self, credentials: creds)
                
                // Can only autoSignIn with Dropbox if we have creds. No way to refresh it seems.
                autoSignIn()
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
    
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success(let dropboxAccessToken):
                logger.info("Success! User is logged into Dropbox!")
                logger.info("Dropbox: access token: \(dropboxAccessToken.accessToken)")
                logger.info("Dropbox: uid: \(dropboxAccessToken.uid)")

                self.dropboxAccessToken = dropboxAccessToken
                
                // It seems we have to save the access token in the keychain, redundantly with Dropbox. I can't see a way to access it.                
                getCurrentAccountInfo(accessToken: dropboxAccessToken.accessToken)
                
            case .cancel:
                logger.info("Authorization flow was manually canceled by user!")
                signUserOut(cancelOnly: true)
                
            case .error(let oauth2Error, let description):
                logger.error("Error: \(description); oauth2Error: \(oauth2Error)")
                // This stemmed from an explicit sign-in request. It didn't complete successfully. Seems ok to sign out.
                signUserOut()
            }
            return true
        }

        return false
    }

    private func getCurrentAccountInfo(accessToken: String) {
        if let client = DropboxClientsManager.authorizedClient {
            client.users.getCurrentAccount().response {[unowned self] (response: Users.FullAccount?, error) in
                
                logger.info("Dropbox: getCurrentAccountInfo: response?.accountId: \(String(describing: response?.accountId))")
                
                // NOTE: This ^^^^ is *not* the same as the uid obtained when first signed in.
                
                if let usersFullAccount = response, error == nil {
                    self.savedCreds = DropboxSavedCreds(userId: usersFullAccount.accountId, username: usersFullAccount.name.displayName, uiDisplayName: usersFullAccount.name.displayName, email: usersFullAccount.email, accessToken: accessToken)
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
            signInOutButton = DropboxSignInButton(vc: vc, signIn: self)
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
        stickySignIn = false
        
        // I don't think this actually revokes the access token. Just clears it locally. Yes. Looking at their code, it just clears the keychain.
        DropboxClientsManager.unlinkClients()
        
        savedCreds = nil
        
        signInOutButton?.buttonShowing = .signIn
        
        if cancelOnly {
            delegate?.signInCancelled(self)
        }
        else {
            delegate?.userIsSignedOut(self)
        }
    }
    
    fileprivate func completeSignInProcess(autoSignIn:Bool) {
        signInOutButton?.buttonShowing = .signOut
        stickySignIn = true
        delegate?.signInCompleted(self, autoSignIn: autoSignIn)
    }
}


private class DropboxSignInButton : UIView {
    weak var vc: UIViewController?
    weak var signIn: DropboxSyncServerSignIn!

    // Spans the entire UIView
    var button = UIButton(type: .system)
    
    var dropboxIconView:UIImageView!
    let label = UILabel()
    
    // 12/27/17; I was having problems getting this to be called at the right time (it was just in `layoutSubviews` at the time), so I separated it out into its own function.
    private func layout() {
        button.frame.size = frame.size
        
        if let dropboxIconView = dropboxIconView {
            dropboxIconView.frame.origin.x = 5
            dropboxIconView.centerVerticallyInSuperview()
            
            label.sizeToFit()
            let remainingWidth = frame.width - dropboxIconView.frame.maxX
            label.center.x = dropboxIconView.frame.maxX + remainingWidth/2.0
            label.centerVerticallyInSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    override var frame: CGRect {
        set {
            super.frame = newValue
            layout()
        }
        
        get {
            return super.frame
        }
    }
        
    // Keeps only weak references to these parameters. You need to set the size of this button.
    init(vc: UIViewController?, signIn: DropboxSyncServerSignIn) {
        super.init(frame: CGRect.zero)
        self.vc = vc
        self.signIn = signIn
        
        button.backgroundColor = .white
        addSubview(button)

        dropboxIconView = UIImageView(image: DropboxIcon()?.image)
        dropboxIconView.contentMode = .scaleAspectFit
        
        // When I can use a better graphic asset, should be able to remove this.
        dropboxIconView.frame.size = CGSize(width: 30, height: 30)
        
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        
        button.addSubview(dropboxIconView)
        button.addSubview(label)
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        
        // Otherwise, `didSet` doesn't get called in init methods. Odd.
        defer {
            // Can't just statically set this-- need to depend on sign-in state. Because on an autosign-in, the button gets allocated late in the process.
            buttonShowing = signIn.userIsSignedIn ? .signOut : .signIn
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tap() {
        switch buttonShowing {
        case .signIn:
            signIn.delegate?.signInStarted(signIn)
            
            var controller:UIViewController?
            if let vc = vc {
                controller = vc
            }
            else {
                controller = UIViewController.getTop()
            }
        
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                controller: controller, openURL: { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
        case .signOut:
            signIn.signUserOut()
        }
    }
    
    enum State {
        case signIn
        case signOut
    }
    
    var buttonShowing:State = .signIn {
        didSet {
            logger.info("Change sign-in state: \(buttonShowing)")
            switch buttonShowing {
            case .signIn:
                label.text = "Sign-In with Dropbox"

            case .signOut:
                label.text = "Sign-Out from Dropbox"
            }

            layout()
        }
    }
}

