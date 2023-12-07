//
//  Models.swift
//  עגלת בלומנפלד
//
//  Created by מרום בלומנפלד on 07/12/2023.
//

import Foundation
import SwiftUI
import FirebaseDatabase


enum Name: String, CaseIterable {
    case  לחץ, מורדי, מירב, מרום, נוי, מאי, שיר, רותם
}

enum Category: String, CaseIterable {
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
    let id = UUID()
    let name: String
    let addedBy: Name
    let category: Category
    var imageData: String? // Base64-encoded image data
    var isImageFullScreen = false

    init(name: String, addedBy: Name, category: Category, image: UIImage?) {
        self.name = name
        self.addedBy = addedBy
        self.category = category

        if let image = image {
            // Convert the UIImage to Data and then to a Base64-encoded string
            let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
            self.imageData = imageData
        } else {
            self.imageData = nil
        }
    }

    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: Any],
            let name = value["name"] as? String,
            let addedByRawValue = value["addedBy"] as? String,
            let addedBy = Name(rawValue: addedByRawValue),
            let categoryRawValue = value["category"] as? String,
            let category = Category(rawValue: categoryRawValue),
            let imageData = value["imageData"] as? String
        else {
            return nil
        }

        self.name = name
        self.addedBy = addedBy
        self.category = category
        self.imageData = imageData
    }

    func toAnyObject() -> Any {
        return [
            "name": name,
            "addedBy": addedBy.rawValue,
            "category": category.rawValue,
            "imageData": imageData ?? ""
        ]
    }

    var uiImage: UIImage? {
        guard let imageData = imageData else {
            return nil
        }
        return UIImage(data: Data(base64Encoded: imageData)!)
    }
}
