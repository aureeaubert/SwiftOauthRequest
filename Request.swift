//
//  Request.swift
//
//  Created by Aurélien Aubert on 26/06/16.
//

import Foundation


enum RequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}


enum RequestAuth {
    case anonymous, user, none
}

class Request {
    
    let clientID: String = "CLIENT_ID"
    let clientSecret: String = "CLIENT_SECRET"
    
    var url: String = "https://helloworld.com"
    var authExt: String = "oauth/auth"
    var tokenExt: String = "oauth/token"
    
    var token: RequestToken?
    
    init() {
        if let token = self.getToken() {
            self.token = token
        }
    }
    
    
    
    //METHODS
    func GET(url: String, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        self.NEW(url: self.url+url, method: .GET, params: params, callback: callback)
    }
    
    func POST(url: String, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        self.NEW(url: self.url+url, method: .POST, params: params, callback: callback)
    }
    
    func PUT(url: String, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        self.NEW(url: self.url+url, method: .PUT, params: params, callback: callback)
    }
    
    func DELETE(url: String, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        self.NEW(url: self.url+url, method: .DELETE, params: params, callback: callback)
    }
    
    
    
    //NEW REQUEST
    func NEW(url: String, method: RequestMethod, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        if self.isValidToken() {
            self.request(url: url, method: method, params: params, callback: callback)
        }
        else {
            self.requestToken(callback: {
                error in
                if error == false {
                    self.NEW(url: url, method: method, params: params, callback: callback)
                }
            })
        }
    }
    
    
    func request(url: String, method: RequestMethod, params: NSDictionary, callback: ((response: NSDictionary) -> Void)) {
        let urlString = "\(url)?\(self.httpParams(params: params))"
        print(urlString)
        let urlRequest = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        urlRequest.httpMethod = method.rawValue

        urlRequest.addValue("application/www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared().dataTask(with: urlRequest as URLRequest) {
            (data, response, error) in
            if error == nil {
                var jsonResult: NSDictionary?
                
                do {
                    jsonResult = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                }
                catch { return }
                
                if jsonResult != nil {
                    callback(response: jsonResult!)
                }
            }
            
        }

        
        task.resume()
    }
    
    
    func httpParams(params: NSDictionary) -> String {
        var httpParams = ""
        for (key, value) in params {
            
            httpParams += "\(key)=\(value)&"
            
        }
        
        if self.token != nil {
            httpParams += "access_token=\(self.token!.accessToken!)"
        }
        
        return httpParams
    }
    
    
    //AUTH
    func anonymousAuth(callback: ((error: Bool) -> Void)) {
        let url = self.url + self.tokenExt
        let params: NSDictionary = ["client_id": self.clientID, "client_secret": self.clientSecret, "grant_type": "client_credentials"]
        
        self.request(url: url, method: .POST, params: params, callback: {
            response in
            callback(error: !(self.updateToken(response: response)))
        })
    }
    
    func userAuth(username: String, password: String, callback: ((error: Bool) -> Void)) {
        let url = self.url + self.tokenExt
        let params: NSDictionary = ["client_id": self.clientID, "client_secret": self.clientSecret, "grant_type": "password", "username": username, "password": password]

        self.request(
            url: url, method: .POST, params: params, callback: {
            response in
            callback(error: !(self.updateToken(response: response)))
        })
    }

    func userAuth(callback: ((error: Bool) -> Void)) {
        if self.token?.isUserAuth == true {
            
            let url = self.url + self.tokenExt
            let params: NSDictionary = ["client_id": self.clientID, "client_secret": self.clientSecret, "grant_type": "refresh_token", "refresh_token": (self.token?.refreshToken)!]

            self.request(url: url, method: .POST, params: params, callback: {
                response in
                callback(error: !(self.updateToken(response: response)))
            })
        }
    }
    
    
    func authType() -> RequestAuth {
        if(self.token != nil) {
            return (self.token?.isUserAuth == true) ? .user : .anonymous
        }

        return .none
    }
    
    
    
    //TOKEN
    func isValidToken() -> Bool {
        if self.token != nil && Date().timeIntervalSince1970 < (self.token!.dateToken.timeIntervalSince1970 + 3600) {
            return true
        }
        else {
            return false
        }
    }
    
    func requestToken(callback: ((error: Bool) -> Void)) {
        if self.token?.isUserAuth == true {
            self.userAuth(callback: callback)
        }
        else {
            self.anonymousAuth(callback: callback)
        }
    }
    
    func updateToken(response: NSDictionary) -> Bool {
        if response["access_token"] != nil {
            self.token = RequestToken(data: response)
            self.saveToken(token: self.token!)
            return true
        }
        else {
            return false
        }
    }
    
    func saveToken(token: RequestToken) {
        KeychainWrapper.setObject(value: token, forKey: "token")
    }
    
    func getToken() -> RequestToken? {
        if let token = KeychainWrapper.objectForKey(keyName: "token") as? RequestToken {
            return token
        }
        else {
            return nil
        }
    }
    
    
    
}
