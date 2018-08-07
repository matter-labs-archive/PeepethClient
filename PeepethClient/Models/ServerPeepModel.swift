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
                                "content" : nil,
                                "timestamp": nil,
                                "confirmed_timestamp": nil,
                                "block": nil,
                                "instant": nil,
                                "shareID":nil,
                                "parentID":nil,
                                "sharesCount":nil,
                                "repliesCount":nil,
                                "tipAmount":nil,
                                "ownerTip":nil,
                                "tipsWei":nil,
                                "lovedByLength":nil,
                                "status":nil,
                                "name":nil,
                                "realName":nil,
                                "avatarUrl":nil,
                                "backgroundUrl":nil,
                                "twitterHandle":nil,
                                "peepstreak":nil,
                                "confirmed":nil,
                                "malaria_nets":nil,
                                "image_url":nil,
                                "nsfw":nil,
                                "share":nil,
                                "parent":nil]
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

