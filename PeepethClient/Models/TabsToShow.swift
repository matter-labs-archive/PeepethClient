//
//  TabsToShow.swift
//  PeepethClient
//
//  Created by Anton Grigorev on 10/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import UIKit

enum tabs: Int {
    case globalPeeps = 1
    case settings = 2
    case userPeeps = 0
}

func tabsToShow(globalPeeps: Bool, userPeeps: Bool, settings: Bool, for tabBarController: UITabBarController?){
    if globalPeeps == false {
        tabBarController?.viewControllers?.remove(at: tabs.globalPeeps.rawValue)
    }
    if userPeeps == false {
        tabBarController?.viewControllers?.remove(at: tabs.userPeeps.rawValue)
    }
    if settings == false {
        tabBarController?.viewControllers?.remove(at: tabs.settings.rawValue)
    }
}
