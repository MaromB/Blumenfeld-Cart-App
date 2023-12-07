import SwiftUI
import Firebase
import FirebaseDatabase
import UIKit



struct ContentView: View {
    @State private var selectedName: Name = .לחץ
    @State private var isWelcomeScreenPresented = false
    @StateObject private var shoppingList = FirebaseService()
    
    var body: some View {
        NavigationView {
                if !isWelcomeScreenPresented {
                    WelcomeView(selectedName: $selectedName, isWelcomeScreenPresented: $isWelcomeScreenPresented)
                } else {
                    ShoppingListView(shoppingList: shoppingList, selectedName: $selectedName)
                        .frame(height: 1000.0)
                        .offset(y: -100)
                }
            }
        .onAppear {
                    shoppingList.configureDatabase()
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
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .padding(20)
            
            Text("בחר את עצמך מתוך הרשימה:")
                .fontWeight(.regular)
                .multilineTextAlignment(.leading)
                .padding(20)
            
            Picker("", selection: $selectedName) {
                ForEach(Name.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
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


struct ShoppingListView: View {
    @ObservedObject var shoppingList: FirebaseService
    @Binding var selectedName: Name
    @State private var newItem = ""
    @State private var newItemCategory = Category.dry
    @State private var newItemImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(Category.allCases, id: \.self) { category in
                        Section(header: Text(category.localizedString)) {
                            ForEach(filteredItems(for: category)) { item in
                                ShoppingItemRow(item: item)
                            }
                            .onDelete(perform: deleteItems).frame(height: 55.0)
                        }
                    }
                }

                VStack(spacing: 12) {
                    TextField("הקלד שם פריט...", text: $newItem)
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
                            if !newItem.isEmpty {
                                let newItem = ShoppingItem(name: newItem, addedBy: selectedName, category: newItemCategory, image: newItemImage)
                                shoppingList.items.append(newItem)
                                resetFields()
                            }
                        }.padding(.trailing, 50.0)
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "photo")
                        }
                    }
                    .padding(.top)
                }
                .padding()

            }
            .environment(\.layoutDirection, .rightToLeft)
            .padding()
            .navigationBarTitle("עגלת קניות - בלומנפלד", displayMode: .inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $newItemImage, isPresented: $showImagePicker)
            }
        }
    }

    private func filteredItems(for category: Category) -> [ShoppingItem] {
        return shoppingList.items.filter { $0.addedBy == selectedName && $0.category == category }
    }

    private func deleteItems(at offsets: IndexSet) {
        shoppingList.items.remove(atOffsets: offsets)
    }

    private func resetFields() {
        newItem = ""
        newItemCategory = .dry
        newItemImage = nil
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    @State private var isImageFullScreen = false

    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: -10) {
                Text(item.name)
                    .font(.headline)
                
                Text("\n נוסף על ידי: \(item.addedBy.rawValue)")
                    .font(.subheadline)
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

