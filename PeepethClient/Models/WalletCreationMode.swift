//
//  WalletCreationMode.swift
//  PeepethClient
//
//  Created by Anton Grigorev on 10/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import Foundation

enum WalletCreationMode {
    
    case importKey
    case createKey
    
    func title() -> String {
        switch self {
        case .importKey:
            return "Import Wallet"
        case .createKey:
            return "Create Wallet"
        }
    }
}
