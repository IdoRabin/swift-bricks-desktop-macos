//
//  AppErrorCode.swift
//  XPlan
//
//  Created by Ido on 08/11/2021.
//

import Foundation

typealias AppErrorInt = Int
enum AppErrorCode : AppErrorInt, AppErrorCodable {
    
    // Misc
    case misc_unknown = 9000
    case misc_failed_loading = 9001
    case misc_failed_saving = 9002
    case misc_operation_canceled = 9003
    
    // Misc
    case web_unknown = 1000
    case web_internet_connection_error = 1003
    case web_unexpected_response = 1100
    
    // Command
    case cmd_failed_execute
    case cmd_failed_undo
    
    // Doc
    case doc_unknown = 2000
    case doc_layer_insert_failed = 2010
    case doc_layer_insert_undo_failed = 2011
    case doc_layer_move_failed = 2012
    case doc_layer_move_undo_failed = 2013
    case doc_layer_delete_failed = 2020
    case doc_layer_delete_undo_failed = 2021
    
    // db
    case db_unknown = 3000
    // case db_failed_init = 3010
    // case db_failed_migration = 3011
    // case db_failed_load = 3012
    //
    // case db_failed_fetch_request = 3020
    // case db_failed_fetch_by_ids = 3021
    // case db_failed_creating_fetch_request = 3022
    // case db_failed_update_request = 3030
    // case db_failed_save = 3040
    // case db_failed_autosave = 3041
    // case db_failed_delete = 3050
    
    // Misc
    case ui_unknown = 5000
    
    var domain : String {
        var result = "xplan"
        if let prefix = "\(self)".split(separator: "_").first {
            result.append(".\(prefix)")
        }
        return result
    }
    
    var desc : String {
        return "TODO:\(self)"
    }
    
    var code: AppErrorInt {
        return self.rawValue
    }
}