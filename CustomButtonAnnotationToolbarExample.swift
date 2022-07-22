//
//  Copyright © 2019-2022 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import UIKit



class CustomButtonAnnotationToolbarExample: Example {

    override init() {
        super.init()
        title = "Add a Custom Button to the Annotation Toolbar"
        contentDescription = "Will add a 'Clear' button to the annotation toolbar that removes all annotations from the visible page."
        category = .barButtons
        priority = 210
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(for: .annualReport)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(AnnotationToolbar.self, with: AnnotationToolbarWithClearButton.self)
            $0.overrideClass(AnnotationToolbar.self, with: CustomAnnotationToolbar.self)
            $0.overrideClass(AnnotationToolbar.self, with: AnnotationToolbarWithThreeColors.self)
            $0.overrideClass(AnnotationStyleViewController.self, with: CustomAnnotationStyleViewController.self)
            
        }
        return controller
    }
}

class AnnotationToolbarWithClearButton: AnnotationToolbar, PDFDocumentViewControllerDelegate {
    var clearAnnotationsButton: ToolbarButton

    // MARK: - Lifecycle
    override init(annotationStateManager: AnnotationStateManager) {
        clearAnnotationsButton = ToolbarButton()
        clearAnnotationsButton.accessibilityLabel = "Clear"
        clearAnnotationsButton.image = SDK.imageNamed("trash")!.withRenderingMode(.alwaysTemplate)

        super.init(annotationStateManager: annotationStateManager)

        // The biggest challenge here isn't the clear button, but correctly updating the clear button if we actually can clear something or not.
        let dnc = NotificationCenter.default
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationChanged, object: nil)
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationsAdded, object: nil)
        dnc.addObserver(self, selector: #selector(annotationChangedNotification(_:)), name: NSNotification.Name.PSPDFAnnotationsRemoved, object: nil)

        // Set document view controller delegate to get notified when the page changes.
        annotationStateManager.pdfController?.documentViewController?.delegate = self

        // Add clear button
        clearAnnotationsButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        updateClearAnnotationButton()
        additionalButtons = [clearAnnotationsButton]
    }

    // MARK: - Clear Button Action
    @objc func clearButtonPressed() {
        guard let pdfController = annotationStateManager.pdfController,
              let document = pdfController.document else {
            return
        }
        // Iterate over all visible pages and remove all editable annotations.
        for pageView in pdfController.visiblePageViews {
            let annotations = document.annotationsForPage(at: pageView.pageIndex, type: editablAnnotationKind)
            document.remove(annotations: annotations)

            // Remove any annotation on the page as well (updates views).
            // Alternatively, you can call `reloadData` on the pdfController.
            for annotation in annotations {
                pageView.remove(annotation, options: nil, animated: true)
            }
        }
    }

    // MARK: - Notifications

    // If we detect annotation changes, schedule a reload.
    @objc func annotationChangedNotification(_ notification: Notification?) {
        // Re-evaluate toolbar button
        if window != nil {
            updateClearAnnotationButton()
        }
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeUndoState undoEnabled: Bool, redoState redoEnabled: Bool) {
        super.annotationStateManager(manager, didChangeUndoState: undoEnabled, redoState: redoEnabled)
        updateClearAnnotationButton()
    }

    // MARK: - Delegate

    func documentViewController(_ documentViewController: PDFDocumentViewController, willBeginDisplaying spreadView: PDFSpreadView, forSpreadAt spreadIndex: Int) {
        updateClearAnnotationButton()
    }

    func documentViewController(_ documentViewController: PDFDocumentViewController, didEndDisplaying spreadView: PDFSpreadView, forSpreadAt spreadIndex: Int) {
        updateClearAnnotationButton()
    }

    // MARK: - Private

    private func updateClearAnnotationButton() {
        guard let pdfController = annotationStateManager.pdfController else {
            return
        }
        let containsAnnotations = pdfController.visiblePageIndexes.contains { index in
            let annotations = pdfController.document?.annotationsForPage(at: PageIndex(index), type: editablAnnotationKind) ?? []
            return !annotations.isEmpty
        }

        clearAnnotationsButton.isEnabled = containsAnnotations
    }

    private var editablAnnotationKind: Annotation.Kind {
        var kind = Annotation.Kind.all
        kind.remove(.link)
        kind.remove(.widget)
        return kind
    }
}
private class CustomAnnotationToolbar1: AnnotationToolbar {
    let redInk = Annotation.Variant(rawValue: "my_red_tool")

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
//        let ink = Item(type: .ink)
        let inkRedTool = Item(type: .ink, variant: redInk, configurationBlock: {_, _, _ in
            return SDK.imageNamed("ink")!.withRenderingMode(.alwaysOriginal)
        })

        let compactGroups = [
            Group(items: [inkRedTool])
        ]
        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
//            Group(items: [ink]),
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

//        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }
}

private class AviationAnnotationToolbar: AnnotationToolbar {

    private var observer: Any?
    private var clearAnnotationsButton: ToolbarButton = ToolbarButton()

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        // The annotation toolbar will unregister all notifications on dealloc.
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationChanged, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsAdded, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsRemoved, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.PSPDFDocumentViewControllerWillBeginDisplayingSpreadView, object: nil, queue: OperationQueue.main) { notification in self.willShowSpreadViewNotification(notification)
        }

        // Customize the annotation toolbar buttons.
        // See https://pspdfkit.com/guides/ios/customizing-the-interface/customizing-the-annotation-toolbar/#annotation-buttons for more details.
        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let ink = Item(type: .ink)
        let square = Item(type: .square)
        let circle = Item(type: .circle)
        let line = Item(type: .line)
        let freeText = Item(type: .freeText)
        let note = Item(type: .note)
        let stamp = Item(type: .stamp)
        let selectionTool = Item(type: .selectionTool)

        let compactGroups = [
            Group(items: [ink]),
            Group(items: [square, circle, line]),
            Group(items: [freeText, note]),
            Group(items: [stamp]),
            Group(items: [selectionTool])
        ]

        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [ink]),
            Group(items: [square]),
            Group(items: [circle]),
            Group(items: [line]),
            Group(items: [freeText]),
            Group(items: [note]),
            Group(items: [stamp]),
            Group(items: [selectionTool])
        ]

        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)

        configurations = [compactConfiguration, regularConfiguration]

        let clearImage = SDK.imageNamed("trash")?.withRenderingMode(.alwaysTemplate)
        clearAnnotationsButton.accessibilityLabel = "Clear"
        clearAnnotationsButton.image = clearImage
        clearAnnotationsButton.addTarget(self, action: #selector(clearButtonPressed(_:)), for: .touchUpInside)

        self.additionalButtons = [clearAnnotationsButton]
        updateClearAnnotationButton()
    }

    // MARK: Clear Button Action

    @objc func clearButtonPressed(_ sender: ToolbarButton) {
        let pdfController = annotationStateManager.pdfController
        let document = pdfController?.document
        let allTypesButLinkAndForms = Annotation.Kind.all.subtracting([.link, .widget])
        guard let annotations = document?.allAnnotations(of: allTypesButLinkAndForms).flatMap({ $0.value }) else {
            return
        }

        document?.remove(annotations: annotations, options: nil)
        SDK.shared.cache.remove(for: document)
        pdfController?.reloadData()
    }

    // MARK: Notifications

    func annotationChangedNotification(_ notification: Notification) {
        // Re-evaluate toolbar button
        if self.window != nil {
            updateClearAnnotationButton()
        }
    }

    func willShowSpreadViewNotification(_ notification: Notification) {
        updateClearAnnotationButton()
    }

    // MARK: PDFAnnotationStateManagerDelegate

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeUndoState undoEnabled: Bool, redoState redoEnabled: Bool) {
        super.annotationStateManager(manager, didChangeUndoState: undoEnabled, redoState: redoEnabled)
        updateClearAnnotationButton()
    }

    // MARK: Private

    private func updateClearAnnotationButton() {
        let pdfController = annotationStateManager.pdfController
        let document = pdfController?.document
        let allTypesButLinkAndForms = Annotation.Kind.all.subtracting([.link, .widget])
        guard let annotations = document?.allAnnotations(of: allTypesButLinkAndForms) else { return }
        // Enable the button only if there are annotations found to clear.
        clearAnnotationsButton.isEnabled = annotations.isEmpty == false
    }
}

private class CustomAnnotationToolbar: AnnotationToolbar {
    let continuousVariant = Annotation.Variant(rawValue: "continuous")

    override init(annotationStateManager: AnnotationStateManager) {
        super.init(annotationStateManager: annotationStateManager)

        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let freeText = Item(type: .freeText)
        let freeTextContinuous = Item(type: .freeText, variant: continuousVariant, configurationBlock: {_, _, _ in
            return SDK.imageNamed("freetext")!.withRenderingMode(.alwaysOriginal)
        })

        let compactGroups = [
            Group(items: [freeText, freeTextContinuous])
        ]
        let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [freeText]),
            Group(items: [freeTextContinuous]),
        ]
        let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)
        configurations = [compactConfiguration, regularConfiguration]
    }

    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        // Re-enable the state only if we already were in the continuous creation mode.
        if newState == nil && oldState == .freeText && oldVariant == continuousVariant {
            manager.state = .freeText
            manager.variant = continuousVariant
        }

        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }
}


class CustomAnnotationStyleViewController: AnnotationStyleViewController
 {
    let userDefults = UserDefaults.standard
    
    override func properties(for annotations: [Annotation]) -> [[AnnotationStyle.Key]] {
        let style = userDefults.string(forKey:"style")
        let annotation = annotations[0]
        if annotation.typeString=="Eraser" {
            let supportedKeys: [AnnotationStyle.Key] = [.color, .alpha, .lineWidth, .fontSize]
            return super.properties(for: annotations).map {
                $0.filter { supportedKeys.contains($0) }
            }
        }
        print(annotation.typeString)
        if style=="width" {
            let supportedKeys: [AnnotationStyle.Key] = [.lineWidth]
            return super.properties(for: annotations).map {
                $0.filter { supportedKeys.contains($0) }
            }
        }
        if style=="color" {
            let supportedKeys: [AnnotationStyle.Key] = [.color, .alpha, .lineWidth, .fontSize]
            return super.properties(for: annotations).map {
                $0.filter { supportedKeys.contains($0) }
            }
        }
        // Allow only a smaller list of known properties in the inspector popover.
        let supportedKeys: [AnnotationStyle.Key] = [.color, .alpha, .fontSize]
        return super.properties(for: annotations).map {
            $0.filter { supportedKeys.contains($0) }
        }
    }
    
   
}


class AnnotationToolbarWithThreeColors: AnnotationToolbar, PDFDocumentViewControllerDelegate {
    
   
    var colorButton1: ColorButton
    var colorButton2: ColorButton
    var colorButton3: ColorButton
    let thicknessView1 : UIButton;
    let thicknessView2 : UIButton;
    let thicknessView3 : UIButton;
    
    var thicknessButton1: ColorButton
    var thicknessButton2: ColorButton
    var thicknessButton3: ColorButton
    var selectedColorButtonIndex = "colorPicker1"
    var selectedthicknessButtonIndex = "thicknessButton1"
    
    var borderColor = UIColor.purple;
    var selectBorder = UIEdgeInsets(top: 12, left: 12.0, bottom: 12.0, right: 12.0);
    var unSelectBorder = UIEdgeInsets(top: 13, left: 13.0, bottom: 13.0, right: 13.0);
    
    var selectThicknessBorder = UIEdgeInsets(top: 6, left: 6.0, bottom: 6.0, right: 6.0);
    var unSelectThicknessBorder1 = UIEdgeInsets(top:24, left: 12, bottom: 24, right: 12);
    var unSelectThicknessBorder2 = UIEdgeInsets(top:23, left: 12, bottom: 23, right: 12);
    var unSelectThicknessBorder3 = UIEdgeInsets(top:22, left: 12, bottom: 22, right: 12);
    
    let userDefults = UserDefaults.standard
    
    var currentVariant: Annotation.Variant?;
    var currentState:Annotation.Tool?;
   

    // MARK: - Lifecycle
    override init(annotationStateManager: AnnotationStateManager) {
       
        
//        let drawingColor = UIColor.red
//        let highlightingColor = UIColor.red
//        let colorProperty = "color"
//        let alphaProperty = "alpha"
//        let lineWidthProperty = "lineWidth"
//
//
//        SDK.shared.styleManager.setLastUsedValue(drawingColor, forProperty: colorProperty, forKey: Annotation.ToolVariantID(tool: .ink))
//        SDK.shared.styleManager.setLastUsedValue(drawingColor, forProperty: colorProperty, forKey: Annotation.ToolVariantID(tool: .ink, variant: .inkPen))
//
//        // Set highlight color.
//        SDK.shared.styleManager.setLastUsedValue(highlightingColor, forProperty: colorProperty, forKey: Annotation.ToolVariantID(tool: .ink, variant: .inkHighlighter))
//        SDK.shared.styleManager.setLastUsedValue(0.5, forProperty: alphaProperty, forKey: Annotation.ToolVariantID(tool: .ink, variant: .inkHighlighter))
//
//        // Set line width of ink annotations.
//        SDK.shared.styleManager.setLastUsedValue(5, forProperty: lineWidthProperty, forKey: Annotation.ToolVariantID(tool: .ink))
//        SDK.shared.styleManager.setLastUsedValue(5, forProperty: lineWidthProperty, forKey: Annotation.ToolVariantID(tool: .ink, variant: .inkPen))
//
//        // Set line width of highlight annotations.
//        SDK.shared.styleManager.setLastUsedValue(20, forProperty: lineWidthProperty, forKey: Annotation.ToolVariantID(tool: .ink, variant: .inkHighlighter))
       

//
        colorButton1 = ColorButton()
        colorButton1.accessibilityLabel = "colorPicker1"
        colorButton1.color=UIColor.black;
        
        colorButton1.shape = ColorButton.Shape(rawValue: ColorButton.Shape.ellipse.rawValue) ?? .ellipse;
//        colorButton1.outerBorderPadding=12;
        colorButton1.contentInset = selectBorder;
        colorButton1.outerBorderColor = borderColor;
        if selectedColorButtonIndex=="colorPicker1" {
            colorButton1.outerBorderWidth = 2
            colorButton1.contentInset = selectBorder;
        } else {
            colorButton1.outerBorderWidth = 0
            colorButton1.contentInset = unSelectBorder;
        }
        
        colorButton2 = ColorButton()
        colorButton2.accessibilityLabel = "colorPicker2"
        colorButton2.color=UIColor.yellow;
        colorButton2.shape = ColorButton.Shape(rawValue: ColorButton.Shape.ellipse.rawValue) ?? .ellipse;
        colorButton2.contentInset = selectBorder;
        colorButton2.outerBorderColor=borderColor;
        if selectedColorButtonIndex=="colorPicker2" {
            colorButton2.outerBorderWidth = 2
            colorButton2.contentInset = selectBorder;
        } else {
            colorButton2.outerBorderWidth = 0
            colorButton2.contentInset = unSelectBorder;
        }
        
        
        
        colorButton3 = ColorButton()
        colorButton3.accessibilityLabel = "colorPicker3"
        colorButton3.color=UIColor.blue;
        colorButton3.shape = ColorButton.Shape(rawValue: ColorButton.Shape.ellipse.rawValue) ?? .ellipse;
        colorButton3.contentInset = selectBorder;
        colorButton3.outerBorderColor = borderColor;
        if selectedColorButtonIndex=="colorPicker3" {
            colorButton3.outerBorderWidth = 2
            colorButton3.contentInset = selectBorder;
        } else {
            colorButton3.outerBorderWidth = 0
            colorButton3.contentInset = unSelectBorder;
        }
        
        
        thicknessView1=UIButton();
        thicknessView1.frame = CGRect(x: 10, y: 24, width: 30, height: 2)
        thicknessView1.backgroundColor=UIColor.gray
        thicknessView1.layer.cornerRadius = 4.0;
        
        thicknessButton1 = ColorButton()
        thicknessButton1.accessibilityLabel = "thicknessButton1"
        thicknessButton1.outerBorderWidth = 0;
        thicknessButton1.innerBorderWidth = 0;
        thicknessButton1.contentInset =  UIEdgeInsets(top: 6, left: 6.0, bottom: 6.0, right: 6.0);
      
        thicknessButton1.addSubview(thicknessView1)
        
        if selectedthicknessButtonIndex=="thicknessButton1" {
            thicknessView1.backgroundColor = UIColor.white;
            thicknessButton1.color=UIColor.black.withAlphaComponent(0.1);
            thicknessButton1.contentInset = selectThicknessBorder;
            annotationStateManager.lineWidth = 5;
        } else {
            thicknessButton1.contentInset = unSelectThicknessBorder1;

           
        }
        
        
        thicknessView2=UIButton();
        thicknessView2.frame = CGRect(x: 10, y: 23, width: 30, height: 4)
        thicknessView2.backgroundColor=UIColor.gray
        thicknessView2.layer.cornerRadius = 4.0;
        
        thicknessButton2 = ColorButton()
        thicknessButton2.accessibilityLabel = "thicknessButton2"
        thicknessButton2.outerBorderWidth = 0;
        thicknessButton2.innerBorderWidth = 0;
        thicknessButton2.contentInset =  UIEdgeInsets(top: 6, left: 6.0, bottom: 6.0, right: 6.0);
      
        thicknessButton2.addSubview(thicknessView2)
        
        if selectedthicknessButtonIndex=="thicknessButton2" {
            thicknessView2.backgroundColor = UIColor.white;
            thicknessButton2.color=UIColor.black.withAlphaComponent(0.1);
            thicknessButton2.contentInset = selectThicknessBorder;
            annotationStateManager.lineWidth = 10;
        } else {
            thicknessButton2.contentInset = unSelectThicknessBorder2;

           
        }

        thicknessView3=UIButton();
        thicknessView3.frame = CGRect(x: 10, y: 21, width: 30, height: 6)
        thicknessView3.backgroundColor=UIColor.gray
        thicknessView3.layer.cornerRadius = 4.0;
        
        thicknessButton3 = ColorButton()
        thicknessButton3.accessibilityLabel = "thicknessButton2"
        thicknessButton3.outerBorderWidth = 0;
        thicknessButton3.innerBorderWidth = 0;
        thicknessButton3.contentInset =  UIEdgeInsets(top: 6, left: 6.0, bottom: 6.0, right: 6.0);
      
        thicknessButton3.addSubview(thicknessView3)
        
        if selectedthicknessButtonIndex=="thicknessButton3" {
            thicknessView3.backgroundColor = UIColor.white;
            thicknessButton3.color=UIColor.black.withAlphaComponent(0.1);
            thicknessButton3.contentInset = selectThicknessBorder;
            annotationStateManager.lineWidth = 15;
        } else {
            thicknessButton3.contentInset = unSelectThicknessBorder3;
          
        }
       

        
        
        let keyStrng = Annotation.ToolVariantID(tool: .ink)
        let styles = SDK.shared.styleManager.styles(forKey: keyStrng)
        if (styles != nil) {
            let colorKey=AnnotationStyle.Key.color;
            let color = styles?[0].styleDictionary?[colorKey];
            colorButton1.color=color as? UIColor;
        }
        
       
        
        

        super.init(annotationStateManager: annotationStateManager)
//        strokeColorButton?.color = UIColor.clear;
//        strokeColorButton?.backgroundColor = UIColor.clear;
//        strokeColorButton?.frame =  CGRect(x: 0, y: 0, width: 0, height: 0)
//        strokeColorButton?.outerBorderWidth = 0;
//        strokeColorButton?.innerBorderWidth = 0;
        
        
        typealias Item = AnnotationToolConfiguration.ToolItem
        typealias Group = AnnotationToolConfiguration.ToolGroup
        let highlight = Item(type: .highlight)
        let freeText = Item(type: .freeText)
        let ink = Item(type: .ink)
        
        let inkHigher = Item(type: .ink,variant: Annotation.Variant(rawValue: "Highlighter"),configurationBlock: {_, _, _ in
            return SDK.imageNamed("ink_highlighter")!.withRenderingMode(.alwaysTemplate)
        })
        let inkmagic = Item(type: .ink,variant: Annotation.Variant(rawValue: "Magic"),configurationBlock: {_, _, _ in
            return SDK.imageNamed("ink_magic")!.withRenderingMode(.alwaysTemplate)
        })
        let eraser = Item(type: .eraser)
       
        let line = Item(type: .line,variant: Annotation.Variant(rawValue: "Arrow"))

        let note = Item(type: .note)
        let image = Item(type: .image)
        let selectionTool = Item(type: .selectionTool)

        let compactGroups = [
            Group(items: [highlight]),
            Group(items: [freeText]),
            Group(items: [note]),
            Group(items: [ink]),
            Group(items: [inkHigher]),
            Group(items: [inkmagic]),
            Group(items: [eraser]),
            Group(items: [line]),
            Group(items: [image]),
            Group(items: [selectionTool])
        ]

       let compactConfiguration = AnnotationToolConfiguration(annotationGroups: compactGroups)

        let regularGroups = [
            Group(items: [highlight]),
            Group(items: [freeText]),
            Group(items: [note]),
            Group(items: [ink]),
            Group(items: [inkHigher]),
            Group(items: [inkmagic]),
            Group(items: [eraser]),
            Group(items: [line]),
            Group(items: [image]),
            Group(items: [selectionTool])
        ]

       let regularConfiguration = AnnotationToolConfiguration(annotationGroups: regularGroups)
     
        configurations = [compactConfiguration, regularConfiguration]
        annotationStateManager.addObserver(self, forKeyPath: "lineWidth", options: [.new], context: nil)
        annotationStateManager.addObserver(self, forKeyPath: "drawColor", options: [.new], context: nil)
        // Set document view controller delegate to get notified when the page changes.
        // Add clear button
        colorButton1.addTarget(self, action: #selector(colorButton1Pressed), for: .touchUpInside)
        colorButton2.addTarget(self, action: #selector(colorButton2Pressed), for: .touchUpInside)
        colorButton3.addTarget(self, action: #selector(colorButton3Pressed), for: .touchUpInside)
        
        thicknessButton1.addTarget(self, action: #selector(thicknessButton1Pressed), for: .touchUpInside)
        thicknessButton2.addTarget(self, action: #selector(thicknessButton2Pressed), for: .touchUpInside)
        thicknessButton3.addTarget(self, action: #selector(thicknessButton3Pressed), for: .touchUpInside)
       
        thicknessView1.addTarget(self, action: #selector(thicknessButton1Pressed), for: .touchUpInside)
        thicknessView2.addTarget(self, action: #selector(thicknessButton2Pressed), for: .touchUpInside)
        thicknessView3.addTarget(self, action: #selector(thicknessButton3Pressed), for: .touchUpInside)
       
    }
    override var strokeColorButton: ColorButton? {
        get {
            return nil;
        }

    }
    override func annotationStateManager(_ manager: AnnotationStateManager, didChangeState oldState: Annotation.Tool?, to newState: Annotation.Tool?, variant oldVariant: Annotation.Variant?, to newVariant: Annotation.Variant?) {
        print(newState)
        print(newVariant)
        if newState == .ink {
            additionalButtons = [colorButton1,colorButton2,colorButton3,thicknessButton1,thicknessButton2,thicknessButton3]
        }
        else if newState == .highlight {
            additionalButtons = [colorButton1,colorButton2,colorButton3,thicknessButton1,thicknessButton2,thicknessButton3]
        }
        else if newState == .line {
            additionalButtons = [colorButton1,colorButton2,colorButton3,thicknessButton1,thicknessButton2,thicknessButton3]
        }
        else if newState == .freeText {
            additionalButtons = [colorButton1,colorButton2,colorButton3,thicknessButton1,thicknessButton2,thicknessButton3]
        }
        else if newState == .eraser{
            additionalButtons = [thicknessButton1,thicknessButton2,thicknessButton3];
        }
      
        super.annotationStateManager(manager, didChangeState: oldState, to: newState, variant: oldVariant, to: newVariant)
    }
    override func annotationStateManager(_ manager: AnnotationStateManager, shouldChangeState currentState: Annotation.Tool?, to proposedState: Annotation.Tool?, variant currentVariant: Annotation.Variant?, to proposedVariant: Annotation.Variant?) -> Bool {
        self.currentState=proposedState;
        self.currentVariant=proposedVariant;
        return true;
        
    }
    
    //处理监听
       override func observeValue(forKeyPath keyPath: String?,
                                  of object: Any?,
                                  change: [NSKeyValueChangeKey : Any]?,
                                  context: UnsafeMutableRawPointer?) {
//           print(keyPath)
//           print(change)
//           let keyStrng = Annotation.ToolVariantID(tool: .ink1)
//           let styles = SDK.shared.styleManager.styles(forKey: keyStrng)
//           print(styles)
           if keyPath == "lineWidth" {
               print("dsddssd",currentState ?? nil)
               print(currentVariant ?? nil)
               var savekey = selectedthicknessButtonIndex;
               if (currentVariant != nil && currentVariant != nil) {
                   savekey=savekey+Annotation.ToolVariantID(tool: currentState!,variant: currentVariant).rawValue
               }
               if (currentVariant != nil && currentVariant == nil) {
                   savekey=savekey+Annotation.ToolVariantID(tool: currentState!).rawValue
               }
               
//               var savekey = selectedthicknessButtonIndex+currentVariant?;Annotation.ToolVariantID(tool: currentState ?? <#default value#>,variant: currentVariant):Annotation.ToolVariantID(tool: currentState);
               userDefults.set(annotationStateManager.lineWidth, forKey: savekey)
              
           }
           if keyPath == "drawColor" {
               if selectedColorButtonIndex=="colorPicker1" {
                 colorButton1.color = annotationStateManager.drawColor;
//                 userDefults.set(colorButton1.color, forKey: "colorPicker1")
                   
              }
               if selectedColorButtonIndex=="colorPicker2" {
                   colorButton2.color = annotationStateManager.drawColor;
              }
               if selectedColorButtonIndex=="colorPicker3" {
                   colorButton3.color = annotationStateManager.drawColor;
              }
           }
       }
       
     @objc func thicknessButton1Pressed() {
        userDefults.set("width", forKey: "style")
       
        if selectedthicknessButtonIndex == "thicknessButton1" {
          
            annotationStateManager.toggleStylePicker(thicknessButton1, presentationOptions: nil)
        }else {
            selectedthicknessButtonIndex = "thicknessButton1"
            thicknessView1.backgroundColor = UIColor.white;
            thicknessButton1.color=UIColor.black.withAlphaComponent(0.1);
            thicknessButton1.contentInset = selectThicknessBorder;
            thicknessButton3.color=UIColor(white: 0.2, alpha: 0.98);
            thicknessButton2.color=UIColor(white: 0.2, alpha: 0.98);
            annotationStateManager.lineWidth = 5;
            
            thicknessButton2.contentInset = unSelectThicknessBorder2;
            thicknessButton3.contentInset = unSelectThicknessBorder3;
            thicknessView3.backgroundColor=UIColor.gray;
            thicknessView2.backgroundColor=UIColor.gray;
            thicknessView1.backgroundColor=UIColor.white;
        }
        
    }
    @objc func thicknessButton2Pressed() {
       userDefults.set("width", forKey: "style")
       
//        let presets = [
//            ColorPreset(color: annotationStateManager.drawColor),
//        ]
//        let styleManager = SDK.shared.styleManager
//        let key = Annotation.ToolVariantID(tool: .ink)
//        styleManager.setPresets(presets, forKey: key, type: .colorPreset)
//        styleManager.setPresets(presets, forKey: Annotation.ToolVariantID(tool: .freeText), type: .colorPreset)
//        styleManager.setPresets(presets, forKey: Annotation.ToolVariantID(tool: .line), type: .colorPreset)

        if selectedthicknessButtonIndex == "thicknessButton2" {
            annotationStateManager.toggleStylePicker(thicknessButton2, presentationOptions: nil)
        }else {
            selectedthicknessButtonIndex = "thicknessButton2"
            thicknessView2.backgroundColor = UIColor.white;
            thicknessButton2.color=UIColor.black.withAlphaComponent(0.1);
            thicknessButton2.contentInset = selectThicknessBorder;
            
            thicknessButton1.color=UIColor(white: 0.2, alpha: 0.98);
            thicknessButton3.color=UIColor(white: 0.2, alpha: 0.98);
            annotationStateManager.lineWidth = 10;
            
            thicknessButton1.contentInset = unSelectThicknessBorder2;
            thicknessButton3.contentInset = unSelectThicknessBorder3;
            thicknessView3.backgroundColor=UIColor.gray;
            thicknessView1.backgroundColor=UIColor.gray;
            thicknessView2.backgroundColor=UIColor.white;
        }
       
   }
    @objc func thicknessButton3Pressed() {
         userDefults.set("width", forKey: "style")
          if selectedthicknessButtonIndex == "thicknessButton3" {
              annotationStateManager.toggleStylePicker(thicknessButton3, presentationOptions: nil)
          }else {
              selectedthicknessButtonIndex = "thicknessButton3"
              thicknessView3.backgroundColor = UIColor.white;
              thicknessButton3.color=UIColor.black.withAlphaComponent(0.1);
              thicknessButton3.contentInset = selectThicknessBorder;
              
              thicknessButton1.contentInset = unSelectThicknessBorder2;
              thicknessButton2.contentInset = unSelectThicknessBorder3;
              thicknessButton1.color=UIColor(white: 0.2, alpha: 0.98);
              thicknessButton2.color=UIColor(white: 0.2, alpha: 0.98);
              annotationStateManager.lineWidth = 15;
              thicknessView2.backgroundColor=UIColor.gray;
              thicknessView1.backgroundColor=UIColor.gray;
              thicknessView3.backgroundColor=UIColor.white;
          }
       
   }

    // MARK: - Clear Button Action
    @objc func colorButton1Pressed() {
        userDefults.set("color", forKey: "style")
       
        if selectedColorButtonIndex == "colorPicker1" {
            annotationStateManager.toggleStylePicker(colorButton1, presentationOptions: nil)
        }else {
            selectedColorButtonIndex = "colorPicker1"
           
           
            
            colorButton1.outerBorderWidth=2;
            colorButton1.contentInset = selectBorder;
            annotationStateManager.drawColor=colorButton1.color;
            
            colorButton2.outerBorderWidth=0;
            colorButton2.contentInset = unSelectBorder;
            
            colorButton3.outerBorderWidth=0;
            colorButton3.contentInset = unSelectBorder;
           
        }
        
    }
    @objc func colorButton2Pressed() {
        userDefults.set("color", forKey: "style")
        
        if selectedColorButtonIndex == "colorPicker2" {
            
            annotationStateManager.toggleStylePicker(colorButton2, presentationOptions: nil)
        }else {
            selectedColorButtonIndex = "colorPicker2"
            colorButton1.outerBorderWidth=0;
            colorButton1.contentInset = unSelectBorder;
           
            colorButton2.outerBorderWidth=2;
            colorButton2.contentInset = selectBorder;
            annotationStateManager.drawColor=colorButton2.color;
            
            colorButton3.outerBorderWidth=0;
            colorButton3.contentInset = unSelectBorder;
        }
    }
    @objc func colorButton3Pressed() {
        userDefults.set("color", forKey: "style")
       
        if selectedColorButtonIndex == "colorPicker3" {
            annotationStateManager.toggleStylePicker(colorButton3, presentationOptions: nil)
        }else {
            selectedColorButtonIndex = "colorPicker3"
            
            colorButton1.outerBorderWidth=0;
            colorButton1.contentInset = unSelectBorder;
           
            colorButton3.outerBorderWidth=2;
            colorButton3.contentInset = selectBorder;
            annotationStateManager.drawColor=colorButton3.color;
            
            colorButton2.outerBorderWidth=0;
            colorButton2.contentInset = unSelectBorder;
            
        }
    }

   
}
