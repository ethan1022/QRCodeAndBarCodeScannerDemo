//
//  ScanViewController.swift
//  BarCodeScannerDemo
//
//  Created by Ethan on 2020/7/18.
//  Copyright © 2020 Ethans. All rights reserved.
//

import UIKit
import AVFoundation

enum QRCodeMode: Int {
    case numeric = 1
    case alphanumeric = 2
    case structuredAppend = 3
    case byte = 4
    case fnc1InFirstPosition = 5
    case eci = 7
    case chineseCharacter = 8
    case fnc1InSecondPosition = 9
    case endOfMessage = 0
}

class ScanViewController: ScanViewBaseController, ScanViewBaseControllerDelegate {
    
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var keepScanButton: UIButton!
    
    var isScanSplitQRCode = false
    var splitQRCodeParity: NSNumber?
    var scanResultDic = [Int: String]()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanResultDic = [Int: String]()
        splitQRCodeParity = nil
        isScanSplitQRCode = false
    }

    @IBAction func tapKeepScan(_ sender: Any) {
        captureSessionStartRunning()
        keepScanButton.isEnabled.toggle()
        textView.text = "The result of scan will show here!!"
    }
    
    @objc func dissmissVC() {
        dismiss(animated: true, completion: nil)
    }
    
    // ScanViewBaseControllerDelegate
    func metadataOutput(_ output: AVMetadataMachineReadableCodeObject) {
        guard let descriptor = output.descriptor as? CIQRCodeDescriptor else {
            debugPrint("cast to CIQRCodeDescriptor failed")
            showQRCodeErrorAlert()
            return
        }

        guard let resultString = output.stringValue else {
            debugPrint("stringValue in output is nil!")
            showQRCodeErrorAlert()
            return
        }
        
        decodeSpliteQRCode(with: descriptor, resultString: resultString)
        keepScanButton.isEnabled.toggle()
    }
    
    // Helper methods
    private func decodeSpliteQRCode(with descriptor: CIQRCodeDescriptor, resultString: String) {
        let supportedModes: [QRCodeMode] = [.structuredAppend, .byte]
        /*
        如果Split QR code是依照Structured appending featurd來製作的話，resultMetadata就會有數值，其中最重要的數值有"sequence"和"parity"，sequence表示的是Split QR code的順序，parity則代表同一組QRC code的ID，如果要知道現在是第幾張(current)以及總共有幾張(total)，必須進行二進位的換算。
        */
        var binary = Binary(data: descriptor.errorCorrectedPayload)
        let modeBitsLength = 4 // 每一次會擷取的長度
        guard binary.bitsWithInternalOffsetAvailable(modeBitsLength) else { return } // 確定binary的長度
        let modeBits = binary.next(bits: modeBitsLength)
        guard let mode = QRCodeMode(rawValue: modeBits), supportedModes.contains(mode) else {
            debugPrint("wrong qrcode mode or unsupported!")
            return
        }
        switch mode {
        case .structuredAppend:
            isScanSplitQRCode = true
            let currentPosition = binary.next(bits: modeBitsLength) + 1
            let totalCount = binary.next(bits: modeBitsLength) + 1
            let parity = binary.next(bits: modeBitsLength * 2)
            parseResult(resultString, currentPosition: currentPosition, totalCount: totalCount, parity: NSNumber(value: parity))
        case .byte:
            /*
            如果Split QR code是依照JAHIS specification 來製作的話，每一張QR Code最後的數值就會以911開頭的數字提供相關資料，例如 911,12345678901234,2,1，意思是 911,資料ID,總共有幾張QRCode,現在是第幾張QRCode
            */
            if resultString.contains("911") {
                guard let (totalCount, currentPosition, parity) = parseJAHISQRcodeContent(resultString) else {
                    // showQRCodeErrorAlert()
                    return
                }
                isScanSplitQRCode = true
                parseResult(resultString, currentPosition: currentPosition, totalCount: totalCount, parity: parity)
            } else {
                if isScanSplitQRCode {
                    // 代表之前掃過Split QR Code的一部分，第二次掃錯或是掃失敗
                    debugPrint("error! scan other split QR Code or scan failed")
                    let alert = UIAlertController(title: "QRCode decode failed", message: nil, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Close", style: .default) { (_) in
                        self.dissmissVC()
                    }
                    alert.addAction(okAction)
                    present(alert, animated: true, completion: nil)
                } else {
                    // 表示不是split QR code
                    textView.text = resultString
                }
            }
        default: return
        }
    }
    
    private func parseResult(_ resultString: String, currentPosition: Int, totalCount: Int, parity: NSNumber) {
        if splitQRCodeParity == nil {
            splitQRCodeParity = parity
        }

        scanResultDic[currentPosition] = resultString
        if splitQRCodeParity == parity {
            if scanResultDic.keys.count != totalCount {
                // 代表資料還不齊全，提醒再掃其他資料
                debugPrint("please scan another QR Code")
                let alert = UIAlertController(title: "Please scan next QRCode", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Close", style: .default) { (_) in
                    self.captureSessionStartRunning()
                }
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            } else {
                // 掃完資料，組合資料，清空資料
                debugPrint("finish scaning QR Code get all data")
                var allResult = ""
                for index in 0 ..< scanResultDic.keys.count where scanResultDic[index] != nil {
                    allResult += scanResultDic[index]!
                }
                textView.text = allResult
            }
        } else {
            // 掃到其他Split QR Code，再來一次
            debugPrint("error! scan other split QR Code")
            showQRCodeErrorAlert()
        }
    }
    
    private func parseJAHISQRcodeContent(_ result: String) -> (totalCount: Int, currentPosition: Int, parity: NSNumber)? {
        guard let jahisCode = result.components(separatedBy: "\n").last else {
            debugPrint("there is no jahisCode!")
            return nil
        }

        let jahisElementArr = jahisCode.components(separatedBy: ",")
        guard jahisElementArr.count > 3,
            let parity: Int = Int(jahisElementArr[1]),
            let totalCount = Int(jahisElementArr[2]),
            let currentPosition = Int(jahisElementArr[3]) else {
                debugPrint("there are wrong jahisElementArr element!")
                return nil
        }
        return (totalCount, currentPosition, NSNumber(value: parity))
    }
    
    private func showQRCodeErrorAlert() {
        let alert = UIAlertController(title: "Error! Scan wrong QRCodes or initialization failed",
                                      message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Close", style: .default) { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.captureSessionStartRunning()
            }
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
