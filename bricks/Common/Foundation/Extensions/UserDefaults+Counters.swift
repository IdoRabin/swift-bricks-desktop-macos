//
//  UserDefaults+Counters.swift
//  Bricks
//
//  Created by Ido Rabin on 02/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation

extension UserDefaults {
    func incrementIntCounter(_ key:String) {
        if self.object(forKey: key) != nil {
            var value : Int = self.integer(forKey: key)
            value += 1
            self.set(value, forKey: key)
        } else {
            self.set(1, forKey: key)
        }
    }
}
