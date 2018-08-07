//
//  PeepsListService.swift
//  PeepethClient
//
//  Created by Антон Григорьев on 06.07.2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import Foundation

/*
 * Service to get list of peeps
 */

class PeepsService: NSObject {
    
    //    var userName: String? = nil
    //    var userPassword: String? = nil
    
    lazy var connection: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: nil)
        return session
    }()
    
    //    func formJsonPeep(peepDict: [String: Any?]) -> Data? {
    //
    //        var jsonDict: [String:Any] = [:]
    //
    //        if smsCode != nil && message == nil {
    //            jsonDict = ["sms_code":smsCode!,
    //                        "project_guid":(GlobalVars.sharedInstance()?.currentProject.projectID)!,
    //                        "docs":""]
    //        } else if message != nil && smsCode == nil {
    //            jsonDict = ["comment":message!,
    //                        "project_guid":(GlobalVars.sharedInstance()?.currentProject.projectID)!,
    //                        "docs":""]
    //
    //        } else if message != nil && smsCode != nil {
    //            jsonDict = ["sms_code":smsCode!,
    //                        "comment":message!,
    //                        "project_guid":(GlobalVars.sharedInstance()?.currentProject.projectID)!,
    //                        "docs":""]
    //
    //        } else {
    //            jsonDict = ["project_guid":(GlobalVars.sharedInstance()?.currentProject.projectID)!,
    //                        "docs":""]
    //        }
    //
    //        var docsJson: [[String:Any]] = []
    //        var docJson: [String:Any] = ["direction_guid":"",
    //                                     "guid":"",
    //                                     "type_guid":""]
    //
    //        for doc in docsForOperation {
    //
    //            docJson["direction_guid"] = doc?.direction_guid
    //            docJson["guid"] = doc?.guid
    //            docJson["type_guid"] = doc?.type_guid
    //            docsJson.append(docJson)
    //
    //        }
    //        jsonDict["docs"] = docsJson
    //
    //        print(jsonDict)
    //
    //        var json: Data? = nil
    //        do {
    //            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
    //            print(jsonData!)
    //            json = jsonData
    //        } catch let error as NSError {
    //            print("Failed to load: \(error.localizedDescription)" as NSString)
    //        }
    //
    //        return json
    //    }
    //
    //    func getAccount(urlString: String) {
    //
    //    }
    //
    //    func postPeep(urlString: String, userName: String, userPassword: String, callback: @escaping ([Any?],String?) ->Void) {
    //        self.userName = userName
    //        self.userPassword = userPassword
    //        let url = URL(string: urlString)
    //
    //        let request = NSMutableURLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60000)
    //        request.httpMethod = "POST"
    //        request.httpBody = nil
    //
    //
    //
    //    }
    
    func getPeeps(url: URL, callback: @escaping ([ServerPeep]?,Error?) -> Void) {
        var peeps = [ServerPeep]()
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60000)
        let dataTask = connection.dataTask(with: request) { data, response, error in
            if let data = data,
                let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] {
                for item in json {
                    var itemDictionary = [String: Any?]()
                    if let tx = item["ipfs"] as? String {
                        itemDictionary["ipfs"] = tx
                    }
                    if let name = item["name"] as? String {
                        itemDictionary["name"] = name
                    }
                    if let content = item["content"] as? String {
                        itemDictionary["content"] = content
                    }
                    if let realName = item["realName"] as? String {
                        itemDictionary["realName"] = realName
                    }
                    if let avatarUrl = item["avatarUrl"] as? String {
                        itemDictionary["avatarUrl"] = avatarUrl
                    }
                    if let image_url = item["image_url"] as? String {
                        itemDictionary["image_url"] = image_url
                    }
                    //if peep is shared
                    var shareDictionary = [String: Any?]()
                    if let share = item["share"] as? [String: Any?] {
                        
                        if let tx = share["ipfs"] as? String {
                            shareDictionary["ipfs"] = tx
                        }
                        if let name = share["name"] as? String {
                            shareDictionary["name"] = name
                        }
                        if let content = share["content"] as? String {
                            shareDictionary["content"] = content
                        }
                        if let realName = share["realName"] as? String {
                            shareDictionary["realName"] = realName
                        }
                        if let avatarUrl = share["avatarUrl"] as? String {
                            shareDictionary["avatarUrl"] = avatarUrl
                        }
                        if let image_url = share["image_url"] as? String {
                            shareDictionary["image_url"] = image_url
                        }
                        
                    }
                    //if peep has parent
                    var parentDictionary = [String: Any?]()
                    if let parent = item["parent"] as? [String: Any?] {
                        
                        if let tx = parent["ipfs"] as? String {
                            parentDictionary["ipfs"] = tx
                        }
                        if let name = parent["name"] as? String {
                            parentDictionary["name"] = name
                        }
                        if let content = parent["content"] as? String {
                            parentDictionary["content"] = content
                        }
                        if let realName = parent["realName"] as? String {
                            parentDictionary["realName"] = realName
                        }
                        if let avatarUrl = parent["avatarUrl"] as? String {
                            parentDictionary["avatarUrl"] = avatarUrl
                        }
                        if let image_url = parent["image_url"] as? String {
                            parentDictionary["image_url"] = image_url
                        }
                        
                    }
                    let peep = ServerPeep(info: itemDictionary, shared: false, parent: false)
                    peeps.append(peep)
                    if shareDictionary.count > 0 {
                        let sharedPeep = ServerPeep(info: shareDictionary, shared: true, parent: false)
                        peeps.append(sharedPeep)
                    }
                    if parentDictionary.count > 0 {
                        let parentPeep = ServerPeep(info: parentDictionary, shared: false, parent: true)
                        peeps.append(parentPeep)
                    }
                }
                callback(peeps,nil)
            } else if let error = error {
                callback(nil,error.localizedDescription as? Error)
            }
        }
        dataTask.resume()
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
}

extension PeepsService: URLSessionDelegate, URLSessionTaskDelegate {
    
    //    func doesHaveCredentials() -> Bool {
    //        guard let _ = self.userName else { return false }
    //        guard let _ = self.userPassword else { return false }
    //        return true
    //    }
    //
    //    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //
    //        print("Got challenge")
    //
    //        //If there are more than 5 failed authentication attempts cancel challenge
    //        guard challenge.previousFailureCount <= 5 else {
    //            print("too many failures")
    //            challenge.sender?.cancel(challenge)
    //            completionHandler(.cancelAuthenticationChallenge, nil)
    //            return
    //        }
    //
    //        //I use only ServerTrust authentication method else cancel challenge
    //        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
    //            print("Unknown authentication method \(challenge.protectionSpace.authenticationMethod)")
    //            challenge.sender?.cancel(challenge)
    //            completionHandler(.cancelAuthenticationChallenge, nil)
    //            return
    //        }
    //
    //        //Have you printed any username or password?
    //        guard self.doesHaveCredentials() else {
    //            challenge.sender?.cancel(challenge)
    //            completionHandler(.cancelAuthenticationChallenge, nil)
    //            DispatchQueue.main.async {
    //                print("Userdata not set")
    //            };
    //            return
    //        }
    //
    //        //And now I'll talk with u about authentication credentials stored only for this session
    //        let credentials = URLCredential(user: self.userName!, password: self.userPassword!, persistence: .forSession)
    //        print("LOGIN IN CREDENTIALS: \(String(describing: self.userName))")
    //        print("PASSWORD IN CREDENTIALS: \(String(describing: self.userPassword))")
    //        print("hostname: \(challenge.protectionSpace.host)")
    //        challenge.sender?.use(credentials, for: challenge)
    //        completionHandler(.useCredential, credentials)
    //
    //        print("End 1st step Challenge")
    //    }
    //
    //    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //
    //        //If there are more than 0 failed authentication attempts cancel challenge
    //        guard challenge.previousFailureCount == 0 else {
    //            print("too many failures")
    //            challenge.sender?.cancel(challenge)
    //            completionHandler(.cancelAuthenticationChallenge, nil)
    //            return
    //        }
    //
    //        let credentials = URLCredential(user: self.userName!, password: self.userPassword!, persistence: .forSession)
    //        challenge.sender?.use(credentials, for: challenge)
    //        completionHandler(.useCredential, credentials)
    //
    //        print("End 2st step Challenge")
    //    }
    
}
