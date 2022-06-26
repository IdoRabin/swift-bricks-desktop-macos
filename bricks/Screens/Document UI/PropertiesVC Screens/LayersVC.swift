//
//  LayersVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("LayersVC")
fileprivate let dlogDDrop : DSLogger? = nil // DLog.forClass("LayersVC_dragDrop")
fileprivate let dlogWarnings : DSLogger? = DLog.forClass("LayersVC_warn")

fileprivate let IS_LOG_DRAGGING = IS_DEBUG && false
fileprivate let DEBUG_DRAWING = IS_DEBUG && false
fileprivate typealias LayerUIInfo = BrickLayers.LayerUIInfo // convenience

// MARK: // Overrides NSDraggingDestination, NSDraggingSource
class LayersTableView : NSTableView  /* NSDraggingDestination, NSDraggingSource overrides */ {
    
    private var lastDragPrefix : String = ""
    private func logDragItem(prefix:String,_ info: NSDraggingInfo?) {
        guard IS_LOG_DRAGGING else {
            return
        }
        
        guard dlogDDrop != nil else {
            return
        }
        
        guard let tv = info?.draggingSource as? LayersTableView else {
            return
        }
        
        guard prefix != lastDragPrefix, let dragLocation = info?.draggingLocation, let tvLoc = self.window?.contentView?.convert(dragLocation, to: tv) else {
            return
        }
        
        let isInTVArea = tv.bounds.insetBy(dx: 4, dy: 4).contains(tvLoc)
        dlogDDrop?.info([prefix, tv.className, "in tv: " + isInTVArea.description, tv.bounds.debugDescription, tvLoc.debugDescription].joined(separator: " | "))
    }
    
    override func updateDraggingItemsForDrag(_ info: NSDraggingInfo?) {
        guard let tv = info?.draggingSource as? LayersTableView, let info = info else {
            dlog?.warning("updateDraggingItemsForDrag tv or info are nil oir wrong type")
            return
        }
        
        super.updateDraggingItemsForDrag(info)
        var infos : [MoveIndexPathTuple:LayerUIInfo] = [:]
        if let w = (self.window?.windowController as? DocWC), let vc = w.docVC?.docWC?.getSubVC(ofType: LayersVC.self) {
            infos = vc.adapter?.fetchCurrentlyDraggedLayerInfoItems(info: info, dropRowIndex: 0) ?? [:]
        }

        let itemsCount = infos.count
        if IS_DEBUG {
            if itemsCount != info.numberOfValidItemsForDrop {
                dlog?.warning("updateDraggingItemsForDrag: some items are invalid / items count validation mismatch (info.numberOfValidItemsForDrop compare). infos: \(infos.valuesArray.descriptions()) \n info.numberOfValidItemsForDrop: \(info.numberOfValidItemsForDrop)")
            }
            if itemsCount != tv.selectedRowIndexes.count {
                dlog?.warning("updateDraggingItemsForDrag: some items are invalid / items count validation mismatch (tv compare).")
            }
        }
        
        switch itemsCount {
        case 0: dlogDDrop?.info("Dragging zero items")
        case 1: dlogDDrop?.info("Dragging one item: \((infos.first?.value)?.basicDesc ?? "<nil>")")
        default:
            dlogDDrop?.info("Dragging \(itemsCount) items: \(infos.valuesArray.basicDescs.descriptionsJoined)")
        }
        
        logDragItem(prefix: "updateDraggingItemsForDrag", info)
    }
}

// MARK: LayersVC implementation
class LayersVC : NSViewController, DocSubVC {
    
    @AppSettable(false, name:"isRequiresRemoveLayersDialog") static var isRequiresRemoveLayersDialog : Bool
    
    // MARK: UI components
    @IBOutlet weak var addButton: MNButton!
    @IBOutlet weak var editButton: MNButton!
    @IBOutlet weak var removeButton: MNButton!
    
    @IBOutlet weak var layersTableview: LayersTableView!
    @IBOutlet weak var layersTableviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var noLayersLabel: NSTextField!
    
    var adapter : LayersTableViewAdapter? = nil
    var bottomToolbarButtons : [MNButton] {
        guard self.isViewLoaded else {
            return []
        }
        return [addButton, editButton, removeButton]
    }
    // MARK: computed properties
    
    // MARK: Private
    private func setupDragOperations() {
        
        for btn in [removeButton, addButton] {
            if let btn = btn {
                btn.corner(radius: AppConstants.BUTTON_CORNER_SMALL)
                btn.registerForDraggedTypes([LayersTableViewAdapter.dragDropPasteboardType])
                btn.updateAcceptedDragAndDropTypes(strings: [LayersTableViewAdapter.dragDropTypeId])
            }
        }
        
        removeButton.dragDropBkgColor = .appFailureRed.withAlphaComponent(0.3)
        removeButton.dragDropAction = [
            LayersTableViewAdapter.dragDropPasteboardType:{() in
                dlogDDrop?.info("dragDropAction - remove!")
                // self.adapter
            }
        ]
        addButton.dragDropBkgColor = .appSuccessGreen.withAlphaComponent(0.3)
        addButton.dragDropAction = [
            LayersTableViewAdapter.dragDropPasteboardType:{() in
                dlogDDrop?.info("dragDropAction - add / duplicate!")
            }
        ]
    }
    
    private func setupAdapterIfNeeded(isInit:Bool) {
        
        // Create adapter if needed
        if adapter == nil {
            adapter = LayersTableViewAdapter(tv: layersTableview, invoker: nil, hostingVC: self)
            adapter?.tableviewHeightConstraint = self.layersTableviewHeightConstraint
        }
        
        // Assign adapter's associated invoker if needed
        if let doc = self.doc, let adapter = adapter, adapter.commandInvoker !== doc.docCommandInvoker {
            adapter.commandInvoker = doc.docCommandInvoker
            adapter.commandInvoker?.observers.add(observer: adapter)
            if !isInit {
                self.adapter?.reloadData()
            }
        }
    }
    
    private func presentRemoveLayersDialogIfNeeded(completion : AppResultBlock? = nil) {
        guard let _ = self.docWC?.window ?? self.layersTableview.window else {
            dlogWarnings?.warning("presentRemoveLayersDialogIfNeeded: No doc window or no tableview or window!")
            return
        }
        
        guard let layersToDel = self.doc?.brick.layers.selectedLayers else {
            dlogWarnings?.warning("presentRemoveLayersDialogIfNeeded: no selected layers!")
            return
        }
        
        if Self.isRequiresRemoveLayersDialog || doc?.brick.layers.count == 1 {
            
            // Plural dialog texts: (layers amount mentioned)
            var title = AppStr.DELETE_N_LAYERS_FORMAT.formatLocalized(layersToDel.count)
            var msg = AppStr.ARE_YOU_SURE_YOU_WANT_TO_DELETE_N_LAYERS_FROM_PLAN_FORMAT.formatLocalized(layersToDel.count)
            
            if layersToDel.count == 1, let layer = layersToDel.first {
                // Singular dialog texts: (layer name mentioned)
                let name = layer.name ?? AppStr.UNTITLED.localized()
                title = AppStr.DELETE_LAYER_X_FORMAT.formatLocalized(name)
                msg = AppStr.ARE_YOU_SURE_YOU_WANT_TO_DELETE_LAYER_X_FROM_PLAN_FORMAT.formatLocalized(name)
            }
            AppAlert.macOSDialog.presentDestructOrCancel(title: title,
                                                         message: msg,
                                                         destructTitle: AppStr.REMOVE.localized(),
                                                         cancelTitle: AppStr.CANCEL.localized(),
                                                         hostVC: self) {
                // Presentastion complete:
            } completion: { isActionButtonTapped in
                // Dismissed with an AppResult
                completion?(isActionButtonTapped ?
                                    .success(layersToDel.ids) :
                                    .failure(AppError(AppErrorCode.user_canceled, detail: "Canceled dialog")))
            }
        } else {
            completion?(.success("NoDialog"))
        }
    }
    
    private func setup() {
        // Seup buttons
        addButton.associatedCommand = CmdLayerAdd.self
        editButton.associatedCommand = CmdLayerEdit.self
        removeButton.associatedCommand = CmdLayerRemove.self
        
        // Setup tableview
        layersTableview.backgroundColor = self.docWC?.window?.backgroundColor ?? NSColor.controlBackgroundColor
        
        self.setupDragOperations()
        self.setupAdapterIfNeeded(isInit: true)
        self.registerToDocWC()
        self.updateBottomToolbarButtons()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup()
    }
    
    fileprivate func dismissTextFieldFirstResponderIfPossible() {
        if MNFocus.shared.current is NSTextField {
            MNFocus.shared.current?.resignFirstResponder()
            DispatchQueue.main.async {
                self.layersTableview.becomeFirstResponder()
            }
        }
    }
    
    deinit {
        if let adapter = adapter {
            self.adapter?.commandInvoker?.observers.remove(observer: adapter)
            self.doc?.docCommandInvoker.observers.remove(observer: adapter)
        }
        
        adapter = nil
        addButton.associatedCommand =  nil
        editButton.associatedCommand = nil
        removeButton.associatedCommand = nil
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.triggerValidations()
        self.setupAdapterIfNeeded(isInit: false)
    }
    
    fileprivate func updateBottomToolbarButtons() {
        // dlog?.info("updateBottomToolbarButtons")
        for button in bottomToolbarButtons {
            button.alphaValue = button.isEnabled ? 1.0 : 0.4
        }
    }
    
    @objc override func triggerValidations() {
        super.triggerValidations()
        self.updateBottomToolbarButtons()
    }
    
    // MARK: Actions
    
    @IBAction func addButtonAction(_ sender: Any) {
        self.dismissTextFieldFirstResponderIfPossible()
        self.adapter?.snapshotIntoLastSelectedRowIndexes(adoc: nil)
        self.doc?.createCommand(CmdLayerAdd.self, context: "addButtonAction")
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        self.dismissTextFieldFirstResponderIfPossible()
        guard layersTableview.selectedRowIndexes.count > 0 else {
            dlogWarnings?.warning("editButtonAction: The UI element that triggered this should not be enabled when selected layers count is 0.")
            return
        }
        
        self.adapter?.snapshotIntoLastSelectedRowIndexes(adoc: nil)
        self.doc?.createCommand(CmdLayerEdit.self, context: "editButtonAction")
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        self.dismissTextFieldFirstResponderIfPossible()
        guard layersTableview.selectedRowIndexes.count > 0, (self.doc?.brick.layers.selectedLayers.count ?? 0) > 0 else {
            dlogWarnings?.warning("removeButtonAction: The UI element that triggered this should not be enabled when selected layers count is 0.")
            return
        }
        
        self.presentRemoveLayersDialogIfNeeded { result in
            if result.isSuccess {
                // Will also enqueue to execute:
                self.adapter?.snapshotIntoLastSelectedRowIndexes(adoc: nil)
                self.doc?.createCommand(CmdLayerRemove.self, context: "removeButtonAction")
            }
        }
    }
    
}

// MARK: LayersVC : NSUserInterfacePluralValidations
extension LayersVC : NSUserInterfacePluralValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard self.isViewLoaded, self.view.window != nil else {
            dlogWarnings?.note("cannot validate UI item \(item) before isViewLoaded.")
            return false
        }
        
        let isValid = docWC?.docVC?.validateUserInterfaceItem(item) ?? false
        // dlog?.info("validateUserInterfaceItem: \((item as? NSView).descOrNil) ")
        return isValid
    }
    
    func validateUserInterfaceItems(_ items: [NSValidatedUserInterfaceItem]) {
        guard items.count > 0 else {
            dlogWarnings?.note("cannot validate 0 UI items.")
            return
        }
        
        guard self.isViewLoaded, self.view.window != nil else {
            dlogWarnings?.note("cannot validate UI items before isViewLoaded.")
            return
        }
        guard let docVC = docWC?.docVC else {
            dlogWarnings?.note("cannot validate UI items when no doc or docVC.")
            return
        }
        
        docVC.validateUserInterfaceItems(items)
        // dlog?.info("validateUserInterfaceItems: \(items)")
    }
}
