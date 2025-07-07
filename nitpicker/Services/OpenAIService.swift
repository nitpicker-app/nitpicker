//
//  OpenAIService.swift
//  nitpicker
//
//  Created by Vishnu R on 07/07/25.
//

import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    // Get API key from UserDefaults or use a placeholder
    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "openai_api_key")
    }

    func correctGrammar(text: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that corrects grammar and spelling mistakes in text. Please review the following text and correct all grammar, spelling, and punctuation mistakes. Maintain the original meaning and language of the text. If the text is in a language other than English, please correct it according to that language’s grammar and spelling rules. Do not translate. Add appropriate punctuation and capitalization where necessary."],
                ["role": "user", "content": text]
            ],
            "temperature": 0.2
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                print("OpenAI API Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(text)
                }
                return
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAI API Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let data = data, let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("OpenAI API Error: \(errorJson)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(text)
                    }
                    return
                }
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String
            else {
                print("OpenAI API: Failed to parse response")
                if let data = data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
                }
                DispatchQueue.main.async {
                    completion(text)
                }
                return
            }

            DispatchQueue.main.async {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }.resume()
    }
}

