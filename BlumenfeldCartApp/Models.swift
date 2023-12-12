//
//  Models.swift
//  עגלת בלומנפלד
//
//  Created by מרום בלומנפלד on 07/12/2023.
//

import Foundation
import SwiftUI
import FirebaseDatabase


enum Name: String, CaseIterable, Codable {
    case לחץ, מורדי, מירב, מרום, נוי, מאי, שיר, רותם
}

enum Category: String, CaseIterable, Codable {
    case dry, vegetablesFruits, chilled, floor_2, subri
    var localizedString: String {
            switch self {
            case .dry:
                return NSLocalizedString("יבש", comment: "Dry category")
            case .vegetablesFruits:
                return NSLocalizedString("ירקות/פירות", comment: "Vegetables/Fruits category")
            case .chilled:
                return NSLocalizedString("מקרר", comment: "Chilled category")
            case .floor_2:
                return NSLocalizedString("קומה 2", comment: "floor_2 category")
            case .subri:
                return NSLocalizedString("סברי", comment: "subri category")
            }
        }
}

struct ShoppingItem: Identifiable {
    let id: String
    let name: String 
    let addedBy: Name
    let category: Category
    var imageData: String?
    let dateAdded: Date
    
    init(name: String, addedBy: Name, category: Category, imageData: String?) {
        let uuid = UUID()
        self.id =  uuid.uuidString  // Generate a new UUID for each item
        self.name = name
        self.addedBy = addedBy
        self.category = category
        self.dateAdded = Date()
        if let imageData = imageData {
                    self.imageData = encodeAndCompressImage(imageData)
                } else {
                    self.imageData = nil
                }
    }
    
    init(id: String, name: String, addedBy: Name, category: Category, imageData: String?, dateAdded: Date) {
        self.id = id
        self.name = name
        self.addedBy = addedBy
        self.category = category
        self.dateAdded = dateAdded
        if let imageData = imageData {
                    self.imageData = encodeAndCompressImage(imageData)
                } else {
                    self.imageData = nil
                }
    }


    init?(snapshotData: [String: Any]) {
        guard
            let name = snapshotData["name"] as? String,
            let addedByRawValue = snapshotData["addedBy"] as? String,
            let addedBy = Name(rawValue: addedByRawValue),
            let categoryRawValue = snapshotData["category"] as? String,
            let category = Category(rawValue: categoryRawValue),
            let imageData = snapshotData["imageData"] as? String,
            let dateAddedTimestamp = snapshotData["dateAdded"] as? TimeInterval
        else {
            print("Failed to extract information from snapshot data.")
            return nil
        }

        if let id = snapshotData["id"] as? String{
                // Initialize with the provided id
                self.init(id: id, name: name, addedBy: addedBy, category: category, imageData: imageData, dateAdded: Date(timeIntervalSince1970: dateAddedTimestamp))
            } else {
                // Generate a new UUID if id is not provided
                self.init(name: name, addedBy: addedBy, category: category, imageData: imageData)
            }
    }

    func toAnyObject() -> Any {
        print("Image Data: \(imageData ?? "nil")")
        
        return [
            "id": id,
            "name": name,
            "addedBy": addedBy.rawValue,
            "category": category.rawValue,
            "imageData": imageData ?? "",
            "dateAdded": dateAdded.timeIntervalSince1970
        ]
    }

    var uiImage: UIImage? {
        if let imageData = imageData, let data = Data(base64Encoded: imageData) {
            return UIImage(data: data)
        }
        return nil
    }

    private func encodeAndCompressImage(_ imageData: String?) -> String? {
        // This method should convert base64-encoded string to compressed base64-encoded string
        guard let imageData = imageData, let data = Data(base64Encoded: imageData),
              let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: 0.1)
        else {
            return nil
        }
        return compressedData.base64EncodedString()
    }
           
}
