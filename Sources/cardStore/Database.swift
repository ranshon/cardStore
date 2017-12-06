//
//  Database.swift
//  testServer
//
//  Created by xuxie on 2017/11/6.
//
//

import Dispatch

import SwiftKuery
import SwiftKueryPostgreSQL

public class Database {
    let queue = DispatchQueue(label:"com.cardstore.database",attributes: .concurrent)
    
    static let usersTable = UserTables()
    static let rechargeTable = RechargeTable()
    static let orderTable = Orders()
    static let balanceTable = BalanceTables()
    
    private func createConnection() -> Connection {
        return PostgreSQLConnection(host: Config.sharedInstance.databaseHost, port: Config.sharedInstance.databasePort,
                                    options: [.userName(Config.sharedInstance.userName),
                                              .password(Config.sharedInstance.password),
                                              .databaseName(Config.sharedInstance.databaseName)])
    }
    
    
    //查询
    func queryUser(with selectin: Select,completion: @escaping (Error?,[User]?) -> ()) {
        
        let connection = createConnection()
        
        connection.connect { conResult in
            
            if conResult != nil {
                completion(conResult,nil)
            }
            
        }
        
        if !connection.isConnected {
            return
        }
        
        selectin.execute(connection) { queryResult in
            if queryResult.success {
                guard let resultSet = queryResult.asResultSet else {
                    
                    completion(BookstoreError.noResult, nil)
                    
                    return
                }
                
                let fields = resultToRows(resultSet: resultSet)
                
                completion(nil,fields.flatMap( User.init(fields:) ))
                
            }
        }
        
        
        
        
        
    }
    
    //新增
    func addUserSync(userName name: String, idNo:String, telNo: String, rechargeMoney money :Int = 0,completion: @escaping (BookstoreError?,User?) -> ()) {
        
        let connection = createConnection()
        
        let insertUser = Insert(into: Database.usersTable,columns: [Database.usersTable.userName,Database.usersTable.idNo,Database.usersTable.telNo],values: [name,idNo,telNo])
        
        var insertUserSql: String = ""
        
        do {
            
            insertUserSql = try connection.descriptionOf(query: insertUser).appending("returning user_id")
            
        } catch  {
            completion(BookstoreError.databaseError("SQL 转换失败"),nil)
            return
        }
        
        connection.connect { conResult in
            if conResult != nil {
                completion(BookstoreError.noConnection,nil)
                connection.closeConnection()
            }
        }
        
        if !connection.isConnected {
            return
        }
        
        
        if connection.isConnected {
            connection.startTransaction(onCompletion: { tranResult in
                if !tranResult.success {
                    completion(BookstoreError.databaseError("事务开启失败"),nil)
                    connection.closeConnection()
                }
            })
        }
        
        //充值
        var insertRecharge :Insert? = nil
        
        //
        var user: User? = nil
        
        //余额
        var insertBalance :Insert? = nil
        
        
        
        if connection.isConnected {
            connection.execute(insertUserSql, onCompletion: { insertResult in
                if insertResult.success {
                    if let resultSet = insertResult.asResultSet {
                        for row in resultSet.rows {
                            
                            user = User.init(id: Int(row[0]! as! Int32), name: name, idNo: idNo, telNo: telNo, balance: money)
                            
                            insertRecharge = Insert(into: Database.rechargeTable,columns: [Database.rechargeTable.userID,Database.rechargeTable.money],values: [row[0]!,money])
                            
                            insertBalance = Insert.init(into: Database.balanceTable, valueTuples: (Database.balanceTable.user_id, row[0]!),(Database.balanceTable.balance,money))
                            
                        }
                    }
                }else {
                    
                    if  insertResult.asError.debugDescription.contains("duplicate key value violates unique constraint") {
                        
                        completion(BookstoreError.userHasExist,nil)
                        
                    }else {
                        completion(BookstoreError.databaseError((insertResult.asError?.localizedDescription)!),nil)
                    }
                    

                    connection.closeConnection()
                }
            })
        }
        
        if connection.isConnected {
            
            if let insertRecharge = insertRecharge {
                
                insertRecharge.execute(connection, onCompletion: { rechargeResult in
                    if !rechargeResult.success {
                        
                        completion(BookstoreError.databaseError(rechargeResult.asError!.localizedDescription),nil)
                        connection.closeConnection()
                        
                    }
                })
                
            }
        }
        
        if connection.isConnected {
            
            if let insertBalance = insertBalance {
                insertBalance.execute(connection, onCompletion: { balanceResult in
                    if !balanceResult.success {
                        connection.closeConnection()
                        completion(BookstoreError.databaseError((balanceResult.asError?.localizedDescription)!),nil)
                    }
                })
            }
            
        }
        
        if connection.isConnected {
            
            connection.commit(onCompletion: { commitResult in
                if !commitResult.success {
                    connection.closeConnection()
                    completion(BookstoreError.databaseError(commitResult.asError!.localizedDescription),nil)
                }else {
                    completion(nil,user)
                }
            })
        }
        
        connection.closeConnection()
        
    }
    
    //充值
    func rechargeUpdate(userId: Int , rechargeMoney money: Int) {
        
        let connection = createConnection()
        
        connection.connect(onCompletion: { conResult in
            
            if conResult != nil {
                
            }
            
        })
        
        if connection.isConnected {
            connection.startTransaction { transactionResult in
                if !transactionResult.success {
                    connection.closeConnection()
                }
            }
        }
        
        if connection.isConnected {
            
            let updateRecharge = Update.init(Database.rechargeTable, set: [(Database.rechargeTable.money, money)], where: Database.rechargeTable.userID == userId)
            
            updateRecharge.execute(connection, onCompletion: { rechargeResult in
                
                if !rechargeResult.success {
                    connection.closeConnection()
                }
                
            })
            
        }
        
        if connection.isConnected {
            
            connection.execute("insert into balanceTable (user_id,balance) values (\(userId),\(money)) on conflict(user_id) do update set balance = balanceTable.balance + \(money) where balanceTable.user_id = \(userId)", onCompletion: { balanceResult in
                if !balanceResult.success {
                    connection.closeConnection()
                }
            })
        }
        
        if connection.isConnected {
            connection.commit(onCompletion: { commitResult in
                if commitResult.success {
                    
                }
            })
        }
        
        connection.closeConnection()
        
    }
    
    
    //消费
    func createBill(userId: Int, spendMoney: Int, onCompletion: @escaping (BookstoreError?) -> ())  {
        
        let connection = createConnection()
        
        let balanceQuery = Select.init(fields: [Database.balanceTable.balance_id], from: [Database.balanceTable]).where(Database.balanceTable.user_id == userId && (Database.balanceTable.balance > spendMoney || Database.balanceTable.balance == spendMoney))
        
        connection.connect { conResult in
            if conResult != nil {
                onCompletion(BookstoreError.noConnection)
            }
        }
        
        if connection.isConnected {
            
            balanceQuery.execute(connection, onCompletion: { balanceResult in
                if !balanceResult.success {
                    onCompletion(BookstoreError.databaseError("余额查询失败"))
                }else {
                    
                    if balanceResult.asResultSet == nil {
                        onCompletion(BookstoreError.databaseError("未查询到用户余额记录"))
                    }
                }
            })
            
        }
        
        if connection.isConnected {
            
            connection.startTransaction(onCompletion: { startResult in
                if !startResult.success {
                    onCompletion(BookstoreError.databaseError("事务开启失败"))
                }
            })
            
        }
        
        if connection.isConnected {
            
            let insert = Insert.init(into: Database.orderTable, valueTuples: (Database.orderTable.user_id, userId),(Database.orderTable.orderMoney,spendMoney))
            
            insert.execute(connection, onCompletion: { insertResult in
                if !insertResult.success {
                    onCompletion(BookstoreError.databaseError("数据插入失败"))
                }
            })
            
        }
        
        if connection.isConnected {
            
            connection.execute("update balanceTable set balance = balance - \(spendMoney) where user_id = \(userId)", onCompletion: { updateResult in
                if !updateResult.success {
                    onCompletion(BookstoreError.databaseError("数据更新失败"))
                }
            })
            
        }
        
        if  connection.isConnected {
            connection.commit(onCompletion: { commitResult in
                
                if !commitResult.success {
                    onCompletion(BookstoreError.databaseError("数据更新失败"))
                }
                
            })
        }
        
        connection.closeConnection()
        
        
        
        
        
    }
    
    
    
    static func allUser(page:Int , row:Int) -> Select {
        
        return Select.init( Database.usersTable.userID,Database.usersTable.userName,Database.usersTable.telNo,Database.balanceTable.balance, from: [Database.usersTable,Database.balanceTable]).where(Database.usersTable.userID == Database.balanceTable.user_id).limit(to: row).offset(page*row)
    }
    
    static func userByTel(userTel: String) -> Select {
        
        return Select.init( Database.usersTable.userID,Database.usersTable.userName,Database.usersTable.telNo,Database.balanceTable.balance, from: [Database.usersTable,Database.balanceTable]).where(Database.usersTable.telNo == userTel && Database.usersTable.userID == Database.balanceTable.user_id )
        
    }
    
    static func userByUserId(userId: Int) -> Select {
        return Select.init( Database.usersTable.userID,Database.usersTable.userName,Database.usersTable.telNo,Database.balanceTable.balance, from: [Database.usersTable,Database.balanceTable]).where(Database.usersTable.userID == userId && Database.balanceTable.user_id == userId)
    }
    
    
    
    //新增
    func addUser(userName name: String, idNo:String, telNo: String, rechargeMoney money :Int = 0,completion: @escaping (Error?) -> ()) {
        
        let connection = createConnection()
        
        let insertUser = Insert(into: Database.usersTable,columns: [Database.usersTable.userName,Database.usersTable.idNo,Database.usersTable.telNo],values: [name,idNo,telNo])
        do {
            let insertUserSql = try connection.descriptionOf(query: insertUser).appending("returning user_id")
            
            connection.connect { conError in
                
                if let conError = conError {
                    completion(conError)
                    connection.closeConnection()
                }
                connection.startTransaction(onCompletion: { startTranResult in
                    if startTranResult.success {
                        
                        connection.execute(insertUserSql, onCompletion: { insertResult in
                            if insertResult.success {
                                
                                if let resultSet = insertResult.asResultSet {
                                    for row in resultSet.rows {
                                        
                                        let insertRecharge = Insert(into: Database.rechargeTable,columns: [Database.rechargeTable.userID,Database.rechargeTable.money],values: [row[0]!,money])
                                        
                                        insertRecharge.execute(connection, onCompletion: { rechargeResult in
                                            
                                            if rechargeResult.success {
                                                connection.commit(onCompletion: { commitResult in
                                                    if commitResult.success {
                                                        connection.closeConnection()
                                                    }else {
                                                        connection.closeConnection()
                                                        completion(commitResult.asError!)
                                                    }
                                                })
                                            }else {
                                                connection.rollback(onCompletion: { rollBack in
                                                    connection.closeConnection()
                                                })
                                                connection.closeConnection()
                                            }
                                        })
                                    }
                                }
                            }else {
                                connection.closeConnection()
                                completion(insertResult.asError!)
                            }
                        })
                        
                        
                    }else {
                        connection.closeConnection()
                        completion(startTranResult.asError!)
                    }
                })
            }
            
        } catch  {
            connection.closeConnection()
            completion(error)
        }
    }
    
    
}









