import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var scannerService = BarcodeScannerService()
    @Environment(\.dismiss) private var dismiss
    
    var onScanCompleted: (String) -> Void
    
    var body: some View {
        ZStack {
            // Camera view
            CameraPreviewView(scannerService: scannerService)
                .ignoresSafeArea()
            
            // Overlay
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding([.top, .leading])
                    
                    Spacer()
                }
                
                Spacer()
                
                // Scan frame
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                        .frame(width: 250, height: 250)
                        .foregroundColor(.white)
                    
                    if let code = scannerService.scannedCode {
                        VStack {
                            Spacer()
                            HStack {
                                Text(code)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                            .frame(width: 250)
                            .padding(.bottom, 20)
                        }
                        .frame(height: 250)
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 20) {
                    if scannerService.scannedCode != nil {
                        HStack(spacing: 30) {
                            Button(action: {
                                scannerService.scannedCode = nil
                                scannerService.startScanning()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(Color.red))
                            }
                            
                            Button(action: {
                                if let code = scannerService.scannedCode {
                                    onScanCompleted(code)
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(Color.green))
                            }
                        }
                    } else {
                        Text("Align the barcode within the frame")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupScanner()
        }
        .onChange(of: scannerService.scannedCode) {
            if let code = scannerService.scannedCode {
                // Provide haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Play sound if needed
                // AudioServicesPlaySystemSound(1108)
                
                print("Scanned: \(code)")
            }
        }
    }
    
    private func setupScanner() {
        scannerService.setupScanner { result in
            switch result {
            case .success:
                scannerService.startScanning()
            case .failure(let error):
                print("Scanner setup failed: \(error)")
                // Handle error
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let scannerService: BarcodeScannerService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black
        
        if let previewLayer = scannerService.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}