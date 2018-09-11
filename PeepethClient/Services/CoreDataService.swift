//
//  CoreDataService.swift
//  PeepethClient
//

import Foundation
import CoreData


class LocalDatabase {
    
    lazy var container: NSPersistentContainer = NSPersistentContainer(name: "CoreDataModel")
    private lazy var mainContext = self.container.viewContext
    
    init() {
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
        }
    }
    
    //You always get only the first wallet, because you can not have more then one in the app.
    func getWallet() -> KeyWalletModel? {
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let results = try mainContext.fetch(requestWallet)
            guard let result = results.first else { return nil }
            return KeyWalletModel.fromCoreData(crModel: result)
            
        } catch {
            print(error)
            return nil
        }
        
        
    }
    
    func walletHadBeenRegistered() {
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let results = try mainContext.fetch(requestWallet)
            guard let result = results.first else { return }
            result.isRegistered = true
            try mainContext.save()
            
        } catch {
            print(error)
            return 
        }
    }
    
    func isWalletRegistered() -> Bool {
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let results = try mainContext.fetch(requestWallet)
            guard let result = results.first else { return false }
            return result.isRegistered
            
        } catch {
            print(error)
            return false
        }
    }
    
    func saveWallet(isRegistered: Bool, wallet: KeyWalletModel, completion: @escaping (Error?)-> Void) {
        container.performBackgroundTask { (context) in
            guard let entity = NSEntityDescription.insertNewObject(forEntityName: "KeyWallet", into: context) as? KeyWallet else { return }
            entity.address = wallet.address
            entity.data = wallet.data
            entity.isRegistered = isRegistered
            do {
                try context.save()
                DispatchQueue.main.async {
                    completion(nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    func deleteWallet(completion: @escaping (Error?)-> Void) {
        
        let requestWallet: NSFetchRequest<KeyWallet> = KeyWallet.fetchRequest()
        
        do {
            let results = try mainContext.fetch(requestWallet)
            
            for item in results {
                mainContext.delete(item)
            }
            try mainContext.save()
            completion(nil)
            
        } catch {
            completion(error)
        }
    }
}
