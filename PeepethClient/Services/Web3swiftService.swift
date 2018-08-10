//
//  Web3swiftService.swift
//  PeepethClient
//

import Foundation
import web3swift
import BigInt

class Web3swiftService {
    static let keyservice = KeysService()
    
    static var web3instance: web3 {
        let web3 = Web3.InfuraMainnetWeb3()
        web3.addKeystoreManager(self.keyservice.keystoreManager())
        return web3
    }
    
    static var currentAddress: EthereumAddress? {
        let wallet = self.keyservice.selectedWallet()
        guard let address = wallet?.address else { return nil }
        let ethAddressFrom = EthereumAddress(address)
        return ethAddressFrom
    }
    
    static var peepethContract: web3.web3contract? {
        guard let contract = Web3swiftService.web3instance.contract(peepEthABI, at: ethContractAddress, abiVersion: 2) else { return nil }
        return contract
    }
    //MARK: - Account creation
    func prepareCreateAccountTransaction(username: String, userDataHash: String, gasLimit: BigUInt = 27500, completion: @escaping (Result<TransactionIntermediate>) -> Void) {
        //preparing
        
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.selectedWallet()
            guard let address = wallet?.address else { return }
            let ethAddressFrom = EthereumAddress(address)
            
            let web3 = Web3.InfuraMainnetWeb3()
            web3.addKeystoreManager(Web3swiftService.keyservice.keystoreManager())
            guard let contract = web3.contract(peepEthABI, at: ethContractAddress, abiVersion: 2) else { return }
            
            var options = Web3Options.defaultOptions()
            options.from = ethAddressFrom
            options.value = 0

            options.gasLimit = gasLimit
            
            guard let gasPrice = web3.eth.getGasPrice().value else { return }
            options.gasPrice = gasPrice
            print(gasPrice)
            
            guard let transaction = contract.method("createAccount", parameters: [username, userDataHash] as [AnyObject], options: options) else { return }
            print(transaction.transaction.data)
            let con = ContractV2(peepEthABI)
            print(transaction.transaction.data.toHexString())
            if let input = con?.decodeInputData(transaction.transaction.data) {
                print(input)
            }
            guard case .success(let estimate) = transaction.estimateGas(options: options) else {return}
            print(estimate)
            DispatchQueue.main.async {
                completion(Result.Success(transaction))
            }
        }
    }
    
    //MARK: - Posting a peep
    func preparePostPeepTransaction(peepDataHash: String, gasLimit: BigUInt = 27500 ,completion: @escaping (Result<TransactionIntermediate>) -> Void) {
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.selectedWallet()
            guard let address = wallet?.address else { return }
            let ethAddressFrom = EthereumAddress(address)
            
            let web3 = Web3.InfuraMainnetWeb3()
            web3.addKeystoreManager(Web3swiftService.keyservice.keystoreManager())
            
            var options = Web3Options.defaultOptions()
            options.from = ethAddressFrom
            options.value = 0
            guard let contract = web3.contract(peepEthABI, at: ethContractAddress, abiVersion: 2) else { return }
            guard let gasPrice = web3.eth.getGasPrice().value else { return }
            options.gasPrice = gasPrice
            options.gasLimit = gasLimit
            guard let transaction = contract.method("post", parameters: [peepDataHash] as [AnyObject], options: options) else { return }
            guard case .success(let estimate) = transaction.estimateGas(options: options) else {return}
            print("estimated cost: \(estimate)")
            DispatchQueue.main.async {
                completion(Result.Success(transaction))
            }
        }
    }
    
    func prepareSharePeepTransaction(peepDataHash: String, gasLimit: BigUInt = 27500, completion: @escaping (Result<TransactionIntermediate>) -> Void) {
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.selectedWallet()
            guard let address = wallet?.address else { return }
            let ethAddressFrom = EthereumAddress(address)
            
            let web3 = Web3.InfuraMainnetWeb3()
            web3.addKeystoreManager(Web3swiftService.keyservice.keystoreManager())
            
            var options = Web3Options.defaultOptions()
            options.from = ethAddressFrom
            options.value = 0
            guard let contract = web3.contract(peepEthABI, at: ethContractAddress, abiVersion: 2) else { return }
            guard let gasPrice = web3.eth.getGasPrice().value else { return }
            options.gasPrice = gasPrice
            options.gasLimit = gasLimit
            guard let transaction = contract.method("share", parameters: [peepDataHash] as [AnyObject], options: options) else { return }
            guard case .success(let estimate) = transaction.estimateGas(options: options) else {return}
            print("estimated cost: \(estimate)")
            DispatchQueue.main.async {
                completion(Result.Success(transaction))
            }
        }
    }
    
    func prepareReplyPeepTransaction(peepDataHash: String, gasLimit: BigUInt = 27500, completion: @escaping (Result<TransactionIntermediate>) -> Void) {
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.selectedWallet()
            guard let address = wallet?.address else { return }
            let ethAddressFrom = EthereumAddress(address)
            
            let web3 = Web3.InfuraMainnetWeb3()
            web3.addKeystoreManager(Web3swiftService.keyservice.keystoreManager())
            
            var options = Web3Options.defaultOptions()
            options.from = ethAddressFrom
            options.value = 0
            guard let contract = web3.contract(peepEthABI, at: ethContractAddress, abiVersion: 2) else { return }
            guard let gasPrice = web3.eth.getGasPrice().value else { return }
            options.gasPrice = gasPrice
            options.gasLimit = gasLimit
            guard let transaction = contract.method("reply", parameters: [peepDataHash] as [AnyObject], options: options) else { return }
            guard case .success(let estimate) = transaction.estimateGas(options: options) else {return}
            print("estimated cost: \(estimate)")
            DispatchQueue.main.async {
                completion(Result.Success(transaction))
            }
        }
    }
    
    
    //Sending Transaction
    func sendTransaction(transaction: TransactionIntermediate, password: String, completion: @escaping (Result<TransactionSendingResult>) -> Void) {
        DispatchQueue.global().async {
            //sending
            let result = transaction.send(password: password, options: nil)
            switch result {
            case .success(let value):
                DispatchQueue.main.async {
                    completion(Result.Success(value))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(Result.Error(error))
                }
            }
        }
    }
    
    
    //Checking whether account already registered or not
    func isAccountRegistered(address: EthereumAddress, completion: @escaping (Result<Bool>) -> Void) {
        DispatchQueue.global().async {
            
            let infura = Web3.InfuraMainnetWeb3()
            
            let contract = infura.contract(peepEthABI, at: ethContractAddress, abiVersion: 2)
            var options = Web3Options.defaultOptions()
            options.from = address
            let transactionIntermediate = contract?.method("accountExists", parameters:[address] as [AnyObject], options: options)
            let result = transactionIntermediate!.call(options: options)
            switch result {
                
            case .success(let res):
                let ans = res["0"] as! Bool
                DispatchQueue.main.async {
                    completion(Result.Success(ans))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(Result.Error(error))
                }
            }
        }
        
    }
    
    //MARK: - Get ETH balance
    func getETHbalance (completion: @escaping (BigUInt?,Error?) -> Void) {
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.localStorage.getWallet()
            guard let address = wallet?.address else { return }
            let ETHaddress = EthereumAddress(address)!
            let web3Main = Web3.InfuraMainnetWeb3()
            let balanceResult = web3Main.eth.getBalance(address: ETHaddress)
            guard case .success(let balance) = balanceResult else {
                completion(nil,balanceResult.error)
                return
            }
            completion(balance,nil)
        }
    }
    
    //    var ABIisValidName = { "constant": true, "inputs": [ { "name": "bStr", "type": "bytes16" } ], "name": "isValidName", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "pure", "type": "function" }
    func isNameValid(username: String, completion: @escaping (Result<Bool>) -> Void) {
        DispatchQueue.global().async {
            
            let infura = Web3.InfuraMainnetWeb3()
            
            let contract = infura.contract(peepEthABI, at: ethContractAddress, abiVersion: 2)
            let options = Web3Options.defaultOptions()
            
            let transactionIntermediate = contract?.method("isValidName", parameters:[username] as [AnyObject], options: options)
            let result = transactionIntermediate!.call(options: options)
            switch result {
                
            case .success(let res):
                let ans = res["0"] as! Bool
                DispatchQueue.main.async {
                    completion(Result.Success(ans))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(Result.Error(error))
                }
            }
        }
    }
    
    //MARK: - Get untrusted address
    func getUntrustedAddress(completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            let wallet = Web3swiftService.keyservice.localStorage.getWallet()
            guard let address = wallet?.address else {
                completion(nil)
                return
                
            }
            completion(address)
        }
    }
    
    
    
}

enum Result<T> {
    case Success(T)
    case Error(Error)
}
