//
//  CameraCaptureView.swift
//  BlumenfeldCartApp
//
//  Created by מרום בלומנפלד on 11/12/2023.
//

import SwiftUI
import Foundation
import AVFoundation


struct CameraCaptureView: View {
    @Binding var image: UIImage?
    @StateObject var camera: CameraModel
        
        // Create an init method
        init(image: Binding<UIImage?>) {
            _image = image
            _camera = StateObject(wrappedValue: CameraModel(image: image.wrappedValue))
        }
        
    var body: some View{
        
        
        ZStack{
            CameraPreview(camera: camera).ignoresSafeArea(.all, edges: .all)
            
            VStack{
                
                Spacer()
                HStack{
                    if camera.isTaken{
                        HStack{
                            
                            Button(action: {}, label: {
                                Text("שמור")
                                    .foregroundColor(.black)
                                    .fontWeight(.semibold)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            })
                            .padding(.trailing, 80)
                            
                            Button(action: {camera.reTake()}, label: {
                                Text("ביטול")
                                    .foregroundColor(.black)
                                     .fontWeight(.semibold)
                                    .padding(.vertical,10)
                                    .padding(.horizontal,20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            })
                            
                        }
                    }else{
                        Button(action: {camera.takePic()}, label: {
                            ZStack{
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                                                                                    
                            }
                                            
                        })
                    }
                    
                    
                } .frame(height: 75)
                    .padding(20)
                
            }
            
        }
        .onAppear(perform: {
            camera.Check()
        })
        
    }
 
 }
 

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    @Published var image: UIImage?
    @Published var imageData = Data()
    
    init(image: UIImage?) {
        self.image = image
    }
    
    func Check(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ (status) in
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            
        default:
            return
            
        }
    }
    
    
    func setUp(){
            do{
                self.session.beginConfiguration()
                let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
                
                let input = try AVCaptureDeviceInput(device: device!)
                
                if self.session.canAddInput(input){
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.output){
                    self.session.addOutput(self.output)
                }
                
                self.session.commitConfiguration()
                
            }catch{
                print(error.localizedDescription)
            }
        }
    
    func takePic(){
        
        DispatchQueue.global(qos: .background).async {
            let photoSettings = AVCapturePhotoSettings()
            self.output.capturePhoto(with: photoSettings, delegate: self)
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                withAnimation{
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        if error != nil{
            return
        }
        print("תמונה נלקחה.")
        
        imageData = photo.fileDataRepresentation()!
        
        image = UIImage(data: self.imageData)
        
    }
    
    func reTake(){
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation{
                    self.isTaken.toggle()
                }
            }
            
        }
        
    }
        
}


struct CameraPreview: UIViewRepresentable{
    
    @ObservedObject var camera : CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        camera.session.startRunning()
        
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}
    
    
    
