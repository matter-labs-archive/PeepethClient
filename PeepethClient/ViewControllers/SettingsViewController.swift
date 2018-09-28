//
//  SettingsViewController.swift
//  PeepethClient
//
//  Created by Антон Григорьев on 08.07.2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import UIKit
import BigInt
import web3swift

class SettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addressCopiedLabel: UILabel!
    @IBOutlet weak var addressCopiedImage: UIImageView!

    let animation = AnimationController()

    let localDatabase = LocalDatabase()
    let keysService = KeysService()
    let service = Web3swiftService()
    let ipfsService = IPFSService()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initializeGestureRecognizers()

        addressCopiedLabel.alpha = 0
        addressCopiedImage.alpha = 0

        self.hideKeyboardWhenTappedAround()

        if localDatabase.isWalletRegistered() {
            registerButton.isUserInteractionEnabled = false
            registerButton.alpha = 0
        } else {
            showEnterAlert()
        }

        getUntrustedAddress()

        service.getETHbalance { (result, _) in
            DispatchQueue.main.async {
                let ethUnits = Web3Utils.formatToEthereumUnits(result!, toUnits: .eth, decimals: 6, decimalSeparator: ".")
                self.balanceLabel.text = "ETH Balance: " + ethUnits!
            }

        }
    }

    func initializeGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.copyAddress))
        addressLabel.addGestureRecognizer(tap)
    }

    @objc func copyAddress() {
        let pasteboard = UIPasteboard.general
        service.getUntrustedAddress(completion: { (address) in
            pasteboard.string = address ?? ""
        })

        DispatchQueue.main.async {
            self.addressCopiedLabel.alpha = 0.0
            self.addressCopiedImage.alpha = 0.0
            UIView.animate(withDuration: 1.0,
                    animations: {
                        self.addressCopiedLabel.alpha = 1.0
                        self.addressCopiedImage.alpha = 1.0
                    }, completion: { _ in
                UIView.animate(withDuration: 2.0, animations: {
                    self.addressCopiedLabel.alpha = 0.0
                    self.addressCopiedImage.alpha = 0.0
                })
            })
        }
    }

    @IBAction func refresh(_ sender: UIBarButtonItem) {
        if localDatabase.isWalletRegistered() {
            registerButton.isUserInteractionEnabled = false
            registerButton.alpha = 0
        }

        getUntrustedAddress()

        service.getETHbalance { (result, _) in
            DispatchQueue.main.async {
                let ethUnits = Web3Utils.formatToEthereumUnits(result!, toUnits: .eth, decimals: 6, decimalSeparator: ".")
                self.balanceLabel.text = "ETH Balance: " + ethUnits!
            }

        }
    }

    func getUntrustedAddress() {

        service.getUntrustedAddress(completion: { (address) in
            DispatchQueue.main.async {
                if address != nil {
                    self.addressLabel.text = "Address: " + address!
                } else {
                    self.getUntrustedAddress()
                }
            }

        })
    }

    @IBAction func showPrivateKey(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }

        let alert = UIAlertController(title: "Show private key", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your password"
        }

        let enterPasswordAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            let passwordTextField = alert.textFields![0] as UITextField
            if let privateKey = self.keysService.getWalletPrivateKey(password: passwordTextField.text!) {
                self.privateKeyAlert(privateKey: privateKey)

            } else {
                self.showErrorAlert(error: "Wrong password")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

        }

        alert.addAction(enterPasswordAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }

    func privateKeyAlert(privateKey: String) {
        let alert = UIAlertController(title: "Private key", message: privateKey, preferredStyle: UIAlertControllerStyle.alert)

        let copyAction = UIAlertAction(title: "Copy", style: .default) { (_) in
            let pasteboard = UIPasteboard.general
            pasteboard.string = privateKey
        }

        let closeAction = UIAlertAction(title: "Close", style: .cancel) { (_) in
        }
        alert.addAction(copyAction)
        alert.addAction(closeAction)

        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func logout(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
        localDatabase.deleteWallet { (error) in
            if error == nil {
                let viewController = self.storyboard?.instantiateViewController(withIdentifier: "enterController") as! EnterViewController
                self.present(viewController, animated: false, completion: nil)
            } else {
                self.showErrorAlert(error: error?.localizedDescription)
            }
        }
    }

    @IBAction func registerAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
        let alert = UIAlertController(title: "Register in Peep", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        alert.addTextField { (textField) in
            //textField.isSecureTextEntry = true
            textField.placeholder = "Enter your user name: MIN 3 chars"
        }
        alert.addTextField { (textField) in
            //textField.isSecureTextEntry = true
            textField.placeholder = "Enter your real name: MIN 3 chars"
        }
        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your password"
        }

        let enterPasswordAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            self.animation.waitAnimation(isEnabled: true, notificationText: "Preparing transaction", selfView: self.view)

            let nickNameTextField = alert.textFields![0] as UITextField
            let realNameTextField = alert.textFields![1] as UITextField
            let passwordTextField = alert.textFields![2] as UITextField

            if (nickNameTextField.text?.count)! < 3 {
                self.showErrorAlert(error: "Use more symbols in nickname")
                return
            }

            if (realNameTextField.text?.count)! < 3 {
                self.showErrorAlert(error: "Use more symbols in real name")
                return
            }

            guard let userName = nickNameTextField.text else {
                return
            }
            guard let realName = realNameTextField.text else {
                return
            }
            guard let password = passwordTextField.text else {
                return
            }

            if let privateKey = self.keysService.getWalletPrivateKey(password: password) {
                self.prepareTransaction(privateKey: privateKey, password: password, realName: realName, userName: userName)

            } else {
                self.showErrorAlert(error: "Wrong password")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

        }

        alert.addAction(enterPasswordAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)

    }

    @IBAction func buttonTouchedDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05,
                animations: {
                    sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                },
                completion: nil)
    }

    @IBAction func buttonTouchedDragInside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05,
                animations: {
                    sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                },
                completion: nil)
    }

    @IBAction func buttonTouchedDragOutside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
    }

    @IBAction func touchCancel(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
    }

    func prepareTransaction(privateKey: String, password: String, realName: String, userName: String) {

        //get your adress
        service.getUntrustedAddress(completion: { (address) in
            if address != nil {
                // send to ipfs, get hash, intermediate transaction - show gas price
                let timeStamp = Int(Date().timeIntervalSince1970)
                let user = User(info: "",
                        location: "",
                        realName: realName,
                        website: "",
                        avatarUrl: "",
                        backgroundUrl: "",
                        messageToWorld: "",
                        untrustedTimestamp: timeStamp)

                self.ipfsService.postToIPFS(data: user, completion: { (result) in
                    switch result {
                    case .Success(let hash):
                        self.service.prepareCreateAccountTransaction(username: userName, userDataHash: hash, completion: { (result) in
                            switch result {
                            case .Success(let transaction):
                                self.confirmTransactionAlert(password: password, transaction: transaction)
                            case .Error(let error):
                                self.showErrorAlert(error: error.localizedDescription)
                            }
                        })
                    case .Error(let error):
                        self.showErrorAlert(error: error.localizedDescription)
                    }
                })

            } else {
                return
            }
        })

    }

    func confirmTransactionAlert(password: String, transaction: (TransactionIntermediate)) {

        animation.waitAnimation(isEnabled: false, notificationText: nil, selfView: self.view)

        let alert = UIAlertController(title: "Confirm transaction", message: nil, preferredStyle: UIAlertControllerStyle.alert)

        alert.addTextField { (textField) in
            //gas price
            let gasPrice = Web3Utils.formatToEthereumUnits(transaction.transaction.gasPrice, toUnits: .eth, decimals: 16, decimalSeparator: ".")!
            let intGasPrice = Float(gasPrice)
            let formattedGasPrice = String(intGasPrice! * pow(10, 9))
            textField.text = "Estimated gas price: " + formattedGasPrice + " Gwei"
            textField.textAlignment = .center
            textField.font = UIFont.systemFont(ofSize: 10)
            textField.isUserInteractionEnabled = false
        }
        alert.addTextField { (textField) in
            //gas limit
            let gasLimit = Web3Utils.formatToEthereumUnits(transaction.transaction.gasLimit, toUnits: .eth, decimals: 16, decimalSeparator: ".")!
            let intGasLimit = Float(gasLimit)
            let formattedGasLimit = String(intGasLimit! * pow(10, 18))
            textField.text = "Estimated gas limit: " + formattedGasLimit
            textField.textAlignment = .center
            textField.font = UIFont.systemFont(ofSize: 10)
            textField.isUserInteractionEnabled = false
        }

        let confirmTransaction = UIAlertAction(title: "OK", style: .default) { (_) in
            self.animation.waitAnimation(isEnabled: true, notificationText: "Sending transaction", selfView: self.view)
            self.sendTransaction(password: password, transaction: transaction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

        }

        alert.addAction(confirmTransaction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }

    func sendTransaction(password: String, transaction: TransactionIntermediate) {

        self.service.sendTransaction(transaction: transaction, password: password, completion: { (result) in
            switch result {
            case .Success:
                self.showAlertSuccessTransaction()
            case .Error(let error):
                self.showErrorAlert(error: error.localizedDescription)
            }
        })

    }

    func showAlertSuccessTransaction() {
        animation.waitAnimation(isEnabled: false, notificationText: nil, selfView: self.view)
        let alert = UIAlertController(title: "Success transaction", message: "Thank you, now just wait while your transaction is providing in the blockchain. It may take some time :) Track your transaction on Etherscan. Restart PeepEth to correctly sign in after it will be provided", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
        }
        alert.addAction(okAction)

        self.present(alert, animated: true, completion: nil)
    }

    func showErrorAlert(error: String?) {
        animation.waitAnimation(isEnabled: false, notificationText: nil, selfView: self.view)
        let alert = UIAlertController(title: "Error", message: error!, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    func showEnterAlert() {
        let alert = UIAlertController(title: "Registration", message: "Add funds to your wallet and register in Peepeth", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        return false
    }

}
