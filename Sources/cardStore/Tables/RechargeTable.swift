//
//  RechargeTable.swift
//  testServer
//
//  Created by xuxie on 2017/11/4.
//
//

import SwiftKuery

final class RechargeTable : Table {
    let tableName = "rechargeTable"
    
    let recharge_id = Column("recharge_id")
    let userID = Column("user_id")
    let money = Column("money")
    let rechargetime = Column("rechargetime")
}
