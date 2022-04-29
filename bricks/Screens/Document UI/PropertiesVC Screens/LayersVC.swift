//
//  LayersVC.swift
//  Bricks
//
//  Created by Ido on 31/12/2021.
//

import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("LayersVC")
fileprivate let dlogWarnings : DSLogger? = DLog.forClass("LayersVC_warn")
 
fileprivate let DEBUG_DRAWING = IS_DEBUG && false

// MARK: LayersVC implementation
class LayersVC : NSViewController, DocSubVC {
    
    @AppSettable(true, name:"isRequiresRemoveLayersDialog") static var isRequiresRemoveLayersDialog : Bool
    
    // MARK: UI components
    @IBOutlet weak var addButton: MNButton!
    @IBOutlet weak var editButton: MNButton!
    @IBOutlet weak var removeButton: MNButton!
    
    @IBOutlet weak var layersTableview: NSTableView!
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
    private func setupAdapterIfNeeded(isInit:Bool) {
        
        // Create adapter if needed
        if adapter == nil {
            adapter = LayersTableViewAdapter(tv: layersTableview, invoker: nil, hostingVC: self)
            adapter?.tableviewHeightConstraint = self.layersTableviewHeightConstraint
        }
        
        // Assign adapter's associated invoker
        if let doc = self.doc, let adapter = adapter, adapter.commandInvoker !== doc.docCommandInvoker {
            adapter.commandInvoker = doc.docCommandInvoker
            adapter.commandInvoker?.observers.add(observer: adapter)
            if !isInit {
                self.adapter?.reloadData()
            }
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.associatedCommand = CmdLayerAdd.self
        editButton.associatedCommand = CmdLayerEdit.self
        removeButton.associatedCommand = CmdLayerRemove.self
        layersTableview.backgroundColor = self.docWC?.window?.backgroundColor ?? NSColor.controlBackgroundColor
        self.setupAdapterIfNeeded(isInit: true)
        self.registerToDocWC()
        self.updateBottomToolbarButtons()
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
        dlog?.info("updateBottomToolbarButtons")
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
        self.adapter?.snapshotIntoLasstSelectedRowIndexes(adoc: nil)
        self.doc?.createCommand(CmdLayerAdd.self, context: "addButtonAction")
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        guard layersTableview.selectedRowIndexes.count > 0 else {
            dlogWarnings?.warning("editButtonAction: The UI element that triggered this should not be enabled when selected layers count is 0.")
            return
        }
        
        self.adapter?.snapshotIntoLasstSelectedRowIndexes(adoc: nil)
        self.doc?.createCommand(CmdLayerEdit.self, context: "editButtonAction")
    }
    
    private func presentRemoveLayersDialogIfNeeded(completion : AppResultBlock? = nil) {
        guard let window = self.docWC?.window ?? self.layersTableview.window else {
            dlogWarnings?.warning("presentRemoveLayersDialogIfNeeded: No doc window or no tableview or window!")
            return
        }
        
        if Self.isRequiresRemoveLayersDialog {
            let alert = NSAlert()
            
            //
            dlog?.todo("Wrap app alert in good cmpletion block-based wrapper")
            
            alert.informativeText = AppStr.REMOVE.localized()
            alert.messageText = AppStr.REMOVE.localized()
            alert.beginSheetModal(for: window) { response in
                switch response /* as! NSModalResponse */ {
                default:
                    // NSModalResponse.alertFirstButtonReturn
                    // NSModalResponse.alertSecondButtonReturn
                    // NSModalResponse.alertThirdButtonReturn
                    dlog?.info("presentRemoveLayersDialogIfNeeded response: \(response)")
                    // completion?(.success("Dialog"))
                }
            }
        } else {
            completion?(.success("NoDialog"))
        }
    }
    
    @IBAction func removeButtonAction(_ sender: Any) {
        guard layersTableview.selectedRowIndexes.count > 0, (self.doc?.brick.layers.selectedLayers.count ?? 0) > 0 else {
            dlogWarnings?.warning("removeButtonAction: The UI element that triggered this should not be enabled when selected layers count is 0.")
            return
        }
        
        
        self.presentRemoveLayersDialogIfNeeded { result in
            if result.isSuccess {
                // Will also enqueue to execute:
                self.adapter?.snapshotIntoLasstSelectedRowIndexes(adoc: nil)
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
        dlog?.info("validateUserInterfaceItem: \((item as? NSView).descOrNil) ")
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
        dlog?.info("validateUserInterfaceItems: \(items)")
    }
    
}

// MARK: LayersTableViewAdapter
class LayersTableViewAdapter : NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    static let ICON_CELL_SZE : CGFloat = 18.0
    static let ALL_COLUMNS_SET = IndexSet([0, 1, 2])
    
    // MARK: Const
    private enum ColumnId : String {
        case layerVisiblityColumnId
        case layerAccessColumnId
        case layerNameColumnId
        
        var cellId : CellId {
            switch self {
            case .layerVisiblityColumnId: return CellId.layerVisiblityCellId
            case .layerAccessColumnId: return CellId.layerAccessCellId
            case .layerNameColumnId: return CellId.layerNameCellId
            }
        }
        static var all : [ColumnId] = [
            .layerVisiblityColumnId,
            .layerAccessColumnId,
            .layerNameColumnId,
        ]
        
        static func fromColumnIndex(_ index:Int)->ColumnId? {
            switch index {
            case 0: return .layerVisiblityColumnId
            case 1: return .layerVisiblityColumnId
            case 2: return .layerNameColumnId
            default:
                return nil
            }
        }
    }
    
    private enum CellId : String {
        case layerVisiblityCellId
        case layerAccessCellId
        case layerNameCellId
    }
    
    // MARK: Static
    // MARK: Properties / members
    weak var tableview : NSTableView? = nil
    weak var tableviewHeightConstraint : NSLayoutConstraint? = nil
    weak var commandInvoker : (AnyObject & CommandInvoker)? = nil
    weak var hostingVC : NSViewController? = nil
    var latestUIInfo : [Int:BrickLayers.LayerUIInfo] = [:]
    var layersVC : LayersVC? {
        guard let layersVC = hostingVC as? LayersVC else {
            if hostingVC == nil {
                dlogWarnings?.warning("LayersTableViewAdapter - weak var hostingVC was not set")
            } else {
                dlogWarnings?.warning("LayersTableViewAdapter - weak var hostingVC is not of the class LayersVC ")
            }
            if tableview == nil {
                dlogWarnings?.warning("LayersTableViewAdapter - weak var tableView was not set for LayersTableViewAdapter")
            }
            return nil
        }

        return layersVC
    }
    
    // MARK: Private
    private var lastSelectedRowIndexes : IndexSet = []
    private var lastSelectedRowUIDS : [LayerUID] = []
    private var isHandlingLayersChange = false
    private var isHandlingLayersSelectionChange = false
    
    fileprivate var doc : BrickDoc? {
        return commandInvoker?.associatedOwner as? BrickDoc
    }
    
    var docWC : DocWC? {
        return tableview?.window?.windowController as? DocWC
    }
    
    // MARK: Lifecycle
    private func setupTableView() {
        guard let tableview = tableview else {
            return
        }
        
        // TV Settings
        tableview.intercellSpacing = NSSize(width: 0, height: 0)
        
        // Columns Settings
        for columnId in ColumnId.all {
            if let col = tableview.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: columnId.rawValue)) {
                if columnId == .layerNameColumnId {
                    // Text
                    // col.sizeToFit()
                } else {
                    // Icons
                    col.minWidth = Self.ICON_CELL_SZE
                    col.maxWidth = Self.ICON_CELL_SZE
                }
            }
        }
    }
    
    private func setup(){
        DispatchQueue.main.performOncePerInstance(self) {
            self.setupTableView()
            
            DispatchQueue.main.asyncAfter(delayFromNow: 0.05, block: {
                self.reloadSelectionsIfNeeded()
            })
        }
    }
    
    init(tv:NSTableView? = nil, invoker:(AnyObject & CommandInvoker)? = nil, hostingVC newHostingVC:NSViewController) {
        super.init()
        tableview = tv
        
        if IS_DEBUG && (tv?.dataSource !== self || tv?.delegate !== self) {
            if (tv?.delegate != nil && tv?.dataSource != nil) {
                dlog?.info("LayersTableViewAdapter got a tv with other delegate \((tv?.delegate).descOrNil) / data source \((tv?.dataSource).descOrNil)")
            }
        }
        
        // Will implement numberOfRows.. cell for row calls for TableView
        tv?.dataSource = self
        tv?.delegate = self
        commandInvoker = invoker
        hostingVC = newHostingVC
        
        setup()
        MNFocus.shared.observers.add(observer: self)
    }
    
    deinit {
        tableview = nil
        
        MNFocus.shared.observers.remove(observer: self)
        commandInvoker?.observers.remove(observer: self)
        commandInvoker = nil
        hostingVC = nil
    }
    
    // MARK: Public
    func updateTVHeight(animated:Bool) {
        guard let supr = tableview?.enclosingScrollView?.superview, let tableview = self.tableview else {
            return
        }
        
        if DEBUG_DRAWING {
            tableview.debugBorder()
        }
        
        
        let rowHeightEx = max(tableview.rowHeight, Self.ICON_CELL_SZE) // + (2 * (tableview?.intercellSpacing.height ?? 0.0)), 22.0)
        let rowsHeight = min((CGFloat(latestUIInfo.count) * rowHeightEx) + 2.0, supr.bounds.height)
        if tableviewHeightConstraint?.constant != rowsHeight {
            if animated {
                NSView.animate(duration: 0.14) { context in
                    self.tableviewHeightConstraint?.animator().constant = rowsHeight
                    // NO need... tableview.superview?.layoutSubtreeIfNeeded()
                }
            } else {
                tableviewHeightConstraint?.constant = rowsHeight
                tableview.needsLayout = true
            }
            
        }
    }
    
    func reloadSelectionsIfNeeded(silent:Bool = false) {
        guard let doc = doc, let tableview = tableview, tableview.superview != nil else {
            return
        }
        
        let sel = doc.brick.layers.selectedLayersByIndex
        let newSelIndexes = IndexSet(sel.keysArray)
        if self.lastSelectedRowIndexes != newSelIndexes {
            self.lastSelectedRowIndexes = newSelIndexes
        }
        
        let newSelUIDS = sel.valuesArray.ids.sorted()
        if newSelIndexes != tableview.selectedRowIndexes {
            if !silent {
                dlog?.info("reloadSelectionsIfNeeded newSelIndexes: \(newSelIndexes.allElements().descriptionsJoined) prev:\(tableview.selectedRowIndexes.allElements().descriptionsJoined)")
            }
            tableview.selectRowIndexes(newSelIndexes, byExtendingSelection: false)
            
            // "Test"
            if IS_DEBUG {
                let newSel = doc.brick.layers.selectedLayersByIndex
                let newEmpiricalSelUIDS = newSel.valuesArray.ids.sorted()
                if newSelUIDS != newEmpiricalSelUIDS {
                    dlogWarnings?.warning("reloadSelectionsIfNeeded: selection of uids:\(newSelUIDS.descriptionLines)")
                }
                
                for idx in newSelIndexes {
                    if self.latestUIInfo.count > idx && newSel.count > idx &&
                       self.latestUIInfo[idx]?.id != newSel[idx]?.id {
                        dlogWarnings?.warning("reloadSelectionsIfNeeded index mistmatch at:\(idx)")
                    }
                }
            }
        }
    }
    
    func reloadData(forRowIndexes indexes: IndexSet, columnIndexes: IndexSet) {
        guard let doc = doc else {
            return
        }
        
        latestUIInfo = doc.brick.layers.safeLayersUIInfos()
        self.updateTVHeight(animated: false)
        
        // Log reloaded infos to see if info is correct or UI does not update?
//         if IS_DEBUG {
//             for (row, info) in latestUIInfo {
//                 if indexes.contains(row) {
//                     dlog?.info("reloadData for rowIndex: \(row) info:\(info)")
//                 }
//             }
//         }
        
        self.tableview?.reloadData(forRowIndexes: indexes, columnIndexes: columnIndexes)
        self.reloadSelectionsIfNeeded(silent: true) // will not notify or log selection changes
    }
    
    func presentNoLayersLabelIfNeeded() {
        guard let layersVC = layersVC else {
            return
        }
        let curAlpha = layersVC.noLayersLabel.alphaValue
        let expAlpha = latestUIInfo.count > 0 ? 0.0 : 1.0
        if curAlpha != expAlpha {
            layersVC.noLayersLabel.animator().alphaValue = expAlpha
        }
    }
    
    func reloadData() {
        guard let doc = doc else {
            return
        }
        
        latestUIInfo = doc.brick.layers.safeLayersUIInfos()
        // Log reloaded infos to see if info is correct or UI does not update?
        // if IS_DEBUG {
        //     for (row, info) in latestUIInfo {
        //         dlog?.info("reloadData for rowIndex: \(row) info:\(info)")
        //     }
        // }

        self.presentNoLayersLabelIfNeeded()
        self.updateTVHeight(animated: false)
        self.tableview?.reloadData()
        self.reloadSelectionsIfNeeded(silent: true) // will not notify or log selection changes
        self.hostingVC?.triggerValidations() // buttons
    }
    
    private func renameLayer(id:LayerUID, at row:Int, newName:String?) {
        TimedEventFilter.shared.filterEvent(key: "LayerAdapter.renameLayer(id:at:newName:)", threshold: 0.05) {
            guard let doc = self.doc, let layer = doc.brick.layers.findLayer(byId: id) else {
                return
            }
            
            
            let info = self.latestUIInfo[row]
            
            // String sanitization:
            let newSanitizedName = layer.sanitize(newName)
            let prevName : String? = layer.sanitize(info?.title)
            dlog?.info("renameLayer row:\(row) id:\( id ) newName:\(newSanitizedName.descOrNil)")
            
            guard prevName != newSanitizedName else {
                return
            }
            
            // Create command
            let cmdEdit = CmdLayerEdit(context: "renameLayer(id:at:newName:)", receiver: doc, layerID: id)
            cmdEdit.undoInfo = ["name":prevName]
            cmdEdit.payload = ["name":newSanitizedName]
            self.doc?.docCommandInvoker.addCommand(cmdEdit)
        }
    }
    
    // MARK: Actions
    private func highlightButton(_ button:NSButton){
        if button.isHighlighted {
            let img = button.image
            button.image = img?.tinted(.lightGray)
        }
    }
    
    @IBAction func onVisiblityCellAction(_ sender: Any) {
        guard let button = sender as? NSButton, let doc = self.doc else {
            return
        }
        let row = button.tag
        guard let info = self.latestUIInfo[row] else {
            return
        }
        
        dlog?.info("onVisiblityCellAction row:\(row) info:\(info.title)")
        highlightButton(button)
        
        let command = CmdLayerSetVisiblity(context: "visiblityCellAction", receiver: doc, layerID: info.id, visibilityStateToSet: info.visibility.toggled())
        doc.enqueueCommand(command)
    }
    
    @IBAction func onAccessCellAction(_ sender: Any) {
        guard let button = sender as? NSButton, let doc = self.doc else {
            return
        }
        let row = button.tag
        guard let info = self.latestUIInfo[row] else {
            return
        }
        
        dlog?.info("onAccessCellAction row:\(row) info:\( info.title)")
        highlightButton(button)
        
        let command = CmdLayerSetAccess(context: "accessCellAction", receiver: doc, layerID: info.id, lockStateToSet: info.access.toggled())
        doc.enqueueCommand(command)
    }
    
    @IBAction func onNameCellAction(_ sender: Any) {
        guard let textField = sender as? NSTextField else {
            return
        }
        let row = textField.tag
        let info = self.latestUIInfo[row]
        dlog?.info("onNameCellAction row:\(row) info:\( (info?.title).descOrNil )")
        if let info = info {
            self.renameLayer(id: info.id, at: row, newName: textField.stringValue)
        }
    }
    
    // MARK: LayersTableViewAdapter : NSTableViewDataSource, NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return doc?.brick.layers.safeCount ?? 0
    }
    
    private func cellId(byTableColumn tableColumn: NSTableColumn?)->NSUserInterfaceItemIdentifier? {
        let columnId = ColumnId(rawValue: tableColumn?.identifier.rawValue ?? "") ?? .layerNameColumnId
        return NSUserInterfaceItemIdentifier(rawValue: columnId.cellId.rawValue)
    }
    
    func snapshotIntoLasstSelectedRowIndexes(adoc:BrickDoc? = nil) {
        guard let doc = adoc ?? self.doc else {
            return
        }
        lastSelectedRowIndexes = tableview?.selectedRowIndexes ?? []
        lastSelectedRowUIDS = doc.brick.layers.selectedLayersByIndex.valuesArray.ids
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.latestUIInfo[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0 else {
            return nil
        }
        guard let layerInfo = self.latestUIInfo[row] else {
            return nil
        }
        
        let columnId = ColumnId(rawValue: tableColumn?.identifier.rawValue ?? "") ?? .layerNameColumnId
        var result : NSView? = nil
        
        func hookButton(_ btn:NSButton, sel : Selector) {
            btn.target = self
            btn.action = sel
            btn.tag = row
        }
        
        if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: columnId.rawValue), owner: self) {
            let isRowSelected = tableView.isRowSelected(row)
            
            //if IS_DEBUG && columnId == .layerNameColumnId {
            //    dlog?.info("cell row \(row) [\(layerInfo.title)] vis:\(layerInfo.visibility) acc:\(layerInfo.access)")
            //}
            
            switch columnId {
            case .layerVisiblityColumnId:
                if let btn : NSButton = view.subviews.first(where: {(view) in  view is NSButton } ) as? NSButton {
                    btn.image = layerInfo.visibility.iconSymbolName.systemSymbolImage
                    btn.contentTintColor = layerInfo.visibility.isHidden ? NSColor.appFailureOrange : nil
                    btn.alphaValue = layerInfo.access.isLocked ? 0.5 : 1.0
                    hookButton(btn, sel: #selector(onVisiblityCellAction(_:)))
                }
            case .layerAccessColumnId:
                if let btn : NSButton = view.subviews.first(where: {(view) in view is NSButton } ) as? NSButton {
                    btn.image = layerInfo.access.iconSymbolName.systemSymbolImage
                    btn.contentTintColor = layerInfo.access.isLocked ? NSColor.appFailureRed : nil
                    btn.alphaValue = layerInfo.visibility.isHidden ? 0.5 : 1.0
                    hookButton(btn, sel: #selector(onAccessCellAction(_:)))
                }
            case .layerNameColumnId:
                if let txt : NSTextField = view.subviews.first(where: {(view) in view is NSTextField } ) as? NSTextField {
                    
                    txt.tag = row
                    txt.attributedStringValue = layerInfo.titlesAttributedString(attributes: nil,
                                                                                 isSelected: isRowSelected,
                                                                                 hostView: tableView)
                    txt.action = #selector(onNameCellAction(_:))
                    txt.target = self
                    txt.delegate = self
                    txt.placeholderString = AppStr.LAYER_NAME.localized()
                }
            }
            
            result = view
        }
        
        return result
    }
    
    // func tableViewSelectionDidChange(_ notification: Notification) {
    func tableViewSelectionIsChanging(_ notification: Notification) {
        guard let tableview = tableview, let doc = doc else {
            return
        }
        guard isHandlingLayersSelectionChange == false else {
            dlogWarnings?.note("tableViewSelectionIsChanging isHandlingLayersSelectionChange == true!")
            return
        }
        isHandlingLayersSelectionChange = true
        
        let rowIndexes = tableview.selectedRowIndexes.union(lastSelectedRowIndexes)
        tableview.needsDisplay = true
        
        for colIdx in Self.ALL_COLUMNS_SET {
            for rowIdx in rowIndexes {
                if rowIdx >= 0 && rowIdx < tableview.numberOfRows {
                    if let cellView = tableview.view(atColumn: colIdx, row: rowIdx, makeIfNecessary: false) as? NSTableCellView {
                        let col = tableview.tableColumns[colIdx]
                        if let colid = ColumnId(rawValue: col.identifier.rawValue) {
                            switch colid {
                            case .layerVisiblityColumnId, .layerAccessColumnId:
                                break // No updates needed for now
                            case .layerNameColumnId:
                                if let info = self.latestUIInfo[rowIdx] {
                                    cellView.textField?.attributedStringValue = info.titlesAttributedString(attributes: nil,
                                                                                                            isSelected: tableview.isRowSelected(rowIdx),
                                                                                                            hostView: tableview)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Save previously selected rows indexes and IDS.
        self.snapshotIntoLasstSelectedRowIndexes(adoc:doc)
        
        let selectedIds = doc.brick.layers.findLayers(at: tableview.selectedRowIndexes).layers?.ids ?? []
        if doc.brick.layers.selectedLayers.ids != selectedIds {
            let result = doc.brick.layers.selectLayers(selectLayerIds: selectedIds, deseletAllOthers: true)
            switch result {
            case .success(let sels):
                var isSuccess = true
                let selectedLayers = doc.brick.layers.selectedLayers
                if IS_DEBUG && (sels != selectedLayers || selectedIds.count != selectedLayers.count) {
                    isSuccess = false
                    dlogWarnings?.warning("tableViewSelectionIsChanging: Selection implementation had \(selectedIds.count) ids to select: \(selectedIds.descriptionsJoined)\nbut selected layers were: \n\(selectedLayers.ids.descriptionsJoined)\n")
                }
                dlog?.successOrFail(condition: isSuccess, items: "tableViewSelectionIsChanging selected layers at indexes:\(doc.brick.layers.selectedLayersByIndex.descriptionLines)")
                if isSuccess {
                    self.latestUIInfo = doc.brick.layers.safeLayersUIInfos() // re-fetch
                    doc.setNeedsSaving(sender: self, context: "LayersVC.tableViewSelectionIsChanging", propsAndVals: ["selectedLayers":selectedIds.descriptionsJoined])
                    DispatchQueue.main.async {
                        self.hostingVC?.triggerValidations()
                    }
                }
                
            case .failure(let error):
                dlogWarnings?.note("tableViewSelectionIsChanging Failed selecting layer at indexes:\(tableview.selectedRowIndexes.allElements().descriptionLines) ids:\(selectedIds.descriptionLines) error:\(error.desc)")
            }
        } else {
            // Not a warning
            dlog?.fail("tableViewSelectionDidChange seletion ids equals the previous ids - no change.")
        }
        
        DispatchQueue.main.asyncAfter(delayFromNow: 0.1, block: {[self] in
            isHandlingLayersSelectionChange = false
        })
    }
}

// MARK: LayersTableViewAdapter : NSTextFieldDelegate , NSControlTextEditingDelegate
extension LayersTableViewAdapter : NSTextFieldDelegate , NSControlTextEditingDelegate {
    
    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textfield = notification.object as? NSTextField, let _ /*doc*/ = self.doc else {
            return
        }
        
        guard textfield.superviewWhichMatches({ view in
            view is NSTableCellView
        }) != nil else {
            return
        }
        
        guard let row = self.tableview?.row(for: textfield), let info = self.latestUIInfo[row] else {
            return
        }
        
        dlog?.info("controlTextDidEndEditing: \(textfield.stringValue) row:\(row)")
        
        if let sanitized = Brick.sanitize(textfield.stringValue), sanitized.count > 0 && sanitized != info.title {
            self.renameLayer(id: info.id, at: row, newName: textfield.stringValue)
            
        } else {
            // No new value, rename to unnamed
            self.renameLayer(id: info.id, at: row, newName: nil)
            // self.reloadData(forRowIndexes: [row], columnIndexes: Self.ALL_COLUMNS_SET)
        }
        
    }
}

// MARK: LayersTableViewAdapter : CommandInvokerObserver
extension LayersTableViewAdapter : CommandInvokerObserver {
    
    private func isShouldReloadAllRows(afterCommand command:Command)->Bool {
        switch command.typeName {
        // case CmdLayerAdd.typeName: return true
        case CmdLayerEdit.typeName:
            if let cmd = command as? CmdLayerEdit {
                return cmd.payload["name"] != nil
            }
        default:
            return false
        }
        return false
    }
    
    func commandInvoker(_ invoker: CommandInvoker, didPerformCommand command: Command, method: CommandExecutionMethod, result: CommandResult) {
        if let invoker = invoker as? (AnyObject & CommandInvoker), commandInvoker == nil {
            if IS_DEBUG && commandInvoker != nil {
                dlogWarnings?.warning("LayersTableViewAdapter.commandInvoker Setup of a NEW command invoker \(invoker.basicDesc)")
            }
            commandInvoker = invoker
        }
        
        // Exact same invoker instance..
        guard commandInvoker?.associatedOwner === invoker.associatedOwner else {
            dlogWarnings?.warning("LayersTableViewAdapter.commandInvoker?.associatedOwner !== invoker.associatedOwner \(commandInvoker?.associatedOwner?.description ?? "<nil>")!=\(invoker.associatedOwner.descOrNil)")
            return
        }
        
        if let cmd = command as? DocCommand, cmd.doc === self.doc { //
            
            // Commands
            switch cmd.category {
            case .layer:
                self.reloadData()
                
                /*
                if let cmd = cmd as? LayerCommand, let doc = cmd.doc {
                    switch cmd.typeName {
                    case CmdLayerRemove.typeName:
                        if result.isSuccess {
                            // ?
                        }
                    case CmdLayerAdd.typeName:
                        // ?
                    default:
                        // ?
                    }
                }*/
            default:
                break
            }
        }
    }
}


extension LayersTableViewAdapter : MNFocusObserver {
    
    func mnFocusChanged(from: NSResponder?, to: NSResponder?) {
         
        // dlog?.info("mnFocusChanged from:\(from.descOrNil) to:\(to.descOrNil)")
        let textField : NSTextField? = (to as? NSTextField) ?? (from as? NSTextField)
        
        guard let textfield = textField, textfield.superviewWhichMatches({ view in
            view is NSTableCellView
        }) != nil, to != from else {
            return
        }
        
        guard let row = self.tableview?.row(for: textfield), let info = self.latestUIInfo[row], let tableview = self.tableview else {
            return
        }
        
        if from == textField, to is DocWindow {
            // Exit edit mode:
            let layer = doc?.brick.layers.findLayer(byId: info.id)
            
            if layer?.sanitize(textfield.stringValue)?.count ?? 0 == 0 {
                textField?.attributedStringValue = info.titlesAttributedString(attributes: nil, isSelected: tableview.selectedRowIndexes.contains(row), hostView: tableview)
            }
            
        } else {
            // Enter edit mode:
            if info.title.count == 0 || info.isUnnamed {
                // Not a real name for this layer: "Unnamed 3" etc etc, so the user may only enter a new name:
                textfield.stringValue = ""
            } else {
                // A real name for this layer: "Unnamed 3" etc etc, so the user may only enter a new name:
                var str = info.title
                str = str.replacingOccurrences(ofFromTo: [
                    info.id.uuidString : ""])
                if info.subtitle != info.id.uuidString {
                    str = str.replacingOccurrences(of: info.subtitle, with: "")
                }
                str = Brick.sanitize(str) ?? ""
                textfield.stringValue = str
            }
            
            DispatchQueue.main.async {
                if let editor = textfield.currentEditor() {
                    editor.selectAll(self)
                }
            }
            
        }
    }
}
