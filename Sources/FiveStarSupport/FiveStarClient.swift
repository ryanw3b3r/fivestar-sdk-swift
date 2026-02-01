//
//  FiveStarClient.swift
//  FiveStarSupport
//
//  Simplified client for interacting with the FiveStar Support API.
//  Customer IDs are now generated server-side for improved security.

import Foundation

/// Configuration for the FiveStar Support client
public struct FiveStarClientConfig: Sendable {
    public let clientId: String
    public let apiUrl: String
    public let platform: String?
    public let appVersion: String?
    public let deviceModel: String?
    public let osVersion: String?

    public init(
        clientId: String,
        apiUrl: String? = nil,
        platform: String? = nil,
        appVersion: String? = nil,
        deviceModel: String? = nil,
        osVersion: String? = nil
    ) {
        self.clientId = clientId
        self.apiUrl = (apiUrl ?? "https://fivestar.support").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.platform = platform
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.osVersion = osVersion
    }
}

/// FiveStar Support Client
///
/// Simplified client for interacting with the FiveStar Support API.
/// Customer IDs are now generated server-side for improved security.
public class FiveStarClient: @unchecked Sendable {
    private let clientId: String
    private let apiUrl: String
    private let deviceInfo: DeviceInfo
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Initialize a new FiveStar Support client
    /// - Parameter config: Client configuration
    public init(config: FiveStarClientConfig) {
        self.clientId = config.clientId
        self.apiUrl = config.apiUrl
        self.deviceInfo = DeviceInfo(
            platform: config.platform,
            appVersion: config.appVersion,
            deviceModel: config.deviceModel,
            osVersion: config.osVersion
        )

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Initialize with individual parameters
    /// - Parameters:
    ///   - clientId: The client ID
    ///   - apiUrl: Optional API URL (defaults to https://fivestar.support)
    ///   - platform: Optional platform identifier (e.g., 'ios', 'web')
    ///   - appVersion: Optional app version string
    ///   - deviceModel: Optional device model
    ///   - osVersion: Optional OS version
    public convenience init(
        clientId: String,
        apiUrl: String? = nil,
        platform: String? = nil,
        appVersion: String? = nil,
        deviceModel: String? = nil,
        osVersion: String? = nil
    ) {
        self.init(config: FiveStarClientConfig(
            clientId: clientId,
            apiUrl: apiUrl,
            platform: platform,
            appVersion: appVersion,
            deviceModel: deviceModel,
            osVersion: osVersion
        ))
    }

    // MARK: - Private Helpers

    /// Get the API URL for a given path.
    private func getUrl(_ path: String) -> URL {
        let urlString = "\(apiUrl)\(path)"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL: \(urlString)")
        }
        return url
    }

    /// Get headers including device information for fingerprinting.
    private func getHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]

        // Add device fingerprinting headers
        if let platform = deviceInfo.platform {
            headers["X-FiveStar-Platform"] = platform
        }
        if let appVersion = deviceInfo.appVersion {
            headers["X-FiveStar-App-Version"] = appVersion
        }
        if let deviceModel = deviceInfo.deviceModel {
            headers["X-FiveStar-Device-Model"] = deviceModel
        }
        if let osVersion = deviceInfo.osVersion {
            headers["X-FiveStar-OS-Version"] = osVersion
        }

        return headers
    }

    /// Perform a GET request
    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        var request = URLRequest(url: getUrl(path))
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in getHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FiveStarAPIError(message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw FiveStarAPIError(message: "HTTP \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw FiveStarAPIError(message: "Failed to decode response: \(error.localizedDescription)")
        }
    }

    /// Perform a POST request
    private func post<Body: Encodable, T: Decodable>(_ path: String, body: Body, as type: T.Type) async throws -> T {
        var request = URLRequest(url: getUrl(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in getHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw FiveStarAPIError(message: "Failed to encode request: \(error.localizedDescription)")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FiveStarAPIError(message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorDict = try? decoder.decode([String: String].self, from: data),
               let message = errorDict["error"] ?? errorDict["message"] {
                throw FiveStarAPIError(message: message, statusCode: httpResponse.statusCode)
            }
            throw FiveStarAPIError(message: "HTTP \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw FiveStarAPIError(message: "Failed to decode response: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    /// Get all available response types for this client.
    /// - Returns: Array of response types
    public func getResponseTypes() async throws -> [ResponseType] {
        struct Response: Codable {
            let types: [ResponseType]?
        }

        var components = URLComponents(string: getUrl("/api/responses/types"))
        components?.queryItems = [URLQueryItem(name: "clientId", value: clientId)]

        guard let url = components?.url else {
            throw FiveStarAPIError(message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in getHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FiveStarAPIError(message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw FiveStarAPIError(message: "HTTP \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
        }

        let result = try decoder.decode(Response.self, from: data)
        return result.types ?? []
    }

    /// Generate a new customer ID from the server.
    ///
    /// Customer IDs are now generated server-side with cryptographic signing.
    /// This replaces the previous client-side generation approach.
    /// - Returns: Generated customer ID with expiration info
    public func generateCustomerId() async throws -> GenerateCustomerIdResult {
        struct RequestBody: Codable {
            let clientId: String
        }

        return try await post("/api/customers/generate", body: RequestBody(clientId: clientId), as: GenerateCustomerIdResult.self)
    }

    /// Register a customer ID for this client.
    ///
    /// This should be called after generating a customer ID to associate
    /// it with optional customer information (email, name).
    ///
    /// - Parameters:
    ///   - customerId: The customer ID from generateCustomerId()
    ///   - options: Optional customer information
    /// - Returns: Registration result
    public func registerCustomer(customerId: String, options: RegisterCustomerOptions? = nil) async throws -> RegisterCustomerResult {
        struct RequestBody: Codable {
            let clientId: String
            let customerId: String
            let email: String?
            let name: String?
            let metadata: String?

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(clientId, forKey: .clientId)
                try container.encode(customerId, forKey: .customerId)
                try container.encodeIfPresent(email, forKey: .email)
                try container.encodeIfPresent(name, forKey: .name)
                try container.encodeIfPresent(metadata, forKey: .metadata)
            }

            private enum CodingKeys: String, CodingKey {
                case clientId, customerId, email, name, metadata
            }
        }

        let body = RequestBody(
            clientId: clientId,
            customerId: customerId,
            email: options?.email,
            name: options?.name,
            metadata: options?.metadata
        )

        return try await post("/api/customers", body: body, as: RegisterCustomerResult.self)
    }

    /// Check if a customer ID is valid and registered for this client.
    ///
    /// - Parameter customerId: The customer ID to verify
    /// - Returns: Verification result
    public func verifyCustomer(customerId: String) async throws -> VerifyCustomerResult {
        struct RequestBody: Codable {
            let clientId: String
            let customerId: String
        }

        let body = RequestBody(clientId: clientId, customerId: customerId)

        do {
            return try await post("/api/customers/verify", body: body, as: VerifyCustomerResult.self)
        } catch {
            return VerifyCustomerResult(valid: false, message: "Verification failed")
        }
    }

    /// Submit a new response/feedback on behalf of a customer.
    ///
    /// - Parameter options: Response options including customer ID, title, description, and type
    /// - Returns: The submitted response result
    public func submitResponse(options: SubmitResponseOptions) async throws -> SubmitResponseResult {
        struct RequestBody: Codable {
            let clientId: String
            let customerId: String
            let title: String
            let description: String
            let responseTypeId: String
            let customerEmail: String?
            let customerName: String?
            let metadata: String?

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(clientId, forKey: .clientId)
                try container.encode(customerId, forKey: .customerId)
                try container.encode(title, forKey: .title)
                try container.encode(description, forKey: .description)
                try container.encode(responseTypeId, forKey: .responseTypeId)
                try container.encodeIfPresent(customerEmail, forKey: .customerEmail)
                try container.encodeIfPresent(customerName, forKey: .customerName)
                try container.encodeIfPresent(metadata, forKey: .metadata)
            }

            private enum CodingKeys: String, CodingKey {
                case clientId, customerId, title, description, responseTypeId, customerEmail, customerName, metadata
            }
        }

        let body = RequestBody(
            clientId: clientId,
            customerId: options.customerId,
            title: options.title,
            description: options.description,
            responseTypeId: options.typeId,
            customerEmail: options.email,
            customerName: options.name,
            metadata: options.metadata
        )

        return try await post("/api/responses", body: body, as: SubmitResponseResult.self)
    }

    /// Get a public feedback page URL for this client.
    /// - Parameter locale: Optional locale for the page
    /// - Returns: The public URL
    public func getPublicUrl(locale: String? = nil) -> String {
        let localePrefix = locale.map { "/\($0)" } ?? ""
        return "\(apiUrl)\(localePrefix)/c/\(clientId)"
    }
}

/// Device information for fingerprinting
private struct DeviceInfo: Sendable {
    let platform: String?
    let appVersion: String?
    let deviceModel: String?
    let osVersion: String?
}
