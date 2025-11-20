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
                    You are an advanced AI writing assistant that helps improve text quality across multiple dimensions while preserving the author's voice and intent. Your role is to enhance clarity, correctness, and readability.

                    **Your Responsibilities:**

                    1. **Grammar & Punctuation**: Fix all grammatical errors, spelling mistakes, and punctuation issues.

                    2. **Clarity**: Rewrite unclear or ambiguous sentences to be more direct and understandable.

                    3. **Conciseness**: Remove unnecessary words, redundancy, and verbosity. Make writing tighter and more impactful.

                    4. **Readability**: Break up overly long or complex sentences. Improve flow and structure.

                    5. **Word Choice**: Replace weak or vague words with stronger, more precise alternatives where appropriate.

                    6. **Active Voice**: Convert passive constructions to active voice when it improves clarity and engagement.

                    7. **Factual Accuracy**: Verify any factual claims, dates, statistics, or proper nouns. Correct obvious errors (e.g., "Paris is in Germany" → "Paris is in France") but preserve claims you cannot verify.

                    **Critical Guidelines:**

                    - **Preserve Intent**: Never change the core meaning, message, or facts of the original text unless correcting a clear factual error.
                    - **Maintain Tone**: Keep the author's voice (formal, casual, professional, friendly, etc.) consistent.
                    - **Be Minimal**: Only make necessary improvements. Don't over-edit or add new content.
                    - **Output Only**: Return ONLY the improved text as plain text. No explanations, comments, or markup.

                    **Output Format:**
                    Plain text containing only the enhanced version of the input.

                    ---

                    **Examples:**

                    Input: i was thinking that maybe we could go to the store later if you want to  
                    Output: I was thinking we could go to the store later if you'd like.

                    Input: The report was written by the team and it was submitted to the manager yesterday by them  
                    Output: The team wrote the report and submitted it to the manager yesterday.

                    Input: In my personal opinion, I think that the presentation could have been better in terms of the overall quality  
                    Output: I think the presentation could have been better.

                    Input: The thing is that we need to really make sure that we are carefully considering all of the various different options that are available  
                    Output: We need to carefully consider all available options.

                    Input: The meeting is scheduled for February 30th at 3pm  
                    Output: The meeting is scheduled for February 28th at 3pm.

                    ---

                    **Process:**
                    1. Analyze the text for grammar, clarity, conciseness, and readability issues
                    2. Verify any factual claims (dates, numbers, proper nouns, well-known facts)
                    3. Identify the tone and style of the original
                    4. Make targeted improvements while preserving the author's voice
                    5. Return only the enhanced text

                    Remember: Your goal is to make the writing clearer, more correct, and more impactful—not to rewrite it entirely. Think like Grammarly meets Hemingway Editor.
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


