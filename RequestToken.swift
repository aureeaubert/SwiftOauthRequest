//
//  RequestToken.swift
//
//  Created by Aurélien Aubert on 05/06/16.
//

import Foundation


class RequestToken: NSObject, NSCoding {
    
    var accessToken: String!
    var refreshToken: String?
    var dateToken: Date!
    var isUserAuth: Bool!
    
    
    init(data: NSDictionary) {
        if let accessToken = data["access_token"] as? String {
            self.accessToken = accessToken
        }
        
        if let refreshToken = data["refresh_token"] as? String {
            self.refreshToken = refreshToken
            self.isUserAuth = true
        }
        else {
            self.isUserAuth = false
        }
        
        self.dateToken = Date()

    }
    
    required init?(coder aDecoder: NSCoder) {
        if let accessToken = aDecoder.decodeObject(forKey: "accessToken") as? String {
            self.accessToken = accessToken
        }
        
        if let refreshToken = aDecoder.decodeObject(forKey: "refreshToken") as? String {
            self.refreshToken = refreshToken
            self.isUserAuth = true
        }
        else {
            self.isUserAuth = false
        }
        
        if let dateToken = aDecoder.decodeObject(forKey: "dateToken") as? Date {
            self.dateToken = dateToken
        }
    }
    
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.accessToken, forKey: "accessToken")
        aCoder.encode(self.refreshToken, forKey: "refreshToken")
        aCoder.encode(self.dateToken, forKey: "dateToken")
    }
    
}
