//
//  Copyright © 2021-2022 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

enum Examples {

    /// The sorted array of all examples found by runtime introspection.
    static let all: [Example] = {
        // Get all subclasses and instantiate them.
        let exampleSubclasses = PSCGetAllExampleSubclasses()
        var examples: [Example] = []
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let currentDevice: PSCExampleTargetDeviceMask = isIPad ? .pad : .phone
        for exampleSubclass in exampleSubclasses {
            guard let exampleSubclass = exampleSubclass as? Example.Type else { continue }
            let example: Example = exampleSubclass.init()
            if example.targetDevice.contains(currentDevice) {
                examples.append(example)
            }
        }
        return examples.sorted()
    }()

    /// The sorted array of examples grouped by category.
    static let grouped: [(Example.Category, [Example])] = {
        let dict = all.reduce(into: [:]) { $0[$1.category, default: []].append($1) }
        return dict.sorted { $0.key.rawValue < $1.key.rawValue }
    }()

    /// The sorted array of examples matching the given query.
    static func matching(_ query: String) -> [Example] {
        let predicate = NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Example.title), query)
        return (all as NSArray).filtered(using: predicate) as? [Example] ?? []
    }

}
