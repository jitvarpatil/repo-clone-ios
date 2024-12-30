//
//  CameraHandler.swift
 
//
//  Created by CometChat Inc. on 23/10/19.
//  Copyright © 2022 CometChat Inc. All rights reserved.
//

import Foundation
import UIKit

class CameraHandler: NSObject{
    static let shared = CameraHandler()
    
    fileprivate weak var currentVC: UIViewController?
    
    //MARK: Internal Properties
    
    var imagePickedBlock: ((String) -> Void)?
    var videoPickedBlock: ((String) -> Void)?
    func presentCamera(for view: UIViewController){
        currentVC = view
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .camera
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
        
    }
    
    func presentPhotoLibrary(for view: UIViewController) {
        currentVC = view
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            myPickerController.mediaTypes = ["public.image", "public.movie"]
            currentVC?.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func showActionSheet(vc: UIViewController) {
        currentVC = vc
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { [weak self] (alert:UIAlertAction!) -> Void in
            guard let this = self else { return }
            this.presentPhotoLibrary(for: vc)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "CANCEL".localize(), style: .cancel, handler: nil))
        vc.view.tintColor = CometChatTheme_v4.palatte.primary
        vc.present(actionSheet, animated: true, completion: nil)
    }
}


extension CameraHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        switch picker.sourceType {
        case .photoLibrary:
            
            if let  videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
                self.videoPickedBlock?(videoURL.absoluteString ?? "")
            }
            
            if let imageURL = info[UIImagePickerController.InfoKey.imageURL] as? NSURL {
                self.imagePickedBlock?(imageURL.absoluteString ?? "")
            }
        case .camera:
            guard let image = info[.originalImage] as? UIImage else {
                return
            }
            saveImage(imageName: "image_\(Int(Date().timeIntervalSince1970 * 100)).png", image: image)
        case .savedPhotosAlbum:
            self.imagePickedBlock?("\(String(describing: info[UIImagePickerController.InfoKey.imageURL]!))")
        @unknown default:
            break
        }
        currentVC?.dismiss(animated: true, completion: nil)
    }
    
    func saveImage(imageName: String, image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
               
            } catch let removeError {
                print(removeError.localizedDescription)
            }
        }
        do {
            try data.write(to: fileURL)
            let path = self.getImagePathFromDiskWith(fileName: fileName)
            if let imagePath = path {
                self.imagePickedBlock?(imagePath.absoluteString)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    func getImagePathFromDiskWith(fileName: String) -> URL? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            return imageUrl
        }
        return nil
    }
    
}
