//
//  TextCorrectionServiceFactory.swift
//  nitpicker
//
//  Created by Vishnu R on 22/07/25.
//

import Foundation

/// Factory for creating and managing text correction services
class TextCorrectionServiceFactory {
    
    /// Available text correction service types
    enum ServiceType {
        case openAI
        case ollama
    }
    
    /// Current active service type
    private static var currentServiceType: ServiceType = .openAI
    
    /// Get the currently configured text correction service
    static var current: TextCorrectionService {
        switch currentServiceType {
        case .openAI:
            return OpenAIService.shared
        case .ollama:
            return OllamaService.shared
        }
    }
    
    /// Switch to a different service type
    /// - Parameter serviceType: The service type to switch to
    static func switchTo(_ serviceType: ServiceType) {
        currentServiceType = serviceType
        print("Switched text correction service to: \(serviceType)")
    }
    
    /// Get service for a specific type without changing the current default
    /// - Parameter serviceType: The service type to get
    /// - Returns: The requested service instance
    static func service(for serviceType: ServiceType) -> TextCorrectionService {
        switch serviceType {
        case .openAI:
            return OpenAIService.shared
        case .ollama:
            return OllamaService.shared
        }
    }
}

// MARK: - Service Type Extensions
extension TextCorrectionServiceFactory.ServiceType {
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .ollama:
            return "Ollama (Local)"
        }
    }
    
    var description: String {
        switch self {
        case .openAI:
            return "Cloud-based AI service using OpenAI's GPT models"
        case .ollama:
            return "Local AI service running on your machine"
        }
    }
}
