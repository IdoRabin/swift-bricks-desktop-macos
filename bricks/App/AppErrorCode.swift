//
//  AppErrorCode.swift
//  XPlan
//
//  Created by Ido on 08/11/2021.
//

import Foundation

typealias AppErrorInt = Int
enum AppErrorCode : AppErrorInt, AppErrorCodable {
    
    // Cancel
    case user_canceled = 999
    
    // Misc
    case misc_unknown = 9000
    case misc_failed_loading = 9001
    case misc_failed_saving = 9002
    case misc_operation_canceled = 9003
    case misc_failed_creating = 9010
    case misc_failed_removing = 9011
    case misc_failed_inserting = 9012
    case misc_failed_updating = 9013
    case misc_failed_reading = 9014
    case misc_no_permission_for_operation = 9020 //
    case misc_readonly_permission_for_operation = 9021 //
    
    // Misc
    case web_unknown = 1000
    case web_internet_connection_error = 1003
    case web_unexpected_response = 1100
    
    // Command
    case cmd_not_allowed_now = 1500 // no permission?
    case cmd_failed_execute = 1501
    case cmd_failed_undo = 1502
    
    // Doc
    case doc_unknown = 2000
    case doc_create_new_failed = 2010
    case doc_create_from_template_failed = 2011
    case doc_open_existing_failed = 2012
    case doc_save_failed = 2013
    case doc_load_failed = 2014
    case doc_close_failed = 2015
    case doc_change_failed = 2016
    
    case doc_layer_insert_failed = 2030
    case doc_layer_insert_undo_failed = 2031
    case doc_layer_move_failed = 2032
    case doc_layer_move_undo_failed = 2033
    case doc_layer_delete_failed = 2040
    case doc_layer_delete_undo_failed = 2041
    case doc_layer_already_exists = 2050
    case doc_layer_lock_unlock_failed = 2051
    case doc_layer_select_deselect_failed = 2052
    case doc_layer_search_failed = 2060
    case doc_layer_change_failed = 2070
    
    // user
    case user_login_failed = 2501
    case user_login_failed_no_permission = 2502
    case user_login_failed_bad_credentials = 2503
    case user_login_failed_permissions_revoked = 2504
    
    case user_logout_failed = 2530
    
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
        var result = "bricks"
        if let prefix = "\(self)".split(separator: "_").first {
            result.append(".\(prefix)")
        }
        return result
    }
    
    var desc : String {
        return "TODO.AppErrorCode.desc|\(self)"
    }
    
    var code: AppErrorInt {
        return self.rawValue
    }
}
