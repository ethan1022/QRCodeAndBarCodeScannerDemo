//
//  ScanViewController.swift
//  BarCodeScannerDemo
//
//  Created by Ethan on 2020/7/18.
//  Copyright © 2020 Ethans. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: ScanViewBaseController, ScanViewBaseControllerDelegate {
    
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var keepScanButton: UIButton!
    
    var scanType: ScanType
    
    init(withScanType scanType: ScanType) {
        self.scanType = scanType
        super.init(nibName: "ScanViewController", bundle: nil)
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keepScanButton.isEnabled = false
        
        let dismissButton = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(dissmissVC))
        navigationItem.leftBarButtonItem = dismissButton
    }
    
    func metadataOutput(_ output: AVMetadataMachineReadableCodeObject) {
        guard let resultStringValue = output.stringValue else { return }
        textView.text = resultStringValue
        keepScanButton.isEnabled.toggle()
    }

    @IBAction func tapKeepScan(_ sender: Any) {
        captureSessionStartRunning()
        keepScanButton.isEnabled.toggle()
        textView.text = "The result of scan will show here!!"
    }
    
    @objc func dissmissVC() {
        dismiss(animated: true, completion: nil)
    }
}
