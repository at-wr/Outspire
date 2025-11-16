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
    private let model: String = Configuration.llmModel
    private let service: OpenAIService

    /// System prompt for CAS reflection outline generation
    private let reflectionPrompt = """
        You are an IB student writing a CAS activity reflection for your club's activities during the past semester. Your reflection should be written in English and be at least 550 words. It should deeply integrate the learning outcomes without explicitly mentioning them by name.

        Structure your reflection with:
        - A beginning paragraph introducing the club and your involvement
        - Three gradations (each focusing on a distinct activity or event)
        - A concluding paragraph that synthesizes your growth and learning

        For each gradation, follow this progression of depth:
        1st gradation: Focus on detailed techniques, specific experiences, and the joy of participation (concrete level)
        2nd gradation: Explore innovative thoughts, lessons learned, and personal growth (reflective level)
        3rd gradation: Examine complex concepts like values, responsibilities, ethical considerations, and community impact (abstract level)

        Your task:
        1. First, interpret the learning outcomes provided and connect them to specific events/activities
        2. Then provide a comprehensive outline including:
           - A fully written beginning paragraph
           - Detailed points for each of the three gradations (not fully written, but substantial outline)
           - A fully written concluding paragraph

        Ensure your reflection demonstrates personal growth, critical thinking, and how these experiences have shaped your perspective.
        """

    init(
        apiKey: String = Configuration.llmApiKey,
        baseURL: String = Configuration.llmBaseURL
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.service = OpenAIServiceFactory.service(
            apiKey: apiKey,
            overrideBaseURL: baseURL
        )
    }

    // MARK: - Helpers

    private func decodeJSONString<T: Decodable>(_ jsonString: String) throws -> T {
        guard let data = jsonString.data(using: String.Encoding.utf8) else {
            throw NSError(
                domain: "LLMService", code: -100,
                userInfo: [NSLocalizedDescriptionKey: "Empty response payload"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Suggests a CAS record (title and description) based on user input and past records.
    func suggestCasRecord(
        userInput: String,
        pastRecords: [ActivityRecord],
        clubName: String
    ) async throws -> CasSuggestion {
        let systemPrompt = """
            You are an IB CAS activity record writer for the \(clubName) Club. Given the user's input and several past records, suggest a suitable title and description for a new CAS record for this club. The title should be concise and descriptive. The description should be personal, reflective, and no less than 90 words. Focus on personal insights and learning experiences.

            Output must be in JSON format matching this schema:
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

        let schema = JSONSchema(
            type: .object,
            properties: [
                "title": JSONSchema(type: .string),
                "description": JSONSchema(type: .string),
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
                .init(role: .user, content: .text(userPrompt)),
            ],
            model: .custom(model),
            responseFormat: .jsonSchema(responseFormat)
        )

        let chat = try await service.startChat(parameters: parameters)
        guard let choice = chat.choices?.first,
              let message = choice.message,
              let jsonString = message.content else {
            throw NSError(
                domain: "LLMService", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid CAS suggestion response"])
        }
        return try decodeJSONString(jsonString)
    }

    /// Suggests an outline for a CAS reflection based on learning outcomes, club, and context.
    func suggestReflectionOutline(
        learningOutcomes: String,
        clubName: String,
        additionalContext: String
    ) async throws -> String {
        let systemPrompt = """
            You are an IB student writing a CAS activity reflection for your club's activities. Your task is to create a structured outline reflecting on activities in the \(clubName) Club. Your outline should incorporate the learning outcomes provided without explicitly mentioning them.

            Return a JSON object with the following fields:
            - title: A descriptive title for the reflection (string)
            - summary: A concise summary of the reflection (string)
            - content: The main reflection content (string) structured with:
              - A beginning paragraph introducing the club and activities
              - Three distinct gradations exploring different aspects and depths
              - A concluding paragraph synthesizing learning and growth

            For the content section, follow this progression of depth:
            1. First gradation: Focus on concrete experiences and techniques
            2. Second gradation: Explore lessons learned and personal growth
            3. Third gradation: Examine abstract concepts like values, ethics, and impact

            The reflection should demonstrate personal growth and critical thinking, while incorporating all applicable learning outcomes without naming them explicitly.

            Learning outcomes to address: \(learningOutcomes)
            """

        let userPrompt = """
            Please create a reflection outline for the \(clubName) Club. During this semester, I \(additionalContext).

            Make sure to address these learning outcomes: \(learningOutcomes).

            Structure your response in JSON format with 'title', 'summary', and 'content' fields.
            """

        let schema = JSONSchema(
            type: .object,
            properties: [
                "title": JSONSchema(type: .string),
                "summary": JSONSchema(type: .string),
                "content": JSONSchema(type: .string),
            ],
            required: ["title", "summary", "content"],
            additionalProperties: false
        )

        let responseFormat = JSONSchemaResponseFormat(
            name: "ReflectionOutline",
            strict: true,
            schema: schema
        )

        let parameters = ChatCompletionParameters(
            messages: [
                .init(role: .system, content: .text(systemPrompt)),
                .init(role: .user, content: .text(userPrompt)),
            ],
            model: .custom(model),
            responseFormat: .jsonSchema(responseFormat)
        )

        let chat = try await service.startChat(parameters: parameters)
        struct ReflectionOutline: Codable { let title: String; let summary: String; let content: String }
        guard let choice = chat.choices?.first,
              let message = choice.message,
              let jsonString = message.content else {
            throw NSError(
                domain: "LLMService", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No valid reflection outline returned"])
        }
        let outline: ReflectionOutline = try decodeJSONString(jsonString)
        return outline.content
    }

    /// Suggests a complete reflection with title, summary and content for regular reflections (non-conversation)
    func suggestFullReflection(
        learningOutcomes: String,
        clubName: String,
        currentTitle: String,
        currentSummary: String,
        currentContent: String,
        isConversation: Bool = false
    ) async throws -> (title: String, summary: String, content: String) {
        if isConversation {
            return try await suggestConversationReflection(
                learningOutcomes: learningOutcomes,
                currentTitle: currentTitle,
                currentSummary: currentSummary,
                currentContent: currentContent
            )
        }

        let systemPrompt = """
            You are an IB student writing a CAS activity reflection for your club's activities during the past semester. Your task is to create a comprehensive reflection about the \(clubName) Club that addresses the specified learning outcomes without explicitly mentioning them.

            The user may provide existing content in their title, summary, and main content. If content is provided, build upon and improve it rather than starting from scratch. Pay attention to the style and focus of what the user has already written.

            Return a JSON object with the following fields:
            - title: A descriptive title for the reflection (string)
            - summary: A concise summary under 100 words (string)
            - content: The complete reflection content (at least 550 words) structured with:
              - A beginning paragraph introducing the club and activities
              - Three distinct gradations exploring different aspects and depths
              - A concluding paragraph synthesizing learning and growth

            The reflection should be closely related to the learning outcomes, but never directly mention them in the text.

            The three gradations should follow this progression:
            1. First gradation: Focus on detailed techniques, specific experiences, and the joy of participation. Include detailed descriptions of what you did and learned.
            2. Second gradation: Explore innovative thoughts, lessons learned, and personal growth. Discuss how these experiences helped you develop new perspectives.
            3. Third gradation: Examine abstract concepts like values, responsibilities, ethics, and societal impact. Reflect on deeper meanings and implications of your activities.

            Each gradation should be about an individual event/activity and thoroughly interpret how it relates to the learning outcomes, expressing both apparent meanings and deeper implications.

            Your reflection should demonstrate genuine personal growth and critical thinking while naturally incorporating all relevant learning outcomes.

            Learning outcomes to address: \(learningOutcomes)
            """

        let userPrompt = """
            Please create a complete reflection for the \(clubName) Club.

            Current information:
            - Title: \(currentTitle.isEmpty ? "[Not provided yet]" : currentTitle)
            - Summary: \(currentSummary.isEmpty ? "[Not provided yet]" : currentSummary)
            - Content: \(currentContent.isEmpty ? "[Not provided yet]" : currentContent)

            Make sure to address these learning outcomes: \(learningOutcomes).

            If I've already started writing, please build upon my existing text while improving it.
            Structure your response in JSON format with 'title', 'summary', and 'content' fields.
            """

        let schema = JSONSchema(
            type: .object,
            properties: [
                "title": JSONSchema(type: .string),
                "summary": JSONSchema(type: .string),
                "content": JSONSchema(type: .string),
            ],
            required: ["title", "summary", "content"],
            additionalProperties: false
        )

        let responseFormat = JSONSchemaResponseFormat(
            name: "FullReflection",
            strict: true,
            schema: schema
        )

        let parameters = ChatCompletionParameters(
            messages: [
                .init(role: .system, content: .text(systemPrompt)),
                .init(role: .user, content: .text(userPrompt)),
            ],
            model: .custom(model),
            responseFormat: .jsonSchema(responseFormat)
        )

        let chat = try await service.startChat(parameters: parameters)
        struct FullReflection: Codable { let title: String; let summary: String; let content: String }
        guard let choice = chat.choices?.first,
              let message = choice.message,
              let jsonString = message.content else {
            throw NSError(
                domain: "LLMService", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No valid reflection response returned"])
        }
        let reflection: FullReflection = try decodeJSONString(jsonString)
        return (reflection.title, reflection.summary, reflection.content)
    }

    /// Suggests a complete conversation reflection with title, summary and content
    private func suggestConversationReflection(
        learningOutcomes: String,
        currentTitle: String,
        currentSummary: String,
        currentContent: String
    ) async throws -> (title: String, summary: String, content: String) {
        let systemPrompt = """
            You are an IB student writing a CAS conversation record about a discussion with your homeroom teacher regarding club activities. Your task is to create a brief record of this conversation.

            The user may provide existing content in their title, summary, and main content. If content is provided, build upon and improve it rather than starting from scratch. Pay attention to the style and focus of what the user has already written.

            Return a JSON object with the following fields:
            - title: A concise title for the conversation record (string)
            - summary: A brief summary under 50 words (string)
            - content: The complete conversation record (200-240 words) that includes:
              - What you discussed about your club activities
              - Brief reflections on your participation
              - Future expectations or plans

            The record should be personal and include insights about your involvement while naturally incorporating the learning outcomes without directly naming them.

            Learning outcomes to address: \(learningOutcomes)
            """

        let userPrompt = """
            I talked to my homeroom teacher about my club activities.

            Current information:
            - Title: \(currentTitle.isEmpty ? "[Not provided yet]" : currentTitle)
            - Summary: \(currentSummary.isEmpty ? "[Not provided yet]" : currentSummary)
            - Content: \(currentContent.isEmpty ? "[Not provided yet]" : currentContent)

            The conversation included discussion about these learning outcomes: \(learningOutcomes).

            Write a brief record about this conversation that includes what I did in the clubs, some brief reflections, and future expectations.
            If I've already started writing, please build upon my existing text while improving it.

            Structure your response in JSON format with 'title', 'summary', and 'content' fields.
            """

        let schema = JSONSchema(
            type: .object,
            properties: [
                "title": JSONSchema(type: .string),
                "summary": JSONSchema(type: .string),
                "content": JSONSchema(type: .string),
            ],
            required: ["title", "summary", "content"],
            additionalProperties: false
        )

        let responseFormat = JSONSchemaResponseFormat(
            name: "ConversationReflection",
            strict: true,
            schema: schema
        )

        let parameters = ChatCompletionParameters(
            messages: [
                .init(role: .system, content: .text(systemPrompt)),
                .init(role: .user, content: .text(userPrompt)),
            ],
            model: .custom(model),
            responseFormat: .jsonSchema(responseFormat)
        )

        let chat = try await service.startChat(parameters: parameters)
        struct ConversationReflection: Codable { let title: String; let summary: String; let content: String }
        guard let choice = chat.choices?.first,
              let message = choice.message,
              let jsonString = message.content else {
            throw NSError(
                domain: "LLMService", code: 4,
                userInfo: [NSLocalizedDescriptionKey: "No valid conversation reflection response returned"])
        }
        let reflection: ConversationReflection = try decodeJSONString(jsonString)
        return (reflection.title, reflection.summary, reflection.content)
    }
}
