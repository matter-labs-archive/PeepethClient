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
    let peepsService = PeepsService()
    var peeps: [ServerPeep]?

    var chosenPeepHash: String?

    var peepsFor: peepsFor = .global {
        didSet {
            peepsNumber = peeps?.count
        }
    }

    var searchingString: String?
    var searchingPage = 1
    var arePeepsLoading: Bool = false
    var peepsNumber: Int?

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

                            case .Error:
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
        tableView.prefetchDataSource = self
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
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.white
        searchBar.tintColor = UIColor.darkText
        definesPresentationContext = true
        searchBar.placeholder = "Your placeholder"

    }

    @objc private func refreshTableData(_ sender: Any) {
        DispatchQueue.cancelPreviousPerformRequests(withTarget: self)
        getPeepsList(older: false)
    }

    func getPeepsList(older: Bool, indexPaths: [IndexPath]? = nil) {
        if !self.arePeepsLoading {
            self.arePeepsLoading = true
            let url = searchingString == nil ? urlForGetPeeps(type: peepsFor, walletAddress: KeysService().selectedWallet()?.address, lastPeep: older ? peeps?.last : nil) : urlForSearchPeeps(searchingString: searchingString!, page: searchingPage)

            guard url != nil else {
                return
            }

            peepsService.getPeeps(url: url!) { (receivedPeeps, error) in
                if error != nil {
                    // MARK: - try again
                    self.getPeepsList(older: older)
                } else {
                    // MARK: - If there is no more peeps to load,
                    //              peeps number becomes stable.
                    if receivedPeeps?.count == 0 {
                        self.peepsNumber = self.peeps?.count
                    }
                    if receivedPeeps != nil {
                        if older {
                            self.peeps?.append(contentsOf: receivedPeeps!)
                            self.tableView.reloadData()
                        } else {
                            self.peeps = receivedPeeps
                            self.tableView.reloadData()
                        }
                        self.refreshControl.endRefreshing()
                        self.getUsersAvatars(for: receivedPeeps)
                        self.getAttachedImages(for: receivedPeeps)
                        self.arePeepsLoading = false

                    } else {
                        //TryAgain
                        self.getPeepsList(older: older, indexPaths: indexPaths)
                        self.refreshControl.endRefreshing()
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
                PeepsService().getDataFromUrl(url: url, completion: { (imageData, _, _) in
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

    /*
     Get avatar for each user and reload its row
     */
    func getUsersAvatars(for peeps: [ServerPeep]?) {
        for peep in peeps! {
            if let url = parseImageServerString(peep: peep) {
                peepsService.getDataFromUrl(url: url, completion: { (imageData, _, _) in
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
        peepsNumber = nil
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

// MARK: - TableView
extension PeepsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peepsNumber ?? (peeps?.count ?? 0) + 20
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeepCell", for: indexPath) as! PeepCell
        guard peeps?.count ?? indexPath.row > indexPath.row else { return cell }
        cell.peep = peeps![indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.default

        return cell
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
        let shareAction = UIAlertAction(title: "Share", style: .default) { (_) in
            let strbrd: UIStoryboard = self.storyboard!
            let shareController: SendPeepViewController = strbrd.instantiateViewController(withIdentifier: "sendPeepViewController") as! SendPeepViewController
            shareController.shareHash = self.chosenPeepHash!
            self.chosenPeepHash = nil

            self.show(shareController, sender: self)
        }
        let parentAction = UIAlertAction(title: "Reply", style: .default) { (_) in
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

// MARK: - Search
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

// MARK: - Prefetching
extension PeepsListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.last?.row ?? 0 > peeps?.count ?? 0 {
            self.getPeepsList(older: true)
        }
    }
}
