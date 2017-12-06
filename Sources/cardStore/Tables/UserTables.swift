//
//  UserTables.swift
//  testServer
//
//  Created by xuxie on 2017/11/6.
//
//

import SwiftKuery
final class UserTables : Table {
    
    let tableName = "users"
    
    let userID =    Column("user_id")
    let userName =     Column("name")
    let idNo =    Column("idNo")
    let telNo =      Column("telNo")
    let balance = Column("balance")
}
