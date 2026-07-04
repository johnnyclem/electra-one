import Foundation
import Security

/// Minimal Keychain wrapper for the AI endpoint's API key. The key is optional
/// (local servers like Ollama need none), entered by the user in Settings and
/// stored securely; the app never ships a key.
enum Keychain {
    // Must stay in sync with BUNDLE_ID in mac/build-app.sh — changing either
    // one alone strands users' stored API keys.
    private static let service = "one.electra.companion"
    private static let account = "ai-api-key"

    static func setAPIKey(_ key: String) {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        if key.isEmpty { return }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func apiKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let s = String(data: data, encoding: .utf8), !s.isEmpty
        else { return nil }
        return s
    }

    static func clear() { setAPIKey("") }
    static var hasKey: Bool { apiKey() != nil }
}
