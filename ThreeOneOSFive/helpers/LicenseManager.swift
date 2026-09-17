import Foundation
import Security
import UIKit

@MainActor
final class LicenseManager: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var hasCompletedInitialCheck = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var message: String?
    @Published private(set) var expirationDate: Date?

    private let endpoint = EndpointVault.licenseURL
    private let keychainService = "com.bts2019amo.3105.ios-access"
    private let keychainAccount = "access-key"
    private let deviceKeychainService = "com.bts2019amo.3105.device"
    private let deviceKeychainAccount = "device-id"
    private let expirationKey = "ios-access.expiration-date"

    private var storedKey: String?
    private var deviceID: String
    private var refreshInFlight = false
    private var lastValidationAt: Date?

    init() {
        storedKey = Self.loadKey(service: keychainService, account: keychainAccount)
        expirationDate = UserDefaults.standard.object(forKey: expirationKey) as? Date

        if let storedDeviceID = Self.loadKey(service: deviceKeychainService, account: deviceKeychainAccount),
           !storedDeviceID.isEmpty {
            deviceID = storedDeviceID
        } else {
            deviceID = UIDevice.current.identifierForVendor?.uuidString.lowercased()
                ?? UUID().uuidString.lowercased()
            try? Self.saveKey(deviceID, service: deviceKeychainService, account: deviceKeychainAccount)
        }
    }

    /// Validate on launch/foreground. A definitive server failure always removes access.
    func refresh(force: Bool = false) {
        guard !refreshInFlight else { return }
        if !force, let lastValidationAt, Date().timeIntervalSince(lastValidationAt) < 45 {
            return
        }

        guard let key = storedKey, !key.isEmpty else {
            isAuthorized = false
            isLoading = false
            hasCompletedInitialCheck = true
            return
        }

        if let expirationDate, expirationDate <= Date() {
            revoke(message: "Sua chave expirou. Informe uma nova chave iOS.")
            hasCompletedInitialCheck = true
            return
        }

        refreshInFlight = true
        if !isAuthorized { isLoading = true }

        Task {
            do {
                let result = try await validate(key: key)
                apply(result, key: key)
            } catch let error as LicenseValidationError {
                if error.isDefinitive {
                    revoke(message: error.localizedDescription)
                } else {
                    // A temporary network error is not proof that a valid key was revoked.
                    if !isAuthorized { message = error.localizedDescription }
                    lastValidationAt = Date()
                }
            } catch {
                if !isAuthorized { message = "Não foi possível verificar sua chave agora." }
                lastValidationAt = Date()
            }
            isLoading = false
            refreshInFlight = false
            hasCompletedInitialCheck = true
        }
    }

    func activate(key rawKey: String) async {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            message = "Informe sua chave iOS."
            return
        }

        isLoading = true
        message = nil
        do {
            let result = try await validate(key: key)
            guard result.isValid else {
                revoke(message: result.message ?? "Chave inválida ou expirada.")
                isLoading = false
                return
            }
            try Self.saveKey(key, service: keychainService, account: keychainAccount)
            storedKey = key
            apply(result, key: key)
        } catch {
            isAuthorized = false
            message = (error as? LocalizedError)?.errorDescription ?? "Falha ao verificar a chave."
        }
        isLoading = false
    }

    private func apply(_ result: ValidationResult, key: String) {
        guard result.isValid else {
            revoke(message: result.message ?? "Chave inválida, expirada ou revogada.")
            return
        }
        storedKey = key
        isAuthorized = true
        message = nil
        expirationDate = result.expirationDate
        if let expirationDate { UserDefaults.standard.set(expirationDate, forKey: expirationKey) }
        lastValidationAt = Date()
    }

    private func revoke(message: String) {
        Self.deleteKey(service: keychainService, account: keychainAccount)
        storedKey = nil
        isAuthorized = false
        isLoading = false
        expirationDate = nil
        UserDefaults.standard.removeObject(forKey: expirationKey)
        self.message = message
    }

    private struct ValidationResult {
        let isValid: Bool
        let message: String?
        let expirationDate: Date?
    }

    private enum LicenseValidationError: LocalizedError {
        case invalidKey(message: String?)
        case server(message: String?)
        case network
        case invalidResponse

        var isDefinitive: Bool {
            switch self {
            case .invalidKey: return true
            case .server, .network, .invalidResponse: return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .invalidKey(let message): return message ?? "Chave inválida ou expirada."
            case .server(let message): return message ?? "O servidor recusou a validação."
            case .network: return "Sem conexão para verificar a chave."
            case .invalidResponse: return "A API retornou uma resposta inválida."
            }
        }
    }

    private func validate(key: String) async throws -> ValidationResult {
        guard key.count <= 100 else {
            throw LicenseValidationError.invalidKey(message: "A chave deve ter no máximo 100 caracteres.")
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        let input: [String: Any] = ["json": ["key": key, "deviceId": deviceID]]
        let data = try JSONSerialization.data(withJSONObject: input)
        components.queryItems = [URLQueryItem(name: "input", value: String(data: data, encoding: .utf8))]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LicenseValidationError.network
        }
        guard let http = response as? HTTPURLResponse else {
            throw LicenseValidationError.network
        }
        guard let root = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw LicenseValidationError.invalidResponse
        }

        let fields = Self.findLicenseFields(in: root)
        let responseMessage = fields["message"] as? String ?? fields["reason"] as? String
        guard (200..<300).contains(http.statusCode) else {
            throw LicenseValidationError.server(message: responseMessage)
        }

        let status = (fields["status"] as? String)?.lowercased()
        let success = Self.boolValue(fields["success"] ?? fields["ok"])
        let valid = Self.boolValue(fields["valid"] ?? fields["isValid"] ?? fields["is_valid"])
        let active = Self.boolValue(fields["active"])
        let expiration = Self.expirationDate(fields: fields)

        // The iOS contract requires every positive signal plus status=active.
        let accepted = success == true && valid == true && active == true && status == "active"
        if !accepted {
            if status == "rate_limited" || status == "frozen" {
                throw LicenseValidationError.server(message: responseMessage ?? Self.message(for: status))
            }
            throw LicenseValidationError.invalidKey(message: responseMessage ?? Self.message(for: status))
        }
        if let expiration, expiration <= Date() {
            throw LicenseValidationError.invalidKey(message: "Sua chave expirou. Informe uma nova chave iOS.")
        }

        return ValidationResult(isValid: true, message: responseMessage, expirationDate: expiration)
    }

    private static func findLicenseFields(in value: Any) -> [String: Any] {
        if let dictionary = value as? [String: Any] {
            if dictionary["status"] != nil || dictionary["success"] != nil || dictionary["active"] != nil {
                return dictionary
            }
            for child in dictionary.values {
                let found = findLicenseFields(in: child)
                if !found.isEmpty { return found }
            }
        } else if let array = value as? [Any] {
            for child in array {
                let found = findLicenseFields(in: child)
                if !found.isEmpty { return found }
            }
        }
        return [:]
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        if let value = value as? String { return ["true", "1", "yes"].contains(value.lowercased()) }
        return nil
    }

    private static func expirationDate(fields: [String: Any]) -> Date? {
        let keys = ["expiresAt", "expirationDate", "expires", "expiry", "validUntil", "expiration"]
        for key in keys {
            if let value = fields[key] as? String, let date = ISO8601DateFormatter().date(from: value) { return date }
            if let value = fields[key] as? NSNumber { return Date(timeIntervalSince1970: value.doubleValue > 2_000_000_000 ? value.doubleValue / 1000 : value.doubleValue) }
        }
        for key in ["remainingSeconds", "secondsLeft", "expiresIn"] {
            if let value = fields[key] as? NSNumber { return Date(timeIntervalSinceNow: value.doubleValue) }
        }
        return nil
    }

    private static func message(for status: String?) -> String {
        switch status {
        case "expired": return "Sua chave expirou. Informe uma nova chave iOS."
        case "revoked": return "Sua chave foi revogada. Informe uma nova chave iOS."
        case "device_mismatch": return "Esta chave está vinculada a outro dispositivo."
        case "rate_limited": return "Muitas tentativas. Aguarde e tente novamente."
        case "pending": return "Sua chave ainda está pendente."
        default: return "Chave inválida para iOS."
        }
    }

    private static func loadKey(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func saveKey(_ value: String, service: String, account: String) throws -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = data
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return true
    }

    private static func deleteKey(service: String, account: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as CFDictionary)
    }
}
