import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class PDFViewController: UIViewController {
    private let url: URL
    private var pdfView: PDFView!
    private var shareButton: UIBarButtonItem!
    private var saveButton: UIBarButtonItem!
    private var printButton: UIBarButtonItem!
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupNavigationBar()
        loadPDFDocument()
    }
    
    private func setupPDFView() {
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemGray6
        view.addSubview(pdfView)
    }
    
    private func setupNavigationBar() {
        // Configure buttons with purple tint
        let purpleColor = UIColor.systemPurple
        
        shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )
        shareButton.tintColor = purpleColor
        
        saveButton = UIBarButtonItem(
            title: "Save",
            style: .plain,
            target: self,
            action: #selector(saveButtonTapped)
        )
        saveButton.tintColor = purpleColor
        
        printButton = UIBarButtonItem(
            title: "Print",
            style: .plain,
            target: self,
            action: #selector(printButtonTapped)
        )
        printButton.tintColor = purpleColor
        
        // Configure close/done button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = purpleColor
        
        navigationItem.rightBarButtonItems = [shareButton, saveButton, printButton]
        navigationItem.leftBarButtonItem = closeButton
        
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func loadPDFDocument() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: self.url) {
                DispatchQueue.main.async {
                    self.pdfView.document = document
                    self.updateButtonStates()
                    self.navigationItem.title = document.documentURL?.lastPathComponent ?? "PDF Document"
                }
            } else {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: "Failed to load PDF document")
                }
            }
        }
    }
    
    private func updateButtonStates() {
        let hasDocument = pdfView.document != nil
        shareButton.isEnabled = hasDocument
        saveButton.isEnabled = hasDocument
        printButton.isEnabled = hasDocument
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        guard let document = pdfView.document else { return }
        
        // Create temporary file for sharing if original URL is not accessible
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            if let data = document.dataRepresentation() {
                try data.write(to: tempUrl)
                
                let activityVC = UIActivityViewController(
                    activityItems: [tempUrl],
                    applicationActivities: nil
                )
                
                if let popover = activityVC.popoverPresentationController {
                    popover.barButtonItem = shareButton
                }
                
                present(activityVC, animated: true)
            }
        } catch {
            showErrorAlert(message: "Failed to prepare document for sharing")
        }
    }
    
    @objc private func saveButtonTapped() {
        guard let document = pdfView.document else { return }
        
        do {
            // Create temporary file with the PDF data
            let tempUrl = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            
            if let data = document.dataRepresentation() {
                try data.write(to: tempUrl)
                
                let documentPicker = UIDocumentPickerViewController(
                    forExporting: [tempUrl],
                    asCopy: true
                )
                
                documentPicker.delegate = self
                
                if let popover = documentPicker.popoverPresentationController {
                    popover.barButtonItem = saveButton
                }
                
                present(documentPicker, animated: true)
            }
        } catch {
            showErrorAlert(message: "Failed to prepare document for saving")
        }
    }
    
    @objc private func printButtonTapped() {
        guard let document = pdfView.document else { return }
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = document.documentURL?.lastPathComponent ?? "Document"
        printInfo.outputType = .general
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = document.dataRepresentation()
        
        printController.present(animated: true) { (_, completed, error) in
            if let error = error {
                self.showErrorAlert(message: "Printing failed: \(error.localizedDescription)")
            }
        }
    }
}

extension PDFViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Show success feedback
        let alert = UIAlertController(
            title: "Success",
            message: "Document saved successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Optional: Handle cancellation
    }
}

struct PDFKitView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> PDFViewController {
        let controller = PDFViewController(url: url)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PDFViewController, context: Context) {
        // Update the view controller if needed
    }
}

// SwiftUI Preview for testing
struct PDFKitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PDFKitView(url: Bundle.main.url(forResource: "sample", withExtension: "pdf")!)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
