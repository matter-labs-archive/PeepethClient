//
//  PeepethAuthService.swift
//  PeepethClient
//

import Foundation
import web3swift
import SwiftSoup

struct NewSecretResponse: Decodable {
    var secret: String
}

struct VisitTokenRequest: Encodable {
    var landing_page: String = "https://peepeth.com/_"
    var platform: String = "Web"
    var referrer: String
    var screen_height: Int = 1050
    var screen_width: Int = 1680
    var visit_token: String
    var visitor_token: String
    
    init(visit_token : String, visitor_token: String, referrer: String) {
        self.visit_token = visit_token
        self.visitor_token = visitor_token
        self.referrer = referrer
    }
}

class PeepethAuthService {
    var session : URLSession
    
    init() {

        self.session = URLSession(configuration: URLSessionConfiguration.ephemeral)
//        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        self.session.configuration.httpCookieAcceptPolicy = .always
        let web3Instance = Web3swiftService.web3instance
        guard let address = Web3swiftService.currentAddress else {return}
        var url = URL(string: "https://peepeth.com/_")!
        var request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data? = nil
        var response: URLResponse? = nil
        var task: URLSessionDataTask? = nil
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
        
        // get CSRF
        guard let bodyString = String.init(data: responseData!, encoding: .utf8) else {return}
        var csrf = ""
        do {
            let doc: Document = try SwiftSoup.parse(bodyString)
            let elements = try doc.select("[name=csrf-token]")
            guard let tag = elements.last() else {return}
            guard let attrs = tag.getAttributes() else {return}
            csrf = attrs.get(key: "content")
        } catch Exception.Error(let type, let message) {
            print("")
        } catch {
            print("")
        }
        print("CSRF = " + csrf)
        
        // visits
        let visitorToken = self.session.configuration.httpCookieStorage?.cookies?.filter({ (c) -> Bool in
            return c.name == "ahoy_visitor"
        }).first?.value
        
        let visitToken = self.session.configuration.httpCookieStorage?.cookies?.filter({ (c) -> Bool in
            return c.name == "ahoy_visit"
        }).first?.value
        
        let referer = self.session.configuration.httpCookieStorage?.cookies?.filter({ (c) -> Bool in
            return c.name == "referer"
        }).first?.value
        
        let visitRequest = VisitTokenRequest.init(visit_token: visitToken!, visitor_token: visitorToken!, referrer: referer!)
        url = URL(string: "https://peepeth.com/ahoy/visits")!
        request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRF-Token")
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(visitRequest)
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
        
        // get account
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "peepeth.com"
        components.path = "/get_account"
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem.init(name: "you", value: "true"))
        queryItems.append(URLQueryItem.init(name: "include_following", value: "true"))
        queryItems.append(URLQueryItem.init(name: "address", value: address.address.lowercased()))
        components.queryItems = queryItems
        request = URLRequest.init(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRF-Token")
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
        let accountData = try? JSONSerialization.jsonObject(with: responseData!, options: []) as? [String: Any]
        print(accountData)
        
        // set is user
        
        url = URL(string: "https://peepeth.com/set_is_user")!
        request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRF-Token")
        request.httpMethod = "PUT"
//        print(session.configuration.httpCookieStorage?.cookies)
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
        
        url = URL(string: "https://peepeth.com/get_new_secret")!
        request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRF-Token")
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
//        print(session.configuration.httpCookieStorage?.cookies)
        guard let newSecret = try? JSONDecoder().decode(NewSecretResponse.self, from: responseData!) else {
            print("Error")
            return
        }
        
        let secret = newSecret.secret.replacingOccurrences(of: "Log in to Peepeth.com by signing this secret code: ", with: "")
        print(secret)

        guard let messageData = secret.data(using: .utf8) else {return}
        guard let messageHash = Web3.Utils.hashPersonalMessage(messageData) else {return}
        print("0x" + messageHash.toHexString())
        // TODO: - Another way to retrieve password
        guard case .success(let signature) = web3Instance.personal.signPersonalMessage(message: messageData, from: address, password: "MYPASSWORD") else {return}
        let hexSignature = "0x" + signature.toHexString()
        print(hexSignature)
        components = URLComponents()
        components.scheme = "https"
        components.host = "peepeth.com"
        components.path = "/verify_signed_secret.js"
        let reencodedSecret = secret.replacingOccurrences(of: " ", with: "+")
//            .replacingOccurrences(of: ":", with: "%3A")
        print(reencodedSecret)
        queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem.init(name: "signed_token", value: hexSignature))
        queryItems.append(URLQueryItem.init(name: "original_token", value: reencodedSecret))
        queryItems.append(URLQueryItem.init(name: "address", value: address.address.lowercased()))
        queryItems.append(URLQueryItem.init(name: "provider", value: "metamask"))
        components.queryItems = queryItems
        request = URLRequest.init(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpShouldHandleCookies = true
        request.setValue("https://peepeth.com/_", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36", forHTTPHeaderField: "User-agent")
        request.setValue("peepeth.com", forHTTPHeaderField: "Host")
        request.setValue("https://peepeth.com", forHTTPHeaderField: "Origin")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(csrf, forHTTPHeaderField: "X-CSRF-Token")
        DispatchQueue.global().async {
            task = self.session.dataTask(with: request) { (data, resp, error) in
                if error != nil {
                    print(error)
                    semaphore.signal()
                    return
                }
                let responseStatusCode = (resp! as! HTTPURLResponse).statusCode
                print(responseStatusCode)
                responseData = data
                response = resp
                semaphore.signal()
            }
            task!.resume()
        }
        semaphore.wait()
        do {
            let b = String(data: responseData!, encoding: .utf8)!
            let doc: Document = try SwiftSoup.parse(b)
            let text = try doc.text()
            print(text)
        } catch Exception.Error(let type, let message) {
            print("")
        } catch {
            print("")
        }
        let cookies = self.session.configuration.httpCookieStorage?.cookies
        print(cookies)
        
    }
}
