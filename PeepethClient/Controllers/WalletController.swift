//
//  WalletController.swift
//  PeepethClient
//
//  Created by Anton Grigorev on 10/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import Foundation
import web3swift

class WalletController {

    let localStorage = LocalDatabase()
    let keysService: KeysService = KeysService()
    let web3service: Web3swiftService = Web3swiftService()

    func createWallet(with mode: WalletCreationMode,
                      password: String?,
                      key: String?,
                      completion: @escaping (Error?) -> Void) {
        guard let password = password else {
            completion(Errors.noPassword)
            return
        }
        switch mode {
        case .createKey:
            keysService.createNewWallet(password: password) { (wallet, error) in
                if let error = error {
                    completion(error)
                } else {
                    //Segue to registration controller(in Peepeth), because if you've just created the wallet, it'll be 100% not registered in Peepeth.
                    self.localStorage.saveWallet(isRegistered: false, wallet: wallet!) { (error) in
                        completion(error)
                    }
                }
            }
        case .importKey:
            guard let key = key else {
                completion(Errors.noKey)
                return
            }
            keysService.addNewWalletWithPrivateKey(key: key, password: password) { (wallet, error) in
                if let error = error {
                    completion(error)
                } else {
                    guard let walletStrAddress = wallet?.address, let walletAddress = EthereumAddress(walletStrAddress) else {
                        completion(error)
                        return
                    }
                    //Check if account registered to save if it is registered or not into core data
                    self.web3service.isAccountRegistered(address: walletAddress, completion: { (result) in
                        switch result {
                        case .Success(let isRegistered):
                            self.localStorage.saveWallet(isRegistered: isRegistered, wallet: wallet!) { (error) in
                                completion(error)
                            }
                        case .Error(let error):
                            completion(error)
                        }

                    })
                }
            }
        }
    }
}
