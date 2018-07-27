//
//  PeepsListViewController.swift
//  PeepethClient
//

import UIKit
import web3swift

class PeepsListViewController: UIViewController {
    
    enum controllerTypes: String {
        case user = "https://peepeth.com/account_peeps?address="
        case global = "https://peepeth.com/get_peeps"
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peepOrRegButton: UIBarButtonItem!
    
    let web3service: Web3swiftService = Web3swiftService()
    
    let animation = AnimationController()
    
    let refreshControl = UIRefreshControl()
    let localDatabase = LocalDatabase()
    var peeps: [ServerPeep]?
    
    var shareHash: String? = nil
    
    var controllerType: controllerTypes = .global
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        shareHash = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Check if account registered in core data
        if localDatabase.isWalletRegistered() {
            self.initWithRegisteredAcc()
            
        } else {
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
                                    self.peepOrRegButton.isEnabled = false
                                    self.tabBarController?.selectedIndex = 2
                                    self.showEnterAlert()
                                }
                                
                            case .Error(let _):
                                self.peepOrRegButton.isEnabled = false
                                self.tabBarController?.selectedIndex = 2
                                self.showEnterAlert()
                            }
                            
                        })
                    } else {
                        self.peepOrRegButton.isEnabled = false
                        self.tabBarController?.selectedIndex = 2
                        self.showEnterAlert()
                    }
                }
                
            })
        }
    }
    
    //Init full functionality
    func initWithRegisteredAcc() {
        self.tabBarController?.selectedIndex = 1
        switch self.restorationIdentifier {
        case "UserPeepsListViewController":
            controllerType = .user
            navigationItem.title = "Your Peeps"
        case "GlobalPeepsListViewController" :
            controllerType = .global
            navigationItem.title = "Global Peeps"
        default:
            controllerType = .global
            navigationItem.title = "Global Peeps"
        }
        
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func refreshTableData(_ sender: Any) {
        getPeepsList(older: false)
    }
    
    func getPeepsList(older: Bool) {
        var url: String? = nil
        switch controllerType {
        case .user:
            guard let walletAddress = KeysService().selectedWallet()?.address else { return }
            let basicUrl: String = controllerType.rawValue + walletAddress.lowercased()
            let olderUrl: String = older ? "&oldest=\(peeps?.last!.info["ipfs"]! as! String)" : ""
            url = basicUrl + olderUrl
        case .global:
            let basicUrl: String = controllerType.rawValue + "?you=0x832a630b949575b87c0e3c00f624f773d9b160f4"
            let olderUrl: String = older ? "&oldest=\(peeps?.last!.info["ipfs"]! as! String)" : ""
            url = basicUrl + olderUrl
        }
        
        guard url != nil else {
            return
        }
        
        if !refreshControl.isRefreshing {
            animation.waitAnimation(isEnabled: true, notificationText: "Getting peeps", selfView: tableView)
        }
        
        PeepsService().getPeeps(urlString: url!){ (receivedPeeps, error) in
            if (error != nil) {
                self.getPeepsList(older: older)
            } else {
                DispatchQueue.main.async {
                    if receivedPeeps != nil {
                        if older {
                            for peep in receivedPeeps! {
                                self.tableView.beginUpdates()
                                self.peeps?.append(peep)
                                let indexPath = IndexPath(row: (self.peeps?.count)!-2, section: 0)
                                self.tableView.insertRows(at: [indexPath], with: .top)
                                self.tableView.endUpdates()
                            }
                            
                        } else {
                            self.peeps = receivedPeeps
                            self.tableView.reloadData()
                        }
                        
                        //Download avatars
                        DispatchQueue.main.async {
                            self.getUsersAvatars(for: receivedPeeps)
                        }
                        
                        self.refreshControl.endRefreshing()
                        
                    } else {
                        self.getPeepsList(older: older)
                        self.refreshControl.endRefreshing()
                    }
                    self.animation.waitAnimation(isEnabled: false, notificationText: nil, selfView: self.tableView)
                }
                
            }
            
        }
    }
    
    /*
     Get avatar for each user and reload its row
     */
    func getUsersAvatars(for peeps: [ServerPeep]?) {
        for peep in peeps! {
            if let fullUrlString = parseImageServerString(urlString: peep.info["avatarUrl"] as? String) {
                
                if let avatarUrl = URL(string: fullUrlString) {
                    PeepsService().getDataFromUrl(url: avatarUrl, completion: { (imageData, response, error) in
                        DispatchQueue.main.async {
                            if imageData != nil {
                                let row = (self.peeps)!.index(of: peep)
                                self.peeps![row!].info["avatar_imageData"] = imageData
                                self.tableView.reloadRows(at: [[0, row!]], with: .none)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func parseImageServerString(urlString: String?) -> String? {
        var fullUrlString: String? = nil
        if let parsedString = (urlString)?.components(separatedBy: ":") {
            let serverString: String = parsedString.count > 0 ? parsedString[0] : ""
            let nameString: String = parsedString.count > 1 ? parsedString[1] : ""
            let extString: String = parsedString.count > 2 ? parsedString[2] : ""
            fullUrlString = "https://\(serverString).s3-us-west-1.amazonaws.com/images/avatars/\(nameString)/small.\(extString)"
        }
        return fullUrlString
    }
    
    @IBAction func exitAccount(_ sender: UIBarButtonItem) {
        localDatabase.deleteWallet { (error) in
            if error == nil {
                let viewController = self.storyboard?.instantiateViewController(withIdentifier: "enterController") as! EnterViewController
                self.present(viewController, animated: false, completion: nil)
            } else {
                self.showErrorAlert(error: error)
            }
        }
        
    }
    
    func showErrorAlert(error: Error?) {
        animation.waitAnimation(isEnabled: false, notificationText: nil, selfView: self.view)
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showEnterAlert() {
        let alert = UIAlertController(title: "Registration", message: "Add funds to your wallet and register in Peepeth. All you need for registration is in the Settings tab", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let shareViewController = segue.destination as? SendPeepViewController {
            if shareHash != nil {
                shareViewController.shareHash = self.shareHash!
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
            if currentOffset/maximumOffset >= 2/3 {
                self.getPeepsList(older: true)
                
            }
        }
        
    }
    
    /*
     Share feature
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        shareHash = peeps![indexPath.row].info["ipfs"] as? String
        
        let strbrd: UIStoryboard = self.storyboard!
        let shareController: SendPeepViewController = strbrd.instantiateViewController(withIdentifier: "sendPeepViewController") as! SendPeepViewController
        shareController.shareHash = self.shareHash!
        
        self.show(shareController, sender: self)
    }
    
    
}
