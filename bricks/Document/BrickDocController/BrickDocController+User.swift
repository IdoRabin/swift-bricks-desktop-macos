//
//  BrickDocController+User.swift
//  Bricks
//
//  Created by Ido on 06/04/2022.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("BrickDocController+User")
extension BrickDocController /* user management */{
    
    static let DEBUG_USER : Bool = Debug.IS_DEBUG && true
    
    var isUserLogggedIn : Bool {
        return self.curUser != nil
    }
    
    internal func setupCurUserIfNeeded() {
        if self.curUser == nil {
            // Setup debug user
            if Self.DEBUG_USER {
                
                let debugUser = BricksUser(id: UserUID(uuidString: "00000000-0000-0000-0000-000000000001"), name: "Debug_User_01")
                
                //self.curUser = debugUser
                self.setCurUser(debugUser) { response in
                    switch response {
                    case .success:
                        dlog?.success("logged in: \(debugUser)")
                    case .failure(let error):
                        dlog?.warning("failed setup: \(error.description)")
                    }
                }
            }
        }
    }
    
    func setCurUser(_ newUser:BricksUser? = nil, completion:@escaping UserResultBlock) {
        
        // Logout, login user:
        DispatchQueue.notMainIfNeeded {
            var result : UserResult = .failure(AppError(AppErrorCode.user_login_failed, detail: "Failed user login / creation for unknown reason"))
            if newUser != self.curUser {
                let logoutResult = self.logoutCurUserIfNeeded()
                if logoutResult.isSuccess {
                    self.internal_setCurUser(newUser)
                    result = self.loginCurUserIfNeeded()
                } else {
                    result = logoutResult
                }
            } else {
                // No need to logout or change cur user, just re-login.
                result = self.loginCurUserIfNeeded()
            }
            
            // After all operations are completed:
            DispatchQueue.mainIfNeeded {
                completion(result)
            }
        }
    }
    
    
                                               
    internal func loginCurUserIfNeeded()->UserResult {
        guard let curUser = self.curUser else {
            return .failure(AppError(AppErrorCode.user_login_failed, detail: "Cannot login user <nil>"))
        }
        guard Thread.current.isMainThread == false else {
            dlog?.warning("loginCurUserIfNeeded must be called from non-main thread")
            return .failure(AppError(AppErrorCode.user_login_failed, detail: "Cannot login user from main thread"))
        }
        
        // TODO: Login user to remote / notify "user is active" if needed
        
        return .success(curUser)
    }
    
    internal func logoutCurUserIfNeeded()->UserResult {
        
        guard let curUser = self.curUser else {
            // the function name has IfNeeded().. so logout for nil is a success
            return .success(nil)
        }
        guard Thread.current.isMainThread == false else {
            dlog?.warning("loginCurUserIfNeeded must be called from non-main thread")
            return .failure(AppError(AppErrorCode.user_login_failed, detail: "Cannot logout user from main thread"))
        }
        
        // TODO: Logout user in remote / notify "user is not active" if needed
        return .success(curUser)
    }
}
