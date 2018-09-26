//
//  ServerPeepModel.swift
//  PeepethClient
//
//  Created by Антон Григорьев on 06.07.2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import Foundation


/*
 * Model of Peeps tweets we got from server
 */
struct ServerPeep {
    var info: [String: Any?] = ["tx": nil,
                                "ipfs": nil,
                                "author": nil,
                                "content": nil,
                                "timestamp": nil,
                                "confirmed_timestamp": nil,
                                "block": nil,
                                "instant": nil,
                                "shareID": nil,
                                "parentID": nil,
                                "sharesCount": nil,
                                "repliesCount": nil,
                                "tipAmount": nil,
                                "ownerTip": nil,
                                "tipsWei": nil,
                                "lovedByLength": nil,
                                "status": nil,
                                "name": nil,
                                "realName": nil,
                                "avatarUrl": nil,
                                "backgroundUrl": nil,
                                "twitterHandle": nil,
                                "peepstreak": nil,
                                "confirmed": nil,
                                "malaria_nets": nil,
                                "image_url": nil,
                                "nsfw": nil,
                                "share": nil,
                                "parent": nil]
    var shared: Bool = false
    var parent: Bool = false

    init(info: [String: Any?], shared: Bool, parent: Bool) {
        self.info = info
        self.shared = shared
        self.parent = parent
    }
}

///*
// * Model of Peeps tweets we post to server
// */
//struct PostServerPeep {
//
//    var info: [String: Any?] = ["ipfs": nil,
//                                "author": nil,
//                                "content" : nil,
//                                "parentID": nil,
//                                "shareID":nil,
//                                "parentID":nil,
//                                "twitter_share":nil,
//                                "picIpfs":nil,
//                                "origContents":nil,
//                                "share_now":nil]
//
//    init(info: [String: Any?], shared: Bool, parent: Bool) {
//        self.info = info
//    }
//}

/*
 Extension to make class equatable by "ipfs" field in ipfs
 */
extension ServerPeep: Equatable {
    static func ==(lhs: ServerPeep, rhs: ServerPeep) -> Bool {
        return (lhs.info["ipfs"] as! String) == (rhs.info["ipfs"] as! String)

    }

}


//peep[ipfs]: xxx
//peep[author]: 0x832a630b949575b87c0e3c00f624f773d9b160f4
//peep[content]: empty_peep
//peep[parentID]:
//peep[shareID]:
//peep[twitter_share]: false
//peep[picIpfs]:
//peep[origContents]: {"type":"peep","content":"empty_peep","pic":"","untrustedAddress":"0x832a630b949575b87c0e3c00f624f773d9b160f4","untrustedTimestamp":1533728914,"shareID":"","parentID":""}
//share_now: true
struct CreateServerPeep: Encodable {
    let ipfs: String
    let author: String
    let content: String
    let parentID: String
    let shareID: String
    let twitterShare: Bool
    let picIpfs: String
    let origContents: Peep
    let shareNow: Bool

    enum CodingKeys: String, CodingKey {
        case ipfs = "peep[ipfs]"
        case author = "peep[author]"
        case content = "peep[content]"
        case parentID = "peep[parentID]"
        case shareID = "peep[shareID]"
        case twitterShare = "peep[twitter_share]"
        case picIpfs = "peep[picIpfs]"
        case origContents = "peep[origContents]"
        case shareNow = "share_now"
    }
}

