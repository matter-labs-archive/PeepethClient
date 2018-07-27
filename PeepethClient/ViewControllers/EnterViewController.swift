//
//  ViewController.swift
//  PeepethClient
//

import UIKit

class EnterViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Delay to prevent some problems
        if (!appDelegate.enterDelay) {
            delay(1.0, closure: {
            })
        }
        self.continueLogin()
    }
    
    func goToLogin() {
        self.performSegue(withIdentifier: "LoginSegue", sender: self)
    }
    
    
    func goToApp() {
        self.performSegue(withIdentifier: "AppSegue", sender: self)
    }


}

extension EnterViewController {
    
    /*
     Checking if there current wallet. If yes - go to peep controller.
     If no - we need to log in.
     */
    func continueLogin() {
        appDelegate.enterDelay = false
        
        if LocalDatabase().getWallet() == nil{
            self.goToLogin()
        } else {
            self.goToApp()
        }
        
    }
    
    
}


