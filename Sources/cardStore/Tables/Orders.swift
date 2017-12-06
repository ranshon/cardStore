//
//  Orders.swift
//  testServer
//
//  Created by xuxie on 2017/11/4.
//
//

import SwiftKuery

final class Orders : Table {
    let tableName = "orders"
    
    let order_id = Column("order_id")
    let user_id = Column("user_id")
    let orderMoney = Column("orderMoney")
    let orderTime = Column("orderTime")
}
