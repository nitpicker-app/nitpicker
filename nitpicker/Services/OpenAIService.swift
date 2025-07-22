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

    func correctGrammar(text: String, completion: @escaping (String) -> Void) async {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a warm, meticulous editor. When I give you a passage, gently polish its grammar, spelling, punctuation, and flow so it reads naturally to a human reader. Keep the writer’s original voice, tone, and intent; make only the fixes needed for clarity and correctness, avoiding robotic or overly formal phrasing. 

                    If the passage is in a language other than English, apply the same light-touch corrections using that language’s rules—never translate or add new ideas.  
                    Return **only** the improved tex̛t.
                    """,
                ],
                [
                    "role": "user",
                    "content": text,  // just pass the raw text; no wrapper needed
                ],
            ],
            "temperature": 0.2,
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
                    if let data = data,
                        let errorJson = try? JSONSerialization.jsonObject(
                            with: data
                        ) as? [String: Any]
                    {
                        print("OpenAI API Error: \(errorJson)")
                    }

                    DispatchQueue.main.async {
                        completion(text)
                    }
                    return
                }
            }

            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            else {
                print("OpenAI API: Failed to parse response")
                if let data = data {
                    print(
                        "Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")"
                    )
                }
                DispatchQueue.main.async {
                    completion(text)
                }
                return
            }

            DispatchQueue.main.async {
                completion(
                    content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }.resume()
    }
}


