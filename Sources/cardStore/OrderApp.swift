//
//  OrderApp.swift
//  helloWorld
//
//  Created by xuxie on 2017/11/16.
//
//

import Kitura
import Foundation

import HeliumLogger
import SwiftyJSON
import SwiftKuery

import Dispatch


public class OrderApp {
    
    let database = Database()
    
    let router = Router()
    
    let queue = DispatchQueue(label: "com.cardstore.web", attributes: .concurrent)
    
    public init() {
        
        HeliumLogger.use()

        router.all("/v1", middleware: BodyParser())
        
        router.get("/v1/allUsers") { request, response, _ in
            
            self.queue.async(execute: {
                let page = request.queryParameters["page"]
                
                let size = request.queryParameters["size"]
                
                guard let _ = page, let _ = size else{
                    response.status(.badRequest)
                    response.send("参数错误")
                    return
                }
                
                self.database.queryUser(with: Database.allUser(page: Int(page!) ?? 0, row: Int(size!) ?? 0), completion: { (error, result) in
                    response.status(.OK)
                    if error != nil {
                        response.send((error!.localizedDescription))
                    }else {
                        response.send(json: result?.dictionary)
                    }
                    
                })
            })
        }
        
        //
        router.post("/v1/addUser") { (request, response, _) in
            self.queue.async {
                guard let parsedBody = request.body else {
                    response.status(.badRequest)
                    response.send("参数错误")
                    return
                }

                switch parsedBody {
                case .json(let jsonBody):
                    
                    guard let name = jsonBody["name"] else {
                        response.status(.badRequest)
                        response.send("姓名不能为空")
                        return
                    }

                    guard let telNo = jsonBody["telNo"] else {
                        response.status(.badRequest)
                        response.send("手机号不能为空")
                        return
                    }

                    let idNo = jsonBody["idNo"] ?? ""
                    let money = jsonBody["money"] ?? ""

                    self.database.addUserSync(userName: name as! String, idNo: idNo as! String, telNo: telNo as! String, rechargeMoney: money as! Int, completion: { error,user in
                        if error != nil {
                            response.send(error!.localizedDescription)
                        }else {
                           // response.send(json: JSON.init(user!.dictionary))
                            response.send(json: ["Body" : user!.dictionary])
                        }
                    })

                default:
                    break
                }
            }
        }

    }
    
    
    
    public func run() {
        
        let envVars = ProcessInfo.processInfo.environment
        let portString: String = envVars["PORT"] ?? envVars["CF_INSTANCE_PORT"] ??  envVars["VCAP_APP_PORT"] ?? "9003"
        let port = Int(portString) ?? 9003
        
        Kitura.addHTTPServer(onPort: port, with: router)
        Kitura.run()
    }
    
}



