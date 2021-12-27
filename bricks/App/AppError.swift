//
//  AppErrors.swift
//  grafo
//
//  Created by Ido on 10/07/2021.
//

import Foundation

fileprivate let dlog : DSLogger? = DLog.forClass("AppError")

/// Allows converting between NSError, error and AppError
protocol AppErrorCodable {
    var desc : String { get }
    var domain : String { get }
    var code : AppErrorInt { get }
    
    var domainCodeDesc : String { get }
}

extension AppErrorCodable /* default implementation */ {
    var domainCodeDesc : String {
        return "\(self.domain).\(self.code)"
    }
}

/// Main app class of error, is derived from Error, but can be initialized by AppError codes and also in concurrance with NSErrors and other Errors and underlying errors / filtered before determining eventual error code
/// The main aim in this class is to wrap each error raised in the app from any source into a more organized state
public class AppError: Error, Codable, AppErrorCodable , CustomDebugStringConvertible, CustomStringConvertible, JSONSerializable {
    
    // Codable
    private enum CodingKeys: String, CodingKey {
        case domain = "domain"
        case code = "code"
        case underlyingError = "underlyingError"
        case desc = "desc" // we use desc because "description" is used by CustomStringConvertible protocol
        case details = "details"
    }
    
    // Base members
    let domain : String
    let code:AppErrorInt
    let desc : String
    let underlyingError:AppError?
    let details:[String]?

    /// Localized description only!
    var localizedDescription: String {
        get {
            return desc
        }
    }
    
    var hasUnderlyingError : Bool {
        return underlyingError != nil
    }
    
    /// CustomStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    public var description: String { // CustomStringConvertible
        var result = "<\(self.domainCodeDesc)> desc: \"\(desc)\"."
        if let details = details, details.count > 0 {
            result += " details:\(details.description)"
        }
        if let underlyingError = underlyingError {
            result.append(" underlying: \(underlyingError.description)")
        }
        
        return result
    }
    
    /// CustomDebugStringConvertible
    /// We have the same description and debugDescription to avoid confusion
    public var debugDescription: String {
        return self.description
    }
    
    
    /// Init in base level (try not to use this init)
    ///
    /// - Parameters:
    ///   - newDomain: domain of error.
    ///   - newCode: code of error
    ///   - newDescription: description of error (should b localized)
    ///   - newDetails: array of strings that detail the cause and exact situation where the error was raisedd (developer eyes only)
    ///   - newUnderlyingError: underlying error that was reaised befoer or was the cause to the main error
    init(domain newDomain:String, code newCode:AppErrorInt, description newDescription:String, details newDetails:[String]? = nil, underlyingError newUnderlyingError:AppError?) {
        
        // Init members
        domain = newDomain
        code = newCode
        desc = newDescription
        underlyingError = newUnderlyingError
        details = newDetails
        
        #if DEBUG
            if desc.contains("couldn't") {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        // Tracks any error created
        self.trackError(error: self)
    }
    
    convenience init(domain newDomain:String? = nil, errcode newCode:AppErrorCode, description newDescription:String, details newDetails:[String]? = nil, underlyingError newUnderlyingError:AppError?) {
        let adomain = newDomain ?? newCode.domain
        self.init(domain: adomain, code: newCode.rawValue, description: newDescription, details: newDetails, underlyingError: newUnderlyingError)
    }
    
    
    /// Init using a given NSError
    ///
    /// - Parameter nserror: NSError to convert to AppError
    init (nserror:NSError, detail:String? = nil) {
        
        // Init memebrs from the NSError:
        domain = nserror.domain
        code = nserror.code
        desc = nserror.localizedDescription
        var newDetails : [String] = []
        
        // Add detail param to details array
        if let detail = detail {
            newDetails.append(detail)
        }
        
        // Add other userInfo keys as details
        if nserror.userInfo.count > 0 {
            for (key,value) in nserror.userInfo {
                let aKey = key.replacingOccurrences(of: "NSValidationErrorKey", with: "❗NSValidationErrorKey")
                newDetails.append("\(aKey) : \(value)")
            }
        }
        details = (newDetails.count > 0) ? newDetails : nil
        
        // Copy underlying error (but convert to AppError as well)
        if let underlyingError = nserror.userInfo[NSUnderlyingErrorKey] as? NSError {
            self.underlyingError = AppError(nserror: underlyingError)
        } else {
            self.underlyingError = nil
        }
        
        #if DEBUG
            if desc.contains("couldn't") {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        // Tracks any error created
        self.trackError(error: self)
    }
    
    
    /// Init an AppError using any AppErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - detail: (optional) detail describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(_ code:AppErrorCodable, detail:String? = nil, underlyingError:Error? = nil) {
        var details : [String]? = nil
        if let detail = detail {
            details = [detail]
        }
        self.init(code, detailsArray:details, underlyingError:underlyingError)
    }
    
    
    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - details: (optional) detail array describing the exact situations raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(_ code:AppErrorCodable, /*we needed to use this name for disambiguation reasons->*/detailsArray:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError as? AppError {
            saunderlying = underlyingError
        } else if let underlyingError = underlyingError {
            saunderlying = AppError(error:underlyingError)
        }
        
        self.init(domain:code.domain, code:code.code, description:code.desc, details: detailsArray, underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    
    convenience init(code:AppErrorCode, detailsArray:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError as? AppError {
            saunderlying = underlyingError
        } else if let underlyingError = underlyingError {
            saunderlying = AppError(error:underlyingError)
        }
        
        self.init(domain:code.domain, errcode:code,
                  description:code.desc,
                  details: detailsArray,
                  underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    

    /// Init an SAError using any SAErrorCodable
    ///
    /// - Parameters:
    ///   - code: code for the error (see AppErrors)
    ///   - details: (optional) array of details describing the exact situation raising the error (developer eyes only)
    ///   - underlyingError: (optional) underlying error that has evoked this error
    convenience init(_ code:AppErrorCodable, details:[String]?, underlyingError:Error? = nil) {
        var saunderlying : AppError? = nil
        if let underlyingError = underlyingError, !(underlyingError is AppError) {
            saunderlying = AppError(error:underlyingError)
        }
        self.init(domain:code.domain, code:code.code, description:code.desc, details: details, underlyingError: (saunderlying != nil ? saunderlying! : nil))
    }
    
    
    /// Init an SAError using any Error
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init(error:Error) {
        #if DEBUG
        if String(describing:type(of: error)) == "SAError" {
            dlog?.raiseAssertFailure("Error converted to error")
        }
        #endif
        
        self.init(nserror: error as NSError)
    }
    
    /// Conveniene optional init an SAError using any Error?
    /// May return nil if provided error is nil
    ///
    /// - Parameter error: error to be converted to an SAError
    convenience init?(error:Error?) {
        #if DEBUG
            if String(describing:type(of: error)) == "SAError" {
                dlog?.raiseAssertFailure("Error converted to error")
            }
        #endif
        
        if let error = error {
            self.init(nserror: error as NSError)
        }
        return nil
    }
    
    // Track error:
    
    /// Track an error using the AppTracking mechanism (analytics)
    ///
    /// - Parameter error: an SAError to be sent to the analytics system
    private func trackError(error:AppError) {
        // let errorName = "error:" + error.domain + " code:" + String(error.code)
        
        // Create params for the analytics system:
        var params : [String:Any] = [:]
        params["description"] = error.desc
        if let details = error.details {
            params["details"] = details.joined(separator: "|")
        }
        
        // Add params for the underlying error
        if let underlyingError = error.underlyingError {
            let desc = "error:" + underlyingError.domain + " code:" + String(underlyingError.code)
            params["underlying_error"] = desc
            params["underlying_error_desc"] = underlyingError.desc
            if let details = underlyingError.details {
                params["underlying_error_details"] = details.joined(separator: "|")
            }
        }
        
        // Param values can be up to 100 characters long. The "firebase_", "google_" and "ga_" prefixes are reserved and should not be used
        #if os(OSX)
        // AppTracking.shared.trackEvent(category: TrackingCategory.Errors, name: errorName, parameters:(params.count > 0 ? params : nil))
        #elseif os(iOS)
        // Does nothing
        #endif
    }
}

extension AppError /*appErrors*/ {
    
    convenience init(by underError:Error?, defaultErrorCode:AppErrorCode, detailsArray:[String]?) {
        self.init(by: underError as NSError?, defaultErrorCode: defaultErrorCode, detailsArray: detailsArray)
    }
    
    convenience init(by underError:Error?, defaultErrorCode:AppErrorCode, detail:String? = nil) {
        self.init(by: underError as NSError?, defaultErrorCode: defaultErrorCode, detail: detail)
    }
    
    convenience init(by underError:NSError?, defaultErrorCode:AppErrorCode, detail:String? = nil) {
        let details : [String]? = detail != nil ? [detail!] : nil
        self.init(by: underError as NSError?, defaultErrorCode: defaultErrorCode, detailsArray: details)
    }
    
    convenience init(by underError:NSError?, defaultErrorCode:AppErrorCode, detailsArray:[String]?) {
        if let underError = underError {
            switch (underError.code, underError.domain) {
            case (-1009, NSURLErrorDomain), (-1003, NSURLErrorDomain), (-1004, NSURLErrorDomain), (-1001, NSURLErrorDomain):
                self.init(AppErrorCode.web_internet_connection_error, detailsArray:detailsArray, underlyingError:underError)
            case (3, "Alamofire.AFError"):
                self.init(AppErrorCode.web_unexpected_response, detailsArray:detailsArray, underlyingError:underError)
            default:
                self.init(defaultErrorCode, details: detailsArray, underlyingError: underError)
            }
        } else {
            self.init(defaultErrorCode, details: detailsArray, underlyingError: underError)
        }
    }
}

extension AppError : Equatable {
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        var result = lhs.domain == rhs.domain && lhs.code == rhs.code
        if result {
            if lhs.hasUnderlyingError != rhs.hasUnderlyingError {
                result = false
            } else if let lhsu = lhs.underlyingError, let rhsu = rhs.underlyingError {
                result = lhsu == rhsu
            }
        }
        return result
    }
}
