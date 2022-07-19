//
//  Copyright © 2021-2022 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

@objc(PSCFileHelper)
public class FileHelper: NSObject {

    /// Creates a temporary file URL.
    @objc public class func temporaryFileURL(prefix: String?, pathExtension: String) -> URL {
        let pathExtensionWithDot = pathExtension.hasPrefix(".") ? pathExtension : ".\(pathExtension)"
        let uuidString = prefix != nil ? NSUUID().uuidString : "_\(NSUUID().uuidString)"

        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempURL = tempDirectory.appendingPathComponent("\(prefix ?? "")\(uuidString)\(pathExtensionWithDot)", isDirectory: false)
        return tempURL
    }

    /// Creates a temporary PDF file URL.
    public class func temporaryPDFFileURL(prefix: String? = nil) -> URL {
        return temporaryFileURL(prefix: prefix, pathExtension: ".pdf")
    }

    /// Copies a file to the documents directory.
    @objc public class func copyFileURLToDocumentDirectory(_ documentURL: URL, overwrite: Bool) -> URL {
        // Copy file from original location to the Document directory (a location we can write to).
        let docsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let newURL = docsFolder.appendingPathComponent(documentURL.lastPathComponent, isDirectory: false)
        let exists = FileManager.default.fileExists(atPath: newURL.path)
        if overwrite {
            do {
                try FileManager.default.removeItem(at: newURL)
            } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
                // The file not existing doesn’t need reporting as an error since that’s what we want anyway.
            } catch {
                print("Error while removing file at \(newURL.path): \(error.localizedDescription)")
            }
        }

        if !exists || overwrite {
            do {
                try FileManager.default.copyItem(at: documentURL, to: newURL)
            } catch {
                print("Error while copying \(documentURL.path): \(error.localizedDescription)")
            }
        }

        return newURL
    }
}
