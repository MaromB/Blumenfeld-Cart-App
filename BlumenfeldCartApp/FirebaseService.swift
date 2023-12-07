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
    private var databaseReference: DatabaseReference?

    init() {
        configureDatabase()
    }

    func configureDatabase() {
        databaseReference = Database.database().reference().child("shoppingLists")
        observeItems()
    }

    private func observeItems() {
        databaseReference?.observe(.value, with: { snapshot in
            var newItems: [ShoppingItem] = []

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let item = ShoppingItem(snapshot: snapshot) {
                    newItems.append(item)
                }
            }

            self.items = newItems
        })
    }

    func addItem(_ item: ShoppingItem) {
        let itemReference = databaseReference?.childByAutoId()
        itemReference?.setValue(item.toAnyObject())
    }
}
