//
//  IPFSService.swift
//  PeepethClient
//

import Foundation

class IPFSService {
    
    private lazy var connection: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        return session
    }()
    
    //TODO: - Put url here
    private let url = URL(string: "http://178.62.253.112/add_data")!
    
    func postToIPFS<T: Encodable>(data: T, completion: @escaping(Result<String>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(data)
        } catch {
            completion(Result.Error(error))
        }
        
        let dataTask = connection.dataTask(with: request) { (data1, response, error) in
            if error != nil {
                completion(Result.Error(error!))
                return
            }
            if let data1 = data1 {
                do {
                    guard let jsonData = try JSONSerialization.jsonObject(with: data1, options: []) as? [String: String] else { return }
                    guard let hash = jsonData["Hash"] else { return }
                    completion(Result.Success(hash))
                } catch {
                    completion(Result.Error(error))
                }
            }
        }
        
        dataTask.resume()
    }
}


//{"info":"","location":"","realName":"Anton Grigoriev","website":"","avatarUrl":"","backgroundUrl":"","messageToWorld":"","untrustedTimestamp":1530695427}
struct User: Encodable {
    let info: String
    let location: String
    let realName: String
    let website: String
    let avatarUrl: String
    let backgroundUrl: String
    let messageToWorld: String
    let untrustedTimestamp: Int
}


//{"type":"peep","content":"Let's start! #web3swift #bankexfoundation","pic":"","untrustedAddress":"0x832a630b949575b87c0e3c00f624f773d9b160f4","untrustedTimestamp":1530699084,"shareID":"","parentID":""}
struct Peep: Encodable {
    let type: String
    let content: String
    let pic: String
    let untrustedAddress: String
    let untrustedTimestamp: Int
    let shareID: String
    let parentID: String
}
