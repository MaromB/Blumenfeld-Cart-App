//
//  FirebaseService.swift
//  עגלת בלומנפלד
//
//  Created by מרום בלומנפלד on 07/12/2023.


import Foundation
import SwiftUI
import FirebaseDatabase

class FirebaseService: ObservableObject {
    @Published var items: [ShoppingItem] = []
    public var databaseReference: DatabaseReference?
    public var databaseHandel: DatabaseHandle?


    init() {
        configureDatabase()
    }

    func configureDatabase() {
        guard databaseReference == nil else {
            return
        }

        databaseReference = Database.database().reference().child("shoppingLists")
        observeItems()
    }
      
    
    func observeItems() {
        guard let databaseReference = databaseReference else {
            return
        }
        databaseReference.removeAllObservers()
                      
        databaseReference.observe(.value) { snapshot in
                     var newItems: [ShoppingItem] = []

            for categoryChild in snapshot.children {
                if let categorySnapshot = categoryChild as? DataSnapshot,
                   let _ = categorySnapshot.value as? [String: Any]{
                    for idSnapshot in categorySnapshot.children.allObjects as! [DataSnapshot] {
                        if let itemData = idSnapshot.value as? [String: Any] {
                            if let item = ShoppingItem(snapshotData: itemData) {
                                newItems.append(item)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                             self.items = newItems
                         }
        }
    }
     
    func addItem(_ item: ShoppingItem, inCategory category: Category) {
        let categoryReference = databaseReference?.child(category.rawValue)
        let itemId = item.id
        categoryReference?.child(itemId).setValue(item.toAnyObject())
    }
    
    func deleteItemFromDatabase(item: ShoppingItem, category: Category) {
        let categoryReference = databaseReference?.child(category.rawValue)
        let itemId = item.id
        categoryReference?.child(itemId).removeValue()
    }
   
    
}
