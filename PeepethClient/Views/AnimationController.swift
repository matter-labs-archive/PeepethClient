//
//  AnimationController.swift
//  PeepethClient
//

import UIKit

class AnimationController: UIView {

    enum tagsForViews: Int {
        case background = 776
        case notification = 775
        case animation = 777
    }

    /*
     Wait animation for load screens:
     isEnabled - true or false
     notificationText - text in the screens center
     selfView - superview for animation view
     */
    func waitAnimation(isEnabled: Bool, notificationText: String?, selfView: UIView) {

        DispatchQueue.main.async {
            if (isEnabled) {

                selfView.alpha = 1.0

                let rect: CGRect = CGRect(x: 0,
                        y: 0,
                        width: UIScreen.main.bounds.size.width,
                        height: UIScreen.main.bounds.size.height)
                let background: UIView = UIView(frame: rect)
                background.backgroundColor = UIColor.lightGray
                background.alpha = 0.4
                background.tag = tagsForViews.background.rawValue

                let notification: UILabel = UILabel.init(frame: CGRect(x: 0,
                        y: 0,
                        width: UIScreen.main.bounds.size.width,
                        height: 15))
                notification.textColor = UIColor.white
                notification.textAlignment = NSTextAlignment.center
                notification.font = UIFont(name: "Apple SD Gothic Neo", size: 15)
                notification.numberOfLines = 1

                let centerX = UIScreen.main.bounds.size.width / 2
                let centerY = UIScreen.main.bounds.size.height / 2

                notification.center = CGPoint(x: centerX, y: centerY - 10)
                notification.tag = tagsForViews.notification.rawValue
                if (notificationText != nil) {
                    notification.text = notificationText
                } else {
                    notification.text = ""
                }

                let animation: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
                var frame: CGRect = animation.frame
                frame.origin.x = centerX - 10
                frame.origin.y = centerY - 50
                frame.size.width = 20
                frame.size.height = 20
                animation.frame = frame
                animation.tag = tagsForViews.animation.rawValue

                selfView.insertSubview(background, at: 5)
                selfView.insertSubview(animation, at: 6)
                selfView.insertSubview(notification, at: 7)

                animation.startAnimating()
            } else {
                selfView.alpha = 1.0
                if let viewWithTag = selfView.viewWithTag(tagsForViews.notification.rawValue) {
                    viewWithTag.removeFromSuperview()
                }
                if let viewWithTag = selfView.viewWithTag(tagsForViews.background.rawValue) {
                    viewWithTag.removeFromSuperview()
                }
                if let viewWithTag = selfView.viewWithTag(tagsForViews.animation.rawValue) {
                    viewWithTag.removeFromSuperview()
                }
            }
        }

    }

}
