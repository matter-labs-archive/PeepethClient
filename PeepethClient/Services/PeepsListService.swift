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

    lazy var connection: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: nil)
        return session
    }()

    func getPeeps(url: URL, callback: @escaping ([ServerPeep]?, Error?) -> Void) {
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
                callback(peeps, nil)
            } else if let error = error {
                callback(nil, error.localizedDescription as? Error)
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


}
