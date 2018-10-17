//
//  PeepethClientUITests.swift
//  PeepethClientUITests
//
//  Created by NewUser on 26/09/2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import XCTest

class PeepethClientUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
//        app.buttons["Import Wallet"].tap()
//
//        let importWalletButton = app.buttons["Import Wallet"]
//        importWalletButton.tap()
//        let pass = app.secureTextFields["Enter password: MIN 5 chars"]
//        pass.tap()
//        pass.typeText("123456")
//
//        let repeatPass = app.secureTextFields["Repeat Password: MIN 5 chars"]
//        repeatPass.tap()
//        repeatPass.typeText("123456")
//
//        let textField = app.secureTextFields["Private Key"]
//        textField.tap()
//        textField.typeText("PRIVATEKEY")
//
//        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.tap()
//        let newButton = app.buttons["Import Wallet"]
//        newButton.tap()
        
        snapshot("Personal Peeps")
        
        let tabBarsQuery = XCUIApplication().tabBars
        tabBarsQuery.children(matching: .button).element(boundBy: 1).tap()
        sleep(10)
        snapshot("All the peeps")
        tabBarsQuery.children(matching: .button).element(boundBy: 2).tap()
        snapshot("Settings")
        
    }

}
