import Foundation

/// Public iOS endpoint configuration. Server secrets never belong in the app.
enum EndpointVault {
    static let licenseURLString = "https://proxysystem.org/api/trpc/proxyKeys.publicCheckKey"
    static let licenseURL = URL(string: licenseURLString)!
}
