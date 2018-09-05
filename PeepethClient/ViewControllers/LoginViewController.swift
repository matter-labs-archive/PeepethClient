//
//  LoginViewController.swift
//  PeepethClient
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var logoHeightStartConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoHeightEndConstraint: NSLayoutConstraint!
    @IBOutlet weak var createWalletButton: UIButton!
    @IBOutlet weak var importWalletButton: UIButton!
    @IBOutlet weak var logoTitle: UILabel!
    @IBOutlet weak var logoSubtitle: UILabel!
    @IBOutlet weak var logoTitleRight: UILabel!
    
    var walletKeysMode: WalletKeysMode = .createKey
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.createWalletButton.alpha = 0
        self.importWalletButton.alpha = 0
        self.logoTitle.alpha = 0
        self.logoSubtitle.alpha = 0
        self.logoTitleRight.alpha = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Enter animation
        logoHeightStartConstraint.isActive = false
        logoHeightEndConstraint.isActive = true
        
        
        
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
            self.createWalletButton.alpha = 1
            self.importWalletButton.alpha = 1
            self.logoTitle.alpha = 1
            self.logoSubtitle.alpha = 1
            self.logoTitleRight.alpha = 1
        }
        
    }
    
    @IBAction func createWalletTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
        walletKeysMode = .createKey
    }
    @IBAction func importWalletTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity
        }
        walletKeysMode = .importKey
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let createWalletController = segue.destination as? CreateWalletViewController {
            createWalletController.mode = walletKeysMode
        }
    }


}
