//
//  Requests.swift
//  PeepethClient
//
//  Created by Anton Grigorev on 10/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import Foundation

func requestForPostingToServer(data: CreateServerPeep, ipfs: String) -> URLRequest? {
    let url = URL(string: "https://peepeth.com/create_peep")!
    var request = URLRequest(url: url)
    request.httpShouldHandleCookies = true
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = "peep%5Bipfs%5D=\(ipfs)&peep%5Bauthor%5D=\(data.author.lowercased())&peep%5Bcontent%5D=\(data.content)&peep%5BparentID%5D=\(data.parentID)&peep%5BshareID%5D=\(data.shareID)&peep%5Btwitter_share%5D=\(data.twitterShare)&peep%5BpicIpfs%5D=\(data.picIpfs)&peep%5BorigContents%5D=%7B%22type%22%3A%22\(data.origContents.type)%22%2C%22content%22%3A%22\(data.origContents.content)%22%2C%22pic%22%3A%22\(data.origContents.pic)%22%2C%22untrustedAddress%22%3A%22\(data.origContents.untrustedAddress.lowercased())%22%2C%22untrustedTimestamp%22%3A\(data.origContents.untrustedTimestamp)%2C%22shareID%22%3A%22\(data.origContents.shareID)%22%2C%22parentID%22%3A%22\(data.origContents.parentID)%22%7D&share_now=true".data(using:String.Encoding.utf8, allowLossyConversion: false)
    return request
}
