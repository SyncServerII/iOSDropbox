
import Foundation
import UIKit
import SwiftyDropbox
import iOSShared

protocol DropboxButtonDelegate: AnyObject {
    func signIn(_ button: DropboxSignInButton, vc: UIViewController?)
    func signOut(_ button: DropboxSignInButton)
}

class DropboxSignInButton : UIView {
    weak var delegate: DropboxButtonDelegate?
    weak var vc: UIViewController?

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
    
    enum DropboxSignInButtonError: Error {
        case couldNotGetImage
    }
    
    // Keeps only weak references to these parameters. You need to set the size of this button.
    init(vc: UIViewController?, signIn: DropboxSyncServerSignIn) throws {
        super.init(frame: CGRect.zero)
        self.vc = vc
        
        button.backgroundColor = .clear
        addSubview(button)
        
        guard let iconImage = DropboxIcon.image else {
            throw DropboxSignInButtonError.couldNotGetImage
        }

        dropboxIconView = UIImageView(image: iconImage)
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
            delegate?.signIn(self, vc: vc)

        case .signOut:
            delegate?.signOut(self)
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
                #warning("Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates.")
                label.text = "Sign-In with Dropbox"

            case .signOut:
                label.text = "Sign-Out from Dropbox"
            }

            layout()
        }
    }
}

