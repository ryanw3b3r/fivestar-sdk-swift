//
//  Models.swift
//  FiveStarSupport
//
//  Data models for FiveStar Support API responses.

import Foundation

// MARK: - Response Type

/// Response type (bug, feature request, etc.)
public struct ResponseType: Codable, Sendable {
    public let id: String
    public let name: String
    public let slug: String
    public let color: String
    public let icon: String

    public init(id: String, name: String, slug: String, color: String, icon: String) {
        self.id = id
        self.name = name
        self.slug = slug
        self.color = color
        self.icon = icon
    }
}

// MARK: - Generate Customer ID Result

/// Result of generating a customer ID from the server
public struct GenerateCustomerIdResult: Codable, Sendable {
    public let customerId: String
    public let expiresAt: String
    public let deviceId: String

    public init(customerId: String, expiresAt: String, deviceId: String) {
        self.customerId = customerId
        self.expiresAt = expiresAt
        self.deviceId = deviceId
    }
}

// MARK: - Register Customer Options

/// Options for registering a customer
public struct RegisterCustomerOptions: Codable, Sendable {
    public let email: String?
    public let name: String?
    public let metadata: String?  // JSON-encoded string of metadata dictionary

    public init(email: String? = nil, name: String? = nil, metadata: String? = nil) {
        self.email = email
        self.name = name
        self.metadata = metadata
    }
}

// MARK: - Submit Response Options

/// Options for submitting a response
public struct SubmitResponseOptions: Codable, Sendable {
    public let customerId: String
    public let title: String
    public let description: String
    public let typeId: String
    public let email: String?
    public let name: String?
    public let metadata: String?  // JSON-encoded string of metadata dictionary

    public init(customerId: String, title: String, description: String, typeId: String, email: String? = nil, name: String? = nil, metadata: String? = nil) {
        self.customerId = customerId
        self.title = title
        self.description = description
        self.typeId = typeId
        self.email = email
        self.name = name
        self.metadata = metadata
    }
}

// MARK: - Submit Response Result

/// Result of submitting a response
public struct SubmitResponseResult: Codable, Sendable {
    public let success: Bool
    public let responseId: String
    public let message: String?

    public init(success: Bool, responseId: String, message: String? = nil) {
        self.success = success
        self.responseId = responseId
        self.message = message
    }
}

// MARK: - Customer Info

/// Customer information
public struct CustomerInfo: Codable, Sendable {
    public let id: String
    public let customerId: String
    public let email: String?
    public let name: String?

    public init(id: String, customerId: String, email: String? = nil, name: String? = nil) {
        self.id = id
        self.customerId = customerId
        self.email = email
        self.name = name
    }
}

// MARK: - Register Customer Result

/// Result of registering a customer
public struct RegisterCustomerResult: Codable, Sendable {
    public let success: Bool
    public let customer: CustomerInfo?
    public let message: String?

    public init(success: Bool, customer: CustomerInfo? = nil, message: String? = nil) {
        self.success = success
        self.customer = customer
        self.message = message
    }
}

// MARK: - Verify Customer Result

/// Customer verification result
public struct VerifyCustomerResult: Codable, Sendable {
    public let valid: Bool
    public let message: String?

    public init(valid: Bool, message: String? = nil) {
        self.valid = valid
        self.message = message
    }
}

// MARK: - API Error

/// API Error from FiveStar Support
public struct FiveStarAPIError: Error, LocalizedError, Sendable {
    public let message: String
    public let statusCode: Int?

    public init(message: String, statusCode: Int? = nil) {
        self.message = message
        self.statusCode = statusCode
    }

    public var errorDescription: String? {
        return message
    }
}

