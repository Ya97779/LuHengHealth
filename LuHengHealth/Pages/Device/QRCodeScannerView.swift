//
//  QRCodeScannerView.swift
//  LuHengHeath
//
//  Created by macios on 2025/9/4.
//

import SwiftUI
import AVFoundation

// 二维码扫描全屏弹层
struct QRCodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCode: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            QRCodeScannerView { code in
                onCode(code)
                dismiss()
            }
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                    .padding(16)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

// 基于 AVFoundation 的扫码视图
struct QRCodeScannerView: UIViewControllerRepresentable {
	var onCode: (String) -> Void
	
	func makeUIViewController(context: Context) -> ScannerViewController {
		let vc = ScannerViewController()
		vc.onCode = onCode
		return vc
	}
	
	func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	let session = AVCaptureSession()
	var previewLayer: AVCaptureVideoPreviewLayer?
	var onCode: ((String) -> Void)?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureSession()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if !session.isRunning { session.startRunning() }
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if session.isRunning { session.stopRunning() }
	}
	
	private func configureSession() {
		guard let device = AVCaptureDevice.default(for: .video),
			  let input = try? AVCaptureDeviceInput(device: device) else { return }
		
		if session.canAddInput(input) { session.addInput(input) }
		
		let output = AVCaptureMetadataOutput()
		if session.canAddOutput(output) { session.addOutput(output) }
		
		output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
		output.metadataObjectTypes = [.qr]
		
		let layer = AVCaptureVideoPreviewLayer(session: session)
		layer.videoGravity = .resizeAspectFill
		layer.frame = view.layer.bounds
		view.layer.addSublayer(layer)
		previewLayer = layer
	}
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
			  obj.type == .qr,
			  let value = obj.stringValue else { return }
		
		if session.isRunning { session.stopRunning() }
		onCode?(value)
	}
}
