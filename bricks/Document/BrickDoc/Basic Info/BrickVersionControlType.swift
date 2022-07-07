//
//  BrickVersionControlType.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Foundation

enum BrickVersionControlType : Int, Codable {
    case none = 0
    case git = 1
    case svn = 2
    case mercurial = 3
}

//extension BrickVersionControlType /* VCS protocol factory */ {
//
//    func factoryCreateVCS(path:URL?)->VCS? {
//        if let path = path {
//            switch self {
//            case .git:
//                return VCSGit(path: path)
//            default:
//                assert(false, "VCS factory not implemented for BrickVersionControlType \(self)")
//            }
//        }
//        return nil
//    }
//}
