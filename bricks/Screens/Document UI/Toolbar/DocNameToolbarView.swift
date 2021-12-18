//
//  DocNameToolbarView.swift
//  Bricks
//
//  Created by Ido on 15/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("DocNameToolbarView")

class DocNameToolbarView : NSView {
    let IMAGE_SIZE : CGFloat = 26

    
    private func setup() {
//        button.onMouseEnter = {(button) in
//            dlog?.todo("onMouseEnter")
//        }
//
//        button.onMouseExit = {(button) in
//            dlog?.todo("onMouseExit")
//        }
    }
    
    func updateWithDoc(_ doc:BrickDoc?) {
        if let doc = doc {
//            button.image = doc.docState.iconImage.scaledToFit(boundingSize: CGSize(width: IMAGE_SIZE, height: IMAGE_SIZE))
//            let docName = doc.displayName ?? AppStr.UNTITLED.localized()
//            let subtitle = doc.fileURL?.lastPathComponents(count: 2) ?? AppStr.UNSAVED.localized()
//
//            let str = "\(docName)\n\(subtitle)"
//            if button.attributedTitle.string != str {
//                let attr = NSMutableAttributedString(string: str, attributes: button.attributesForWholeTitle)
//                attr.setAtttibutesForStrings(matching: docName, attributes: [.font : NSFont.systemFont(ofSize: 14, weight: .bold)])
//                attr.setAtttibutesForStrings(matching: subtitle, attributes: [.font : NSFont.systemFont(ofSize: 11, weight: .regular)])
//                button.attributedTitle = attr
//                button.instrinsicContentSizePadding = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//            }
//
//            dlog?.info("updateWithDoc: [\(doc.displayName.descOrNil)] file: \(doc.fileURL?.lastPathComponents(count: 2) ?? "<nil>" )")
        } else {
            // doc == nil
//            button.image = AppImages.docNewEmptyDocumentIcon.image.scaledToFit(boundingSize: CGSize(width: IMAGE_SIZE, height: IMAGE_SIZE))
//            button.titleNBSPPrefixIfNeeded(count: 2)
//            button.title = AppStr.UNTITLED.localized()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // dlog?.info("awoken!")
        setup()
    }
}

