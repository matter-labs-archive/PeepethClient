//
//  PeepsListViewController.swift
//  PeepethClient
//
//  Created by Антон Григорьев on 06.07.2018.
//  Copyright © 2018 BaldyAsh. All rights reserved.
//

import UIKit
import web3swift

class PeepsListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peepOrRegButton: UIBarButtonItem!

    //var searchController: UISearchController!

    let web3service: Web3swiftService = Web3swiftService()
    let alerts = Alerts()

    let animation = AnimationController()

    let refreshControl = UIRefreshControl()
    let localDatabase = LocalDatabase()
    var peeps: [ServerPeep]?

    var chosenPeepHash: String? = nil

    var peepsFor: peepsFor = .global

    var searchingString: String? = nil
    var searchingPage = 1

    lazy var searchBar: UISearchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 200, height: 20))

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        chosenPeepHash = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //Check if account registered in core data
        if localDatabase.isWalletRegistered() {
            self.initWithRegisteredAcc()

        } else {
            DispatchQueue.main.async {
                self.animation.waitAnimation(isEnabled: true,
                        notificationText: "Preparing...",
                        selfView: self.view)
            }
            web3service.getUntrustedAddress(completion: { (address) in
                DispatchQueue.main.async {
                    if address != nil {
                        //Check if account registered to save if it is registered or not into core data
                        self.web3service.isAccountRegistered(address: EthereumAddress(address!)!, completion: { (result) in
                            switch result {
                            case .Success(let isRegistered):
                                if isRegistered {
                                    self.localDatabase.walletHadBeenRegistered()
                                    self.initWithRegisteredAcc()
                                } else {
                                    self.walletIsUnregistered()
                                }

                            case .Error(_):
                                self.walletIsUnregistered()
                            }

                        })
                    } else {
                        self.walletIsUnregistered()
                    }
                }

            })
        }
    }

    func walletIsUnregistered() {
        self.peepOrRegButton.isEnabled = false
        tabsToShow(globalPeeps: false, userPeeps: false, settings: true, for: self.tabBarController)
        alerts.show("Registration", with: "Add funds to your wallet and register in Peepeth. All you need for registration is in the Settings tab", for: self)
    }

    func currentTab(identifier: String?) {
        switch identifier {
        case "UserPeepsListViewController":
            peepsFor = .user
            navigationItem.title = "Your Peeps"
        case "GlobalPeepsListViewController":
            peepsFor = .global
            navigationItem.title = "Global Peeps"
        default:
            peepsFor = .global
            navigationItem.title = "Global Peeps"
        }
    }


    //Init full functionality
    func initWithRegisteredAcc() {
        DispatchQueue.main.async {
            self.animation.waitAnimation(isEnabled: false,
                    notificationText: nil,
                    selfView: self.view)
        }

        currentTab(identifier: self.restorationIdentifier)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension

        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)
        getPeepsList(older: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.prefersLargeTitles = false
        //searchController = UISearchController(searchResultsController: nil)
        //searchBar
        //searchController.searchResultsUpdater = self
        //searchController.dimsBackgroundDuringPresentation = false
        //tableView.tableHeaderView = searchController.searchBar
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.darkText
        definesPresentationContext = true
        searchBar.placeholder = "Your placeholder"


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func refreshTableData(_ sender: Any) {
        DispatchQueue.cancelPreviousPerformRequests(withTarget: self)
        getPeepsList(older: false)
    }

    func getPeepsList(older: Bool) {
        let lastViewTag = 111
        DispatchQueue.main.async {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
            view.alpha = 0
            view.tag = lastViewTag
            self.view.addSubview(view)
            self.animation.waitAnimation(isEnabled: true,
                    notificationText: "Getting peeps",
                    selfView: self.view.subviews.last!)
        }

        let url = searchingString == nil ? urlForGetPeeps(type: peepsFor, walletAddress: KeysService().selectedWallet()?.address, lastPeep: older ? peeps?.last : nil) : urlForSearchPeeps(searchingString: searchingString!, page: searchingPage)

        guard url != nil else {
            return
        }

        PeepsService().getPeeps(url: url!) { (receivedPeeps, error) in
            if (error != nil) {
                self.getPeepsList(older: older)
            } else {
                DispatchQueue.global().sync {
                    if receivedPeeps != nil {
                        if older {
                            self.peeps?.append(contentsOf: receivedPeeps!)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
//                            for peep in receivedPeeps! {
//                                DispatchQueue.main.async {
//                                    self.peeps?.append(peep)
//                                    self.tableView.beginUpdates()
//                                    //self.peeps?.append(peep)
//                                    let indexPath = IndexPath(row: (self.peeps?.count)!-2, section: 0)
//                                    self.tableView.insertRows(at: [indexPath], with: .top)
//                                    self.tableView.endUpdates()
//
//                                }
//
//                            }

                        } else {
                            DispatchQueue.main.async {
                                self.peeps = receivedPeeps
                                self.tableView.reloadData()
                            }
                        }

                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                        }

                    } else {
                        //TryAgain
                        self.getPeepsList(older: older)
                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3000), execute: {
                        self.animation.waitAnimation(isEnabled: false,
                                notificationText: nil,
                                selfView: self.view.viewWithTag(lastViewTag)!)
                        self.view.viewWithTag(lastViewTag)?.removeFromSuperview()
                    })

                }

                DispatchQueue.global().sync {
                    if receivedPeeps != nil {
                        self.getUsersAvatars(for: receivedPeeps)
                    }
                }

                DispatchQueue.global().sync {
                    if receivedPeeps != nil {
                        self.getAttachedImages(for: receivedPeeps)
                    }
                }

            }

        }
    }

    /*
     Get attached images for each user and reload its row
     */
    func getAttachedImages(for peeps: [ServerPeep]?) {
        for peep in peeps! {
            if let url = parseAttachedImageServerString(peep: peep) {
                if url != nil {
                    PeepsService().getDataFromUrl(url: url, completion: { (imageData, response, error) in
                        DispatchQueue.main.async {
                            if imageData != nil {
                                let row = (self.peeps)!.index(of: peep)
                                self.peeps![row!].info["attached_imageData"] = imageData
                                self.tableView.beginUpdates()
                                self.tableView.reloadRows(at: [[0, row!]], with: .none)
                                self.tableView.endUpdates()

                            }
                        }
                    })
                }
            }
        }
    }

    /*
     Get avatar for each user and reload its row
     */
    func getUsersAvatars(for peeps: [ServerPeep]?) {
        for peep in peeps! {
            if let url = parseImageServerString(peep: peep) {

                PeepsService().getDataFromUrl(url: url, completion: { (imageData, response, error) in
                    DispatchQueue.main.async {
                        if imageData != nil {
                            let row = (self.peeps)!.index(of: peep)
                            self.peeps![row!].info["avatar_imageData"] = imageData
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(at: [[0, row!]], with: .none)
                            self.tableView.endUpdates()
                        }
                    }
                })

            }
        }
    }

    @IBAction func search(_ sender: UIBarButtonItem) {
        search()
    }

    @objc func search() {
        let searchNavBar = UIBarButtonItem(customView: searchBar)
        let canceSearchNavBarButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelSearch))
        navigationItem.leftBarButtonItems = [searchNavBar, canceSearchNavBarButton]
        self.navigationItem.title = nil
    }

    @objc func cancelSearch() {
        self.tableView.setContentOffset(.zero, animated: true)
        self.searchingString = nil
        searchingPage = 1
        self.getPeepsList(older: false)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        let leftNavBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search(_:)))
        self.navigationItem.leftBarButtonItems = [leftNavBarButton]
        currentTab(identifier: self.restorationIdentifier)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let shareViewController = segue.destination as? SendPeepViewController {
            if chosenPeepHash != nil {
                shareViewController.shareHash = self.chosenPeepHash!
            }

        }
    }


}

extension PeepsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if peeps != nil {
            return peeps!.count
        } else {
            return 0
        }

    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeepCell", for: indexPath) as! PeepCell

        cell.peep = peeps![indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.default

        return cell
    }

    /*
     Get old peeps when scrolling
     */
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = contentHeight - frameHeight

        guard !(self.refreshControl.isRefreshing) else {
            return
        }

        DispatchQueue.global(qos: .utility).sync {
            if currentOffset / maximumOffset >= 2 / 3 {
                if searchingString != nil {
                    self.searchingPage += 1
                }
                self.getPeepsList(older: true)

            }
        }

    }

    /*
     Share feature
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        chosenPeepHash = peeps![indexPath.row].info["ipfs"] as? String

        showAlertSuccessTransaction()

    }

    func showAlertSuccessTransaction() {
        let alert = UIAlertController(title: "Choose Action",
                message: nil,
                preferredStyle: UIAlertControllerStyle.actionSheet)
        let shareAction = UIAlertAction(title: "Share", style: .default) { (action) in
            let strbrd: UIStoryboard = self.storyboard!
            let shareController: SendPeepViewController = strbrd.instantiateViewController(withIdentifier: "sendPeepViewController") as! SendPeepViewController
            shareController.shareHash = self.chosenPeepHash!
            self.chosenPeepHash = nil

            self.show(shareController, sender: self)
        }
        let parentAction = UIAlertAction(title: "Reply", style: .default) { (action) in
            let strbrd: UIStoryboard = self.storyboard!
            let shareController: SendPeepViewController = strbrd.instantiateViewController(withIdentifier: "sendPeepViewController") as! SendPeepViewController
            shareController.parentHash = self.chosenPeepHash!

            self.chosenPeepHash = nil

            self.show(shareController, sender: self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(shareAction)
        alert.addAction(parentAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }
}

extension PeepsListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text! != "" {
            self.tableView.setContentOffset(.zero, animated: true)
            self.searchingString = self.searchBar.text!
            self.searchingPage = 1
            self.getPeepsList(older: false)
        } else {
            self.tableView.setContentOffset(.zero, animated: true)
            self.searchingString = nil
            self.searchingPage = 1
            self.getPeepsList(older: false)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            cancelSearch()
        }
    }
}

extension PeepsListViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelSearch()
    }
}
