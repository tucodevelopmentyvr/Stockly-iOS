import SwiftUI
import PDFKit
import UIKit
import WebKit

// Simple PDF display screen - using direct link to PDF
struct EnhancedPDFPreviewView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    // Add a state variable to prevent multiple dismissals
    @State private var isDismissing = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: {
                    // Prevent multiple dismissals
                    if !isDismissing {
                        isDismissing = true
                        dismiss()
                    }
                }) {
                    Text("Back")
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.leading)
                
                Spacer()
                
                // Add home button in center
                Button(action: {
                    // Prevent multiple dismissals
                    if !isDismissing {
                        isDismissing = true
                        dismiss()
                        
                        // Use notification to reset the navigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("ReturnToMainMenu"), object: nil)
                        }
                    }
                }) {
                    Image(systemName: "house.fill")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Button(action: {
                    sharePDF()
                }) {
                    Text("Share")
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.trailing)
            }
            .padding(.vertical)
            
            Spacer()
            
            // Direct URL Link
            Link(destination: url) {
                VStack(spacing: 15) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 60))
                    
                    Text("Open PDF")
                        .font(.headline)
                    
                    Text("Tap to open in external viewer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 30)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .navigationBarHidden(true)
        // Add id to ensure the view is not recreated unnecessarily
        .id("pdf-preview-\(url.lastPathComponent)")
    }
    
    // Share PDF using activity sheet
    private func sharePDF() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
        }
        
        rootViewController.present(activityVC, animated: true)
    }
}

// Web View for displaying PDFs
struct WebViewPDF: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the URL has actually changed
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

// Simple SwiftUI wrapper for PDFKit
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only load if the document is different or not loaded
        if pdfView.document?.documentURL != url {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
    }
}

// Use Safari View Controller for PDF viewing - much more reliable
struct SafariViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        // First check if file exists
        if FileManager.default.fileExists(atPath: url.path) {
            // Use a simple UIViewController that embeds a WKWebView
            let viewController = PDFViewController()
            viewController.url = url
            return viewController
        } else {
            // Show error if file doesn't exist
            let errorVC = UIHostingController(rootView: PDFErrorView(url: url))
            return errorVC
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Intentionally empty - no update needed
    }
}

// Custom PDF view controller using WKWebView
class PDFViewController: UIViewController {
    var url: URL?
    private var pdfView: PDFView?
    private var isPDFLoaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
    }
    
    private func setupPDFView() {
        guard let url = url else { return }
        
        let pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(pdfView)
        
        // Add a close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        closeButton.layer.cornerRadius = 15
        closeButton.frame = CGRect(x: 20, y: 40, width: 70, height: 30)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Add Home button
        let homeButton = UIButton(type: .system)
        homeButton.setImage(UIImage(systemName: "house.fill"), for: .normal)
        homeButton.tintColor = UIColor.systemBlue
        homeButton.backgroundColor = UIColor.systemBackground
        homeButton.layer.cornerRadius = 20
        homeButton.frame = CGRect(x: view.bounds.width/2 - 20, y: 40, width: 40, height: 40)
        homeButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)
        view.addSubview(homeButton)
        
        // Create a share button
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.backgroundColor = UIColor.systemGreen
        shareButton.layer.cornerRadius = 15
        shareButton.frame = CGRect(x: view.bounds.width - 90, y: 40, width: 70, height: 30)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        view.addSubview(shareButton)
        
        // Load PDF document manually when explicit user action is taken
        let openButton = UIButton(type: .system)
        openButton.setTitle("View PDF", for: .normal)
        openButton.setTitleColor(.white, for: .normal)
        openButton.backgroundColor = UIColor.systemBlue
        openButton.layer.cornerRadius = 10
        openButton.frame = CGRect(x: view.bounds.width/2 - 100, y: view.bounds.height/2 - 25, width: 200, height: 50)
        openButton.addTarget(self, action: #selector(openPDFTapped), for: .touchUpInside)
        view.addSubview(openButton)
        
        // Add an instructional label
        let label = UILabel()
        label.text = "PDF Generated Successfully"
        label.textAlignment = .center
        label.frame = CGRect(x: view.bounds.width/2 - 150, y: view.bounds.height/2 - 80, width: 300, height: 30)
        view.addSubview(label)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func homeTapped() {
        // First dismiss this view controller - and make sure we're not posting the notification too soon
        let notificationName = NSNotification.Name("ReturnToMainMenu")
        
        // Dismiss first
        dismiss(animated: true) { [weak self] in
            // Post notification after successful dismissal with a slight delay
            // to ensure the dismissal has fully completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: notificationName, object: nil)
                
                // Also directly navigate to root using UIKit
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    
                    // Dismiss any presented view controllers
                    self?.recursivelyDismissViewControllers(rootViewController)
                    
                    // Try to pop to root in any navigation controllers
                    if let navController = rootViewController as? UINavigationController {
                        navController.popToRootViewController(animated: true)
                    } else if let tabController = rootViewController as? UITabBarController {
                        tabController.selectedIndex = 0
                        if let nav = tabController.selectedViewController as? UINavigationController {
                            nav.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    // Recursively dismiss all presented view controllers
    private func recursivelyDismissViewControllers(_ viewController: UIViewController) {
        if let presented = viewController.presentedViewController {
            recursivelyDismissViewControllers(presented)
            viewController.dismiss(animated: false)
        }
    }
    
    @objc private func shareTapped() {
        guard let url = url else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // On iPad, present from a popover
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.width - 55, y: 55, width: 0, height: 0)
            popover.permittedArrowDirections = .up
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func openPDFTapped() {
        guard let url = url, !isPDFLoaded else { return }
        
        // Prevent multiple loads
        isPDFLoaded = true
        
        // Instantiate the PDF view only when requested
        let pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Remove the open button and label first
        for subview in view.subviews {
            if subview is UIButton && (subview as? UIButton)?.titleLabel?.text == "View PDF" {
                subview.removeFromSuperview()
            }
            if subview is UILabel {
                subview.removeFromSuperview()
            }
        }
        
        view.addSubview(pdfView)
        
        // Make sure close and share buttons are visible
        view.bringSubviewToFront(view.subviews.first(where: { ($0 as? UIButton)?.titleLabel?.text == "Close" }) ?? UIView())
        view.bringSubviewToFront(view.subviews.first(where: { ($0 as? UIButton)?.titleLabel?.text == "Share" }) ?? UIView())
        
        // Now load the PDF
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            pdfView.autoScales = true
            pdfView.displayMode = .singlePageContinuous
            self.pdfView = pdfView
        }
    }
}

// Error view for missing PDFs
struct PDFErrorView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
            
            Text("PDF File Not Found")
                .font(.headline)
            
            Text("The PDF file could not be loaded.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

// Extension to find the topmost view controller
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
    
    // Property to get the navigation controller if this view controller is embedded in one
    var navigationController: UINavigationController? {
        // First check if this is already a navigation controller
        if let navController = self as? UINavigationController {
            return navController
        }
        // Then check if this is embedded in a navigation controller
        else if let navController = self.parent as? UINavigationController {
            return navController
        }
        // Then check if this is embedded in a tab controller that's in a navigation controller
        else if let tabController = self.parent as? UITabBarController,
                let navController = tabController.navigationController {
            return navController
        }
        // Finally check if there's a navigation controller in the responder chain
        else {
            var responder: UIResponder? = self.next
            while responder != nil {
                if let navController = responder as? UINavigationController {
                    return navController
                }
                responder = responder?.next
            }
            return nil
        }
    }
}
