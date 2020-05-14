# iOSDropbox
iOS Dropbox library for SyncServerII


1) Register your application in the Dropbox App Console. 
https://dropbox.com/developers/apps
Part of what you get here is a  DropboxAppKey

2) Add a Dropbox URL scheme to your app in Xcode
(See https://github.com/dropbox/SwiftyDropbox#get-started)

```
<key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>db-<APP_KEY></string>
            </array>
            <key>CFBundleURLName</key>
            <string></string>
        </dict>
    </array>
```

3) Into your Info.plist for your app, add:

```
<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>dbapi-8-emm</string>
		<string>dbapi-2</string>
	</array>
```

4) Pass the DropboxAppKey to the  `DropboxSyncServerSignIn`  constructor.

See also 
https://www.dropbox.com/developers/documentation/swift
