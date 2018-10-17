//
//  PeepCell.swift
//  PeepethClient
//

import UIKit

class PeepCell: UITableViewCell {

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var sharedLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var attachedImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var attachedHeight: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!

    var peep: ServerPeep! {
        didSet {
            peepSetConfigure()
        }
    }

    func peepSetConfigure() {
        userAvatar.layer.cornerRadius = userAvatar.frame.size.width / 2
        userAvatar.clipsToBounds = true
        userNameLabel.text = peep.info["realName"] as? String
        nickNameLabel.text = (peep.info["name"] != nil) ? "@" + (peep.info["name"] as? String)! : nil
        messageLabel.text = peep.info["content"] as? String
        spinner.isHidden = true

        if let imageData = peep.info["avatar_imageData"] {
            let image = UIImage(data: imageData as! Data)
            self.userAvatar.image = image
        } else {
            self.userAvatar.image = UIImage(named: "peepLogo")
        }

        if peep.info["image_url"] != nil {
            let image = peep.info["attached_imageData"] != nil ? UIImage(data: peep.info["attached_imageData"] as! Data) : UIImage(named: "peepLogo")
            self.attachedImage.image = image
            self.attachedImage.isHidden = false
            self.attachedHeight?.constant = 200
        } else {
            self.attachedImage.image = nil
            self.attachedImage.isHidden = true
            self.attachedHeight?.constant = 0
        }

        // if peep has parent or it is shared
        sharedLabel.isHidden = peep.shared || peep.parent ? false : true
        leftConstraint.constant = peep.shared || peep.parent ? 25 : 5
        if peep.shared {
            sharedLabel.text = "Shared"
        }
        if peep.parent {
            sharedLabel.text = "Replied"
        }
        if !peep.parent && !peep.shared {
            self.separatorView.backgroundColor = UIColor.lightGray
        } else {
            self.separatorView.backgroundColor = UIColor.white
        }

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.userNameLabel.text = ""
        self.nickNameLabel.text = ""
        self.messageLabel.text = ""
        self.userAvatar.image = UIImage(named: "peepLogo")
        self.sharedLabel.isHidden = true
        self.separatorView.backgroundColor = UIColor.white
        self.leftConstraint.constant = 5
        self.attachedImage.image = nil
    }

}
