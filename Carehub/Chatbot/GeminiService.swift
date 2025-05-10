//
//  GeminiService.swift
//  Carehub
//
//  Created by Yash Gupta on 08/05/25.
//

import Foundation
import Network

class GeminiService {
    static let shared = GeminiService()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Configuration
    private let apiKey = "AIzaSyAlrBy-vrGifZLfdHZrKF9Rxq5gejcNpLE"
    private let modelName = "gemini-1.5-pro"
    private let maxRetryAttempts = 3
    private let baseDelay: TimeInterval = 1.0
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"
    
    @Published var isNetworkAvailable = true
    
    init() {
        setupNetworkMonitor()
    }
    
    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                print("Network status changed: \(path.status)")
            }
        }
        monitor.start(queue: queue)
    }
    
    func sendMessage(_ text: String) async throws -> String {
        guard isNetworkAvailable else {
            throw NSError(domain: "NetworkError", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection"
            ])
        }
        
        guard !apiKey.isEmpty, apiKey.starts(with: "AIza") else {
            throw NSError(domain: "GeminiError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid API key format"
            ])
        }
        
        let urlString = "\(apiEndpoint)\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GeminiError", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid URL"
            ])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Define the system prompt for concise, professional responses
        let systemPrompt = """
        You are a professional healthcare assistant chatbot for a healthcare management app. Help users understand their symptoms and suggest the most appropriate medical department to consult from the following: General Practitioner, Cardiology, Orthopedics, Neurology, Gynecology, Surgery, Dermatology, Endocrinology, ENT, Oncology, Psychiatry, Urology, Pediatrics. Use the following guidelines:
        - For common symptoms like fever, cough, or fatigue, suggest "Pediatrics".
        - For ear, nose, or throat-related symptoms (e.g., sore throat, ear pain), suggest ENT.
        - For heart-related symptoms (e.g., chest pain), suggest Cardiology.
        - For skin issues, suggest Dermatology.
        - For neurological symptoms (e.g., headache, dizziness), suggest Neurology.
        - For bone or joint issues, suggest Orthopedics.
        - For diabetes or hormonal issues, suggest Endocrinology.
        - For cancer-related concerns, suggest Oncology.
        - For mental health concerns, suggest Psychiatry.
        - For child-related symptoms, suggest Pediatrics.
        Provide concise responses (2-3 lines max), focusing on general guidance and the appropriate department. Do not provide medical diagnoses or treatments. Always include a disclaimer to consult a healthcare professional. Be empathetic and professional.
        """
        
        // Prepend the system prompt to the user's input
        let combinedText = "\(systemPrompt)\n\nUser: \(text)"
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": combinedText]
                    ]
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            throw NSError(domain: "GeminiError", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to serialize request body"
            ])
        }
        
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                if attempt > 0 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    print("🔄 Retry attempt \(attempt) in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawResponse)")
                } else {
                    print("Raw response: Unable to decode as UTF-8")
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "GeminiError", code: 4, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid response type"
                    ])
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "HTTP error: \(httpResponse.statusCode), Response: \(String(data: data, encoding: .utf8) ?? "Unknown")"
                    throw NSError(domain: "GeminiError", code: 4, userInfo: [
                        NSLocalizedDescriptionKey: errorMessage
                    ])
                }
                
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let candidates = jsonResponse?["candidates"] as? [[String: Any]],
                      let firstCandidate = candidates.first,
                      let content = firstCandidate["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let firstPart = parts.first,
                      let responseText = firstPart["text"] as? String else {
                    throw NSError(domain: "GeminiError", code: 5, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to parse response"
                    ])
                }
                
                return responseText
            } catch let error as URLError where error.code == .networkConnectionLost {
                lastError = error
                print("⚠️ Network connection lost (attempt \(attempt + 1))")
                continue
            } catch {
                lastError = error
                break
            }
        }
        
        throw lastError ?? NSError(domain: "GeminiError", code: 6, userInfo: [
            NSLocalizedDescriptionKey: "Unknown error occurred"
        ])
    }
}
