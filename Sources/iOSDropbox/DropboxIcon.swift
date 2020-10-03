import Foundation
import UIKit
import iOSShared

struct DropboxIcon {
    static var iconBundleFile = ("db_x80", "png")

    static var fileURL: URL? {
        // https://developer.apple.com/documentation/swift_packages/bundling_resources_with_a_swift_package
        return Bundle.module.url(forResource: iconBundleFile.0, withExtension: iconBundleFile.1)
    }
    
    static var image: UIImage? {
        guard let url = fileURL else {
            logger.error("Could not get icon URL")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: url) else {
            logger.error("Could not get image data")
            return nil
        }
        
        return UIImage(data: imageData)
    }
}
