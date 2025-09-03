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
    }
    
    /// Current active service type
    private static var currentServiceType: ServiceType = .openAI
    
    /// Get the currently configured text correction service
    static var current: TextCorrectionService {
        return OpenAIService.shared
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
        return OpenAIService.shared
    }
}

// MARK: - Service Type Extensions
extension TextCorrectionServiceFactory.ServiceType {
    var displayName: String {
        return "OpenAI"
    }
    
    var description: String {
        return "Cloud-based AI service using OpenAI's GPT models"
    }
}
