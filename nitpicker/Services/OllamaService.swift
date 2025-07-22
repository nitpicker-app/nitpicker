//
//  OllamaService.swift
//  nitpicker
//
//  Created by Vishnu R on 22/07/25.
//

import Foundation
import Ollama

/// Local AI text correction service using Ollama
@MainActor
class OllamaService: TextCorrectionService {
    static let shared = OllamaService()
    
    private let client: Client
    private let model: String
    
    
    private init(host: URL = URL(string: "http://localhost:11434")!, 
                 model: String = "gemma3n:e2b") {
        self.model = model
        self.client = Client(host: host)
    }
    
    func correctGrammar(text: String, completion: @escaping (String) -> Void) async {
        do {
            let prompt = """
            You are a warm, meticulous editor. When I give you a passage, gently polish its grammar, spelling, punctuation, and flow so it reads naturally to a human reader. Keep the writer's original voice, tone, and intent; make only the fixes needed for clarity and correctness, avoiding robotic or overly formal phrasing.

            If the passage is in a language other than English, apply the same light-touch corrections using that language's rules—never translate or add new ideas.
            Return **only** the improved text in plain text format without enclosing the content in quotes. **Do not provide any explanations or additional comments.**
            If the text is already correct, simply return it as is without any changes.
            
            Text to correct: "\(text)"
            """
            
            let modelInfo = try await client.showModel("gemma3n:e2b")
            if modelInfo.capabilities.contains(.thinking) {
                print("Ollama Service: ✅ Model supports thinking capabilities. Using custom prompt.")
            } else {
                print("Ollama Service: ⚠️ Model does not support thinking capabilities. Using default prompt.")
            }
            
            let response = try await client.chat(
                model: Model.ID(rawValue: model) ?? Model.ID(rawValue: "gemma3n:e2b")!,
                messages: [
                    .user(prompt),
                ],
                options: [
                    "temperature": 0.2,
                    "top_p": 0.9,
                    "top_k": 20
                ],
                keepAlive: .minutes(5)
            )
            
            let correctedText = response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalText = correctedText.isEmpty ? text : correctedText
            
            DispatchQueue.main.async {
                completion(finalText)
            }
            
        } catch {
            print("Ollama Service Error: \(error.localizedDescription)")
            
            // Return original text on error
            DispatchQueue.main.async {
                completion(text)
            }
        }
    }
}

