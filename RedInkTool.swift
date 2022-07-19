//
//  Copyright © 2018-2022 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import PSPDFKit
import PSPDFKitUI


class CreateAnnotationsFastModeExample: Example {

    override init() {
        super.init()
        title = "Add custom Red Ink Tool"
        category = .annotations
        priority = 202
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .quickStart)
        let pdfController = PDFViewController(document: document) {
            $0.overrideClass(AnnotationToolbar.self, with: CustomAnnotationToolbar.self)
        }
        return pdfController
    }
}

private class CustomAnnotationToolbar: AnnotationToolbar {
    let redInk = Annotation.Variant(rawValue: "my_red_tool")

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let ink = Item(type: .ink)
        let inkRedTool = Item(type: .ink, variant: redInk, configurationBlock: {_, _, _ in
            return SDK.imageNamed("ink")!.withRenderingMode(.alwaysOriginal)
        })

        let compactGroups = [
            Group(items: [ink, inkRedTool])
        ]
        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [ink]),
            Group(items: [inkRedTool]),
        ]
        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)
        configurations = [compactConfiguration, regularConfiguration]
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        // Set your custom property for your custom annotation variant.
        if newState == .ink && newVariant == redInk {
            manager.drawColor = UIColor.red
        }

        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }
}
