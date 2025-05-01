import Foundation
import SwiftOpenAI

/// The output structure for LLM suggestions.
struct CasSuggestion: Codable {
    let title: String?
    let description: String?
}

final class LLMService {
    // MARK: - Properties

    private let apiKey: String
    private let baseURL: String
    private let model: String = "grok/grok-3-latest"

    private let service: OpenAIService

    init(
        apiKey: String = Configuration.llmApiKey, // You should add this to your Configuration.swift
        baseURL: String = Configuration.llmBaseURL // Add proxy path if needed
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.service = OpenAIServiceFactory.service(
            apiKey: apiKey,
            overrideBaseURL: baseURL
        )
    }

    /// Suggests a CAS record (title and description) based on user input and past records.
    func suggestCasRecord(
        userInput: String,
        pastRecords: [ActivityRecord]
    ) async throws -> CasSuggestion {
        // Compose the system and user prompt
        let systemPrompt = """
        You are an IB CAS activity record writer. Given the user's input and several past records, suggest a suitable title and description for a new CAS record. Description should be no less than 90 words. Output must be in JSON format matching this schema:
        {
            "title": string,
            "description": string
        }
        """

        let pastExamples = pastRecords.prefix(3).enumerated().map { idx, record in
            """
            Example \(idx + 1):
            Title: \(record.C_Theme)
            Description: \(record.C_Reflection)
            """
        }.joined(separator: "\n\n")

        let userPrompt = """
        User Input:
        \(userInput)

        Past Records:
        \(pastExamples)
        """

        // Define the JSON schema for structured output
        let schema = JSONSchema(
            type: .object,
            properties: [
                "title": JSONSchema(type: .string),
                "description": JSONSchema(type: .string)
            ],
            required: ["title", "description"],
            additionalProperties: false
        )
        let responseFormat = JSONSchemaResponseFormat(
            name: "CasSuggestion",
            strict: true,
            schema: schema
        )

        let parameters = ChatCompletionParameters(
            messages: [
                .init(role: .system, content: .text(systemPrompt)),
                .init(role: .user, content: .text(userPrompt))
            ],
            model: .custom(model),
            responseFormat: .jsonSchema(responseFormat)
        )

        let chat = try await service.startChat(parameters: parameters)
        guard let choices = chat.choices, let choice = choices.first else {
            throw NSError(domain: "LLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No choices returned from LLM"])
        }
        // Try to extract the JSON string from the message content
        guard let message = choice.message else {
            throw NSError(domain: "LLMService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No message in LLM response"])
        }
        if let jsonString = message.content as? String,
           let jsonData = jsonString.data(using: String.Encoding.utf8) {
            return try JSONDecoder().decode(CasSuggestion.self, from: jsonData)
        } else if let jsonString = message.content,
                  let stringified = jsonString as? CustomStringConvertible,
                  let jsonData = stringified.description.data(using: String.Encoding.utf8) {
            // Fallback: try to stringify and decode
            return try JSONDecoder().decode(CasSuggestion.self, from: jsonData)
        } else {
            throw NSError(domain: "LLMService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No valid JSON output from LLM"])
        }
    }
}
