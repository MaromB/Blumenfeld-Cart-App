import SwiftUI
import Firebase
import FirebaseDatabase
import UIKit
import Foundation



struct ContentView: View {
    @State private var selectedName: Name = .לחץ
    @State private var isWelcomeScreenPresented = false
    @StateObject private var firebaseService = FirebaseService()
    
    var body: some View {
        NavigationView {
                if !isWelcomeScreenPresented {
                    WelcomeView(selectedName: $selectedName, isWelcomeScreenPresented: $isWelcomeScreenPresented)
                } else {
                    shoppingListView(firebaseService: firebaseService, selectedName: $selectedName)
                        .frame(height: 1000.0)
                        .offset(y: -100)
                }
            }
        .onAppear {
                    firebaseService.configureDatabase()
                }
        }
    }


struct WelcomeView: View {
    @Binding var selectedName: Name
    @Binding var isWelcomeScreenPresented: Bool
    @State private var showAlert = false
        
    var body: some View {
        VStack {
            Image("food_logo")
                .resizable()
                .frame(width: 250, height: 300)
                .cornerRadius(30)
            
            Text("עגלת הקניות של \n משפחת בלומנפלד")
                .font(.title)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .padding(20)
            
            Text("בחר את עצמך מתוך הרשימה:")
                .font(.title2)
                .fontWeight(.regular)
                .multilineTextAlignment(.leading)
                .padding(20)
            
            Picker("", selection: $selectedName) {
                ForEach(Name.allCases, id: \.self) {
                    Text($0.rawValue).font(.title).fontWeight(.heavy).tag($0)
                }
            }.padding()
            
            Button("המשך") {
                if selectedName == .לחץ{
                    showAlert = true
                }
                else{
                    isWelcomeScreenPresented = true
                    }
            }.alert(isPresented: $showAlert) {
                Alert(
                    title: Text("בבקשה בחר משתמש"),
                    message: Text("אתה חייב לבחור משתמש מתוך הרשימה על מנת להמשיך"),
                    dismissButton: .default(Text("OK"))
                    )
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "isFirstLaunch") {
                UserDefaults.standard.set(false, forKey: "isFirstLaunch")
            } else {
                isWelcomeScreenPresented = false
            }
        }
    }
}


struct shoppingListView: View {
    @ObservedObject var firebaseService = FirebaseService()
    @Binding var selectedName: Name
    @State private var newItemName  = ""
    @State private var newItemCategory = Category.dry
    @State private var newItemImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(Category.allCases, id: \.self) { category in
                        Section(header: Text(category.localizedString)) {
                            ForEach(filteredItems(for: category), id: \.id) { item in
                                ShoppingItemRow(item: item, selectedName: $selectedName)
                            }
                            .onDelete { indexSet in
                                deleteItems(at: indexSet, category: category)
                            }
                        }
                    }
                    .frame(height: 30.0)
                }
                
                VStack(spacing: 12) {
                    TextField("הקלד את שם הפריט...", text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 5.0)
                    
                    Picker("Category", selection: $newItemCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.localizedString).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack(spacing: 12) {
                        Button("הוסף פריט") {
                            if !newItemName.isEmpty {
                                if let imageData = newItemImage?.jpegData(compressionQuality: 1.0) {
                                    let base64Image = imageData.base64EncodedString()
                                    let newItem = ShoppingItem(name: newItemName, addedBy: selectedName, category: newItemCategory, imageData: base64Image)
                                    firebaseService.addItem(newItem, inCategory: newItemCategory)
                                    resetFields()
                                }
                                else{
                                    let newItem = ShoppingItem(name: newItemName, addedBy: selectedName, category: newItemCategory, imageData: "")
                                    firebaseService.addItem(newItem, inCategory: newItemCategory)
                                    resetFields()
                                }
                            }
                        }.padding(.trailing, 50.0)
                        Menu {
                            Button("העלה תמונה מאלבום"){
                                showImagePicker = true
                            }
                            Button("צלם תמונה"){
                                showCameraPicker = true
                            }

                        }label: {
                            Image(systemName: "photo")
                        }
                    }
                    .padding(.top)
                }
                .padding()
                
            }
            .environment(\.layoutDirection, .rightToLeft)
            .padding()
            .navigationBarTitle("Shopping Cart - Blumenfeld", displayMode: .inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $newItemImage, isPresented: $showImagePicker)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraCaptureView(image: $newItemImage)
            }
        }
    }
    
    
    func filteredItems(for category: Category) -> [ShoppingItem] {
        return firebaseService.items.filter { $0.category == category }
    }
    
    func deleteItemLocally(item: ShoppingItem) {
        if let index = firebaseService.items.firstIndex(where: { $0.id == item.id }) {
            firebaseService.items.remove(at: index)
        }
    }
    
    func deleteItems(at indices: IndexSet, category: Category) {
        let itemsToDelete = indices.compactMap { index in
            filteredItems(for: category)[index]
        }

        for item in itemsToDelete {
            deleteItemLocally(item: item)
            firebaseService.deleteItemFromDatabase(item: item, category: category)
        }
    }
    

    private func resetFields() {
        newItemName  = ""
        newItemCategory = .dry
        newItemImage = nil
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    @Binding var selectedName: Name
    @State private var isImageFullScreen = false
    @State private var showAlert = false
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: item.dateAdded)
    }

    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: -10) {
                if selectedName.rawValue == "מורדי" || selectedName.rawValue == "מירב"{
                    Text(item.name)
                        .font(.title).fontWeight(.heavy).onTapGesture {
                            showAlert = true
                        }
                }else{
                    Text(item.name)
                        .font(.headline).fontWeight(.medium).onTapGesture {
                            showAlert = true
                        }
                }
                

            }.alert(isPresented: $showAlert) {
                Alert(
                    title: Text("מידע"),
                    message: Text("הפריט נוסף על ידי \(item.addedBy.rawValue) בתאריך ֿֿ\(formattedDate)"),
                    dismissButton: .default(Text("OK"))
                    )
            }
            Spacer()
            
            if let imageData = item.imageData,
               let image = UIImage(data: Data(base64Encoded: imageData)!) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        isImageFullScreen.toggle()
                    }
            }
        }
        .fullScreenCover(isPresented: $isImageFullScreen) {
            if let imageData = item.imageData,
                          let image = UIImage(data: Data(base64Encoded: imageData)!) {
                FullScreenImageView(image: image, isImageFullScreen: $isImageFullScreen)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

