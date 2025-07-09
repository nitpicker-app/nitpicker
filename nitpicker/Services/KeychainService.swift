import Foundation
import Security

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case itemNotFound
    case duplicateItem
    case dataConversionError
    case unhandledError(status: OSStatus)
}

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    func saveAPIKey(_ key: String) throws {
        // Convert string to data
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        // Prepare query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "openai_api_key",
            kSecAttrService as String: "com.nitpicker.apikey",
            kSecValueData as String: data
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func getAPIKey() -> String? {
        // Prepare query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "openai_api_key",
            kSecAttrService as String: "com.nitpicker.apikey",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        guard let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "openai_api_key",
            kSecAttrService as String: "com.nitpicker.apikey"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}