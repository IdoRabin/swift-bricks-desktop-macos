//
//  BrickLayersContainer.swift
//  Bricks
//
//  Created by Ido on 20/02/2022.
//

import Foundation

typealias LayersResult = Result<[BrickLayer], AppError>

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayersContainer")

extension LayersResult {
    var layers : [BrickLayer]? {
        switch self {
        case .failure: return nil
        case .success(let result): return result
        }
    }
    
    var asCommandResult : CommandResult {
        switch self {
        case LayersResult.failure(let error):  return CommandResult.failure(error)
        case LayersResult.success(let layers): return CommandResult.success(layers)
        }
    }
}

protocol BrickLayersContainer {
    var count : Int {get}
    var minLayerIndex : Int? { get }
    var maxLayerIndex : Int? { get }
    
    // Add / Remove
    func addLayers(layers:[BrickLayer])->LayersResult
    func addLayer(id:LayerUID?, name:String?)->LayersResult
    func removeLayers(ids:[LayerUID])->LayersResult
    
    // Layer order
    func indexOfLayers(ids:[LayerUID])->[Int?]
    func indexOfLayer(id:LayerUID)->Int?
    func indexOfLayer(layer:BrickLayer)->Int?
    func changeLayerOrder(id:LayerUID, toIndex:Int)->LayersResult
    func changeLayerOrderToTop(id:LayerUID)->LayersResult
    func changeLayerOrderToBottom(id:LayerUID)->LayersResult
    
    // Find
    func findLayers(ids:[LayerUID])->LayersResult
    func findLayers(names:[String])->LayersResult
    func findLayers(hidden:Bool?)->LayersResult
    
    // Edit
    func lockLayers(ids:[LayerUID])->LayersResult
    func unlockLayers(ids:[LayerUID])->LayersResult
    func selectLayers(selectLayerIds:[LayerUID], deseletAllOthers:Bool )->LayersResult
    func deselectLayers(deselectLayerIds:[LayerUID])->LayersResult
}
