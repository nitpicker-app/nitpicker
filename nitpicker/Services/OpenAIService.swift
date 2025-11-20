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
                    Rewrite user-provided text to correct grammatical errors and add appropriate punctuation, ensuring the meaning and essence of the original sentence are preserved. Respond only with the corrected version of the text, mimicking the style of writing assistance tools such as Grammarly.

                    - Before producing your output, internally review the user's input for grammar, punctuation, and readability issues.
                    - Consider context, tone, and the original intent to avoid altering the sentence's meaning.
                    - Avoid unnecessary elaboration, stylistic changes, or content additions—focus strictly on grammar and punctuation.
                    - Always deliver your answer as a single, corrected sentence or paragraph, formatted as plain text.
                    - Do not include any explanation or commentary in the output; return only the revised text.

                    **Output Format:**  
                    Plain text containing only the improved version of the input, with correct grammar and punctuation.

                    ---

                    **Example 1**  
                    Input: i dont think this is a good idea can you help me  
                    Output: I don't think this is a good idea. Can you help me?

                    **Example 2**  
                    Input: when she arrive lets go to dinner  
                    Output: When she arrives, let's go to dinner.

                    *(For real use: The input may be longer or more complex; always ensure only grammar and punctuation are updated, not meaning.)*

                    ---

                    **Reminder:**  
                    Your goal is to correct grammar and punctuation only, keeping the original meaning and tone intact. Respond only with the improved text, as plain text, and nothing else.
                    """,
                ],
                [
                    "role": "user",
                    "content": "User Input:\n" + text,
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


