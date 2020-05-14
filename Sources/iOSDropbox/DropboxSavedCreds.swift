import PersistentValue
import Foundation

// Purely for saving creds into NSUserDefaults
// NSObject subclass needed for NSCoding to work.
class DropboxSavedCreds : NSObject, NSCoding {
    // From the Dropbox docs: `The associated user`
    /* And at: https://www.dropbox.com/developers/documentation/http/documentation#users-get_account
     `uid String Deprecated. The API v1 user/team identifier. Please use account_id instead, or if using the Dropbox Business API, team_id.`
    */
    var uid: String!
    
    var displayName:String!
    var email:String!
    
    // This is what we're sending up the server. From the code docs from Dropbox: `The user's unique Dropbox ID.`
    var accountId: String!
    
    // [1] Change to using PersistentValue .file to avoid issues with background launches.
    static private var data = try! PersistentValue<Data>(name: "DropboxSavedCreds.data", storage: .file)

    init(uid:String, accountId:String, displayName:String, email:String) {
        self.uid = uid
        self.accountId = accountId
        self.displayName = displayName
        self.email = email
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uid, forKey: "uid")
        aCoder.encode(accountId, forKey: "accountId")
        aCoder.encode(displayName, forKey: "displayName")
        aCoder.encode(email, forKey: "email")
    }
    
    required init?(coder aDecoder: NSCoder) {
        uid = (aDecoder.decodeObject(forKey: "uid") as! String)
        accountId = (aDecoder.decodeObject(forKey: "accountId") as! String)
        displayName = (aDecoder.decodeObject(forKey: "displayName") as! String)
        email = (aDecoder.decodeObject(forKey: "email") as! String)
    }
    
    func save() throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        DropboxSavedCreds.data.value = data
    }
    
    static func retrieve() throws -> DropboxSavedCreds? {
        guard let data = DropboxSavedCreds.data.value else {
            return nil
        }
                
        if let object = try NSKeyedUnarchiver.unarchivedObject(ofClass: DropboxSavedCreds.self, from: data) {
            return object
        }
        else {
            return nil
        }
    }
}
