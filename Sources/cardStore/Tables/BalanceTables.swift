//
//  BalanceTables.swift
//  helloWorld
//
//  Created by xuxie on 2017/11/15.
//
//

import SwiftKuery

final class BalanceTables : Table{
    let tableName = "balanceTable"
    
    let balance_id = Column("balance_id")
    let balance = Column("balance")
    let user_id = Column("user_id")
}
