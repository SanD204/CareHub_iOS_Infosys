//
//  Pdf_Viewer.swift
//  Carehub
//
//  Created by admin24 on 28/04/25.
//

import Foundation
import SwiftUI
import PDFKit

// PDFViewer and PDFKitRepresentedView remain unchanged
struct PDFViewer: View {
    let pdfUrl: URL
    
    var body: some View {
        PDFKitRepresentedView(url: pdfUrl)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("PDF Viewer")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        } else {
            print("Failed to load PDF document from URL: \(url)")
        }
    }
}

