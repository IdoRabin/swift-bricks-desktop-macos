//
//  BrickLayers.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation
import AppKit

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayers")
fileprivate let dlogNL : DSLogger? = nil // DLog.forClass("BrickLayers+Nearest")

class BrickLayers : CodableHashable, BasicDescable {
    static let MAX_LAYERS_ALLOWED = 32
    static let MIN_LAYER_NAME_LENGTH = 1
    static let MAX_LAYER_NAME_LENGTH = 128
    
    static let SETTING_ = 128
    @AppSettable(true, name: "BrickLayers.selectAddedLayer") static var selectAddedLayer : Bool
    @AppSettable(true, name: "BrickLayers.selectNearRemovedLayers") static var selectNearRemovedLayers : Bool
    
    // MARK: Properties
    private(set) var orderedLayers : [BrickLayer] = []
   
    // MARK: Privare
    private(set) var isBusy = false
    
    var isIdle : Bool {
        return !self.isBusy
    }
    
    // MARK: Lifecycle
    // MARK: Public
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(orderedLayers)
    }
    
    /// all layrs that are selected, in the same order they appear in orderedLayers. Equivalent to filtering the orderedLayers array with where: layer.selection.isSelected
    var selectedLayers : [BrickLayer] {
        return self.orderedLayers.filter(selection: .selected)
    }
    
    var selectedLayersByIndex : [Int:BrickLayer] {
        return self.layersByOrderIndex { layer in
            layer.isSelected
        }
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayers, rhs: BrickLayers) -> Bool {
        return lhs.orderedLayers == rhs.orderedLayers
    }
    
    // MARK: Equality
    var count : Int {
        return orderedLayers.count
    }
    
    var safeCount : Int {
        var result : Int = 0
        DispatchQueue.main.safeSync {[self] in
            result = orderedLayers.count
        }
        return result
    }
    
    // MARK: Count and layers access
    var layersByOrderIndex : [Int:BrickLayer] {
        var result : [Int:BrickLayer]  = [:]
        orderedLayers.forEachIndex { index, layer in
            result[index] = layer
        }
        return result
    }
    func layersByOrderIndex(filter test:(BrickLayer)->Bool)->[Int:BrickLayer] {
        var result : [Int:BrickLayer]  = [:]
        orderedLayers.forEachIndex { index, layer in
            if test(layer) {
                result[index] = layer
            }
        }
        return result
    }
    
    /// find a layer with the given id, or nil
    /// - Parameter id: id to search for
    /// - Returns: the first found layer with the given id
    func layer(byId id:LayerUID)->BrickLayer? {
        // NOTE: findLayer(byId id:LayerUID)->BrickLayer? calls this function
        return self.orderedLayers.first(id: id)
    }

    /// find a layer at the given order index, or nil if out of bounds
    /// - Parameter atOrderedIndex: index at orderedLayers array
    /// - Returns: the first found layer at the given index, or nil if out of bounds
    func layer(atOrderedIndex index:Int)->BrickLayer? {
        guard self.count > 0, let minn = self.minLayerIndex, let maxx = self.maxLayerIndex else {
            return nil
        }
        guard index >= minn && index <= maxx else {
            dlog?.note("layer(at index:\(index) out of bounds [\(minn)...\(maxx)]")
            return nil
        }
        return orderedLayers[index]
    }
    
    // Convenience
    subscript (index:Int) -> BrickLayer? {
        return self.layer(atOrderedIndex: index)
    }
    
    func count(visiblility:BrickLayer.Visiblity)->Int {
        return 0// orderedLayers.filter(visiblility: visiblility).count
    }

    func count(access:BrickLayer.Access)->Int {
        return 0// return orderedLayers.filter(access: access).count
    }
    
    var basicDesc : String {
        return "<\(type(of: self)) \(String(memoryAddressOf: self)) \(self.count) layers>"
    }
    
    struct LayerUIInfo : CodableHashable, JSONSerializable, BasicDescable {
        static let UNNAMED_LAYER_STRING = AppStr.UNNAMED.localized()
        static let TAG_DEFAULT_VAL : Int = -1
        
        let title : String
        let subtitle : String
        let access : BrickLayer.Access
        let visibility : BrickLayer.Visiblity
        let id : LayerUID
        let isUnnamed : Bool
        var tag : Int = TAG_DEFAULT_VAL
        
        static func unnamedTitle(id:LayerUID, index:Int? = 0)->String {
            return Self.UNNAMED_LAYER_STRING + String.NBSP + id.uuidString.safeSuffix(size: 4)
        }
        
        func unnamedTitle(index:Int? = 0)->String {
            return Self.UNNAMED_LAYER_STRING + String.NBSP + self.id.uuidString.safeSuffix(size: 4)
        }
        
        init (layer:BrickLayer, at index:Int, unnamedTitle:String?) {
            id = layer.id
            subtitle = Debug.IS_DEBUG ? layer.id.uuidString : "" // TODO: change this
            access = layer.access
            visibility = layer.visiblity
            isUnnamed = (layer.name?.count ?? 0) == 0
            
            title = (layer.name?.count ?? 0 > 0) ? layer.name! : (unnamedTitle ?? Self.unnamedTitle(id:layer.id))
        }
        
        func titlesAttributedString(attributes:[NSAttributedString.Key : Any]?, isSelected:Bool, hostView:NSView)->NSAttributedString {
            let str = [title, subtitle].joined(separator: " ")
            var attrs = attributes ?? [.font : NSFont.systemFont(ofSize: NSFont.systemFontSize)]
            var txtColor : NSColor = .labelColor
            if isSelected {
                txtColor = isDarkThemeActive(view: hostView) ? .labelColor :  .highlightColor
            }
            if !isSelected && (self.access.isLocked || self.visibility.isHidden) {
                txtColor = txtColor.blended(withFraction: 0.5, of: NSColor.controlBackgroundColor)!
            }
            attrs[.foregroundColor] = txtColor
            let attr = NSMutableAttributedString(string: str, attributes: attrs)
            if self.subtitle.count > 0, attrs.keys.contains(.font) {
                let smallFont = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular) // (attrs[.font] as! NSFont).withSize(9)
                attr.setAtttibutesForStrings(matching: subtitle, attributes: [.font:smallFont,
                                                                              .foregroundColor:txtColor.withAlphaComponent(0.7)])
            }
            return attr
        }
        
        var basicDesc: String {
            var accumStrs : [String] = []
            accumStrs.append("\"\(self.title.isEmpty ? AppStr.UNNAMED.localized() : self.title)\"")
            if self.tag != Self.TAG_DEFAULT_VAL {
                accumStrs.append("tag: \(tag)")
            }
            if self.id.uid.hashValue != 0 {
                accumStrs.append("id: \(id.uuidString)")
            }
            return "<LayerUIInfo " + accumStrs.joined(separator: " ") + " >"
        }
    }
    
    func safeLayerUIInfo(at index:Int)->LayerUIInfo? {
        guard let layer = self.layer(atOrderedIndex:index) else {
            return nil
        }
        
        var result :LayerUIInfo? = nil
        var ttl : String? = nil
        if layer.name?.count ?? 0 > 0 {
            ttl = layer.name
        } else {
            let signifier = layer.id.uuidString.suffix(4) // just 
            ttl = LayerUIInfo.UNNAMED_LAYER_STRING + String.NBSP + "\(signifier)"
        }

        DispatchQueue.main.safeSync {
            result = LayerUIInfo(layer:layer, at: index, unnamedTitle: ttl)
        }
        return result
    }
    
    func safeLayersUIInfos()->[Int:LayerUIInfo] {
        var result :[Int:LayerUIInfo] = [:]
        guard self.count > 0, let minn = self.minLayerIndex, let maxx = self.maxLayerIndex else {
            return result
        }
        
        DispatchQueue.main.safeSync {
            for index in minn...maxx {
                if let info = self.safeLayerUIInfo(at: index) {
                    
                    // We set the UI order to be last-top, first-bottom
                    result[index] = info
                }
            }
        }
        return result
    }
    
    func isLayerNameAllowed(_ newName:Any?, forLayerAt at:Int)->CommandResult {
        if newName.descOrNil.lowercased().contains("nil") {
            // Allow nil name:
            return .success("")
        }
        
        guard let newName = newName as? String else {
            return .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "Layer name value is not a string"))
        }
        
        return self.isLayerNameAllowed(newName, forLayerAt: at)
    }
    
    func isLayerNameAllowed(_ newName:String, forLayerAt at:Int)->CommandResult {
        guard at >= 0 && at < self.count else {
            return .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "new layer name for layet at index \(at) - is out of bounds."))
        }
        
        // Too loong / short
        guard newName.count >= Self.MIN_LAYER_NAME_LENGTH &&
              newName.count <= Self.MAX_LAYER_NAME_LENGTH else {
                  return .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "new layer name too long or short: [\(newName)] should be [\(Self.MIN_LAYER_NAME_LENGTH)...\(Self.MAX_LAYERS_ALLOWED)] chars long."))
        }
        
        return .success(newName)
    }

    /// Check if a dictionary of changes to a gien layer is allowed (permission and all values checked to be legal for assignment)
    /// - Parameters:
    ///   - dic: dictionary of field name (String) and value (Any)
    ///   - layerID: layer id of the layer to change
    /// - Returns: Result succes with the dictionary or failute with an error
    func isAllowedEdit(_ dic:[String:AnyCodable], layerID:LayerUID)->CommandResult {
        guard let layerIndex = self.indexOfLayer(id: layerID) else {
            return .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "failed finding layer index for layer: \(layerID)"))
        }
        
        var result : CommandResult = .success(dic)
        
        // Dictionary of changes to apply to the layer:
        for (key, val) in dic {
            var itemResult : CommandResult = .success(val)
            switch key {
            case "name":
                itemResult = isLayerNameAllowed(val, forLayerAt: layerIndex)
            default:
                dlog?.note("isAllowedEdit did not handle case of: [\(key)] changing")
            }
            if itemResult.isFailed {
                result = itemResult
                break
            }
        }
        
        return result
    }
    
    /// Apply a dictionary of changes to a given layer (by id)
    /// NOTE: Assumes isAllowedEdit(dic) was called before this method
    /// - Parameters:
    ///   - dic: dictionary of field name (String) and value (Any)
    ///   - layerID: layer id of the layer to change
    /// - Returns: Result succes with the dictionary or failute with an error
    func applyEdit(_ dic:[String:AnyCodable], layerID:LayerUID)->CommandResult {
        guard let layerIndex = self.indexOfLayer(id: layerID) else {
            return .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "applyEdit failed finding layer index for layer: \(layerID)"))
        }
        
        var result : CommandResult = .success(dic)
        
        // Dictionary of changes to apply to the layer:
        for (key, val) in dic {
            var itemResult : CommandResult = .success(val)
            switch key {
            case "name":
                if let anewName = val as? String, let newName = Brick.sanitize(anewName) {
                    self[layerIndex]?.name = newName
                } else if "\(val)".lowercased().contains("nil") {
                    self[layerIndex]?.name = nil
                } else {
                    itemResult = .failure(AppError(AppErrorCode.doc_layer_change_failed, detail: "applyioEdit - layer name value is not a string"))
                }
            default:
                dlog?.note("applyEdit did not handle case of: [\(key)] changing")
            }
            
            if itemResult.isFailed {
                result = itemResult
                break
            }
        }
        
        return result
    }
}

extension BrickLayers : BrickLayersContainer {
    func indexOfLayers(ids: [LayerUID]) -> [Int?] {
        var result : [Int?] = []
        for id in ids {
            let indexOrNil = self.orderedLayers.firstIndex { layer in
                layer.id == id
            }
            result.append(indexOrNil)
        }
        return result
    }
    
    func indexOfLayer(id: LayerUID) -> Int? {
        return indexOfLayers(ids: [id]).first!
    }
    
    func indexOfLayer(layer: BrickLayer) -> Int? {
        return indexOfLayers(ids: [layer.id]).first!
    }
    
    func findLayersNearestTo(ids:[LayerUID], minGrow:UInt = 0, maxGrow:UInt = 2)->[BrickLayer] {
        var result : [BrickLayer] = []
        
        guard self.count > 0 else {
            return result
        }
        
        guard maxGrow <= self.count else {
            dlog?.warning("findLayersNearestTo: maxGrow \(maxGrow) cannot be >= count \(self.count) of all layers")
            return result
        }
        
        guard minGrow < maxGrow else {
            dlog?.warning("findLayersNearestTo: minGrow (\(minGrow) sould be smaller than maxGrow (\(maxGrow)")
            return result
        }
        
        
        guard ids.count < self.count else {
            dlog?.warning("findLayersNearestTo: \(ids.descriptionsJoined) ids cound must be smaller than layers count")
            return result
        }
        
        guard ids.isEmpty == false else {
            dlog?.warning("findLayersNearestTo: \(ids.descriptionsJoined) at least one input id needed")
            return result
        }
        
        
        let byIndex = self.layersByOrderIndex { layer in
            ids.contains(layer.id)
        }
        
        if byIndex.count == ids.count {
            let indexes = byIndex.keysArray.sorted()
            
            dlogNL?.info("findLayersNearestTo: \(ids.descriptionsJoined) at: \(indexes.descriptionsJoined)")
            dlogNL?.info("findLayersNearestTo START")
            DLog.indentStart(logger: dlogNL)
            
            // All layers in ids were found in self layers ordered array)
            let minGrow = clamp(value: minGrow, lowerlimit: 1, upperlimit: maxGrow)
            let maxGrow = clamp(value: maxGrow, lowerlimit: minGrow + 1, upperlimit: max(maxGrow, minGrow + 1))
            var wasFound = false
            for adex in minGrow...maxGrow { // Attempts with as minimum
                for sign in [-1, +1] {
                    let add = sign * Int(adex)
                    for index in indexes {
                        let idx = index + add
                        if idx >= 0 && idx < self.count {
                            let layer = self.layer(atOrderedIndex: idx)
                            
                            
                            if let layer = layer, !ids.contains(layer.id) {
                                result.append(layer)
                                wasFound = true
                            }
                            
                            dlogNL?.successOrFail(condition: wasFound, items: "findLayersNearestTo: at index: \(idx) layer: \(layer?.id.description ?? "<nil>")")
                        }
                        
                        if wasFound { break }
                    }
                    if wasFound { break }
                }
                if wasFound { break }
            }
            DLog.indentEnd(logger: dlogNL)
            dlogNL?.successOrFail(condition: wasFound, items: "findLayersNearestTo END")
        } else {
            dlog?.warning("findLayersNearestTo: \(ids.descriptionsJoined) failed finding some ids: \( (self.findLayers(ids: ids).layers?.ids.descriptionsJoined).descOrNil)")
        }
        
        return result
    }
    
    private func operateOnLayers(byIds ids:[LayerUID], block:([BrickLayer])->LayersResult)->LayersResult {
        let foundLayers = self.findLayers(ids: ids)
        switch foundLayers {
        case .failure:
            return foundLayers
        case .success(let layers):
            return block(layers)
        }
    }
    
    // MARK: Public from protocol
    func addLayers(layers: [BrickLayer]) -> LayersResult {
        guard self.count < Self.MAX_LAYERS_ALLOWED else {
            return .failure(AppError(AppErrorCode.doc_layer_insert_failed, detail: "Max layers count reached: \(Self.MAX_LAYERS_ALLOWED), cannot add more."))
        }
        
        // Determine the index to insert the new layer/s:
        var indexToInsertAt : Int = 0 // no layer selected: insert at top
        if self.selectedLayers.count > 0 {
            
            // Selected layers: insert above the topmost selected layer
            let indexes = self.indexOfLayers(ids: self.selectedLayers.ids).compactMap { index in
                return index
            } as [Int]
            indexToInsertAt = indexes.min() ?? 0
        }
        
        // Actually Add layers:
        var toAdd = layers
        let existing = layers.filter(ids: orderedLayers.ids)
        if existing.count > 0 {
            if existing.count == layers.count {
                dlog?.warning("Layers already exist in the layers ordered list: \(existing.ids.descriptionsJoined)")
            } else {
                dlog?.warning("Some layers already exist in the layers ordered list: \(existing.ids.descriptionsJoined)")
            }
            toAdd = layers.excluding(ids: existing.ids)
        }
        
        if toAdd.count > 0 || layers.count == 0 {
            if indexToInsertAt >= 0 && indexToInsertAt <= layers.count {
                orderedLayers.insert(contentsOf: toAdd, at: indexToInsertAt)
            } else {
                orderedLayers.append(contentsOf: toAdd)
            }
            
            // Change selection if needed
            if Self.selectAddedLayer { // App Settings
                _ = self.selectLayers(selectLayerIds: toAdd.ids, deseletAllOthers: true)
            }
            
            return .success(toAdd)
        } else {
            return .failure(AppError(AppErrorCode.doc_layer_insert_failed, detail: "0 layers to add (excluded \(existing.count) already existing)"))
        }
        // return .failure(AppError(AppErrorCode.doc_layer_insert_failed, detail: "Unknown error"))
    }
    
    func addLayer(id: LayerUID?, name: String?) -> LayersResult {
        let layr = BrickLayer(uid: id, name: name)
        return self.addLayers(layers: [layr])
    }
   
    func removeLayers(ids: [LayerUID]) -> LayersResult {
        return self.operateOnLayers(byIds: ids) { layers in
            
            var nearestIds : [LayerUID] = []
            let isSelectNearestLayers = Self.selectNearRemovedLayers
            if isSelectNearestLayers { // App Settings
                let maxgrow = UInt(max(self.count - 1, 2))
                nearestIds = self.findLayersNearestTo(ids: ids, minGrow: 0, maxGrow: maxgrow).ids
            }
            
            if orderedLayers.remove(objects: layers) == ids.count {
                
                // Change selection if needed
                if isSelectNearestLayers, nearestIds.count > 0 { // App Settings
                    _ = self.selectLayers(selectLayerIds: nearestIds, deseletAllOthers: true)
                }
                
                return .success(layers)
            } else {
                return .failure(AppError(AppErrorCode.doc_layer_delete_failed, detail: "Some layers were not deleted!"))
            }
        }
    }
    
    /// Move layer in the "stack" order of the layers to a new index
    /// - Parameters:
    ///   - id:id of the layer to move
    ///   - toIndex: new index to set the layer in: NOTE the new index should be given in old array indexes (i.e as if was not yet removed from prev. location)
    /// - Returns: succes with the moved layer or the failure error
    func changeLayerOrder(id: LayerUID, toIndex: Int) -> LayersResult {
        let curIndex = self.indexOfLayer(id: id)
        let layer = self.orderedLayers.filter(ids: [id]).first
        if let curIndex = curIndex, let layer = layer {
            if curIndex == toIndex {
                // No need to mode
                return .success([layer])
            } else {
                orderedLayers.remove(at: curIndex)
                var newIndex = toIndex
                if newIndex > curIndex {
                    newIndex -= 1 // was removed, we fix the index
                }
                if newIndex > -1 && newIndex <= self.orderedLayers.count {
                    orderedLayers.insert(layer, at: newIndex)
                }
                return .success([layer])
            }
        }
        
        return .failure(AppError(AppErrorCode.doc_layer_move_failed, detail: "Layer id \(id) was not found"))
    }
    
    func changeLayerOrderToTop(id: LayerUID) -> LayersResult {
        return self.changeLayerOrder(id: id, toIndex: self.count)
    }
    
    func changeLayerOrderToBottom(id: LayerUID) -> LayersResult {
        return self.changeLayerOrder(id: id, toIndex: 0)
    }
    
    private func findLayers(test: (BrickLayer)->Bool) -> LayersResult {
        guard self.orderedLayers.count > 0 else {
            return .failure(AppError(AppErrorCode.doc_layer_search_failed, detail: "Not layers to search in"))
        }
        var result : [BrickLayer] = []
        for layer in orderedLayers {
            if test(layer) {
                result.append(layer)
            }
        }
        return .success(result.uniqueElements())
    }
    
    func findLayers(at indexes: IndexSet) -> LayersResult {
        return self.findLayers { layer in
            if let index = self.indexOfLayer(layer: layer),
               indexes.contains(index) {
               return true // test success: layer index in the index set
            }
            return false // test failed
        }
    }
    
    func findLayer(byId id:LayerUID)->BrickLayer? {
        // Convenience
        return self.layer(byId: id)
    }
    
    func findLayers(ids: [LayerUID]) -> LayersResult {
        return self.findLayers { layer in
            ids.contains(layer.id)
        }
    }
    
    func findLayers(names: [String], caseSensitive:Bool = true) -> LayersResult {
        return self.findLayers { layer in
            if caseSensitive {
                return names.contains(layer.name ?? "")
            } else {
                return names.lowercased.contains(layer.name?.lowercased() ?? "")
            }
        }
    }
    
    func findLayers(hidden: Bool?) -> LayersResult {
        return self.findLayers { layer in
            layer.isHidden == hidden
        }
    }
    
    func setLayersVisibility(ids: [LayerUID], newVisibilityState:BrickLayer.Visiblity) -> LayersResult {
        self.operateOnLayers(byIds: ids) { layers in
            var changes = 0
            for layer in layers {
                if layer.visiblity != newVisibilityState {
                    layer.visiblity = newVisibilityState
                    changes += 1
                }
            }
            
            return .success(layers)
            //return.failure(AppError(AppErrorCode.doc_layer_lock_unlock_failed, detail: "set layer locked \(isLocked): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func setLayersAccess(ids: [LayerUID], newAccessState:BrickLayer.Access) -> LayersResult {
        self.operateOnLayers(byIds: ids) { layers in
            var changes = 0
            for layer in layers {
                if layer.access != newAccessState {
                    layer.access = newAccessState
                    changes += 1
                }
            }
            
            return .success(layers)
            //return.failure(AppError(AppErrorCode.doc_layer_lock_unlock_failed, detail: "set layer locked \(isLocked): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func setLayersSelected(ids: [LayerUID], selectionState:BrickLayer.Selection) -> LayersResult {
        self.operateOnLayers(byIds: ids) { layers in
            var changesCount = 0
            for layer in layers {
                if layer.selection != selectionState {
                    layer.selection = selectionState
                    changesCount += 1
                }
            }
            return .success(layers.filter({ layer in
                layer.isSelected
            }))
            // return.failure(AppError(AppErrorCode.doc_layer_select_deselect_failed, detail: "set layer selected \(isSelected): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func lockLayers(ids: [LayerUID]) -> LayersResult {
        return self.setLayersAccess(ids: ids, newAccessState: .locked)
    }
    
    func unlockLayers(ids: [LayerUID]) -> LayersResult {
        return self.setLayersAccess(ids: ids, newAccessState: .unlocked)
    }
    
    func selectLayers(selectLayerIds:[LayerUID], deseletAllOthers:Bool = false)->LayersResult {
        
        // Set seletion to layers:
        let result1 = self.setLayersSelected(ids: selectLayerIds, selectionState: .selected)
        switch result1 {
        case .success(let layers):
            
            // Deselect other layers
            if deseletAllOthers {
                let deselectIds : Set<LayerUID> = Set(orderedLayers.ids).subtracting(selectLayerIds)
                let result2 = self.setLayersSelected(ids: deselectIds.allElements(), selectionState: .nonselected)
                switch result2 {
                case .success:
                    return .success(selectedLayers)
                case .failure:
                    return result2
                }
            } else {
                return .success(layers)
            }
        case .failure:
            return result1
        }
    }
    
    func deselectLayers(deselectLayerIds: [LayerUID]) -> LayersResult {
        self.setLayersSelected(ids: deselectLayerIds, selectionState: .nonselected)
    }
    
    var minLayerIndex: Int? {
        return self.count > 0 ? 0 : nil
    }
    
    var maxLayerIndex: Int? {
        return self.count > 0 ? self.count - 1 : nil
    }
    
}

extension Sequence where Element : BrickLayer {

    var ids : [LayerUID] {
        return self.compactMap { layer in
            return layer.id
        }
    }
    
    func filter(access:BrickLayer.Access)->[BrickLayer] {
        return self.filter({ layer in
            layer.access == access
        })
    }

    func filter(visiblility:BrickLayer.Visiblity)->[BrickLayer] {
        return self.filter({ layer in
            layer.visiblity == visiblility
        })
    }

    func filter(selection:BrickLayer.Selection)->[BrickLayer] {
        return self.filter({ layer in
            layer.selection == selection
        })
    }

    func first(id:LayerUID)->BrickLayer? {
        return self.filter({ layer in
            layer.id == id
        }).first
    }
    
    func filter(ids:[LayerUID])->[BrickLayer] {
        return self.filter({ layer in
            ids.contains(layer.id)
        })
    }

    func filter(names:[String], caseSensitive:Bool = false)->[BrickLayer] {
        let nams = caseSensitive ? names :  names.lowercased
        return self.filter({ layer in
            let name = caseSensitive ? layer.name : layer.name?.lowercased()
            return nams.contains(name ?? "")
        })
    }

    func excluding(ids:[LayerUID])->[BrickLayer] {
        return self.filter({ layer in
            return !ids.contains(layer.id)
        })
    }
    
    func contains(allIds ids:[LayerUID])->Bool {
        return self.filter(ids: ids).count == ids.count
    }

    func contains(anyOfIds ids:[LayerUID])->Bool {
        return self.filter(ids: ids).count > 0 // TODO: Optimize for stopping on first found id
    }

    func contains(allNames names:[String], caseSensitive:Bool = false)->Bool {
        return self.filter(names: names).count == names.count
    }

    func contains(anyOfNames names:[String], caseSensitive:Bool = false)->Bool {
        return self.filter(names: names, caseSensitive: caseSensitive).count > 0 // TODO: Optimize for stopping on first found name
    }
}


extension Sequence where Element == BrickLayers.LayerUIInfo {
    var titles : [String] {
        return self.map { layerInfo in
            layerInfo.title
        }
    }
}
