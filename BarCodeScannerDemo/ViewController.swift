//
//  ViewController.swift
//  BarCodeScannerDemo
//
//  Created by Ethan on 2020/7/18.
//  Copyright © 2020 Ethans. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var QRCodeImageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        textField.becomeFirstResponder()
        
        // Configure QRCode image
        QRCodeImageView.isUserInteractionEnabled = true
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressTriggered(_:)))
        longPressGestureRecognizer.delaysTouchesBegan = true
        QRCodeImageView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @IBAction func generateQRCode(_ sender: Any) {
        guard let text = textField.text else { return }
        let data = text.data(using: .isoLatin1)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transformed = CGAffineTransform(scaleX: QRCodeImageView.frame.width / 35,
                                                y: QRCodeImageView.frame.height / 35)
            let context = CIContext()
            // need to convert CIImage to CGImage or we can not save to camera roll
            // refernce -> https://stackoverflow.com/questions/44864432/saving-to-user-photo-library-silently-fails
            if let qrcodeImage = filter.outputImage?.transformed(by: transformed),
                let cgImage = context.createCGImage(qrcodeImage, from: qrcodeImage.extent) {
                QRCodeImageView.image = UIImage(cgImage: cgImage)
            }
        }
    }
    
    @IBAction func scanQRCode(_ sender: Any) {
        let alert = UIAlertController(title: "Choose the type you want to scan",
                                      message: nil, preferredStyle: .actionSheet)
        let scanQRCode = UIAlertAction(title: "QRCode", style: .default) { (_) in
            let scanVC = ScanViewController(withScanType: .qrCode)
            let navController = UINavigationController(rootViewController: scanVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
        
        let scanBarCode =  UIAlertAction(title: "BarCode", style: .default) { (_) in
            let scanVC = ScanViewController(withScanType: .barCode)
            let navController = UINavigationController(rootViewController: scanVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
        alert.addAction(scanQRCode)
        alert.addAction(scanBarCode)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func longPressTriggered(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let image = QRCodeImageView.image,
            image != UIImage(named: "QRCodeImagePlaceholder"),
            gestureRecognizer.state == .began else { return }

        if gestureRecognizer.state == .began {
            let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            let saveToAlbumAction = UIAlertAction(title: "Yes", style: .default) { (_) in
                let authorizationStatus = PHPhotoLibrary.authorizationStatus()
                switch authorizationStatus {
                case .notDetermined:
                    PHPhotoLibrary.requestAuthorization { (status) in
                        if status == .authorized {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }
                case .authorized:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                case .denied, .restricted:
                    let cameraAccessDeniedAlert = UIAlertController(title: "Camera Access Denied", message: "Camera is not enabled. Please go to \"Settings\" on your phone to enable Camera for this app", preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                    cameraAccessDeniedAlert.addAction(okayAction)
                    self.present(cameraAccessDeniedAlert, animated: true, completion: nil)
                    return
                @unknown default:
                    fatalError("PHPhotoLibrary has new authorization status!!")
                }
            }
            
            let saveToAlbumAlert = UIAlertController(title: nil, message: "Would you like to save this QR Code to your album?", preferredStyle: .alert)
            saveToAlbumAlert.addAction(cancelAction)
            saveToAlbumAlert.addAction(saveToAlbumAction)
            present(saveToAlbumAlert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
