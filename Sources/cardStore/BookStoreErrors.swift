/**
 Copyright IBM Corporation 2017
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation


enum BookstoreError: Error {
    
    case noConnection
    case noResult
    case invalidLengthQuery(String)
    case insertionProblem
    case badRequest
    case databaseError(String)
    case balanceNotEnough
    case userHasExist
    
}

extension BookstoreError: LocalizedError {
    
    var errorDescription: String? {
        
        switch self {
            
        case .noConnection:
            return "Could not make a connection"
            
        case .noResult:
            return "Database returned no result"
            
        case .invalidLengthQuery(let query):
            return "\(query) was too short"
            
        case .insertionProblem:
            return "Could not insert the element"
            
        case .badRequest:
            return "There was a bad request"
            
        case .databaseError(let message):
            return "Database error: \(message)"
            
        case .balanceNotEnough:
            return "余额不足"
        case .userHasExist:
            return "用户已存在"
        }
        
    }
    
}
