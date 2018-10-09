//
//  CreateWalletViewController.swift
//  PeepethClient
//

import UIKit
import web3swift
import QRCodeReader

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
    @IBOutlet weak var enterPrivateKeyLabel: NSLayoutConstraint!
    @IBOutlet weak var enterKeyLabel: UILabel!
    @IBOutlet weak var qrLabel: UILabel!
    @IBOutlet weak var orQrLabel: UILabel!
    @IBOutlet weak var qrImageHeigh: NSLayoutConstraint!
    @IBOutlet weak var qrLabelHeight: NSLayoutConstraint!
    
    var mode: WalletCreationMode = .createKey
    let keysService: KeysService = KeysService()
    let ipfsService = IPFSService()
    let localStorage = LocalDatabase()
    let web3service: Web3swiftService = Web3swiftService()
    let alerts = Alerts()
    let walletController = WalletController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = mode.title()
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
            qrLabelHeight.constant = 0
            enterPrivateKeyLabel.constant = 0
            qrImageHeigh.constant = 0
            privateKeyHeight.constant = 0
            orQrLabel.alpha = 0
            qrLabel.alpha = 0
            enterKeyLabel.alpha = 0
            qrCodeButton.alpha = 0
            qrCodeButton.isUserInteractionEnabled = false
            enterPrivateKeyTextField.isUserInteractionEnabled = false
        }
    }
    
    func createWallet() {
        guard passwordTextField.text == repeatPasswordTextField.text else {
            passwordsDontMatch.isHidden = false
            return
        }
        passwordsDontMatch.isHidden = true
        
        walletController.createWallet(with: mode, password: passwordTextField.text, key: enterPrivateKeyTextField.text) { (error) in
            guard error == nil else {
                self.alerts.show(error, for: self)
                return
            }
            self.performSegue(withIdentifier: "GoToEnterScreenWithExistingAccount", sender: nil)
        }
        
    }
    
    @IBAction func createWalletButtonTapped(_ sender: UIButton) {
        createWallet()
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
    }
    
    
    @IBAction func backAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonTouchedDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05,
                       animations: {
                        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)},
                       completion: nil)
    }
    
    @IBAction func buttonTouchedDragInside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05,
                       animations: {
                        sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)},
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
    
    //QR feature
    
    @IBAction func qrScanTapped(_ sender: UIButton) {
        readerVC.delegate = self
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in }
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
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
        if passwordTextField.text == repeatPasswordTextField.text &&
            !(passwordTextField.text?.isEmpty ?? true) {
            createButton.isEnabled = true
            createButton.alpha = 1
        }
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
        textField.textColor = UIColor.orange
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
                !futureString.isEmpty && ((passwordTextField.text?.count)! > 4) {
                createButton.isEnabled = true
            }
        case passwordTextField:
            if !futureString.isEmpty &&
                futureString == repeatPasswordTextField.text ||
                repeatPasswordTextField.text?.isEmpty == true {
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
            passwordsDontMatch.text = "Passwords don't match"
            repeatPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        } else if  (!(passwordTextField.text?.isEmpty ?? true) ||
            !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
            ((passwordTextField.text?.count)! < 5){
            passwordsDontMatch.isHidden = false
            passwordsDontMatch.text = "Password is too short"
            repeatPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        } else {
            repeatPasswordTextField.textColor = UIColor.darkGray
            passwordTextField.textColor = UIColor.darkGray
        }
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done && createButton.isEnabled && ((passwordTextField.text?.count)! > 4) {
            createWallet()
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
