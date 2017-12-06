//
//  User.swift
//  helloWorld
//
//  Created by xuxie on 2017/11/10.
//
//

struct User {
    let id : Int
    let name : String
    let idNo : String?
    let telNo : String
    let balance : Int?
}

extension User : FieldMappable {
    init?(fields: [String : Any]) {
        if let fieldID = fields["user_id"] as? Int32 {
            id = Int(fieldID)
        }else {
            return nil
        }
        
        name = fields["name"] as! String
        
        idNo = fields["idNo"] as? String
        
        if let fieldtelNo = fields["telno"] {
            telNo = fieldtelNo as! String
        }else {
            return nil
        }
        
        if let fieldBalance = fields["balance"] as? Int32 {
            balance = Int(fieldBalance)
        }else {
            balance = nil;
        }
    }
    
    
}

extension User : DictionaryConvertible {
    var dictionary: [String: Any] {
        var basicItems = [String:Any]()
        
        basicItems["id"]     = id
        basicItems["name"]  = name
        basicItems["idNo"] = idNo
        basicItems["telNo"]   = telNo
        
        if let balance = balance {
            basicItems["balance"] = balance
        }
        return basicItems
    }
}

