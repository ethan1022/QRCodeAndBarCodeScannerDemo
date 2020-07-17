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
    }
    
    func metadataOutput(_ output: AVMetadataMachineReadableCodeObject) {
        guard let resultStringValue = output.stringValue else { return }
        print(resultStringValue)
    }

}
