//
//  OpenAIService.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation

class OpenAIService: TextCorrectionService {
    static let shared = OpenAIService()

    private var apiKey: String {
        return KeychainService.shared.getAPIKey() ?? ""
    }

    func correctGrammar(text: String, completion: @escaping (String?) -> Void) async {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let model = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5.4-mini"
        let body: [String: Any] = [
            "model": model,
            "instructions": ModeManager.shared.effectiveSystemPrompt,
            "input": "User Input:\n" + text,
            "temperature": 0.2,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("OpenAI API Error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let data = data,
                   let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("OpenAI API Error (\(httpResponse.statusCode)): \(errorJson)")
                }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                print("OpenAI API: Failed to parse response")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            // Responses API returns output_text as a top-level convenience field
            if let outputText = json["output_text"] as? String {
                DispatchQueue.main.async {
                    completion(outputText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                return
            }

            // Fallback: traverse output[0].content[0].text
            if let output = json["output"] as? [[String: Any]],
               let content = output.first?["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                DispatchQueue.main.async {
                    completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                return
            }

            print("OpenAI API: Failed to parse response")
            DispatchQueue.main.async { completion(nil) }
        }.resume()
    }
}


