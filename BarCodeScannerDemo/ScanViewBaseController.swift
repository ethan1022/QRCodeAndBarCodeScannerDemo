//
//  ScanViewBaseController.swift
//  BarCodeScannerDemo
//
//  Created by Ethan on 2020/7/18.
//  Copyright © 2020 Ethans. All rights reserved.
//

import UIKit
import AVFoundation

@objc enum ScanType: Int {
    case barCode
    case qrCode

    var metadataObjectType: [AVMetadataObject.ObjectType] {
        switch self {
        case .barCode:
            return [.code39, .code93, .code128, .code39Mod43, .ean13,
                    .ean8, .itf14, .aztec, .dataMatrix, .upce, ]
        case .qrCode:
            return [.qr]
        }
    }
}

protocol ScanViewBaseControllerDelegate: class {
    func metadataOutput(_ output: AVMetadataMachineReadableCodeObject)
    var scanType: ScanType { get set }
}

class ScanViewBaseController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    private let captureSession = AVCaptureSession()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureOutput = AVCaptureMetadataOutput()
    weak var delegate: ScanViewBaseControllerDelegate?
    var scanAreaRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        willSet {
            // prepare for setting scan area
            captureOutput.rectOfInterest = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: newValue)
        }
    }

    enum ScanError: String, Error {
        case noInternetError
        case noDeviceFoundError
        case addInputError
        case addOutputError
        case machineUnreadableError
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialCaptureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer.frame = self.view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning == true {
            captureSession.stopRunning()
        }
    }

    // Public methods
    @objc func captureSessionStartRunning() {
        captureSession.startRunning()
    }

    @objc func captureSessionStopRunning() {
        captureSession.stopRunning()
    }

    // Private methods
    private func initialCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                debugPrint(ScanError.addInputError.rawValue)
            }
        } catch {
            debugPrint(ScanError.noDeviceFoundError.rawValue)
        }
        captureOutput = AVCaptureMetadataOutput()
        captureOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        } else {
            debugPrint(ScanError.addOutputError.rawValue)
        }
        captureOutput.metadataObjectTypes = delegate?.scanType.metadataObjectType
        videoPreviewLayer.needsDisplayOnBoundsChange = true
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.zPosition = -1
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = self.view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject
            else {
                debugPrint(ScanError.machineUnreadableError.rawValue)
                return
        }

        delegate?.metadataOutput(object)
    }

}

