//
//  LoginViewController.swift
//  PeepethClient
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var logoVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightStartConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoMovingToTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightEndConstraint: NSLayoutConstraint!
    @IBOutlet weak var createWalletButton: UIButton!
    @IBOutlet weak var importWalletButton: UIButton!
    
    var walletKeysMode: WalletKeysMode = .createKey
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createWalletButton.alpha = 0
        self.importWalletButton.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Enter animation
        logoVerticalCenterConstraint.isActive = false
        logoMovingToTopConstraint.isActive = true
        logoHeightStartConstraint.isActive = false
        logoHeightEndConstraint.isActive = true
        
        
        
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
            self.createWalletButton.alpha = 1
            self.importWalletButton.alpha = 1
            
            
        }
        
    }
    
    @IBAction func createWalletTapped(_ sender: UIButton) {
        walletKeysMode = .createKey
    }
    @IBAction func importWalletTapped(_ sender: UIButton) {
        walletKeysMode = .importKey
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createWalletController = segue.destination as? CreateWalletViewController {
            createWalletController.mode = walletKeysMode
        }
    }


}
