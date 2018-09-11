//
//  ActionViews.swift
//  PeepethClient
//
//  Created by Anton Grigorev on 10/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import UIKit

class Alerts {
    func show(_ error: Error?, for controller: UIViewController) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        controller.present(alert, animated: true, completion: nil)
    }
    
    func show(_ title: String?, with message: String?, for controller: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        controller.present(alert, animated: true, completion: nil)
    }
}
