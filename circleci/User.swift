//
//  User.swift
//  circleci
//
//  Created by Adrien Caranta on 2017-04-18.
//  Copyright © 2017 Impak Finance. All rights reserved.
//

import Foundation

class User {
    
    struct DatabaseFields {
        static let uidKey:String = "id"
        static let nameKey:String = "name"
        static let imeiKey:String = "imei"
        static let isRetailKey:String = "is_retail"
        static let isEntrepreneurKey:String = "is_entrepreneur"
        static let isCapitalPartnerKey:String = "is_capital_partner"
    }
    
    var uid:String
    var name:String
    var imei:String
    var isRetail:Bool
    var isEntrepreneur:Bool
    var isCapitalPartner:Bool
    
    init() {
        self.uid = ""
        self.name = ""
        self.imei = ""
        self.isRetail = false
        self.isEntrepreneur = false
        self.isCapitalPartner = false
    }
    
    convenience init(data: [String: Any]) {
        self.init()
        self.uid = data[User.DatabaseFields.uidKey] as? String ?? ""
        self.name = data[User.DatabaseFields.nameKey] as? String ?? ""
        self.imei = data[User.DatabaseFields.imeiKey] as? String ?? ""
        self.isRetail = data[User.DatabaseFields.isRetailKey] as? Bool ?? false
        self.isEntrepreneur = data[User.DatabaseFields.isEntrepreneurKey] as? Bool ?? false
        self.isCapitalPartner = data[User.DatabaseFields.isCapitalPartnerKey] as? Bool ?? false
    }
    
}
