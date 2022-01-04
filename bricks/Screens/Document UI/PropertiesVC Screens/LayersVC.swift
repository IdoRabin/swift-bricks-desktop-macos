//
//  LayersVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("LayersVC")

class LayersVC : NSViewController {
    
    // MARK: UI components
    @IBOutlet weak var addButton: MNButton!
    @IBOutlet weak var editButton: MNButton!
    @IBOutlet weak var removeButton: MNButton!
    
    // MARK: computed properties
    var doc : BrickDoc? {
        return docWC?.document as? BrickDoc
    }
    
    var docWC : DocWC? {
        return (self.view.window?.windowController as? DocWC)
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton.associatedCommand = CmdLayerAdd.self
        editButton.associatedCommand = CmdLayerEdit.self
        removeButton.associatedCommand = CmdLayerRemove.self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.triggerValidations()
    }
    
    @IBAction func addButtonAction(_ sender: Any) {
        self.doc?.createCommand(CmdLayerAdd.self, context: "addButtonAction")
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        self.doc?.createCommand(CmdLayerEdit.self, context: "editButtonAction")
    }
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        self.doc?.createCommand(CmdLayerRemove.self, context: "deleteButtonAction")
    }
    
    
}

extension LayersVC : NSUserInterfacePluralValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard self.isViewLoaded, self.view.window != nil else {
            dlog?.note("cannot validate UI item \(item) before isViewLoaded.")
            return false
        }
        
        return docWC?.docVC?.validateUserInterfaceItem(item) ?? false
    }
    
    func validateUserInterfaceItems(_ items: [NSValidatedUserInterfaceItem]) {
        guard self.isViewLoaded, self.view.window != nil else {
            dlog?.note("cannot validate UI items before isViewLoaded.")
            return
        }
        guard let docVC = docWC?.docVC else {
            dlog?.note("cannot validate UI items when no doc or docVC.")
            return
        }
        
        docVC.validateUserInterfaceItems(items)
    }
    
}
