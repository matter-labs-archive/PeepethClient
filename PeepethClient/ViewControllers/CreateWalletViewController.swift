//
//  CreateWalletViewController.swift
//  PeepethClient
//

import UIKit
import web3swift
import QRCodeReader

enum WalletKeysMode {
    
    case importKey
    case createKey
    
    func title() -> String {
        switch self {
        case .importKey:
            return "Import wallet"
        case .createKey:
            return "Create wallet"
        }
    }
}

class CreateWalletViewController: UIViewController,
QRCodeReaderViewControllerDelegate {

    @IBOutlet weak var passwordsDontMatch: UILabel!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    @IBOutlet weak var enterPrivateKeyTextField: UITextField!
    @IBOutlet weak var privateKeyHeight: NSLayoutConstraint!
    @IBOutlet weak var qrCodeButton: UIButton!
    
    var mode: WalletKeysMode = .createKey
    let keysService: KeysService = KeysService()
    let ipfsService = IPFSService()
    let localStorage = LocalDatabase()
    let web3service: Web3swiftService = Web3swiftService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        createButton.setTitle(mode.title(), for: .normal)
        createButton.isEnabled = false
        createButton.alpha = 0.5
        passwordsDontMatch.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if mode == .createKey {
            privateKeyHeight.constant = 0
            qrCodeButton.isUserInteractionEnabled = false
            qrCodeButton.alpha = 0
        }
    }
    
    @IBAction func createWalletButtonTapped(_ sender: Any) {
        guard passwordTextField.text == repeatPasswordTextField.text else {
            passwordsDontMatch.isHidden = false
            return
        }
        passwordsDontMatch.isHidden = true
        
        if mode == .createKey {
            //Create new wallet
            keysService.createNewWallet(password: passwordTextField.text!) { (wallet, error) in
                if let error = error {
                    self.showErrorAlert(error: error)
                } else {
                    //Segue to registration controller(in Peepeth), because if you've just created the wallet, it'll be 100% not registered in Peepeth.
                    self.localStorage.saveWallet(isRegistered: false, wallet: wallet!) { (error) in
                        if error == nil {
                            self.performSegue(withIdentifier: "GoToEnterScreenWithExistingAccount", sender: nil)
                        } else {
                            self.showErrorAlert(error: error)
                        }
                    }
                }
            }
        } else {
            //Import wallet
            keysService.addNewWalletWithPrivateKey(key: enterPrivateKeyTextField.text!, password: passwordTextField.text!) { (wallet, error) in
                if let error = error {
                    self.showErrorAlert(error: error)
                    return
                } else {
                    guard let walletStrAddress = wallet?.address, let walletAddress = EthereumAddress(walletStrAddress) else {
                        self.showErrorAlert(error: nil )
                        return
                    }
                    //Check if account registered to save if it is registered or not into core data
                    self.web3service.isAccountRegistered(address: walletAddress, completion: { (result) in
                        switch result {
                        case .Success(let isRegistered):
                            self.localStorage.saveWallet(isRegistered: isRegistered, wallet: wallet!) { (error) in
                                if error == nil {
                                    self.performSegue(withIdentifier: "GoToEnterScreenWithExistingAccount", sender: nil)
                                } else {
                                    self.showErrorAlert(error: error)
                                }
                            }
                        case .Error(let error):
                            self.showErrorAlert(error: error)
                        }
                        
                    })
                }
            }
            
            
        }
    }
    
    
    @IBAction func backAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func showErrorAlert(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //QR feature
    
    @IBAction func qrScanTapped(_ sender: Any) {
        readerVC.delegate = self
        
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in }
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    // Scan
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        enterPrivateKeyTextField.text = result.value
        dismiss(animated: true, completion: nil)
    }
    
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
    }
    
}

extension CreateWalletViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.returnKeyType = createButton.isEnabled ? UIReturnKeyType.done : .next
        textField.textColor = UIColor.blue
        if textField == passwordTextField || textField == repeatPasswordTextField {
            passwordsDontMatch.isHidden = true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = (textField.text ?? "")  as NSString
        let futureString = currentText.replacingCharacters(in: range, with: string) as String
        createButton.isEnabled = false
        
        switch textField {
        case enterPrivateKeyTextField:
            if passwordTextField.text == repeatPasswordTextField.text &&
                !(passwordTextField.text?.isEmpty ?? true) &&
                !futureString.isEmpty {
                createButton.isEnabled = true
            }
        case passwordTextField:
            if !futureString.isEmpty &&
                futureString == repeatPasswordTextField.text {
                passwordsDontMatch.isHidden = true
                createButton.isEnabled = (!(enterPrivateKeyTextField.text?.isEmpty ?? true) || mode == .createKey)
            } else {
                passwordsDontMatch.isHidden = false
                createButton.isEnabled = false
            }
        case repeatPasswordTextField:
            if !futureString.isEmpty &&
                futureString == passwordTextField.text {
                passwordsDontMatch.isHidden = true
                createButton.isEnabled = (!(enterPrivateKeyTextField.text?.isEmpty ?? true) || mode == .createKey)
            } else {
                passwordsDontMatch.isHidden = false
                createButton.isEnabled = false
            }
        default:
            createButton.isEnabled = false
            passwordsDontMatch.isHidden = false
        }
        
        createButton.alpha = createButton.isEnabled ? 1.0 : 0.5
        textField.returnKeyType = createButton.isEnabled ? UIReturnKeyType.done : .next
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.textColor = UIColor.darkGray
        
        guard textField == repeatPasswordTextField ||
            textField == passwordTextField else {
                return true
        }
        if (!(passwordTextField.text?.isEmpty ?? true) ||
            !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
            passwordTextField.text != repeatPasswordTextField.text {
            passwordsDontMatch.isHidden = false
            repeatPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        } else {
            repeatPasswordTextField.textColor = UIColor.darkGray
            passwordTextField.textColor = UIColor.darkGray
        }
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done && createButton.isEnabled {
            createWalletButtonTapped(self)
        } else if textField.returnKeyType == .next {
            let index = textFields.index(of: textField) ?? 0
            let nextIndex = (index == textFields.count - 1) ? 0 : index + 1
            textFields[nextIndex].becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        return true
    }
}
